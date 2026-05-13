#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-local-validate}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$ROOT_DIR/script"
BUILD_NUMBER_DEFAULT="$(date -u +%Y%m%d%H%M)"
# shellcheck source=app_metadata.sh
source "$SCRIPT_DIR/app_metadata.sh"
RELEASE_DIR="$ROOT_DIR/Release"
BUILD_DIR="$RELEASE_DIR/build"
PRODUCT_DIR="$RELEASE_DIR/product"
APP_BUNDLE="$PRODUCT_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ENTITLEMENTS="$RELEASE_DIR/$APP_NAME-AppStore.entitlements"
EXPANDED_ENTITLEMENTS="$PRODUCT_DIR/$APP_NAME-expanded-entitlements.plist"
ZIP_PATH="$PRODUCT_DIR/$APP_NAME-$VERSION-$BUILD_NUMBER.zip"
PKG_PATH="$PRODUCT_DIR/$APP_NAME-$VERSION-$BUILD_NUMBER.pkg"

usage() {
  cat <<EOF
usage: $0 [local-validate|app-store]

local-validate  Build a sandboxed ad-hoc signed app and ZIP.
app-store       Build a signed app and pkg for App Store upload.

For app-store mode, set:
  SIGNING_IDENTITY="Apple Distribution: Your Name (TEAMID)"
  INSTALLER_IDENTITY="3rd Party Mac Developer Installer: Your Name (TEAMID)"

Optional:
  BUNDLE_ID, VERSION, BUILD_NUMBER, MIN_SYSTEM_VERSION, CATEGORY
EOF
}

case "$MODE" in
  local-validate|app-store)
    ;;
  --help|-h|help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if [[ "$MODE" == "app-store" ]]; then
  : "${SIGNING_IDENTITY:?Set SIGNING_IDENTITY for app-store mode.}"
  : "${INSTALLER_IDENTITY:?Set INSTALLER_IDENTITY for app-store mode.}"
else
  SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"
fi

cd "$ROOT_DIR"

rm -rf "$BUILD_DIR" "$PRODUCT_DIR"
mkdir -p "$BUILD_DIR" "$APP_MACOS" "$APP_RESOURCES"

swift build -c release
BUILD_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"

install -m 755 "$BUILD_BINARY" "$APP_BINARY"
install -m 644 "$ROOT_DIR/Resources/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
install -m 644 "$RELEASE_DIR/APP-STORE-LICENSE.md" "$APP_RESOURCES/APP-STORE-LICENSE.md"
install -m 644 "$RELEASE_DIR/COMMERCIAL-NOTICE.md" "$APP_RESOURCES/COMMERCIAL-NOTICE.md"

"$SCRIPT_DIR/write_info_plist.sh" "$INFO_PLIST" release

/usr/bin/plutil -lint "$INFO_PLIST" "$ENTITLEMENTS"

CODESIGN_ARGS=(
  --force
  --deep
  --strict
  --options runtime
  --entitlements "$ENTITLEMENTS"
  --sign "$SIGNING_IDENTITY"
)

if [[ "$SIGNING_IDENTITY" == "-" ]]; then
  CODESIGN_ARGS+=(--timestamp=none)
fi

/usr/bin/codesign "${CODESIGN_ARGS[@]}" "$APP_BUNDLE"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
/usr/bin/codesign -d --entitlements :- "$APP_BUNDLE" >"$EXPANDED_ENTITLEMENTS" 2>/dev/null

if [[ "$MODE" == "app-store" ]]; then
  /usr/bin/productbuild \
    --component "$APP_BUNDLE" /Applications \
    --sign "$INSTALLER_IDENTITY" \
    "$PKG_PATH"
  echo "Built App Store package: $PKG_PATH"
else
  /usr/bin/ditto -c -k --norsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
  echo "Built local validation app: $APP_BUNDLE"
  echo "Built local validation zip: $ZIP_PATH"
fi

echo "Expanded entitlements: $EXPANDED_ENTITLEMENTS"

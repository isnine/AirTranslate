# AirTranslate Mac App Store Release Kit

This folder contains the release-only materials for preparing AirTranslate for paid Mac App Store distribution.

## What This Adds

- App Store sandbox entitlements.
- A repeatable release bundle and package script.
- A commercial release notice instead of shipping the App Store release as MIT-licensed material.
- App Store Connect metadata and review-note drafts.
- A privacy notice draft aligned with the current local-first app behavior.

## Assumptions

- The app name remains `AirTranslate`.
- The bundle identifier is `dev.appcaster.AirTranslate`.
- The current release-candidate version is `1.2.0`.
- The app is sold as a paid Mac App Store app.
- The source tree may still contain the root MIT `LICENSE`; this release kit does not ship that license as the commercial App Store release license.
- The release bundle must never include user API keys, bearer tokens, signing private keys, provisioning profiles, or local `.env` files.

Override the defaults when needed:

```bash
BUNDLE_ID="com.example.AirTranslate" VERSION="1.2.0" BUILD_NUMBER="120"
```

## Local Validation Build

This creates a sandboxed, ad-hoc signed app bundle and ZIP for local inspection.

```bash
./Release/build_app_store_release.sh local-validate
```

Outputs:

```text
Release/product/AirTranslate.app
Release/product/AirTranslate-<version>-<build>.zip
Release/product/AirTranslate-expanded-entitlements.plist
```

`Release/product/` is a local build-output folder and should stay out of commits.

## App Store Package Build

This requires Apple Developer Program signing certificates installed in Keychain.

```bash
SIGNING_IDENTITY="Apple Distribution: Your Name (TEAMID)" \
INSTALLER_IDENTITY="3rd Party Mac Developer Installer: Your Name (TEAMID)" \
./Release/build_app_store_release.sh app-store
```

Outputs:

```text
Release/product/AirTranslate.app
Release/product/AirTranslate-<version>-<build>.pkg
Release/product/AirTranslate-expanded-entitlements.plist
```

Upload the package with Transporter or another Apple-supported App Store Connect upload path.

## Secret Safety Gate

Before committing or uploading a release candidate, run a secret scan over the source tree and current diff. The app may mention `OPENAI_API_KEY` as a Keychain account name, but it must not contain a real key value, bearer credential, signing private key, provisioning profile, or `.env` file.

Suggested local checks:

```bash
rg -n --hidden --glob '!.git/**' --glob '!.build/**' --glob '!Release/product/**' \
  -i 'bearer|private key|client secret|access token|refresh token|api key' .

git diff -- . ':(exclude).build/**' ':(exclude)Release/product/**' | \
  rg -n -i 'bearer|private key|client secret|access token|refresh token|api key'
```

## Important App Store Constraints

- Mac App Store apps must enable App Sandbox.
- App Store Connect requires an app record before build upload.
- Paid apps require a Paid Apps Agreement before sale.
- Builds can be uploaded through Xcode, Transporter, altool, or App Store Connect API upload tooling.
- System audio capture needs `NSAudioCaptureUsageDescription`.
- Speech recognition needs `NSSpeechRecognitionUsageDescription`.
- ScreenCaptureKit prompts for Screen Recording permission on first use.

Official references:

- [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox)
- [Configuring the macOS App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox/)
- [NSAudioCaptureUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nsaudiocaptureusagedescription)
- [Asking Permission to Use Speech Recognition](https://developer.apple.com/documentation/Speech/asking-permission-to-use-speech-recognition)
- [Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [App pricing and availability](https://developer.apple.com/help/app-store-connect/reference/app-pricing-and-availability/)

## My Practical Read

The current SwiftPM app can be packaged for local use, but App Store sale readiness depends on signing, sandbox runtime testing, App Store Connect metadata, screenshots, privacy answers, and Apple review. This folder gives the project a clean release lane without disturbing the local development script.

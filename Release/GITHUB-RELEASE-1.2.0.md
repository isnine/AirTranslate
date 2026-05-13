# AirTranslate 1.2.0

Open-source release for GPT realtime captions, multilingual documentation, and the Apache 2.0 release bundle.

AirTranslate is an independent open-source project and is not affiliated with Apple or OpenAI.

## Highlights

- Optional OpenAI Realtime transcription and translation modes.
- Realtime translation-only mode with optional translated audio playback.
- Floating captions in GPT mode now show the current live caption unit instead of the accumulated transcript, making the overlay feel closer to movie subtitles.
- OpenAI API keys are user-provided runtime data stored in macOS Keychain.
- English, Korean, Japanese, and Simplified Chinese README files.
- Apache 2.0 release bundle with `LICENSE` and `NOTICE` included.

## Download

Download `AirTranslate-1.2.0.zip` from this release, unzip it, then open `AirTranslate.app`.

macOS may require you to approve the app in Privacy & Security because this ZIP is an open-source ad-hoc signed build, not a notarized distribution.

## Verification

- `swift build`
- `swift test`
- `./Release/build_open_source_release.sh`
- Secret-pattern scan for API keys, bearer tokens, private keys, and local secret files.

## Privacy

Apple mode uses macOS system frameworks. GPT mode is optional and only sends the necessary audio or text to OpenAI after the user provides an API key.

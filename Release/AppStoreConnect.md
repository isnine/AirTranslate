# AirTranslate App Store Connect Draft

Use this as the first App Store Connect pass. Replace bracketed fields before submission.

## App Record

- Platform: macOS
- Name: AirTranslate
- Subtitle: Live captions for Mac audio
- Bundle ID: `dev.appcaster.AirTranslate`
- SKU: `airtranslate-macos`
- Category: Productivity
- Pricing: Paid app
- Paid Apps Agreement: Required before sale if the price is not free.

## Version Metadata

- Version: `1.2.0`
- Copyright: `2026 [Copyright Owner]`
- Support URL: `[support URL]`
- Marketing URL: `[optional marketing URL]`
- Privacy Policy URL: `[privacy policy URL]`

## Korean Description Draft

AirTranslate는 Mac에서 재생되는 소리를 실시간으로 기록하고 번역하는 macOS 앱입니다.

영상, 회의, 강의 같은 오디오를 재생하면 원문 기록과 번역을 나란히 확인할 수 있고, 필요하면 플로팅 자막 창으로 화면 위에 띄워 볼 수 있습니다.

AirTranslate는 자체 서버, 계정, 광고, 분석 SDK 없이 Apple의 macOS 시스템 프레임워크를 중심으로 동작합니다. 저장된 기록은 사용자 Mac의 앱 컨테이너 안에 보관됩니다.

GPT 모드는 사용자가 직접 입력한 OpenAI API 키가 있을 때만 동작하며, 키는 macOS Keychain에 저장됩니다. 앱과 릴리즈 패키지에는 API 키가 포함되지 않습니다.

## Keywords Draft

translation, captions, transcription, speech, audio, subtitle, Korean, English, meeting, lecture

## Review Notes Draft

AirTranslate captures system audio only after the user presses the start capture control.

The app requests Screen Recording because ScreenCaptureKit requires this permission to access the selected display stream and system audio. AirTranslate does not save screen frames.

The app requests System Audio Recording to capture audio playing on the Mac.

The app requests Speech Recognition to convert captured audio into text. Translation is performed through Apple's system Translation framework.

The app has no developer-operated server, account system, analytics SDK, advertising SDK, or tracking SDK. Saved transcripts are local app data.

OpenAI-powered GPT mode is optional. The app does not ship with an OpenAI API key or bearer token. Users must enter their own key at runtime, and AirTranslate stores that user-provided key in macOS Keychain.

## Privacy Label Working Answer

Candidate answer: Data Not Collected by the developer.

Verify this before submission against the final binary and App Store Connect questionnaire. This answer depends on keeping the app free of analytics, ads, tracking SDKs, custom network clients, accounts, and developer-operated servers.

## Screenshot Requirements

Prepare at least one required Mac screenshot with a 16:10 aspect ratio. Apple currently accepts these Mac screenshot sizes:

- `1280 x 800`
- `1440 x 900`
- `2560 x 1600`
- `2880 x 1800`

Suggested screenshots:

- Main transcription and translation workspace.
- Floating caption window over a real playback context.
- Saved transcripts management view.
- Settings view showing language and caption controls.

Prepared screenshot files:

- `Release/assets/app-store-screenshots/01-main-workspace-2880x1800.png`
- `Release/assets/app-store-screenshots/02-floating-captions-2880x1800.png`
- `Release/assets/app-store-screenshots/03-saved-transcripts-2880x1800.png`
- `Release/assets/app-store-screenshots/04-privacy-settings-2880x1800.png`

## App Review Risk Checklist

- Confirm sandboxed build can start capture after permissions are granted.
- Confirm saved transcripts write inside the sandbox container.
- Confirm no unsupported entitlements are present.
- Confirm the app bundle and package contain no API keys, bearer tokens, private signing keys, provisioning profiles, or `.env` files.
- Confirm `NSAudioCaptureUsageDescription` is present for system audio capture.
- Confirm `NSSpeechRecognitionUsageDescription` is present for Speech.
- Confirm the app name and subtitle fit App Store length limits.
- Confirm the privacy policy matches the final app behavior.
- Confirm macOS 26.0 minimum target is intentional because it narrows the customer base.

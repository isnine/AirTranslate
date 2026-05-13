# AirTranslate Privacy Notice Draft

AirTranslate transcribes and translates audio playing on the user's Mac.

## Data Handling

- AirTranslate does not require an account.
- AirTranslate does not include a developer-operated backend.
- AirTranslate does not include analytics, ads, tracking SDKs, or telemetry SDKs.
- Captured audio is used for live transcription and translation while the user has capture running.
- Saved transcripts are stored locally in the app's macOS container.
- Settings are stored locally with macOS app preferences.

## Apple System Services

AirTranslate uses Apple system frameworks, including ScreenCaptureKit, Speech, and Translation.

Speech recognition and language assets may be processed or downloaded through Apple-managed system services. AirTranslate does not send audio, transcripts, or translations to a server operated by this app's developer.

## Permissions

AirTranslate requests only permissions tied to its core function:

- Screen Recording, because ScreenCaptureKit requires it for system audio capture.
- System Audio Recording, because the app captures audio playing on the Mac.
- Speech Recognition, because the app converts captured audio into text.

AirTranslate does not request Contacts, Calendar, Photos, Location, browser data, or Full Disk Access.

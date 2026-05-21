import Foundation
import Testing
@testable import AirTranslate

@Suite
struct TranslationSessionStoreLanguageCandidateTests {
    @Test
    func supportedLanguageOrderIsUsedForAutoDetectionCandidateSelection() {
        let candidates = LanguageOption.prioritizedAutoDetectionCandidates(
            sourceLanguage: LanguageOption.korean,
            targetLanguage: LanguageOption.korean
        )

        #expect(candidates.first == LanguageOption.english)
    }

    @Test
    func targetLanguageIsExcludedFromAutoDetectionCandidates() {
        let candidates = LanguageOption.prioritizedAutoDetectionCandidates(
            sourceLanguage: LanguageOption.korean,
            targetLanguage: LanguageOption.english
        )

        #expect(!candidates.contains(LanguageOption.english))
    }

    @Test
    func targetLanguageIsExcludedWhenManualSourceMatchesTarget() {
        let candidates = LanguageOption.prioritizedAutoDetectionCandidates(
            sourceLanguage: LanguageOption.korean,
            targetLanguage: LanguageOption.korean
        )

        #expect(candidates.first == LanguageOption.english)
        #expect(!candidates.contains(LanguageOption.korean))
    }

    @Test
    func autoDetectionCandidatesIncludeAllNonTargetSupportedLanguagesInSourcePriorityOrder() {
        let candidates = LanguageOption.prioritizedAutoDetectionCandidates(
            sourceLanguage: LanguageOption.korean,
            targetLanguage: LanguageOption.english
        )
        let expected = LanguageOption.supported.filter { $0 != LanguageOption.english }

        #expect(candidates == expected)
        #expect(Set(candidates.map({ $0.id })) == Set(expected.map({ $0.id })))
    }

    @Test
    func everySupportedLanguageIsExcludedWhenItIsTheTarget() {
        for target in LanguageOption.supported {
            let candidates = LanguageOption.prioritizedAutoDetectionCandidates(
                sourceLanguage: LanguageOption.english,
                targetLanguage: target
            )

            #expect(!candidates.contains(target))
            #expect(candidates.count == LanguageOption.supported.count - 1)
        }
    }

    @Test
    func autoDetectionRequestsConfirmationForLanguageChangeAfterSilence() {
        let shouldConfirm = AutoDetectionLanguageChangePolicy.shouldRequestConfirmation(
            isAutoDetectionEnabled: true,
            activeLanguage: LanguageOption.english,
            detectedLanguage: LanguageOption.supported[2],
            confidence: 0.9,
            hadLongSilence: true,
            hasVisibleTranscript: true,
            minimumSwitchConfidence: 0.72
        )

        #expect(shouldConfirm)
    }

    @Test
    func autoDetectionDoesNotRequestConfirmationWithoutSilence() {
        let shouldConfirm = AutoDetectionLanguageChangePolicy.shouldRequestConfirmation(
            isAutoDetectionEnabled: true,
            activeLanguage: LanguageOption.english,
            detectedLanguage: LanguageOption.supported[2],
            confidence: 0.9,
            hadLongSilence: false,
            hasVisibleTranscript: true,
            minimumSwitchConfidence: 0.72
        )

        #expect(!shouldConfirm)
    }

    @Test
    func autoDetectionDoesNotRequestConfirmationForLowConfidenceSwitch() {
        let shouldConfirm = AutoDetectionLanguageChangePolicy.shouldRequestConfirmation(
            isAutoDetectionEnabled: true,
            activeLanguage: LanguageOption.english,
            detectedLanguage: LanguageOption.supported[2],
            confidence: 0.5,
            hadLongSilence: true,
            hasVisibleTranscript: true,
            minimumSwitchConfidence: 0.72
        )

        #expect(!shouldConfirm)
    }

    @Test
    func autoDetectionDoesNotRequestConfirmationForInitialLanguageDetection() {
        let shouldConfirm = AutoDetectionLanguageChangePolicy.shouldRequestConfirmation(
            isAutoDetectionEnabled: true,
            activeLanguage: nil,
            detectedLanguage: LanguageOption.supported[2],
            confidence: 0.9,
            hadLongSilence: true,
            hasVisibleTranscript: false,
            minimumSwitchConfidence: 0.72
        )

        #expect(!shouldConfirm)
    }

    @Test
    func longSessionCaptionLineTrimsDisplayOnly() {
        let text = (1...500)
            .map { "Live transcript line \($0) keeps accumulating during a long session." }
            .joined(separator: "\n")
        let line = CaptionLine(
            sourceText: text,
            translatedText: text,
            createdAt: Date(),
            isFinal: false,
            usesLongSessionDisplay: true
        )

        #expect(line.sourceText == text)
        #expect(line.translatedText == text)
        #expect(line.sourceDisplayText != text)
        #expect(line.translatedDisplayText != text)
        #expect(line.sourceDisplayText.hasPrefix("..."))
        #expect(line.translatedDisplayText.hasPrefix("..."))
    }

    @Test
    func immediateFloatingCaptionPresentationBypassesDwell() {
        let presentedAt = Date()

        #expect(
            FloatingCaptionPresentationPolicy.canPresentUpdate(
                isImmediateDisplayEnabled: true,
                presentedText: "Hello",
                translatedText: "",
                candidateText: "Hello there",
                presentedAt: presentedAt,
                now: presentedAt.addingTimeInterval(0.1)
            )
        )
    }

    @Test
    func stableFloatingCaptionPresentationKeepsDwell() {
        let presentedAt = Date()

        #expect(
            !FloatingCaptionPresentationPolicy.canPresentUpdate(
                isImmediateDisplayEnabled: false,
                presentedText: "Hello, this subtitle should stay readable.",
                translatedText: "",
                candidateText: "A completely revised subtitle arrives quickly.",
                presentedAt: presentedAt,
                now: presentedAt.addingTimeInterval(0.5)
            )
        )
    }

    @Test
    func floatingCaptionTextAlignmentMapsToSwiftUIAlignment() {
        #expect(FloatingCaptionTextAlignment.leading.textAlignment == .leading)
        #expect(FloatingCaptionTextAlignment.center.textAlignment == .center)
    }

    @Test
    func azureRealtimeURLUsesWebSocketSessionEndpoint() {
        let config = OpenAIRealtimeProviderConfig.azure(
            host: "example.openai.azure.com",
            apiKey: "test-key"
        )

        #expect(
            config.transcriptionURL()?.absoluteString
                == "wss://example.openai.azure.com/openai/v1/realtime?model=gpt-realtime-1.5"
        )
        #expect(
            config.translationURL(modelID: "gpt-realtime-translate")?.absoluteString
                == "wss://example.openai.azure.com/openai/v1/realtime/translations?model=gpt-realtime-translate"
        )
    }

    @Test
    func azureTranscriptionSessionUpdateUsesRealtimeSessionWithWhisperInput() throws {
        let payload = try OpenAIRealtimeTranscriber.sessionUpdatePayload(
            language: LanguageOption.supported[0],
            modelID: "gpt-realtime-whisper",
            outputMode: .transcription,
            providerKind: .azure
        )
        let json = try #require(try JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
        let session = try #require(json["session"] as? [String: Any])
        let audio = try #require(session["audio"] as? [String: Any])
        let input = try #require(audio["input"] as? [String: Any])
        let transcription = try #require(input["transcription"] as? [String: Any])
        let turnDetection = try #require(input["turn_detection"] as? [String: Any])

        #expect(session["type"] as? String == "realtime")
        #expect(transcription["model"] as? String == "gpt-realtime-whisper")
        #expect(transcription["language"] as? String == "en")
        #expect(turnDetection["type"] as? String == "server_vad")
        #expect(turnDetection["threshold"] as? Double == 0.5)
    }

    @Test
    func azureTranslationSessionUpdateDeclaresWhisperInputConfig() throws {
        let payload = try OpenAIRealtimeTranscriber.sessionUpdatePayload(
            language: LanguageOption.supported[3],
            modelID: "gpt-realtime-translate",
            outputMode: .translationOnly,
            providerKind: .azure
        )
        let json = try #require(try JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
        let session = try #require(json["session"] as? [String: Any])
        let audio = try #require(session["audio"] as? [String: Any])
        let input = try #require(audio["input"] as? [String: Any])
        let transcription = try #require(input["transcription"] as? [String: Any])
        let noiseReduction = try #require(input["noise_reduction"] as? [String: Any])
        let output = try #require(audio["output"] as? [String: Any])

        #expect(input["format"] == nil)
        #expect(transcription["model"] as? String == "gpt-realtime-whisper")
        #expect(noiseReduction["type"] as? String == "near_field")
        #expect(output["language"] as? String == "zh")
    }

    @Test
    func openAITranslationSessionUpdateOmitsInputTranscription() throws {
        let payload = try OpenAIRealtimeTranscriber.sessionUpdatePayload(
            language: LanguageOption.supported[3],
            modelID: "gpt-realtime-translate",
            outputMode: .translationOnly,
            providerKind: .openAI
        )
        let json = try #require(try JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
        let session = try #require(json["session"] as? [String: Any])
        let audio = try #require(session["audio"] as? [String: Any])
        let output = try #require(audio["output"] as? [String: Any])

        #expect(audio["input"] == nil)
        #expect(output["language"] as? String == "zh")
    }
}

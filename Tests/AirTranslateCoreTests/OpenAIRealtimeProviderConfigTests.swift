import Foundation
import Testing
@testable import AirTranslate

@Suite
struct OpenAIRealtimeProviderConfigTests {
    @Test
    func openAIProviderUsesBearerAuthorizationOnly() {
        let config = OpenAIRealtimeProviderConfig.openAI(apiKey: "openai-test-key")
        var request = URLRequest(url: URL(string: "wss://api.openai.com/v1/realtime")!)

        config.apply(to: &request)

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer openai-test-key")
        #expect(request.value(forHTTPHeaderField: "api-key") == nil)
    }

    @Test
    func azureProviderUsesAPIKeyHeaderOnly() {
        let config = OpenAIRealtimeProviderConfig.azure(
            host: "example.openai.azure.com",
            apiKey: "azure-test-key"
        )
        var request = URLRequest(url: URL(string: "wss://example.openai.azure.com/openai/v1/realtime")!)

        config.apply(to: &request)

        #expect(request.value(forHTTPHeaderField: "api-key") == "azure-test-key")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test
    func openAIRealtimeURLsUsePublicRealtimeEndpoints() {
        let config = OpenAIRealtimeProviderConfig.openAI(apiKey: "test-key")

        #expect(
            config.transcriptionURL(modelID: "gpt-realtime-whisper")?.absoluteString
                == "wss://api.openai.com/v1/realtime?intent=transcription"
        )
        #expect(
            config.translationURL(modelID: "gpt-realtime-translate")?.absoluteString
                == "wss://api.openai.com/v1/realtime/translations?model=gpt-realtime-translate"
        )
    }

    @Test
    func azureEndpointNormalizationKeepsOnlySchemeHostAndPort() {
        let endpoint = " https://example.openai.azure.com:444/openai/deployments/demo?api-version=preview "

        #expect(AzureOpenAIEndpoint.normalize(endpoint) == "https://example.openai.azure.com:444")
        #expect(AzureOpenAIEndpoint.host(from: endpoint) == "example.openai.azure.com")
    }

    @Test
    func bareAzureEndpointDefaultsToHTTPS() {
        #expect(
            AzureOpenAIEndpoint.normalize("example.openai.azure.com")
                == "https://example.openai.azure.com"
        )
        #expect(AzureOpenAIEndpoint.host(from: "example.openai.azure.com") == "example.openai.azure.com")
    }

    @Test
    func azureTranscriptionSessionAlwaysUsesWhisperInputModel() throws {
        let payload = try OpenAIRealtimeTranscriber.sessionUpdatePayload(
            language: LanguageOption.english,
            modelID: "unexpected-session-model",
            outputMode: .transcription,
            providerKind: .azure
        )
        let json = try #require(try JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
        let session = try #require(json["session"] as? [String: Any])
        let audio = try #require(session["audio"] as? [String: Any])
        let input = try #require(audio["input"] as? [String: Any])
        let format = try #require(input["format"] as? [String: Any])
        let transcription = try #require(input["transcription"] as? [String: Any])

        #expect(json["type"] as? String == "session.update")
        #expect(session["type"] as? String == "realtime")
        #expect(format["type"] as? String == "audio/pcm")
        #expect(format["rate"] as? Int == 24_000)
        #expect(transcription["model"] as? String == "gpt-realtime-whisper")
        #expect(transcription["language"] as? String == "en")
    }

    @Test
    func openAITranscriptionSessionUsesSelectedWhisperModel() throws {
        let payload = try OpenAIRealtimeTranscriber.sessionUpdatePayload(
            language: LanguageOption.korean,
            modelID: "gpt-realtime-whisper",
            outputMode: .transcription,
            providerKind: .openAI
        )
        let json = try #require(try JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
        let session = try #require(json["session"] as? [String: Any])
        let audio = try #require(session["audio"] as? [String: Any])
        let input = try #require(audio["input"] as? [String: Any])
        let transcription = try #require(input["transcription"] as? [String: Any])
        let noiseReduction = try #require(input["noise_reduction"] as? [String: Any])

        #expect(json["type"] as? String == "session.update")
        #expect(session["type"] as? String == "transcription")
        #expect(transcription["model"] as? String == "gpt-realtime-whisper")
        #expect(transcription["language"] as? String == "ko")
        #expect(noiseReduction["type"] as? String == "near_field")
    }

    @Test
    func realtimeTranslationSessionTargetsOutputLanguage() throws {
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
        let output = try #require(audio["output"] as? [String: Any])

        #expect(json["type"] as? String == "session.update")
        #expect(transcription["model"] as? String == "gpt-realtime-whisper")
        #expect(output["language"] as? String == "zh")
    }
}

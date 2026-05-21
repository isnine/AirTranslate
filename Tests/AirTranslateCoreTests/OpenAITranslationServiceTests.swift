import Foundation
import Testing
@testable import AirTranslate

@Suite
struct OpenAITranslationServiceTests {
    @Test
    func translatePostsResponsesRequestWithRealtimeTranslateModel() async throws {
        let httpClient = CapturingOpenAITranslationHTTPClient(
            data: Data(#"{"output_text":"  Translated hello  "}"#.utf8),
            statusCode: 200
        )
        let service = OpenAITranslationService(
            apiKeyProvider: StaticOpenAIAPIKeyProvider(apiKey: "test-api-key"),
            httpClient: httpClient
        )

        let translation = try await service.translate(
            "Hello",
            source: .english,
            target: .korean,
            model: .gptRealtimeTranslate
        )
        let request = try #require(await httpClient.lastRequest)
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

        #expect(translation == "Translated hello")
        #expect(request.url?.absoluteString == "https://api.openai.com/v1/responses")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-api-key")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(json["model"] as? String == "gpt-realtime-translate")
        #expect(json["input"] as? String == "Hello")
        #expect(json["store"] as? Bool == false)
        #expect((json["instructions"] as? String)?.contains("English") == true)
        #expect((json["instructions"] as? String)?.contains("Korean") == true)
    }

    @Test
    func translateReadsFirstNestedOutputTextWhenOutputTextIsMissing() async throws {
        let response = Data(
            #"{"output":[{"content":[{"text":"Bonjour"}]}]}"#.utf8
        )
        let service = OpenAITranslationService(
            apiKeyProvider: StaticOpenAIAPIKeyProvider(apiKey: "test-api-key"),
            httpClient: CapturingOpenAITranslationHTTPClient(data: response, statusCode: 200)
        )

        let translation = try await service.translate(
            "Hello",
            source: .english,
            target: LanguageOption.supported[5],
            model: .gptRealtimeTranslate
        )

        #expect(translation == "Bonjour")
    }

    @Test
    func translateThrowsRequestFailedWithServerMessage() async throws {
        let response = Data(#"{"error":{"message":"bad deployment"}}"#.utf8)
        let service = OpenAITranslationService(
            apiKeyProvider: StaticOpenAIAPIKeyProvider(apiKey: "test-api-key"),
            httpClient: CapturingOpenAITranslationHTTPClient(data: response, statusCode: 404)
        )

        await #expect(throws: OpenAITranslationError.requestFailed(statusCode: 404, message: "bad deployment")) {
            _ = try await service.translate(
                "Hello",
                source: .english,
                target: .korean,
                model: .gptRealtimeTranslate
            )
        }
    }

    @Test
    func translateDoesNotCallNetworkWhenModelIsOff() async throws {
        let httpClient = CapturingOpenAITranslationHTTPClient(
            data: Data(#"{"output_text":"ignored"}"#.utf8),
            statusCode: 200
        )
        let service = OpenAITranslationService(
            apiKeyProvider: StaticOpenAIAPIKeyProvider(apiKey: nil),
            httpClient: httpClient
        )

        let translation = try await service.translate(
            "Hello",
            source: .english,
            target: .korean,
            model: .off
        )

        #expect(translation == "Hello")
        #expect(await httpClient.lastRequest == nil)
    }

    @Test
    func translateRequiresAPIKeyOnlyForEnabledModel() async throws {
        let service = OpenAITranslationService(
            apiKeyProvider: StaticOpenAIAPIKeyProvider(apiKey: nil),
            httpClient: CapturingOpenAITranslationHTTPClient(
                data: Data(#"{"output_text":"ignored"}"#.utf8),
                statusCode: 200
            )
        )

        await #expect(throws: OpenAITranslationError.missingAPIKey) {
            _ = try await service.translate(
                "Hello",
                source: .english,
                target: .korean,
                model: .gptRealtimeTranslate
            )
        }
    }
}

private struct StaticOpenAIAPIKeyProvider: OpenAITranslationAPIKeyProviding {
    let apiKey: String?

    func readAPIKey() throws -> String? {
        apiKey
    }
}

private actor CapturingOpenAITranslationHTTPClient: OpenAITranslationHTTPClient {
    private let data: Data
    private let statusCode: Int
    private(set) var lastRequest: URLRequest?

    init(data: Data, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }
}

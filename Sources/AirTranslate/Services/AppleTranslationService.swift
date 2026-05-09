import Foundation
@preconcurrency import Translation

@MainActor
final class AppleTranslationService {
    private let availability = LanguageAvailability()
    private var sessionsByLanguagePair: [String: TranslationSession] = [:]

    func translate(
        _ text: String,
        source: LanguageOption,
        target: LanguageOption,
        model: IntelligenceModel
    ) async throws -> String {
        guard !text.isEmpty else { return text }
        guard model != .appleSpeechOnly else { return text }

        let sourceLanguage = Locale.Language(identifier: source.id)
        let targetLanguage = Locale.Language(identifier: target.id)
        let status = await availability.status(from: sourceLanguage, to: targetLanguage)

        guard status != .unsupported else {
            throw TranslationServiceError.unsupportedPair(source.localizedTitle, target.localizedTitle)
        }

        let session = translationSession(
            source: sourceLanguage,
            target: targetLanguage,
            cacheKey: languagePairKey(source: source, target: target)
        )
        if !(await session.isReady) {
            try await session.prepareTranslation()
        }

        let response = try await session.translate(text)
        return response.targetText
    }

    private func languagePairKey(source: LanguageOption, target: LanguageOption) -> String {
        "\(source.id)->\(target.id)"
    }

    private func translationSession(
        source: Locale.Language,
        target: Locale.Language,
        cacheKey: String
    ) -> TranslationSession {
        if let session = sessionsByLanguagePair[cacheKey] {
            return session
        }

        let session = TranslationSession(installedSource: source, target: target)
        sessionsByLanguagePair[cacheKey] = session
        return session
    }
}

enum TranslationServiceError: LocalizedError {
    case unsupportedPair(String, String)

    var errorDescription: String? {
        switch self {
        case let .unsupportedPair(source, target):
            AppText.unsupportedTranslation(source: source, target: target)
        }
    }
}

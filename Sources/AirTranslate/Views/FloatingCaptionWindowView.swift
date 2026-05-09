import SwiftUI

struct FloatingCaptionWindowView: View {
    @Bindable var session: TranslationSessionStore

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 8) {
                content
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 420, idealWidth: 720, maxWidth: 960, minHeight: 90, idealHeight: preferredHeight, maxHeight: preferredHeight)
        .contentShape(Rectangle())
        .gesture(WindowDragGesture())
        .allowsWindowActivationEvents(true)
        .overlay {
            FloatingCaptionDragSurface()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(FloatingWindowConfigurator(preferredContentHeight: preferredHeight))
    }

    @ViewBuilder
    private var content: some View {
        switch session.floatingCaptionDisplayMode {
        case .original:
            subtitleText(session.floatingSourceText, font: session.floatingCaptionTextSize.primaryFont)
        case .originalAndTranslation:
            if !session.floatingSourceText.isEmpty {
                subtitleText(session.floatingSourceText, font: session.floatingCaptionTextSize.secondaryFont)
                    .opacity(0.82)
            }
            subtitleText(translationText, font: session.floatingCaptionTextSize.primaryFont)
        case .translation:
            subtitleText(translationText, font: session.floatingCaptionTextSize.primaryFont)
        }
    }

    private var translationText: String {
        if !session.floatingTranslationText.isEmpty {
            return session.floatingTranslationText
        }
        if !session.floatingSourceText.isEmpty {
            return AppText.translating
        }
        return AppText.noFloatingCaptionsYet
    }

    private var lineLimit: Int {
        session.floatingCaptionLineCount.rawValue
    }

    private var preferredHeight: CGFloat {
        let textSize = session.floatingCaptionTextSize
        let lineCount = CGFloat(lineLimit)
        let primaryHeight = textSize.primaryLineHeight * lineCount + CGFloat(lineLimit - 1) * 5
        let secondaryHeight = textSize.secondaryLineHeight * lineCount + CGFloat(lineLimit - 1) * 5
        let textHeight: CGFloat

        switch session.floatingCaptionDisplayMode {
        case .original, .translation:
            textHeight = primaryHeight
        case .originalAndTranslation:
            textHeight = primaryHeight + secondaryHeight + 8
        }

        return min(max(90, textHeight + 36), 720)
    }

    private func subtitleText(_ text: String, font: Font) -> some View {
        StreamingTranscriptText(
            text: text.isEmpty ? AppText.noFloatingCaptionsYet : text,
            font: font,
            foregroundColor: .white,
            isTextSelectionEnabled: false,
            lineLimit: lineLimit,
            textAlignment: .center,
            frameAlignment: .center,
            truncationMode: .tail
        )
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        .lineSpacing(5)
        .shadow(color: .black.opacity(0.95), radius: 3, x: 0, y: 1)
        .shadow(color: .black.opacity(0.65), radius: 8, x: 0, y: 2)
    }
}

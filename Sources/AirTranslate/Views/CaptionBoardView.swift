import SwiftUI

struct CaptionBoardView: View {
    @Bindable var session: TranslationSessionStore
    @State private var isFloatingCaptionVisible = FloatingCaptionWindowController.isOpen

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SessionOverviewCard(
                title: AppText.transcriptWorkspace,
                subtitle: session.languageSummary,
                isRunning: session.isRunning,
                isPaused: session.isPaused,
                isFloatingCaptionVisible: isFloatingCaptionVisible,
                toggleCapture: {
                    toggleCapture()
                },
                togglePause: {
                    togglePause()
                },
                showFloatingCaptions: {
                    toggleFloatingCaptions()
                }
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if session.lines.isEmpty {
                            ContentUnavailableView(
                                AppText.noCaptionsYet,
                                systemImage: "captions.bubble",
                                description: Text(AppText.noCaptionsDescription)
                            )
                            .frame(maxWidth: .infinity, minHeight: 320)
                            .padding(24)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.08))
                            }
                        }

                        ForEach(session.lines) { line in
                            CaptionLineView(line: line)
                                .id(line.id)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, 4)
                    .animation(.spring(response: 0.32, dampingFraction: 0.86), value: session.lines.count)
                }
                .onChange(of: session.lines.last?.id) { _, id in
                    if let id {
                        withAnimation(.easeOut(duration: 0.22)) {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: session.lines.last?.revision) { _, _ in
                    if let id = session.lines.last?.id {
                        withAnimation(.easeOut(duration: 0.22)) {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(24)
        .onAppear {
            syncFloatingCaptionVisibility()
        }
        .onReceive(NotificationCenter.default.publisher(for: FloatingCaptionWindowController.visibilityDidChangeNotification)) { _ in
            syncFloatingCaptionVisibility()
        }
    }

    private func toggleFloatingCaptions() {
        FloatingCaptionWindowController.toggle(session: session)
        syncFloatingCaptionVisibility()
    }

    private func toggleCapture() {
        session.isRunning ? session.stop() : session.start()
    }

    private func togglePause() {
        session.isPaused ? session.resume() : session.pause()
    }

    private func syncFloatingCaptionVisibility() {
        isFloatingCaptionVisible = FloatingCaptionWindowController.isOpen
    }
}

private struct CaptionLineView: View {
    let line: CaptionLine

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            TranscriptPane(
                title: AppText.original,
                description: AppText.originalDescription,
                text: line.sourceText,
                isPrimary: true
            )
            TranscriptPane(
                title: AppText.translation,
                description: AppText.translationDescription,
                text: line.translatedText,
                isPrimary: false
            )
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct TranscriptPane: View {
    let title: String
    let description: String
    let text: String
    let isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(description)
                .font(.caption)
                .foregroundStyle(.tertiary)

            StreamingTranscriptText(
                text: text,
                font: isPrimary ? .body : .body.weight(.medium)
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 360, alignment: .topLeading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        }
    }
}

private struct SessionOverviewCard: View {
    let title: String
    let subtitle: String
    let isRunning: Bool
    let isPaused: Bool
    let isFloatingCaptionVisible: Bool
    let toggleCapture: () -> Void
    let togglePause: () -> Void
    let showFloatingCaptions: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "captions.bubble.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 34, height: 34)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                SessionStatusBadge(isRunning: isRunning, isPaused: isPaused)

                Button(action: toggleCapture) {
                    HeaderCaptureTransportButton(isRunning: isRunning, isPaused: isPaused)
                }
                .buttonStyle(.plain)
                .help(isRunning ? AppText.stop : AppText.start)
                .accessibilityLabel(isRunning ? AppText.stop : AppText.start)

                if isRunning {
                    Button(action: togglePause) {
                        HeaderPauseTransportButton(isPaused: isPaused)
                    }
                    .buttonStyle(.plain)
                    .help(isPaused ? AppText.resume : AppText.pause)
                    .accessibilityLabel(isPaused ? AppText.resume : AppText.pause)
                }

                Button(action: showFloatingCaptions) {
                    HeaderFloatingCaptionToggleButton(isOn: isFloatingCaptionVisible)
                }
                .buttonStyle(.plain)
                .help(AppText.showFloatingCaptions)
                .accessibilityLabel(AppText.showFloatingCaptions)
                .accessibilityValue(isFloatingCaptionVisible ? AppText.floatingCaptionPowerOn : AppText.floatingCaptionPowerOff)
            }
            .padding(6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
            }
            .layoutPriority(2)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        }
    }
}

private struct HeaderCaptureTransportButton: View {
    let isRunning: Bool
    let isPaused: Bool

    private var accentColor: Color {
        if isPaused {
            return .orange
        }
        if isRunning {
            return .red
        }
        return .accentColor
    }

    private var systemImage: String {
        isRunning ? "stop.fill" : "play.fill"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accentColor.opacity(isRunning ? 0.18 : 0.14))

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(accentColor.opacity(isRunning ? 0.5 : 0.32), lineWidth: 1)

            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(accentColor)
                .offset(x: isRunning ? 0 : 1.4)

            if isRunning {
                Circle()
                    .fill(isPaused ? Color.orange : Color.green)
                    .frame(width: 7, height: 7)
                    .shadow(color: (isPaused ? Color.orange : Color.green).opacity(0.6), radius: 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(7)
            }
        }
        .frame(width: 42, height: 42)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct HeaderPauseTransportButton: View {
    let isPaused: Bool

    private var accentColor: Color {
        isPaused ? .accentColor : .secondary
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accentColor.opacity(isPaused ? 0.14 : 0.1))

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(accentColor.opacity(isPaused ? 0.34 : 0.18), lineWidth: 1)

            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(accentColor)
                .offset(x: isPaused ? 1.1 : 0)
        }
        .frame(width: 42, height: 42)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct HeaderFloatingCaptionToggleButton: View {
    let isOn: Bool

    private var accentColor: Color {
        isOn ? .green : .secondary
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accentColor.opacity(isOn ? 0.16 : 0.1))

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(accentColor.opacity(isOn ? 0.42 : 0.18), lineWidth: 1)

            Image(systemName: isOn ? "captions.bubble.fill" : "captions.bubble")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accentColor)

            Circle()
                .fill(isOn ? Color.green : Color.secondary.opacity(0.55))
                .frame(width: 7, height: 7)
                .shadow(color: (isOn ? Color.green : Color.clear).opacity(0.6), radius: 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(7)
        }
        .frame(width: 42, height: 42)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SessionStatusBadge: View {
    let isRunning: Bool
    let isPaused: Bool

    private var title: String {
        isPaused ? AppText.paused : (isRunning ? AppText.listening : AppText.idle)
    }

    private var systemImage: String {
        isPaused ? "pause.circle.fill" : (isRunning ? "waveform.circle.fill" : "moon.zzz.fill")
    }

    private var foregroundStyle: Color {
        isPaused ? .orange : (isRunning ? .green : .secondary)
    }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(foregroundStyle)
            .frame(width: 42, height: 42)
            .background(foregroundStyle.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(foregroundStyle.opacity(0.18), lineWidth: 1)
            }
            .help(title)
            .accessibilityLabel(title)
    }
}

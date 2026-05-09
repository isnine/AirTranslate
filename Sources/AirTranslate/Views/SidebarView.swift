import SwiftUI

struct SidebarView: View {
    @Bindable var session: TranslationSessionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                captureCard
                sessionCard
                outputCard
                libraryCard

                if session.selectedSavedTranscriptID != nil {
                    editorCard
                }
            }
            .padding(12)
        }
        .background(.bar)
        .navigationTitle("AirTranslate")
    }

    private var captureCard: some View {
        SidebarCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: statusSymbolName)
                        .font(.title3)
                        .foregroundStyle(statusColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(AppText.capture)
                            .font(.headline)
                        Text(session.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                if needsPermissionAction {
                    Button {
                        session.openPrivacySettings()
                    } label: {
                        Label(AppText.openPrivacySettings, systemImage: "gear")
                    }
                    .controlSize(.small)
                }
            }
        }
    }

    private var sessionCard: some View {
        SidebarCard(title: AppText.session) {
            VStack(spacing: 10) {
                Picker(AppText.from, selection: $session.sourceLanguage) {
                    ForEach(LanguageOption.supported) { language in
                        Text(language.localizedTitle).tag(language)
                    }
                }

                Picker(AppText.to, selection: $session.targetLanguage) {
                    ForEach(LanguageOption.supported) { language in
                        Text(language.localizedTitle).tag(language)
                    }
                }

                Divider()

                Picker(AppText.model, selection: $session.selectedModel) {
                    ForEach(IntelligenceModel.allCases) { model in
                        Text(model.title).tag(model)
                    }
                }
            }
        }
    }

    private var outputCard: some View {
        SidebarCard(title: AppText.liveOutput) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(AppText.transcriptPolish, isOn: $session.isTranscriptLintEnabled)
                Toggle(AppText.voiceOutput, isOn: $session.isDubbingEnabled)
            }
        }
    }

    private var libraryCard: some View {
        SidebarCard(title: AppText.library) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Label(AppText.autoSave, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    Button {
                        session.openTranscriptsFolder()
                    } label: {
                        Label(AppText.openLibrary, systemImage: "folder")
                    }
                    .labelStyle(.iconOnly)
                    .help(AppText.openLibrary)
                }

                if session.savedTranscripts.isEmpty {
                    Text(AppText.savedEmpty)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 4) {
                        ForEach(session.savedTranscripts) { transcript in
                            Button {
                                session.selectSavedTranscript(transcript.id)
                            } label: {
                                SavedTranscriptRow(
                                    transcript: transcript,
                                    isSelected: session.selectedSavedTranscriptID == transcript.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var editorCard: some View {
        SidebarCard(title: AppText.editSaved) {
            VStack(alignment: .leading, spacing: 10) {
                TextEditor(text: $session.savedDraftSourceText)
                    .font(.caption)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .background(.quaternary.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                HStack {
                    Button {
                        session.saveSelectedTranscriptEdits()
                    } label: {
                        Label(AppText.saveEdits, systemImage: "checkmark")
                    }

                    Spacer(minLength: 0)

                    Button(role: .destructive) {
                        session.deleteSelectedTranscript()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .help(AppText.deleteSavedTranscript)
                }
            }
        }
    }

    private var needsPermissionAction: Bool {
        session.statusMessage.localizedCaseInsensitiveContains("permission")
            || session.statusMessage.localizedCaseInsensitiveContains("권한")
    }

    private var statusSymbolName: String {
        if session.isPaused {
            return "pause.circle.fill"
        }
        if session.isRunning {
            return "waveform.circle.fill"
        }
        return "circle.dotted"
    }

    private var statusColor: Color {
        if session.isPaused {
            return .orange
        }
        if session.isRunning {
            return .green
        }
        return .secondary
    }
}

private struct SidebarCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        }
    }
}

private struct SavedTranscriptRow: View {
    let transcript: SavedTranscript
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: isSelected ? "doc.text.fill" : "doc.text")
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(transcript.title)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                Text(transcript.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

import SwiftUI

struct SettingsView: View {
    @Bindable var session: TranslationSessionStore
    @State private var openAIAPIKey = ""
    @State private var azureEndpoint = ""
    @State private var azureAPIKey = ""

    var body: some View {
        Form {
            Section(AppText.gptModels) {
                Picker(AppText.openAIProvider, selection: $session.openAIProvider) {
                    ForEach(OpenAIProvider.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
            }

            switch session.openAIProvider {
            case .openAI:
                Section(AppText.openAIAPIKey) {
                    SecureField(AppText.openAIAPIKeyPlaceholder, text: $openAIAPIKey)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Text(session.hasOpenAIAPIKey ? AppText.openAIAPIKeyConfigured : AppText.openAIAPIKeyNotConfigured)
                            .font(.caption)
                            .foregroundStyle(session.hasOpenAIAPIKey ? .green : .secondary)

                        Spacer()

                        Button(AppText.saveOpenAIAPIKey) {
                            session.saveOpenAIAPIKey(openAIAPIKey)
                            openAIAPIKey = ""
                        }
                        .disabled(openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button(AppText.removeOpenAIAPIKey) {
                            session.removeOpenAIAPIKey()
                            openAIAPIKey = ""
                        }
                        .disabled(!session.hasOpenAIAPIKey)
                    }

                    Text(AppText.openAIAPIKeyDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .azure:
                Section(AppText.openAIProviderAzureTitle) {
                    TextField(AppText.azureOpenAIEndpointPlaceholder, text: $azureEndpoint)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.URL)
                        .autocorrectionDisabled(true)

                    Text(AppText.azureOpenAIEndpointFormatHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SecureField(AppText.azureOpenAIAPIKeyPlaceholder, text: $azureAPIKey)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Text(session.hasAzureOpenAIConfig ? AppText.azureOpenAIConfigConfigured : AppText.azureOpenAIConfigNotConfigured)
                            .font(.caption)
                            .foregroundStyle(session.hasAzureOpenAIConfig ? .green : .secondary)

                        Spacer()

                        Button(AppText.saveAzureOpenAIConfig) {
                            session.saveAzureOpenAIConfig(endpoint: azureEndpoint, apiKey: azureAPIKey)
                            azureAPIKey = ""
                            azureEndpoint = session.azureOpenAIEndpoint
                        }
                        .disabled(
                            azureAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || azureEndpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )

                        Button(AppText.removeAzureOpenAIConfig) {
                            session.removeAzureOpenAIConfig()
                            azureAPIKey = ""
                            azureEndpoint = ""
                        }
                        .disabled(!session.hasAzureOpenAIConfig)
                    }
                }
            }

            Section(AppText.transcript) {
                Picker(AppText.sessionLength, selection: $session.sessionDurationMode) {
                    ForEach(SessionDurationMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
                .disabled(session.isRunning)

                Text(session.sessionDurationMode.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Stepper(
                    value: $session.paragraphBreakSilenceInterval,
                    in: 1...15,
                    step: 0.5
                ) {
                    HStack {
                        Text(AppText.paragraphBreakSilenceInterval)
                        Spacer()
                        Text(AppText.seconds(session.paragraphBreakSilenceInterval))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(AppText.paragraphBreakSilenceDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(AppText.floatingCaptions) {
                Picker(AppText.floatingDisplay, selection: $session.floatingCaptionDisplayMode) {
                    ForEach(FloatingCaptionDisplayMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                Picker(AppText.floatingTextSize, selection: $session.floatingCaptionTextSize) {
                    ForEach(FloatingCaptionTextSize.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }

                Picker(AppText.floatingLineCount, selection: $session.floatingCaptionLineCount) {
                    ForEach(FloatingCaptionLineCount.allCases) { lineCount in
                        Text(lineCount.title).tag(lineCount)
                    }
                }

                Text(AppText.floatingDisplayDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(AppText.requiredAssets) {
                SettingsAssetAvailabilityRow(
                    title: AppText.speechLanguagePack,
                    availability: session.modelAvailability(for: .appleSpeechOnly)
                ) {
                    session.downloadModelAssets(for: .appleSpeechOnly)
                }

                SettingsAssetAvailabilityRow(
                    title: AppText.translationLanguagePack,
                    availability: session.modelAvailability(for: .appleOnDevice)
                ) {
                    session.downloadModelAssets(for: .appleOnDevice)
                }
            }

            Section(AppText.permissions) {
                Text(AppText.permissionsHelp)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
        .onAppear {
            azureEndpoint = session.azureOpenAIEndpoint
        }
    }
}

private struct SettingsAssetAvailabilityRow: View {
    let title: String
    let availability: ModelAvailability
    let download: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: symbolName)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)

                Text(availability.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if availability.state == .checking || availability.state == .downloading {
                ProgressView()
                    .controlSize(.small)
            } else if availability.state.canDownload {
                Button(AppText.download) {
                    download()
                }
            } else {
                Text(availability.state.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
        }
        .help(availability.detail)
    }

    private var symbolName: String {
        switch availability.state {
        case .checking:
            "clock"
        case .installed:
            "checkmark.seal.fill"
        case .downloadRequired, .downloading:
            "arrow.down.circle.fill"
        case .unsupported, .unavailable, .failed:
            "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch availability.state {
        case .checking:
            .secondary
        case .installed:
            .green
        case .downloadRequired, .downloading:
            .orange
        case .unsupported, .unavailable, .failed:
            .red
        }
    }
}

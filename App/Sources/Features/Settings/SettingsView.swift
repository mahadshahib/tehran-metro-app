import SwiftUI
import MetroDomain

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        let lang = settings.language
        return NavigationStack {
            List {
                Section {
                    NavigationLink {
                        FavoritesView()
                    } label: {
                        Label(Loc.favorites.string(for: lang), systemImage: "star")
                    }
                }

                // Each option is its own selectable row (no non-tappable title row).
                Section(Loc.language.string(for: lang)) {
                    selectRow(Loc.languageEnglish, isOn: settings.language == .english) {
                        settings.language = .english
                    }
                    selectRow(Loc.languageFarsi, isOn: settings.language == .farsi) {
                        settings.language = .farsi
                    }
                }

                Section(Loc.appearance.string(for: lang)) {
                    selectRow(Loc.themeSystem, isOn: settings.theme == .system) { settings.theme = .system }
                    selectRow(Loc.themeLight, isOn: settings.theme == .light) { settings.theme = .light }
                    selectRow(Loc.themeDark, isOn: settings.theme == .dark) { settings.theme = .dark }
                }

                Section(Loc.nameDisplay.string(for: lang)) {
                    selectRow(Loc.nameAuto, isOn: settings.nameDisplay == .auto) { settings.nameDisplay = .auto }
                    selectRow(Loc.nameEnglish, isOn: settings.nameDisplay == .english) { settings.nameDisplay = .english }
                    selectRow(Loc.nameFarsi, isOn: settings.nameDisplay == .farsi) { settings.nameDisplay = .farsi }
                }

                Section(Loc.about.string(for: lang)) {
                    Text(Loc.dataDisclaimer.string(for: lang))
                        .font(.app(.footnote)).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(Loc.tabSettings.string(for: lang))
        }
    }

    /// A fully tappable option row with a trailing checkmark when selected.
    private func selectRow(_ text: LocalizedText, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack {
                Text(text.string(for: settings.language))
                    .foregroundStyle(.primary)
                Spacer()
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.app(.body, weight: .semibold))
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

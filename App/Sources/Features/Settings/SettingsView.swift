import SwiftUI
import MetroDomain

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        let lang = settings.language
        return NavigationStack {
            List {
                Section(Loc.favorites.string(for: lang)) {
                    NavigationLink {
                        FavoritesView()
                    } label: {
                        Label(Loc.favorites.string(for: lang), systemImage: "star")
                    }
                }

                Section(Loc.language.string(for: lang)) {
                    Picker(Loc.language.string(for: lang), selection: $settings.language) {
                        Text(Loc.languageEnglish.string(for: lang)).tag(AppLanguage.english)
                        Text(Loc.languageFarsi.string(for: lang)).tag(AppLanguage.farsi)
                    }
                    .pickerStyle(.inline)
                }

                Section(Loc.appearance.string(for: lang)) {
                    Picker(Loc.appearance.string(for: lang), selection: $settings.theme) {
                        Text(Loc.themeSystem.string(for: lang)).tag(AppSettings.Theme.system)
                        Text(Loc.themeLight.string(for: lang)).tag(AppSettings.Theme.light)
                        Text(Loc.themeDark.string(for: lang)).tag(AppSettings.Theme.dark)
                    }
                    .pickerStyle(.segmented)
                }

                Section(Loc.nameDisplay.string(for: lang)) {
                    Picker(Loc.nameDisplay.string(for: lang), selection: $settings.nameDisplay) {
                        Text(Loc.nameAuto.string(for: lang)).tag(AppSettings.NameDisplay.auto)
                        Text(Loc.nameEnglish.string(for: lang)).tag(AppSettings.NameDisplay.english)
                        Text(Loc.nameFarsi.string(for: lang)).tag(AppSettings.NameDisplay.farsi)
                    }
                    .pickerStyle(.inline)
                }

                Section(Loc.about.string(for: lang)) {
                    Text(Loc.dataDisclaimer.string(for: lang))
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(Loc.tabSettings.string(for: lang))
        }
    }
}

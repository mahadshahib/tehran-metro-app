import SwiftUI
import Observation
import MetroDomain

/// User-tunable settings, persisted to `UserDefaults`. The language override is
/// independent of the system language (requirement §6).
@Observable
final class AppSettings {
    enum Theme: String, CaseIterable, Codable { case system, light, dark }
    enum NameDisplay: String, CaseIterable, Codable { case auto, english, farsi }

    var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }
    var theme: Theme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }
    var nameDisplay: NameDisplay {
        didSet { defaults.set(nameDisplay.rawValue, forKey: Keys.nameDisplay) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let language = "settings.language"
        static let theme = "settings.theme"
        static let nameDisplay = "settings.nameDisplay"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Default language follows the system on first launch, then is sticky.
        if let raw = defaults.string(forKey: Keys.language), let lang = AppLanguage(rawValue: raw) {
            self.language = lang
        } else {
            let preferred = Locale.preferredLanguages.first ?? "en"
            self.language = preferred.hasPrefix("fa") ? .farsi : .english
        }
        self.theme = defaults.string(forKey: Keys.theme).flatMap(Theme.init) ?? .system
        self.nameDisplay = defaults.string(forKey: Keys.nameDisplay).flatMap(NameDisplay.init) ?? .auto
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Resolve which language to use for a station's display name.
    func displayLanguage(for content: AppLanguage) -> AppLanguage {
        switch nameDisplay {
        case .auto: return language
        case .english: return .english
        case .farsi: return .farsi
        }
    }

    /// Localized station name honoring the name-display preference.
    func stationName(_ station: Station) -> String {
        switch nameDisplay {
        case .auto: return station.name(for: language)
        case .english: return station.nameEN
        case .farsi: return station.nameFA
        }
    }
}

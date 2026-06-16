import Foundation

/// Locale-aware number formatting that lives in the domain layer so it is
/// unit-testable without the app/UI. Drives Persian (۰۱۲) vs Western (012)
/// digits from the language's locale — never via manual string swapping.
public enum NumberLocalization {

    public static func locale(for language: AppLanguage) -> Locale {
        Locale(identifier: language == .farsi ? "fa_IR" : "en_US")
    }

    /// Format an integer in the language's native digits.
    public static func string(_ value: Int, language: AppLanguage) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale(for: language)
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

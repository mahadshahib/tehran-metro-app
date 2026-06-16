import Foundation
import SwiftUI
import MetroDomain

/// A bilingual string. We centralize copy in code (rather than only in an
/// `.xcstrings` catalog) because the app supports a **per-app language override**
/// that must be independent of the system language and work fully offline. This
/// makes the override deterministic and unit-testable. Numerals and calendars
/// still go through locale-aware system formatters.
struct LocalizedText {
    let en: String
    let fa: String

    func string(for language: AppLanguage) -> String {
        language == .farsi ? fa : en
    }
}

/// Locale-aware numeral + measurement formatting.
enum Numerals {
    static func locale(for language: AppLanguage) -> Locale {
        Locale(identifier: language == .farsi ? "fa_IR" : "en_US")
    }

    /// Format an integer using the language's native digits (۰۱۲ vs 012).
    /// Delegates to the domain layer so the logic is unit-tested there.
    static func string(_ value: Int, language: AppLanguage) -> String {
        NumberLocalization.string(value, language: language)
    }

    /// Format a distance in meters → "450 m" / "۱٫۲ km" with native digits.
    static func distance(meters: Double, language: AppLanguage) -> String {
        let formatter = MeasurementFormatter()
        formatter.locale = locale(for: language)
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = meters >= 1000 ? 1 : 0
        return formatter.string(from: Measurement(value: meters, unit: UnitLength.meters))
    }

    /// Format a duration in minutes → "12 min" / "۱۲ دقیقه".
    static func minutes(_ value: Int, language: AppLanguage) -> String {
        let number = string(value, language: language)
        return language == .farsi ? "\(number) دقیقه" : "\(value) min"
    }
}

extension AppLanguage {
    var layoutDirection: LayoutDirection { isRTL ? .rightToLeft : .leftToRight }
    var swiftUILocale: Locale { Numerals.locale(for: self) }
}

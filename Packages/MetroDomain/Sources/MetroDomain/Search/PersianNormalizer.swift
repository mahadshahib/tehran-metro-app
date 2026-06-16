import Foundation

/// Normalizes Persian/Arabic text so that search "just works" regardless of how
/// the user types a name. Handles the classic pitfalls:
///   - Arabic yeh (ي U+064A) vs Persian yeh (ی U+06CC)
///   - Arabic kaf (ك U+0643) vs Persian kaf (ک U+06A9)
///   - Arabic/Persian digit variants → ASCII
///   - ZWNJ / half-spaces and other zero-width marks → removed
///   - Diacritics / harakat stripped
///   - Case- and whitespace-insensitive
public enum PersianNormalizer {

    /// Characters that should be collapsed to a single canonical form.
    private static let charMap: [Character: Character] = [
        // Yeh variants → Persian yeh
        "ي": "ی", "ئ": "ی", "ﯼ": "ی", "ﯽ": "ی", "ى": "ی",
        // Kaf variants → Persian kaf
        "ك": "ک", "ﮎ": "ک", "ﮏ": "ک", "ﮐ": "ک", "ﮑ": "ک",
        // Alef variants → plain alef
        "أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا",
        // Heh / teh marbuta
        "ة": "ه", "ۀ": "ه",
        // Waw variants
        "ؤ": "و"
    ]

    /// Digit translation: Persian (۰-۹) and Arabic-Indic (٠-٩) → ASCII.
    private static let digitMap: [Character: Character] = [
        "۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4",
        "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9",
        "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
        "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9"
    ]

    /// Zero-width and formatting marks to strip entirely.
    private static let zeroWidth: Set<Character> = [
        "\u{200C}", // ZWNJ (half-space)
        "\u{200D}", // ZWJ
        "\u{200E}", // LRM
        "\u{200F}", // RLM
        "\u{FEFF}", // BOM / ZWNBSP
        "\u{0640}"  // tatweel / kashida
    ]

    /// Combining marks (harakat/diacritics) to strip.
    private static func isDiacritic(_ scalar: Unicode.Scalar) -> Bool {
        // Arabic combining marks block (harakat) and general combining marks.
        (0x064B...0x065F).contains(scalar.value)
            || (0x0610...0x061A).contains(scalar.value)
            || scalar.value == 0x0670
    }

    /// Produce a canonical, comparable key for `text`.
    public static func normalize(_ text: String) -> String {
        var result = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            let ch = Character(scalar)
            if zeroWidth.contains(ch) { continue }
            if isDiacritic(scalar) { continue }
            if let mapped = charMap[ch] {
                result.append(contentsOf: mapped.unicodeScalars)
            } else if let digit = digitMap[ch] {
                result.append(contentsOf: digit.unicodeScalars)
            } else {
                result.append(scalar)
            }
        }
        // Collapse internal whitespace runs to a single space, trim, lowercase.
        let collapsed = String(result)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return collapsed.lowercased()
    }

    /// True if `query` matches `candidate` (substring match on normalized forms).
    public static func matches(query: String, candidate: String) -> Bool {
        let q = normalize(query)
        guard !q.isEmpty else { return true }
        return normalize(candidate).contains(q)
    }
}

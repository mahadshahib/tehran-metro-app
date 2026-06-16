import SwiftUI

extension Color {
    /// Create a Color from a "#RRGGBB" (or "RRGGBB") hex string. Falls back to
    /// gray for malformed input — never crashes.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value), cleaned.count == 6 else {
            self = .gray
            return
        }
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

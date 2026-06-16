import SwiftUI
import CoreText

/// Registers any font files bundled under `App/Resources/Fonts` at runtime. If
/// the Vazirmatn font is not bundled (e.g. fetched separately), the app falls
/// back gracefully to the system font — nothing crashes and CI still builds.
enum FontRegistrar {
    private(set) static var vazirmatnAvailable = false

    static func registerBundledFonts() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) else { return }
        for url in urls {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                if url.lastPathComponent.lowercased().contains("vazir") {
                    vazirmatnAvailable = true
                }
            }
        }
    }
}

extension Font {
    /// Persian-friendly font. Uses Vazirmatn when bundled, otherwise the system
    /// font (which still renders Persian correctly, just less polished).
    static func metro(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        if FontRegistrar.vazirmatnAvailable {
            let name = weight == .bold || weight == .semibold ? "Vazirmatn-Bold" : "Vazirmatn-Regular"
            return .custom(name, size: pointSize(for: style), relativeTo: style)
        }
        return .system(style, weight: weight)
    }

    private static func pointSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline, .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption, .caption2: return 12
        @unknown default: return 17
        }
    }
}

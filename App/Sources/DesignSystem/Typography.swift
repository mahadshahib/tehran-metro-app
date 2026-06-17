import SwiftUI
import CoreText
import UIKit

/// Resolves which bundled Persian font family to use. Prefers real IRANSans /
/// IRANYekan if the user drops those TTFs into `App/Resources/Fonts`, otherwise
/// falls back to the bundled **Vazirmatn**. Nothing ever falls back to the
/// system font for Persian once a family is found.
enum AppFont {
    struct Face { let regular: String; let medium: String; let bold: String }

    /// Candidate PostScript-name sets, in priority order.
    private static let candidates: [Face] = [
        Face(regular: "IRANSansXFaNum-Regular", medium: "IRANSansXFaNum-Medium", bold: "IRANSansXFaNum-Bold"),
        Face(regular: "IRANSansX-Regular", medium: "IRANSansX-Medium", bold: "IRANSansX-Bold"),
        Face(regular: "IRANSansMobile", medium: "IRANSansMobile(FaNum)", bold: "IRANSansMobile-Bold"),
        Face(regular: "IRANYekanX-Regular", medium: "IRANYekanX-Medium", bold: "IRANYekanX-Bold"),
        Face(regular: "IRANYekanXFaNum-Regular", medium: "IRANYekanXFaNum-Medium", bold: "IRANYekanXFaNum-Bold"),
        Face(regular: "Vazirmatn-Regular", medium: "Vazirmatn-Medium", bold: "Vazirmatn-Bold")
    ]

    private(set) static var face: Face?
    static var isAvailable: Bool { face != nil }

    /// Pick the first candidate whose regular face is actually registered.
    static func resolve() {
        for candidate in candidates where UIFont(name: candidate.regular, size: 12) != nil {
            face = candidate
            return
        }
        face = nil
    }

    static func name(for weight: Font.Weight) -> String? {
        guard let face else { return nil }
        switch weight {
        case .bold, .semibold, .heavy, .black: return face.bold
        case .medium: return face.medium
        default: return face.regular
        }
    }

    static func uiFont(size: CGFloat, weight: Font.Weight = .regular) -> UIFont? {
        guard let name = name(for: weight) else { return nil }
        return UIFont(name: name, size: size)
    }
}

/// Point sizes per text style, used so the custom font scales with Dynamic Type.
enum AppFontMetrics {
    static func size(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline, .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 17
        }
    }
}

extension Font {
    /// The app's text font for a semantic style. Uses the bundled Persian family
    /// (which also renders Latin cleanly), scaling with Dynamic Type.
    static func app(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        let resolvedWeight = effectiveWeight(style: style, requested: weight)
        if let name = AppFont.name(for: resolvedWeight) {
            return .custom(name, size: AppFontMetrics.size(for: style), relativeTo: style)
        }
        return .system(style, weight: weight)
    }

    /// Fixed-size variant for bespoke UI (icons, badges).
    static func app(size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        if let name = AppFont.name(for: weight) {
            return .custom(name, size: size, relativeTo: style)
        }
        return .system(size: size, weight: weight)
    }

    private static func effectiveWeight(style: Font.TextStyle, requested: Font.Weight) -> Font.Weight {
        if requested != .regular { return requested }
        return style == .headline ? .semibold : .regular
    }
}

/// Registers bundled fonts and applies the custom font to UIKit-backed chrome
/// (navigation bars, tab bars) so *nothing* stays on the system font.
enum FontRegistrar {
    static func registerBundledFonts() {
        if let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) {
            for url in urls {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        AppFont.resolve()
        configureUIKitAppearance()
    }

    private static func configureUIKitAppearance() {
        guard AppFont.isAvailable else { return }

        if let large = AppFont.uiFont(size: 32, weight: .bold),
           let inline = AppFont.uiFont(size: 17, weight: .semibold) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.titleTextAttributes = [.font: inline]
            appearance.largeTitleTextAttributes = [.font: large]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
        }

        if let tabFont = AppFont.uiFont(size: 10, weight: .medium) {
            UITabBarItem.appearance().setTitleTextAttributes([.font: tabFont], for: .normal)
            UITabBarItem.appearance().setTitleTextAttributes([.font: tabFont], for: .selected)
        }
    }
}

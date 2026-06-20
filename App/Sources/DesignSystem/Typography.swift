import SwiftUI
import CoreText
import UIKit

/// Resolves the Persian font family to use and maps weights to **real, existing
/// face names**, so SwiftUI never silently falls back to the system font for a
/// missing weight. Auto-discovers IRANSans / IRANYekan if present, else uses the
/// bundled Vazirmatn.
enum AppFont {
    struct Face { let regular: String; let medium: String; let bold: String }

    /// Family-name fragments to look for, in priority order.
    private static let preferred = [
        "iransansx", "iranyekanx", "iransans", "iranyekan",
        "vazirmatn", "vazir", "shabnam", "sahel"
    ]

    private(set) static var face: Face?
    static var isAvailable: Bool { face != nil }

    /// Inspect the *registered* font families and pick face names that actually
    /// exist, classifying them by weight keyword.
    static func resolve() {
        let families = UIFont.familyNames
        for key in preferred {
            guard let family = families.first(where: { $0.lowercased().contains(key) }) else { continue }
            let faces = UIFont.fontNames(forFamilyName: family)
            guard !faces.isEmpty else { continue }
            face = classify(faces)
            return
        }
        face = nil
    }

    private static func classify(_ faces: [String]) -> Face {
        func has(_ name: String, _ word: String) -> Bool { name.lowercased().contains(word) }
        let weightWords = ["bold", "medium", "light", "black", "heavy", "thin",
                           "demibold", "semibold", "extrabold", "ultra"]

        let regular = faces.first(where: { has($0, "regular") })
            ?? faces.first(where: { name in !weightWords.contains(where: { has(name, $0) }) })
            ?? faces[0]

        let bold = faces.first(where: { has($0, "bold") && !has($0, "semibold") && !has($0, "demibold") })
            ?? faces.first(where: { has($0, "bold") })
            ?? faces.first(where: { has($0, "black") || has($0, "heavy") })
            ?? regular

        let medium = faces.first(where: { has($0, "medium") })
            ?? faces.first(where: { has($0, "demibold") || has($0, "semibold") })
            ?? regular

        return Face(regular: regular, medium: medium, bold: bold)
    }

    static func name(for weight: Font.Weight) -> String? {
        guard let face else { return nil }
        switch weight {
        case .bold, .heavy, .black, .semibold: return face.bold
        case .medium: return face.medium
        default: return face.regular
        }
    }

    static func uiFont(size: CGFloat, weight: Font.Weight = .regular) -> UIFont? {
        guard let name = name(for: weight), let f = UIFont(name: name, size: size) else { return nil }
        return f
    }
}

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
    static func app(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        let resolved = effectiveWeight(style: style, requested: weight)
        if let name = AppFont.name(for: resolved) {
            return .custom(name, size: AppFontMetrics.size(for: style), relativeTo: style)
        }
        return .system(style, weight: weight)
    }

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

/// Registers bundled fonts and applies the custom font to all UIKit-backed
/// chrome — nav bars, tab bars, segmented controls, search bars, bar buttons —
/// so nothing renders in the system font.
enum FontRegistrar {
    static func registerBundledFonts() {
        if let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) {
            for url in urls { CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) }
        }
        AppFont.resolve()
        configureUIKitAppearance()
    }

    private static func configureUIKitAppearance() {
        guard AppFont.isAvailable else { return }
        let label = UIColor.label

        // Navigation bars (inline + large titles).
        if let large = AppFont.uiFont(size: 30, weight: .bold),
           let inline = AppFont.uiFont(size: 17, weight: .semibold) {
            let nav = UINavigationBarAppearance()
            nav.configureWithDefaultBackground()
            nav.titleTextAttributes = [.font: inline, .foregroundColor: label]
            nav.largeTitleTextAttributes = [.font: large, .foregroundColor: label]
            UINavigationBar.appearance().standardAppearance = nav
            UINavigationBar.appearance().scrollEdgeAppearance = nav
            UINavigationBar.appearance().compactAppearance = nav
        }

        // Tab bar items (must go through UITabBarAppearance on iOS 15+).
        if let tab = AppFont.uiFont(size: 10, weight: .medium) {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            for item in [appearance.stackedLayoutAppearance,
                         appearance.inlineLayoutAppearance,
                         appearance.compactInlineLayoutAppearance] {
                item.normal.titleTextAttributes = [.font: tab]
                item.selected.titleTextAttributes = [.font: tab]
            }
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }

        // Segmented controls.
        if let seg = AppFont.uiFont(size: 13, weight: .medium) {
            UISegmentedControl.appearance().setTitleTextAttributes([.font: seg], for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes([.font: seg], for: .selected)
        }

        // Search bars and bar-button items.
        if let body = AppFont.uiFont(size: 17) {
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).font = body
            UIBarButtonItem.appearance().setTitleTextAttributes([.font: body], for: .normal)
            UIBarButtonItem.appearance().setTitleTextAttributes([.font: body], for: .highlighted)
            UIBarButtonItem.appearance().setTitleTextAttributes([.font: body], for: .selected)
        }
    }
}

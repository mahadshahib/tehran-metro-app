import SwiftUI

/// Centralized spacing, radius, and typography tokens. Keeps the UI consistent
/// and makes global tweaks one-line changes.
enum DS {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let pill: CGFloat = 999
    }

    enum Size {
        static let lineDot: CGFloat = 12
        static let interchangeNode: CGFloat = 16
        static let stationNode: CGFloat = 10
        static let tapTarget: CGFloat = 44
    }
}

extension View {
    /// Standard card styling used across feature screens.
    func metroCard() -> some View {
        self
            .padding(DS.Spacing.l)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
    }
}

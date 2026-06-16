import SwiftUI

/// Full-width primary call-to-action button. Used for the single most important
/// action on a screen (e.g. "Find route").
struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                (enabled ? Color.accentColor : Color.secondary.opacity(0.4)),
                in: RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
            )
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// A soft, tappable "chip" used for quick picks (favorite stations, etc.).
struct ChipButtonStyle: ButtonStyle {
    var tint: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, DS.Spacing.m)
            .padding(.vertical, DS.Spacing.s)
            .background(tint.opacity(0.12), in: Capsule())
            .foregroundStyle(tint)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

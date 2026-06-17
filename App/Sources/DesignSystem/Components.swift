import SwiftUI
import MetroDomain

/// A line identifier badge: colored disc + the line number. Never encodes meaning
/// in color alone — the number is always shown (accessibility / colorblind safe).
struct LineBadge: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    let lineID: LineID
    var compact: Bool = false

    private var color: Color {
        Color(hex: model.line(lineID)?.colorHex ?? "#888888")
    }

    var body: some View {
        let number = Numerals.string(lineID, language: settings.language)
        if compact {
            Text(number)
                .font(.app(.caption, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(color, in: Circle())
                .accessibilityLabel(Loc.lineName(lineID, language: settings.language))
        } else {
            HStack(spacing: DS.Spacing.xs) {
                Circle().fill(color).frame(width: DS.Size.lineDot, height: DS.Size.lineDot)
                Text(Loc.lineName(lineID, language: settings.language))
                    .font(.app(.subheadline, weight: .medium))
            }
            .padding(.horizontal, DS.Spacing.s)
            .padding(.vertical, DS.Spacing.xs)
            .background(color.opacity(0.12), in: Capsule())
            .foregroundStyle(color)
            .accessibilityElement(children: .combine)
        }
    }
}

/// A row representing a station: name, its line badges, and status indicators.
struct StationRow: View {
    @Environment(AppSettings.self) private var settings
    let station: Station
    var showLines: Bool = true

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(settings.stationName(station))
                    .font(.app(.body, weight: .medium))
                    .foregroundStyle(.primary)
                HStack(spacing: DS.Spacing.s) {
                    if station.isInterchange {
                        Label(Loc.interchange.string(for: settings.language), systemImage: "arrow.triangle.swap")
                            .font(.app(.caption2))
                            .foregroundStyle(.secondary)
                    }
                    if !station.isInService {
                        Label(Loc.notInService.string(for: settings.language), systemImage: "exclamationmark.triangle")
                            .font(.app(.caption2))
                            .foregroundStyle(.orange)
                    }
                }
            }
            Spacer()
            if showLines {
                HStack(spacing: DS.Spacing.xs) {
                    ForEach(station.lines, id: \.self) { LineBadge(lineID: $0, compact: true) }
                }
            }
        }
        .padding(.vertical, DS.Spacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A small empty-state view.
struct EmptyStateView: View {
    let systemImage: String
    let message: String
    var body: some View {
        ContentUnavailableView(message, systemImage: systemImage)
    }
}

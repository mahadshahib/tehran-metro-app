import SwiftUI
import MetroDomain

/// A line's stations in travel order, drawn as a vertical line diagram.
struct LineDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    let lineID: LineID

    private var line: Line? { model.line(lineID) }

    var body: some View {
        List {
            if let line {
                Section {
                    ForEach(Array(line.orderedStations.enumerated()), id: \.element) { index, stationID in
                        if let station = model.station(stationID) {
                            NavigationLink(value: NavTarget.station(stationID)) {
                                StationLineRow(
                                    station: station,
                                    color: Color(hex: line.colorHex),
                                    isFirst: index == 0,
                                    isLast: index == line.orderedStations.count - 1,
                                    otherLines: station.lines.filter { $0 != lineID }
                                )
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: DS.Spacing.l, bottom: 0, trailing: DS.Spacing.l))
                        }
                    }
                }
                ForEach(Array(line.branches.enumerated()), id: \.offset) { _, branch in
                    if branch.count > 1 {
                        Section(branchTitle(branch)) {
                            ForEach(Array(branch.enumerated()), id: \.element) { index, stationID in
                                if let station = model.station(stationID) {
                                    NavigationLink(value: NavTarget.station(stationID)) {
                                        StationLineRow(
                                            station: station,
                                            color: Color(hex: line.colorHex),
                                            isFirst: index == 0,
                                            isLast: index == branch.count - 1,
                                            otherLines: station.lines.filter { $0 != lineID }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(Loc.lineName(lineID, language: settings.language))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func branchTitle(_ branch: [StationID]) -> String {
        guard let terminal = branch.first, let station = model.station(terminal) else {
            return Loc.line.string(for: settings.language)
        }
        return "\(Loc.toward.string(for: settings.language)) \(settings.stationName(station))"
    }
}

/// One station drawn with the connecting line-segment glyph on the leading edge.
private struct StationLineRow: View {
    @Environment(AppSettings.self) private var settings
    let station: Station
    let color: Color
    let isFirst: Bool
    let isLast: Bool
    let otherLines: [LineID]

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            // Vertical line track with a node.
            ZStack {
                VStack(spacing: 0) {
                    Rectangle().fill(isFirst ? .clear : color).frame(width: 4)
                    Rectangle().fill(isLast ? .clear : color).frame(width: 4)
                }
                Circle()
                    .fill(station.isInterchange ? Color(.systemBackground) : color)
                    .frame(width: station.isInterchange ? DS.Size.interchangeNode : DS.Size.stationNode,
                           height: station.isInterchange ? DS.Size.interchangeNode : DS.Size.stationNode)
                    .overlay(Circle().stroke(color, lineWidth: station.isInterchange ? 3 : 0))
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(settings.stationName(station))
                    .font(.app(.body, weight: isFirst || isLast ? .semibold : .regular))
                    .strikethrough(!station.isInService)
                    .foregroundStyle(station.isInService ? .primary : .secondary)
                if isFirst || isLast {
                    Text(Loc.terminal.string(for: settings.language))
                        .font(.app(.caption2)).foregroundStyle(.secondary)
                }
            }
            Spacer()
            HStack(spacing: DS.Spacing.xs) {
                ForEach(otherLines, id: \.self) { LineBadge(lineID: $0, compact: true) }
            }
        }
        .padding(.vertical, DS.Spacing.xs)
        .frame(minHeight: DS.Size.tapTarget)
        .accessibilityElement(children: .combine)
    }
}

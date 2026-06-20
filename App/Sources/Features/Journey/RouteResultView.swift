import SwiftUI
import MetroDomain

/// Shows a planned journey as a full station-by-station timeline: board, every
/// stop ridden, each transfer station, and arrival — with line-colored track.
struct RouteResultView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    let route: Route
    var onSave: (() -> Void)? = nil

    @State private var expanded = true

    private var lang: AppLanguage { settings.language }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            summaryCard
            timelineCard
            footer
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: "clock.fill").foregroundStyle(.tint)
                Text(Numerals.minutes(route.estimate.totalMinutes, language: lang))
                    .font(.app(.title3, weight: .bold))
                Text(Loc.approximate.string(for: lang))
                    .font(.app(.caption2)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: DS.Spacing.m) {
                Label(Loc.stopsLabel(route.totalStops, language: lang), systemImage: "smallcircle.filled.circle")
                Label(Loc.transfersLabel(route.transferCount, language: lang), systemImage: "arrow.triangle.swap")
            }
            .font(.app(.subheadline)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.l)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
    }

    // MARK: - Timeline

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(Loc.routeSteps.string(for: lang)).font(.app(.headline))
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    Text((expanded ? Loc.hideStations : Loc.showStations).string(for: lang))
                        .font(.app(.footnote))
                }
            }
            .padding(.bottom, DS.Spacing.s)

            ForEach(Array(route.legs.enumerated()), id: \.offset) { index, leg in
                legBlock(index: index, leg: leg)
            }
            arriveRow
        }
        .padding(DS.Spacing.l)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
    }

    @ViewBuilder
    private func legBlock(index: Int, leg: RouteLeg) -> some View {
        let color = Color(hex: leg.colorHex)
        // Leg header: which line, toward which terminal.
        HStack(spacing: DS.Spacing.s) {
            LineBadge(lineID: leg.line)
            Image(systemName: "arrow.forward").font(.app(.caption2)).foregroundStyle(.secondary)
            Text(name(leg.towardTerminal)).font(.app(.subheadline, weight: .medium)).lineLimit(1)
            Spacer()
            Text(Loc.stopsLabel(leg.stopCount, language: lang))
                .font(.app(.caption)).foregroundStyle(.secondary)
        }
        .padding(.vertical, DS.Spacing.xs)

        // Stations of this leg. First leg shows its origin; later legs reuse the
        // previous leg's transfer station, so skip their duplicated first stop.
        // The final leg's last stop is the destination, shown by `arriveRow`.
        let stations = visibleStations(index: index, leg: leg)
        ForEach(Array(stations.enumerated()), id: \.element) { offset, stationID in
            let isBoard = index == 0 && offset == 0
            let isLegEnd = stationID == leg.to
            let isJourneyTransfer = isLegEnd && index < route.legs.count - 1
            if expanded || isBoard || isJourneyTransfer {
                stopRow(stationID: stationID, color: color,
                        emphasized: isBoard || isJourneyTransfer,
                        role: isBoard ? .depart : (isJourneyTransfer ? .transfer(to: route.legs[index + 1].line) : .normal),
                        showTopLine: !isBoard,
                        showBottomLine: true)
            }
        }
    }

    private func visibleStations(index: Int, leg: RouteLeg) -> [StationID] {
        var stations = index == 0 ? leg.stations : Array(leg.stations.dropFirst())
        if index == route.legs.count - 1 { stations = Array(stations.dropLast()) }
        return stations
    }

    private enum StopRole { case depart, normal, transfer(to: LineID), arrive }

    private func stopRow(stationID: StationID, color: Color, emphasized: Bool,
                         role: StopRole, showTopLine: Bool, showBottomLine: Bool) -> some View {
        let rowHeight: CGFloat = emphasized ? 46 : 32
        return HStack(alignment: .center, spacing: DS.Spacing.m) {
            trackCell(color: color, emphasized: emphasized,
                      showTopLine: showTopLine, showBottomLine: showBottomLine, height: rowHeight)
            VStack(alignment: .leading, spacing: 1) {
                Text(name(stationID))
                    .font(.app(emphasized ? .body : .subheadline, weight: emphasized ? .semibold : .regular))
                    .foregroundStyle(emphasized ? .primary : .secondary)
                switch role {
                case .depart:
                    Text(Loc.depart.string(for: lang)).font(.app(.caption2)).foregroundStyle(.secondary)
                case .transfer(let line):
                    HStack(spacing: DS.Spacing.xs) {
                        Text(Loc.transferTo.string(for: lang)).font(.app(.caption2)).foregroundStyle(.orange)
                        LineBadge(lineID: line, compact: true)
                    }
                case .arrive:
                    Text(Loc.arrive.string(for: lang)).font(.app(.caption2)).foregroundStyle(.green)
                case .normal:
                    EmptyView()
                }
            }
            Spacer()
        }
        .frame(height: rowHeight)
    }

    private var arriveRow: some View {
        stopRow(stationID: route.destination, color: Color(hex: route.legs.last?.colorHex ?? "#34C759"),
                emphasized: true, role: .arrive, showTopLine: true, showBottomLine: false)
    }

    /// The vertical line + node drawn on the leading edge of each stop.
    private func trackCell(color: Color, emphasized: Bool, showTopLine: Bool,
                           showBottomLine: Bool, height: CGFloat) -> some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle().fill(showTopLine ? color : .clear)
                Rectangle().fill(showBottomLine ? color : .clear)
            }
            .frame(width: 5, height: height)
            Circle()
                .fill(emphasized ? color : Color(.systemBackground))
                .frame(width: emphasized ? 16 : 10, height: emphasized ? 16 : 10)
                .overlay(Circle().stroke(color, lineWidth: emphasized ? 0 : 3))
        }
        .frame(width: 22, height: height)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            ShareLink(item: RouteFormatter.shareText(route, model: model, settings: settings)) {
                Label(Loc.share.string(for: lang), systemImage: "square.and.arrow.up")
            }
            Spacer()
            if let onSave {
                Button {
                    onSave()
                } label: {
                    Label(Loc.saveRoute.string(for: lang), systemImage: "bookmark")
                }
            }
        }
        .font(.app(.subheadline))
        .padding(.horizontal, DS.Spacing.xs)
    }

    private func name(_ id: StationID) -> String {
        model.station(id).map { settings.stationName($0) } ?? id
    }
}

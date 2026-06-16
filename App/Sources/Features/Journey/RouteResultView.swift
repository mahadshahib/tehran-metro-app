import SwiftUI
import MetroDomain

struct RouteResultView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    let route: Route
    var onSave: (() -> Void)? = nil

    private var lang: AppLanguage { settings.language }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            summary
            ForEach(route.legs) { leg in
                RouteLegCard(leg: leg)
                if leg.id != route.legs.last?.id {
                    transferRow(at: leg.to)
                }
            }
            alightRow
            footer
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(spacing: DS.Spacing.m) {
                Label(Numerals.minutes(route.estimate.totalMinutes, language: lang), systemImage: "clock")
                    .font(.headline)
                Text("·").foregroundStyle(.secondary)
                Text(Loc.stopsLabel(route.totalStops, language: lang))
                Text("·").foregroundStyle(.secondary)
                Text(Loc.transfersLabel(route.transferCount, language: lang))
            }
            .font(.subheadline)
            Text(Loc.approximate.string(for: lang))
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .metroCard()
    }

    private func transferRow(at stationID: StationID) -> some View {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: "figure.walk.arrival").foregroundStyle(.secondary)
            Text("\(Loc.transferAt.string(for: lang)) \(stationName(stationID))")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.leading, DS.Spacing.l)
    }

    private var alightRow: some View {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: "mappin.and.ellipse").foregroundStyle(.green)
            Text("\(Loc.alightAt.string(for: lang)) \(stationName(route.destination))")
                .font(.subheadline.weight(.medium))
        }
        .padding(.leading, DS.Spacing.l)
    }

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
        .font(.subheadline)
        .padding(.top, DS.Spacing.s)
    }

    private func stationName(_ id: StationID) -> String {
        model.station(id).map { settings.stationName($0) } ?? id
    }
}

/// A single leg: board line X toward terminal Y, ride N stops.
struct RouteLegCard: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    let leg: RouteLeg

    private var lang: AppLanguage { settings.language }
    private var color: Color { Color(hex: leg.colorHex) }

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.m) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 6)
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack(spacing: DS.Spacing.s) {
                    LineBadge(lineID: leg.line)
                    Text("\(Loc.toward.string(for: lang)) \(name(leg.towardTerminal))")
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                }
                Text("\(Loc.board.string(for: lang)): \(name(leg.from))")
                    .font(.subheadline)
                Text(Loc.stopsLabel(leg.stopCount, language: lang))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(DS.Spacing.m)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: DS.Radius.m))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(Loc.lineName(leg.line, language: lang)), \(Loc.toward.string(for: lang)) \(name(leg.towardTerminal)), \(Loc.stopsLabel(leg.stopCount, language: lang))"
        )
    }

    private func name(_ id: StationID) -> String {
        model.station(id).map { settings.stationName($0) } ?? id
    }
}

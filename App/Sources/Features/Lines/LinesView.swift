import SwiftUI
import MetroDomain

/// Overview of all lines plus a global station search entry point.
struct LinesView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section(Loc.lines.string(for: settings.language)) {
                        ForEach(model.network.sortedLines) { line in
                            NavigationLink(value: NavTarget.line(line.id)) {
                                LineRow(line: line)
                            }
                        }
                    }
                } else {
                    Section(Loc.stations.string(for: settings.language)) {
                        let results = model.network.search(searchText)
                        if results.isEmpty {
                            Text(Loc.noResults.string(for: settings.language))
                                .foregroundStyle(.secondary)
                        }
                        ForEach(results) { station in
                            NavigationLink(value: NavTarget.station(station.id)) {
                                StationRow(station: station)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Loc.appName.string(for: settings.language))
            .searchable(text: $searchText, prompt: Loc.searchStations.string(for: settings.language))
            .navigationDestination(for: NavTarget.self) { $0.destination }
        }
    }
}

private struct LineRow: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    let line: Line

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: line.colorHex))
                .frame(width: 6, height: 34)
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(Loc.lineName(line.id, language: settings.language))
                    .font(.app(.headline))
                if let first = line.terminals.first, let last = line.terminals.dropFirst().first,
                   let a = model.station(first), let b = model.station(last) {
                    Text("\(settings.stationName(a)) — \(settings.stationName(b))")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(Loc.stopsLabel(line.allStations.count, language: settings.language))
                .font(.app(.caption))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Type-safe navigation targets shared across the app.
enum NavTarget: Hashable {
    case line(LineID)
    case station(StationID)

    @ViewBuilder var destination: some View {
        switch self {
        case .line(let id): LineDetailView(lineID: id)
        case .station(let id): StationDetailView(stationID: id)
        }
    }
}

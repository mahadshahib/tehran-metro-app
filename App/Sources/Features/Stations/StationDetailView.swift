import SwiftUI
import SwiftData
import MetroDomain

struct StationDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    let stationID: StationID

    @State private var isFavorite = false

    private var station: Station? { model.station(stationID) }

    var body: some View {
        Group {
            if let station {
                List {
                    headerSection(station)
                    linesSection(station)
                    if let address = station.addressFA {
                        Section(Loc.address.string(for: settings.language)) {
                            Text(address).font(.metro(.body))
                        }
                    }
                    facilitiesSection(station)
                    actionSection(station)
                }
                .navigationTitle(settings.stationName(station))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            UserDataStore.toggleFavorite(stationID, context: context)
                            isFavorite.toggle()
                        } label: {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                        }
                        .accessibilityLabel((isFavorite ? Loc.removeFavorite : Loc.addFavorite).string(for: settings.language))
                    }
                }
                .onAppear {
                    isFavorite = UserDataStore.isFavorite(stationID, context: context)
                    UserDataStore.recordRecent(stationID, context: context)
                }
            } else {
                EmptyStateView(systemImage: "questionmark", message: Loc.noResults.string(for: settings.language))
            }
        }
    }

    private func headerSection(_ station: Station) -> some View {
        Section {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text(station.nameFA).font(.metro(.title2, weight: .bold))
                    .environment(\.layoutDirection, .rightToLeft)
                Text(station.nameEN).font(.title3).foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight)
                if !station.isInService {
                    Label(Loc.notInService.string(for: settings.language), systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline).foregroundStyle(.orange)
                }
            }
            .padding(.vertical, DS.Spacing.xs)
        }
    }

    private func linesSection(_ station: Station) -> some View {
        Section(Loc.linesServed.string(for: settings.language)) {
            ForEach(station.lines, id: \.self) { lineID in
                NavigationLink(value: NavTarget.line(lineID)) {
                    HStack {
                        LineBadge(lineID: lineID)
                        Spacer()
                        if station.isInterchange {
                            Image(systemName: "arrow.triangle.swap").foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func facilitiesSection(_ station: Station) -> some View {
        let items = FacilityCatalog.available(in: station.facilities, language: settings.language)
        return Group {
            if !items.isEmpty {
                Section(Loc.facilities.string(for: settings.language)) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: DS.Spacing.s)], alignment: .leading) {
                        ForEach(items, id: \.label) { item in
                            Label(item.label, systemImage: item.symbol)
                                .font(.subheadline)
                                .padding(.vertical, DS.Spacing.xs)
                        }
                    }
                }
            }
        }
    }

    private func actionSection(_ station: Station) -> some View {
        Section {
            NavigationLink {
                JourneyPlannerView(presetOrigin: stationID)
            } label: {
                Label(Loc.findRoute.string(for: settings.language), systemImage: "figure.walk")
            }
            Button {
                ExternalMaps.openDirections(to: station, name: settings.stationName(station))
            } label: {
                Label(Loc.directions.string(for: settings.language), systemImage: "location.fill")
            }
        }
    }
}

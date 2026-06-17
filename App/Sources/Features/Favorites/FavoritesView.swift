import SwiftUI
import SwiftData
import MetroDomain

struct FavoritesView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context

    @Query(sort: \FavoriteStation.addedAt, order: .reverse) private var favorites: [FavoriteStation]
    @Query(sort: \SavedRoute.savedAt, order: .reverse) private var savedRoutes: [SavedRoute]

    private var lang: AppLanguage { settings.language }

    var body: some View {
        List {
            Section(Loc.favorites.string(for: lang)) {
                if favorites.isEmpty {
                    Text(Loc.noFavorites.string(for: lang)).foregroundStyle(.secondary)
                }
                ForEach(favorites) { fav in
                    if let station = model.station(fav.stationID) {
                        NavigationLink(value: NavTarget.station(station.id)) {
                            StationRow(station: station)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet { UserDataStore.delete(favorites[index], context: context) }
                }
            }

            Section(Loc.savedRoutes.string(for: lang)) {
                if savedRoutes.isEmpty {
                    Text(Loc.noSavedRoutes.string(for: lang)).foregroundStyle(.secondary)
                }
                ForEach(savedRoutes) { route in
                    if let origin = model.station(route.originID), let dest = model.station(route.destinationID) {
                        NavigationLink {
                            JourneyPlannerView(presetOrigin: route.originID, presetDestination: route.destinationID)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(settings.stationName(origin)) → \(settings.stationName(dest))")
                                    .font(.app(.body, weight: .medium))
                                Text(Loc.tabJourney.string(for: lang))
                                    .font(.app(.caption)).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet { UserDataStore.delete(savedRoutes[index], context: context) }
                }
            }
        }
        .navigationTitle(Loc.favorites.string(for: lang))
        .navigationDestination(for: NavTarget.self) { $0.destination }
    }
}

import SwiftUI
import SwiftData
import MetroDomain

/// A searchable station picker presented as a sheet. Offers search plus quick
/// access to favorites and recents.
struct StationPickerView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    @Environment(LocationManager.self) private var location
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \FavoriteStation.addedAt, order: .reverse) private var favorites: [FavoriteStation]
    @Query(sort: \RecentStation.visitedAt, order: .reverse) private var recents: [RecentStation]

    let title: String
    let onSelect: (StationID) -> Void

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    nearestSection
                    quickSection(Loc.favorites, ids: favorites.map(\.stationID))
                    quickSection(Loc.recents, ids: recents.map(\.stationID))
                    Section(header: SectionHeaderLabel(Loc.stations.string(for: settings.language))) {
                        ForEach(model.network.serviceStations) { row($0) }
                    }
                } else {
                    let results = model.network.search(searchText)
                    if results.isEmpty {
                        Text(Loc.noResults.string(for: settings.language)).foregroundStyle(.secondary)
                    }
                    ForEach(results) { row($0) }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: Loc.searchStations.string(for: settings.language))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Loc.cancel.string(for: settings.language)) { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var nearestSection: some View {
        if let coordinate = location.lastCoordinate,
           let nearest = model.network.nearestStations(to: coordinate, limit: 1).first {
            Section(header: SectionHeaderLabel(Loc.nearestToMe.string(for: settings.language))) {
                row(nearest)
            }
        } else if !location.isDenied {
            Section {
                Button {
                    location.startTracking()
                } label: {
                    Label(Loc.useMyLocation.string(for: settings.language), systemImage: "location.fill")
                }
            }
        }
    }

    @ViewBuilder
    private func quickSection(_ titleText: LocalizedText, ids: [StationID]) -> some View {
        let stations = ids.compactMap { model.station($0) }
        if !stations.isEmpty {
            Section(header: SectionHeaderLabel(titleText.string(for: settings.language))) {
                ForEach(stations) { row($0) }
            }
        }
    }

    private func row(_ station: Station) -> some View {
        Button {
            onSelect(station.id)
            dismiss()
        } label: {
            StationRow(station: station)
        }
        .buttonStyle(.plain)
    }
}

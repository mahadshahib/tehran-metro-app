import SwiftUI
import MapKit
import MetroDomain

/// Geographic map (MapKit) with line-colored station pins, the user's location,
/// and a "nearest stations" list with one-tap external walking directions.
struct NearbyView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    @State private var location = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.7, longitude: 51.4),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    )
    @State private var selected: StationID?

    private var lang: AppLanguage { settings.language }

    private var referenceCoordinate: Coordinate? { location.lastCoordinate }

    private var nearest: [Station] {
        guard let coord = referenceCoordinate else { return [] }
        return model.network.nearestStations(to: coord, limit: 5)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                map
                list
            }
            .navigationTitle(Loc.tabNearby.string(for: lang))
            .navigationDestination(for: NavTarget.self) { $0.destination }
            .onAppear { location.requestPermissionAndLocation() }
            .onChange(of: location.lastCoordinate?.latitude) { _, _ in centerOnUser() }
        }
    }

    private var map: some View {
        Map(position: $cameraPosition, selection: $selected) {
            UserAnnotation()
            ForEach(model.network.serviceStations) { station in
                Marker(settings.stationName(station),
                       coordinate: CLLocationCoordinate2D(latitude: station.coordinate.latitude,
                                                          longitude: station.coordinate.longitude))
                    .tint(Color(hex: station.lines.first.flatMap { model.line($0)?.colorHex } ?? "#888888"))
                    .tag(Optional(station.id))
            }
        }
        .mapControls { MapUserLocationButton(); MapCompass() }
        .frame(height: 320)
        .environment(\.layoutDirection, .leftToRight)
    }

    @ViewBuilder
    private var list: some View {
        List {
            if !location.isAuthorized && referenceCoordinate == nil {
                Section {
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text(Loc.enableLocation.string(for: lang)).font(.subheadline)
                        Button(Loc.useMyLocation.string(for: lang)) {
                            location.requestPermissionAndLocation()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            Section(Loc.nearestStations.string(for: lang)) {
                if nearest.isEmpty {
                    Text(Loc.locationUnavailable.string(for: lang)).foregroundStyle(.secondary)
                }
                ForEach(nearest) { station in
                    NearbyRow(station: station, reference: referenceCoordinate)
                }
            }
        }
    }

    private func centerOnUser() {
        guard let coord = location.lastCoordinate else { return }
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
}

private struct NearbyRow: View {
    @Environment(AppSettings.self) private var settings
    let station: Station
    let reference: Coordinate?

    var body: some View {
        HStack {
            NavigationLink(value: NavTarget.station(station.id)) {
                VStack(alignment: .leading, spacing: 2) {
                    StationRow(station: station)
                    if let reference {
                        Text(Numerals.distance(meters: station.coordinate.distance(to: reference),
                                               language: settings.language))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Button {
                ExternalMaps.openDirections(to: station, name: settings.stationName(station))
            } label: {
                Image(systemName: "location.fill")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Loc.directions.string(for: settings.language))
        }
    }
}

import SwiftUI
import MapKit
import MetroDomain

/// Offline-first "find a station near me" screen.
///
/// Two modes, both of which compute results from the **bundled** station
/// coordinates — no network required:
///   • **My location** — live GPS tracking; the nearest station updates as you move.
///   • **Explore map** — pan the map and a crosshair finds the nearest station to
///     any point, even with no GPS signal (e.g. underground).
///
/// Only the map *tiles* need a connection; an indicator makes that explicit.
struct NearbyView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    @Environment(LocationManager.self) private var location
    @State private var reachability = ReachabilityMonitor()

    @State private var mode: Mode = .myLocation
    @State private var cameraPosition: MapCameraPosition = .region(Self.tehranRegion)
    @State private var mapCenter: Coordinate?
    @State private var selected: StationID?
    @State private var activeSheet: ActiveSheet?

    enum Mode: String, CaseIterable { case myLocation, exploreMap }

    private enum ActiveSheet: Identifiable {
        case detail(StationID)
        case plan(StationID)
        var id: String {
            switch self {
            case .detail(let s): return "detail-\(s)"
            case .plan(let s): return "plan-\(s)"
            }
        }
    }

    private var lang: AppLanguage { settings.language }

    /// The coordinate we measure "nearest" from, depending on mode.
    private var reference: Coordinate? {
        mode == .myLocation ? location.lastCoordinate : mapCenter
    }

    private var nearest: [Station] {
        guard let reference else { return [] }
        return model.network.nearestStations(to: reference, limit: 6)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mapSection
                Divider()
                controls
            }
            .navigationTitle(Loc.tabNearby.string(for: lang))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: NavTarget.self) { $0.destination }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { reachabilityBadge }
            }
            .sheet(item: $activeSheet, onDismiss: { selected = nil }) { sheet in
                switch sheet {
                case .detail(let id):
                    NavigationStack { StationDetailView(stationID: id) }
                        .presentationDetents([.medium, .large])
                case .plan(let id):
                    JourneyPlannerView(presetOrigin: id)
                }
            }
            .onChange(of: selected) { _, newValue in
                if let id = newValue { activeSheet = .detail(id) }
            }
            .onAppear { applyMode() }
            .onChange(of: mode) { _, _ in applyMode() }
        }
    }

    /// Configure tracking + camera for the active mode.
    private func applyMode() {
        switch mode {
        case .myLocation:
            location.startTracking()
            // Live-follow the user; falls back to Tehran until a fix arrives.
            cameraPosition = .userLocation(fallback: .region(Self.tehranRegion))
        case .exploreMap:
            // Freeze to a pannable region so the crosshair can explore freely.
            let center = mapCenter.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            } ?? Self.tehranRegion.center
            cameraPosition = .region(MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            ))
        }
    }

    // MARK: - Map

    private var mapSection: some View {
        ZStack {
            Map(position: $cameraPosition, selection: $selected) {
                UserAnnotation()
                ForEach(model.network.serviceStations) { station in
                    Marker(settings.stationName(station),
                           coordinate: station.clLocation)
                        .tint(Color(hex: station.lines.first.flatMap { model.line($0)?.colorHex } ?? "#888888"))
                        .tag(station.id)
                }
            }
            .mapControls { MapUserLocationButton(); MapCompass() }
            .onMapCameraChange(frequency: .onEnd) { context in
                mapCenter = Coordinate(latitude: context.region.center.latitude,
                                       longitude: context.region.center.longitude)
            }
            .environment(\.layoutDirection, .leftToRight)   // geography never mirrors

            if mode == .exploreMap {
                Image(systemName: "scope")
                    .font(.app(size: 34, weight: .light))
                    .foregroundStyle(.primary)
                    .shadow(radius: 2)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: 300)
    }

    // MARK: - Controls + nearest list

    private var controls: some View {
        List {
            Section {
                Picker("", selection: $mode) {
                    Label(Loc.myLocation.string(for: lang), systemImage: "location.fill").tag(Mode.myLocation)
                    Label(Loc.exploreMap.string(for: lang), systemImage: "scope").tag(Mode.exploreMap)
                }
                .pickerStyle(.segmented)
            }

            if !reachability.isOnline {
                Section {
                    Label(Loc.offlineMapNote.string(for: lang), systemImage: "wifi.slash")
                        .font(.app(.footnote)).foregroundStyle(.secondary)
                }
            }

            statusSection

            Section(Loc.nearestStations.string(for: lang)) {
                if nearest.isEmpty {
                    Text(Loc.locationUnavailable.string(for: lang)).foregroundStyle(.secondary)
                }
                ForEach(Array(nearest.enumerated()), id: \.element.id) { index, station in
                    NearbyRow(station: station, reference: reference, isNearest: index == 0,
                              onDirections: { ExternalMaps.openDirections(to: station, name: settings.stationName(station)) },
                              onPlan: { activeSheet = .plan(station.id) })
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var statusSection: some View {
        if mode == .myLocation {
            if location.isDenied {
                Section {
                    Label(Loc.locationDenied.string(for: lang), systemImage: "location.slash")
                        .font(.app(.subheadline)).foregroundStyle(.orange)
                }
            } else if location.lastCoordinate == nil {
                Section {
                    Button {
                        location.startTracking()
                    } label: {
                        Label(Loc.useMyLocation.string(for: lang), systemImage: "location.fill")
                    }
                }
            } else if location.isTracking {
                Section {
                    Label {
                        Text(Loc.live.string(for: lang))
                    } icon: {
                        Image(systemName: "dot.radiowaves.left.and.right").foregroundStyle(.green)
                    }
                    .font(.app(.footnote))
                }
            }
        } else {
            Section {
                Label(Loc.panToExplore.string(for: lang), systemImage: "hand.draw")
                    .font(.app(.footnote)).foregroundStyle(.secondary)
            }
        }
    }

    private var reachabilityBadge: some View {
        Label(
            (reachability.isOnline ? Loc.online : Loc.offline).string(for: lang),
            systemImage: reachability.isOnline ? "wifi" : "wifi.slash"
        )
        .font(.app(.caption2))
        .foregroundStyle(reachability.isOnline ? Color.secondary : Color.orange)
        .labelStyle(.titleAndIcon)
    }

    private static let tehranRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.7, longitude: 51.4),
        span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
    )
}

private struct NearbyRow: View {
    @Environment(AppSettings.self) private var settings
    let station: Station
    let reference: Coordinate?
    let isNearest: Bool
    let onDirections: () -> Void
    let onPlan: () -> Void

    private var lang: AppLanguage { settings.language }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            NavigationLink(value: NavTarget.station(station.id)) {
                HStack(spacing: DS.Spacing.s) {
                    StationRow(station: station)
                    if isNearest {
                        Image(systemName: "location.north.circle.fill")
                            .foregroundStyle(.tint)
                            .accessibilityLabel(Loc.nearestStation.string(for: lang))
                    }
                }
            }
            if let reference {
                let meters = station.coordinate.distance(to: reference)
                HStack(spacing: DS.Spacing.m) {
                    Label(Numerals.distance(meters: meters, language: lang), systemImage: "ruler")
                    Label(Loc.walkMinutes(Numerals.walkingMinutes(meters: meters), language: lang),
                          systemImage: "figure.walk")
                }
                .font(.app(.caption)).foregroundStyle(.secondary)
            }
            if isNearest {
                HStack(spacing: DS.Spacing.l) {
                    Button(action: onDirections) {
                        Label(Loc.directions.string(for: lang), systemImage: "location.fill")
                    }
                    Button(action: onPlan) {
                        Label(Loc.planFromHere.string(for: lang), systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                    }
                }
                .font(.app(.subheadline))
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}

private extension Station {
    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

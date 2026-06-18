import SwiftUI
import SwiftData
import MetroDomain

/// The app's home: get a commuter from A to B in as few taps as possible.
/// Pick a destination (origin can be one tap via "Nearest"), and the route
/// appears instantly. When idle, saved routes and favorites offer one-tap planning.
struct JourneyPlannerView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    @Environment(LocationManager.self) private var location
    @Environment(\.modelContext) private var context

    @Query(sort: \SavedRoute.savedAt, order: .reverse) private var savedRoutes: [SavedRoute]
    @Query(sort: \FavoriteStation.addedAt, order: .reverse) private var favorites: [FavoriteStation]

    @State private var viewModel: JourneyViewModel?
    @State private var picking: Endpoint?
    @State private var pendingNearest = false

    var presetOrigin: StationID? = nil
    var presetDestination: StationID? = nil

    private enum Endpoint: Identifiable { case origin, destination; var id: Int { hashValue } }
    private var lang: AppLanguage { settings.language }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    Color.clear
                }
            }
            .navigationTitle(Loc.tabJourney.string(for: lang))
            .navigationDestination(for: NavTarget.self) { $0.destination }
            .onAppear(perform: ensureViewModel)
            .onChange(of: location.lastCoordinate) { _, _ in fulfillNearestIfPending() }
        }
    }

    // MARK: - Setup

    private func ensureViewModel() {
        guard viewModel == nil else { return }
        viewModel = JourneyViewModel(
            engine: model.engine, language: lang,
            origin: presetOrigin, destination: presetDestination
        )
        viewModel?.plan()
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ vm: JourneyViewModel) -> some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                endpointsCard(vm)
                quickChips(vm)
                modePicker(vm)

                if let error = vm.errorMessage {
                    infoCard(error, systemImage: "exclamationmark.triangle.fill", tint: .orange)
                } else if let route = vm.route {
                    RouteResultView(route: route, onSave: {
                        Haptics.tap()
                        UserDataStore.saveRoute(origin: route.origin, destination: route.destination, context: context)
                    })
                } else {
                    quickStart(vm)
                }
            }
            .padding(DS.Spacing.l)
        }
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.immediately)
        .onChange(of: vm.route) { _, newValue in
            if newValue != nil { Haptics.success() }
        }
        .sheet(item: $picking) { endpoint in
            StationPickerView(
                title: (endpoint == .origin ? Loc.selectOrigin : Loc.selectDestination).string(for: lang)
            ) { id in
                Haptics.selection()
                if endpoint == .origin { vm.originID = id } else { vm.destinationID = id }
                vm.plan()
            }
        }
    }

    // MARK: - From / To card

    private func endpointsCard(_ vm: JourneyViewModel) -> some View {
        HStack(spacing: DS.Spacing.s) {
            VStack(spacing: 0) {
                endpointRow(vm, .origin, dotColor: .green, label: Loc.from,
                            placeholder: Loc.selectOrigin)
                Divider().padding(.leading, 36)
                endpointRow(vm, .destination, dotColor: .red, label: Loc.to,
                            placeholder: Loc.whereTo)
            }
            Button {
                Haptics.tap()
                vm.swap()
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.app(.body, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(vm.originID == nil && vm.destinationID == nil)
            .accessibilityLabel(Loc.swap.string(for: lang))
        }
        .padding(DS.Spacing.s)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func endpointRow(_ vm: JourneyViewModel, _ endpoint: Endpoint,
                             dotColor: Color, label: LocalizedText, placeholder: LocalizedText) -> some View {
        let stationID = endpoint == .origin ? vm.originID : vm.destinationID
        let station = stationID.flatMap { model.station($0) }
        let isLocating = endpoint == .origin && pendingNearest && station == nil
        return Button {
            Haptics.tap()
            picking = endpoint
        } label: {
            HStack(spacing: DS.Spacing.m) {
                Image(systemName: "circle.fill")
                    .font(.app(size: 11))
                    .foregroundStyle(dotColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label.string(for: lang))
                        .font(.app(.caption)).foregroundStyle(.secondary)
                    Text(isLocating ? Loc.locating.string(for: lang)
                         : (station.map { settings.stationName($0) } ?? placeholder.string(for: lang)))
                        .font(.app(.body, weight: .medium))
                        .foregroundStyle(station == nil ? .secondary : .primary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.forward").font(.app(.footnote)).foregroundStyle(.tertiary)
            }
            .frame(minHeight: 52)
            .padding(.horizontal, DS.Spacing.s)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick chips (Nearest origin / clear)

    @ViewBuilder
    private func quickChips(_ vm: JourneyViewModel) -> some View {
        if vm.originID == nil {
            HStack {
                Button {
                    useNearestOrigin(vm)
                } label: {
                    Label(Loc.nearestToMe.string(for: lang), systemImage: "location.fill")
                }
                .buttonStyle(ChipButtonStyle())
                Spacer()
            }
        }
    }

    // MARK: - Mode

    private func modePicker(_ vm: JourneyViewModel) -> some View {
        @Bindable var vm = vm
        return Picker(Loc.findRoute.string(for: lang), selection: $vm.mode) {
            Text(Loc.fewestTransfers.string(for: lang)).tag(RouteMode.fewestTransfers)
            Text(Loc.fewestStops.string(for: lang)).tag(RouteMode.fewestStops)
        }
        .pickerStyle(.segmented)
        .onChange(of: vm.mode) { _, _ in
            Haptics.selection()
            vm.plan()
        }
    }

    // MARK: - Idle quick-start (saved routes + favorites)

    @ViewBuilder
    private func quickStart(_ vm: JourneyViewModel) -> some View {
        let savedPairs: [SavedRoutePair] = savedRoutes.compactMap { r in
            guard let o = model.station(r.originID), let d = model.station(r.destinationID) else { return nil }
            return SavedRoutePair(id: r.id, origin: o, dest: d)
        }
        let favoriteStations = favorites.compactMap { model.station($0.stationID) }

        if savedPairs.isEmpty && favoriteStations.isEmpty {
            ContentUnavailableView {
                Label(Loc.planJourney.string(for: lang), systemImage: "tram.fill")
            } description: {
                Text(Loc.quickPlanHint.string(for: lang))
            }
            .padding(.top, DS.Spacing.xl)
        } else {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                if !savedPairs.isEmpty {
                    sectionHeader(Loc.savedRoutes)
                    VStack(spacing: DS.Spacing.s) {
                        ForEach(savedPairs) { pair in
                            savedRouteRow(vm, origin: pair.origin, dest: pair.dest)
                        }
                    }
                }
                if !favoriteStations.isEmpty {
                    sectionHeader(Loc.favorites)
                    FlowChips(stations: favoriteStations) { station in
                        Haptics.selection()
                        vm.destinationID = station.id
                        vm.plan()
                    }
                }
            }
        }
    }

    private func savedRouteRow(_ vm: JourneyViewModel, origin: Station, dest: Station) -> some View {
        Button {
            Haptics.selection()
            vm.originID = origin.id
            vm.destinationID = dest.id
            vm.plan()
        } label: {
            HStack(spacing: DS.Spacing.m) {
                Image(systemName: "bookmark.fill").foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(settings.stationName(origin)) → \(settings.stationName(dest))")
                        .font(.app(.body, weight: .medium)).foregroundStyle(.primary).lineLimit(1)
                    Text(Loc.findRoute.string(for: lang))
                        .font(.app(.caption)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.forward.circle.fill").foregroundStyle(.tint)
            }
            .padding(DS.Spacing.m)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Small helpers

    private func sectionHeader(_ text: LocalizedText) -> some View {
        Text(text.string(for: lang))
            .font(.app(.headline))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoCard(_ message: String, systemImage: String, tint: Color) -> some View {
        Label(message, systemImage: systemImage)
            .font(.app(.subheadline))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.l)
            .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: DS.Radius.m))
    }

    // MARK: - Nearest origin

    private func useNearestOrigin(_ vm: JourneyViewModel) {
        Haptics.tap()
        location.startTracking()
        if let coordinate = location.lastCoordinate,
           let nearest = model.network.nearestStations(to: coordinate, limit: 1).first {
            vm.originID = nearest.id
            vm.plan()
        } else {
            pendingNearest = true
        }
    }

    private func fulfillNearestIfPending() {
        guard pendingNearest, let vm = viewModel,
              let coordinate = location.lastCoordinate,
              let nearest = model.network.nearestStations(to: coordinate, limit: 1).first else { return }
        pendingNearest = false
        vm.originID = nearest.id
        vm.plan()
        Haptics.selection()
    }
}

/// A resolved saved route (both stations exist), drivable by `ForEach`.
private struct SavedRoutePair: Identifiable {
    let id: String
    let origin: Station
    let dest: Station
}

/// A wrapping row of tappable station chips.
private struct FlowChips: View {
    @Environment(AppSettings.self) private var settings
    let stations: [Station]
    let onTap: (Station) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: DS.Spacing.s)],
                  alignment: .leading, spacing: DS.Spacing.s) {
            ForEach(stations) { station in
                Button {
                    onTap(station)
                } label: {
                    Text(settings.stationName(station)).lineLimit(1)
                }
                .buttonStyle(ChipButtonStyle())
            }
        }
    }
}

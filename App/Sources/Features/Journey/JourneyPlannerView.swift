import SwiftUI
import SwiftData
import MetroDomain

struct JourneyPlannerView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context

    @State private var viewModel: JourneyViewModel? = nil
    @State private var picking: Endpoint? = nil

    var presetOrigin: StationID? = nil
    var presetDestination: StationID? = nil

    private enum Endpoint: Identifiable { case origin, destination; var id: Int { hashValue } }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    Color.clear
                }
            }
            .navigationTitle(Loc.tabJourney.string(for: settings.language))
            .onAppear(perform: ensureViewModel)
        }
    }

    private func ensureViewModel() {
        guard viewModel == nil else { return }
        viewModel = JourneyViewModel(
            engine: model.engine, language: settings.language,
            origin: presetOrigin, destination: presetDestination
        )
        viewModel?.plan()
    }

    @ViewBuilder
    private func content(_ vm: JourneyViewModel) -> some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                endpointsCard(vm)
                modePicker(vm)
                if let error = vm.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange).font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let route = vm.route {
                    RouteResultView(route: route, onSave: {
                        UserDataStore.saveRoute(origin: route.origin, destination: route.destination, context: context)
                    })
                } else if !vm.canPlan {
                    EmptyStateView(systemImage: "tram", message: Loc.planJourney.string(for: settings.language))
                        .padding(.top, DS.Spacing.xxl)
                }
            }
            .padding(DS.Spacing.l)
        }
        .sheet(item: $picking) { endpoint in
            StationPickerView(
                title: (endpoint == .origin ? Loc.selectOrigin : Loc.selectDestination).string(for: settings.language)
            ) { id in
                if endpoint == .origin { vm.originID = id } else { vm.destinationID = id }
                vm.plan()
            }
        }
    }

    private func endpointsCard(_ vm: JourneyViewModel) -> some View {
        HStack(spacing: DS.Spacing.m) {
            VStack(spacing: DS.Spacing.s) {
                endpointButton(Loc.from, stationID: vm.originID) { picking = .origin }
                Divider()
                endpointButton(Loc.to, stationID: vm.destinationID) { picking = .destination }
            }
            Button {
                vm.swap()
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.title3)
                    .frame(width: DS.Size.tapTarget, height: DS.Size.tapTarget)
            }
            .accessibilityLabel(Loc.swap.string(for: settings.language))
            .disabled(vm.originID == nil && vm.destinationID == nil)
        }
        .metroCard()
    }

    private func endpointButton(_ label: LocalizedText, stationID: StationID?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label.string(for: settings.language)).font(.caption).foregroundStyle(.secondary)
                    Text(stationID.flatMap { model.station($0) }.map { settings.stationName($0) }
                         ?? Loc.search.string(for: settings.language))
                        .font(.body.weight(.medium))
                        .foregroundStyle(stationID == nil ? .secondary : .primary)
                }
                Spacer()
                Image(systemName: "chevron.forward").font(.footnote).foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: DS.Size.tapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func modePicker(_ vm: JourneyViewModel) -> some View {
        @Bindable var vm = vm
        return Picker(Loc.findRoute.string(for: settings.language), selection: $vm.mode) {
            Text(Loc.fewestTransfers.string(for: settings.language)).tag(RouteMode.fewestTransfers)
            Text(Loc.fewestStops.string(for: settings.language)).tag(RouteMode.fewestStops)
        }
        .pickerStyle(.segmented)
        .onChange(of: vm.mode) { _, _ in vm.plan() }
    }
}

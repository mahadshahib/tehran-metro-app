import Foundation
import Observation
import MetroDomain
import MetroData

/// Root app model: owns the immutable network and the routing engine, both built
/// once at launch from the bundled data. Everything is offline.
@Observable
final class AppModel {
    let network: MetroNetwork
    let engine: RoutingEngine
    /// Non-nil if data loading failed (shown as an error state).
    let loadError: String?

    init() {
        do {
            let network = try MetroDataLoader.loadBundledNetwork()
            self.network = network
            self.engine = RoutingEngine(network: network)
            self.loadError = nil
        } catch {
            // Construct an empty network so the app can still launch and show an
            // explicit error rather than crashing.
            let empty = MetroNetwork(stations: [:], lines: [:])
            self.network = empty
            self.engine = RoutingEngine(network: empty)
            self.loadError = String(describing: error)
        }
    }

    func station(_ id: StationID?) -> Station? {
        guard let id else { return nil }
        return network.station(id)
    }

    func line(_ id: LineID) -> Line? { network.line(id) }
}

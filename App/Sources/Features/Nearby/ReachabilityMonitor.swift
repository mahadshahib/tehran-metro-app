import Foundation
import Observation
import Network

/// Lightweight online/offline monitor built on the first-party Network framework
/// (no third-party dependency). Used only to tell the user that *map tiles* need
/// a connection — every station-finding feature works fully offline regardless.
@Observable
final class ReachabilityMonitor {
    var isOnline: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.tehranmetro.reachability")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.isOnline = online }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}

import Foundation
import Observation
import MetroDomain

/// Drives the journey planner. Pure presentation state on top of the framework-
/// free `RoutingEngine`.
@Observable
final class JourneyViewModel {
    var originID: StationID?
    var destinationID: StationID?
    var mode: RouteMode = .fewestTransfers
    var route: Route?
    var errorMessage: String?

    private let engine: RoutingEngine
    private let language: AppLanguage

    init(engine: RoutingEngine, language: AppLanguage, origin: StationID? = nil, destination: StationID? = nil) {
        self.engine = engine
        self.language = language
        self.originID = origin
        self.destinationID = destination
    }

    var canPlan: Bool { originID != nil && destinationID != nil }

    func swap() {
        let o = originID
        originID = destinationID
        destinationID = o
        plan()
    }

    func plan() {
        errorMessage = nil
        route = nil
        guard let origin = originID, let destination = destinationID else { return }
        do {
            route = try engine.route(from: origin, to: destination, mode: mode)
        } catch let error as RoutingEngine.RoutingError {
            errorMessage = message(for: error)
        } catch {
            errorMessage = Loc.noRoute.string(for: language)
        }
    }

    private func message(for error: RoutingEngine.RoutingError) -> String {
        switch error {
        case .sameStation: return Loc.sameStationMsg.string(for: language)
        case .noRouteFound, .unknownStation, .stationOutOfService:
            return Loc.noRoute.string(for: language)
        }
    }
}

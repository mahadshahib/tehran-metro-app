import Foundation

/// Optimization preference for journey planning.
public enum RouteMode: String, Sendable, CaseIterable, Codable {
    /// Minimize number of line changes (transfers weighted heavily).
    case fewestTransfers
    /// Minimize total number of stops ridden.
    case fewestStops
}

/// One leg of a journey: ride a single line from `from` to `to`.
public struct RouteLeg: Hashable, Sendable, Identifiable {
    public let id: Int
    public let line: LineID
    public let colorHex: String
    /// Ordered stations ridden on this leg, inclusive of both ends.
    public let stations: [StationID]
    /// The terminal this train heads toward (the rider's travel direction).
    public let towardTerminal: StationID

    public var from: StationID { stations.first ?? "" }
    public var to: StationID { stations.last ?? "" }
    /// Number of stops ridden on this leg (edges between stations).
    public var stopCount: Int { max(0, stations.count - 1) }

    public init(id: Int, line: LineID, colorHex: String, stations: [StationID], towardTerminal: StationID) {
        self.id = id
        self.line = line
        self.colorHex = colorHex
        self.stations = stations
        self.towardTerminal = towardTerminal
    }
}

/// A complete planned journey from origin to destination.
public struct Route: Hashable, Sendable {
    public let origin: StationID
    public let destination: StationID
    public let legs: [RouteLeg]
    public let mode: RouteMode

    public init(origin: StationID, destination: StationID, legs: [RouteLeg], mode: RouteMode) {
        self.origin = origin
        self.destination = destination
        self.legs = legs
        self.mode = mode
    }

    /// Total stops ridden across all legs.
    public var totalStops: Int { legs.reduce(0) { $0 + $1.stopCount } }
    /// Number of transfers (line changes) = legs - 1.
    public var transferCount: Int { max(0, legs.count - 1) }

    /// Interchange station IDs where the rider changes line.
    public var transferStations: [StationID] {
        guard legs.count > 1 else { return [] }
        return legs.dropLast().map(\.to)
    }
}

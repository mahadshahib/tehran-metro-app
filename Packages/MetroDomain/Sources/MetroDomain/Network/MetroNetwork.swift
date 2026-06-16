import Foundation

/// The full, immutable metro network: stations, lines, and the adjacency graph.
/// Built once by the data layer and cached. Framework-free and `Sendable` so it
/// can be shared safely across actors.
public struct MetroNetwork: Sendable {
    public let stations: [StationID: Station]
    public let lines: [LineID: Line]
    /// Convenience: lines sorted by id.
    public let sortedLines: [Line]
    /// Convenience: stations sorted by English name.
    public let sortedStations: [Station]

    public init(stations: [StationID: Station], lines: [LineID: Line]) {
        self.stations = stations
        self.lines = lines
        self.sortedLines = lines.values.sorted { $0.id < $1.id }
        self.sortedStations = stations.values.sorted { $0.nameEN < $1.nameEN }
    }

    public func station(_ id: StationID) -> Station? { stations[id] }
    public func line(_ id: LineID) -> Line? { lines[id] }

    /// All in-service stations.
    public var serviceStations: [Station] { sortedStations.filter(\.isInService) }

    /// Interchange stations (serve more than one line), in service.
    public var interchanges: [Station] {
        sortedStations.filter { $0.isInterchange && $0.isInService }
    }

    /// Stations on a given line, in travel order (trunk only).
    public func orderedStations(on lineID: LineID) -> [Station] {
        guard let line = lines[lineID] else { return [] }
        return line.orderedStations.compactMap { stations[$0] }
    }

    /// Color hex for a line, or nil if unknown.
    public func color(of lineID: LineID) -> String? { lines[lineID]?.colorHex }

    /// Search stations by query across both languages, returning best-ordered
    /// matches. Prefix matches rank above interior substring matches.
    public func search(_ query: String, limit: Int = 50) -> [Station] {
        let q = PersianNormalizer.normalize(query)
        guard !q.isEmpty else { return Array(sortedStations.prefix(limit)) }
        var scored: [(Station, Int)] = []
        for station in sortedStations {
            let en = PersianNormalizer.normalize(station.nameEN)
            let fa = PersianNormalizer.normalize(station.nameFA)
            let score: Int
            if en == q || fa == q { score = 0 }
            else if en.hasPrefix(q) || fa.hasPrefix(q) { score = 1 }
            else if en.contains(q) || fa.contains(q) { score = 2 }
            else { continue }
            scored.append((station, score))
        }
        return scored
            .sorted { $0.1 != $1.1 ? $0.1 < $1.1 : $0.0.nameEN < $1.0.nameEN }
            .prefix(limit)
            .map(\.0)
    }

    /// Nearest in-service stations to a coordinate, closest first.
    public func nearestStations(to coordinate: Coordinate, limit: Int = 5) -> [Station] {
        serviceStations
            .map { ($0, $0.coordinate.distance(to: coordinate)) }
            .sorted { $0.1 < $1.1 }
            .prefix(limit)
            .map(\.0)
    }
}

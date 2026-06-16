import Foundation
@testable import MetroDomain

/// A tiny hand-built network for routing unit tests, designed so that the two
/// modes diverge:
///
///   Line 1: A — B — C — D — E         (terminals A, E)
///   Line 2: A — P — Z                 (terminals A, Z)
///   Line 3: Z — E                     (terminals Z, E)
///   Interchanges: A (lines 1,2), E (lines 1,3), Z (lines 2,3)
///
/// Route A→E:
///   - fewest transfers → Line 1 straight through: 4 stops, 0 transfers
///   - fewest stops      → Line 2 then Line 3:      3 stops, 1 transfer
enum SyntheticNetwork {

    static func make(disable: Set<StationID> = []) -> MetroNetwork {
        func station(_ id: String, lines: [Int], neighbors: [String]) -> Station {
            Station(
                id: id, nameEN: id, nameFA: id, lines: lines,
                coordinate: Coordinate(latitude: 35.7, longitude: 51.4),
                addressFA: nil, isInService: !disable.contains(id),
                neighbors: neighbors.sorted(),
                facilities: Facilities()
            )
        }

        let stationsList = [
            station("A", lines: [1, 2], neighbors: ["B", "P"]),
            station("B", lines: [1], neighbors: ["A", "C"]),
            station("C", lines: [1], neighbors: ["B", "D"]),
            station("D", lines: [1], neighbors: ["C", "E"]),
            station("E", lines: [1, 3], neighbors: ["D", "Z"]),
            station("P", lines: [2], neighbors: ["A", "Z"]),
            station("Z", lines: [2, 3], neighbors: ["P", "E"])
        ]
        let stations = Dictionary(uniqueKeysWithValues: stationsList.map { ($0.id, $0) })

        let lines: [LineID: Line] = [
            1: Line(id: 1, colorHex: "#E0001F",
                    orderedStations: ["A", "B", "C", "D", "E"], branches: [], terminals: ["A", "E"]),
            2: Line(id: 2, colorHex: "#2F4389",
                    orderedStations: ["A", "P", "Z"], branches: [], terminals: ["A", "Z"]),
            3: Line(id: 3, colorHex: "#67C5F5",
                    orderedStations: ["Z", "E"], branches: [], terminals: ["Z", "E"])
        ]

        return MetroNetwork(stations: stations, lines: lines)
    }
}

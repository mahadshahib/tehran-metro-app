import Foundation

/// Line number, 1...7 in the Tehran Metro source data.
public typealias LineID = Int

/// A metro line. Colors and ordering are derived from the source data, which is
/// the single source of truth — no hardcoded line lists.
public struct Line: Identifiable, Hashable, Sendable {
    public let id: LineID
    /// Exact hex color string from the data, e.g. "#E0001F".
    public let colorHex: String
    /// Stations in travel order along the line's trunk. For lines with a branch
    /// (Line 1, Line 4) this is the longest path; `branches` holds the spurs.
    public let orderedStations: [StationID]
    /// Additional branch sequences for lines that fork (each starts at the
    /// junction's neighbor and runs to a branch terminal).
    public let branches: [[StationID]]
    /// All terminal (end-of-track) station IDs on this line.
    public let terminals: [StationID]

    public init(
        id: LineID, colorHex: String, orderedStations: [StationID],
        branches: [[StationID]], terminals: [StationID]
    ) {
        self.id = id
        self.colorHex = colorHex
        self.orderedStations = orderedStations
        self.branches = branches
        self.terminals = terminals
    }

    /// English line name, e.g. "Line 1".
    public var nameEN: String { "Line \(id)" }

    /// All stations on the line including branches, de-duplicated, trunk first.
    public var allStations: [StationID] {
        var seen = Set<StationID>()
        var result: [StationID] = []
        for s in orderedStations + branches.flatMap({ $0 }) where seen.insert(s).inserted {
            result.append(s)
        }
        return result
    }
}

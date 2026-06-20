import Foundation

/// Stable unique identifier for a station. Equals the English name / dictionary
/// key in the source data, which is guaranteed unique (verified: 0 duplicates).
public typealias StationID = String

/// A metro station. Pure value type, framework-free.
public struct Station: Identifiable, Hashable, Sendable, Codable {
    public let id: StationID
    public let nameEN: String
    public let nameFA: String
    /// Line numbers this station serves (1...7). More than one ⇒ interchange.
    public let lines: [LineID]
    public let coordinate: Coordinate
    /// Persian address. Optional — missing on 3 stations in the source.
    public let addressFA: String?
    /// Source field `disabled` is inverted: `true` here means the station is open.
    public let isInService: Bool
    /// Adjacency list (neighbor station IDs), symmetrized at load time.
    public let neighbors: [StationID]
    public let facilities: Facilities

    public var isInterchange: Bool { lines.count > 1 }

    public init(
        id: StationID, nameEN: String, nameFA: String, lines: [LineID],
        coordinate: Coordinate, addressFA: String?, isInService: Bool,
        neighbors: [StationID], facilities: Facilities
    ) {
        self.id = id
        self.nameEN = nameEN
        self.nameFA = nameFA
        self.lines = lines
        self.coordinate = coordinate
        self.addressFA = addressFA
        self.isInService = isInService
        self.neighbors = neighbors
        self.facilities = facilities
    }

    /// Localized display name for a language.
    public func name(for language: AppLanguage) -> String {
        switch language {
        case .farsi: return nameFA
        case .english: return nameEN
        }
    }
}

/// The two fully-supported app languages. Independent of system language.
public enum AppLanguage: String, Sendable, Codable, CaseIterable {
    case english = "en"
    case farsi = "fa"

    public var isRTL: Bool { self == .farsi }
}

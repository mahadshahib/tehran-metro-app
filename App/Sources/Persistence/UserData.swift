import Foundation
import SwiftData

/// A favorited station (referenced by its stable station ID).
@Model
final class FavoriteStation {
    @Attribute(.unique) var stationID: String
    var addedAt: Date

    init(stationID: String, addedAt: Date = .now) {
        self.stationID = stationID
        self.addedAt = addedAt
    }
}

/// A saved journey (origin + destination IDs), for quick re-planning.
@Model
final class SavedRoute {
    @Attribute(.unique) var id: String   // "\(origin)->\(destination)"
    var originID: String
    var destinationID: String
    var savedAt: Date

    init(originID: String, destinationID: String, savedAt: Date = .now) {
        self.id = "\(originID)->\(destinationID)"
        self.originID = originID
        self.destinationID = destinationID
        self.savedAt = savedAt
    }
}

/// A recent station search/selection, for quick re-access.
@Model
final class RecentStation {
    @Attribute(.unique) var stationID: String
    var visitedAt: Date

    init(stationID: String, visitedAt: Date = .now) {
        self.stationID = stationID
        self.visitedAt = visitedAt
    }
}

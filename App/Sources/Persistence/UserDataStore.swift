import Foundation
import SwiftData

/// Thin helpers for mutating user data. Read paths use `@Query` in views.
enum UserDataStore {

    static func isFavorite(_ stationID: String, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<FavoriteStation>(
            predicate: #Predicate { $0.stationID == stationID }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    static func toggleFavorite(_ stationID: String, context: ModelContext) {
        let descriptor = FetchDescriptor<FavoriteStation>(
            predicate: #Predicate { $0.stationID == stationID }
        )
        if let existing = try? context.fetch(descriptor), let first = existing.first {
            context.delete(first)
        } else {
            context.insert(FavoriteStation(stationID: stationID))
        }
        try? context.save()
    }

    static func recordRecent(_ stationID: String, context: ModelContext) {
        let descriptor = FetchDescriptor<RecentStation>(
            predicate: #Predicate { $0.stationID == stationID }
        )
        if let existing = try? context.fetch(descriptor), let first = existing.first {
            first.visitedAt = .now
        } else {
            context.insert(RecentStation(stationID: stationID))
        }
        try? context.save()
        pruneRecents(context: context)
    }

    static func saveRoute(origin: String, destination: String, context: ModelContext) {
        let route = SavedRoute(originID: origin, destinationID: destination)
        context.insert(route)   // @Attribute(.unique) upserts on the composite id
        try? context.save()
    }

    static func delete<T: PersistentModel>(_ object: T, context: ModelContext) {
        context.delete(object)
        try? context.save()
    }

    /// Keep only the 20 most-recent stations.
    private static func pruneRecents(context: ModelContext) {
        var descriptor = FetchDescriptor<RecentStation>(
            sortBy: [SortDescriptor(\.visitedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1000
        guard let all = try? context.fetch(descriptor), all.count > 20 else { return }
        for stale in all.dropFirst(20) { context.delete(stale) }
        try? context.save()
    }
}

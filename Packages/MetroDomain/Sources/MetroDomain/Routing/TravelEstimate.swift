import Foundation

/// Assumption-based travel-time model. The source data contains **no timetable**,
/// so all times are explicitly approximate. Constants are tunable and surfaced
/// in the UI as "approximate".
public struct TravelEstimate: Sendable, Hashable {
    /// Seconds spent riding per stop (dwell + travel between two stations).
    public static let secondsPerStop: Double = 120   // ~2 min/stop
    /// Seconds added per transfer (walk between platforms + wait).
    public static let secondsPerTransfer: Double = 240 // ~4 min/transfer

    public let totalSeconds: Double
    /// Always true for this data set — there is no real timetable.
    public let isApproximate: Bool

    public init(stops: Int, transfers: Int) {
        self.totalSeconds = Double(stops) * Self.secondsPerStop
            + Double(transfers) * Self.secondsPerTransfer
        self.isApproximate = true
    }

    public var totalMinutes: Int { Int((totalSeconds / 60).rounded()) }
}

public extension Route {
    /// Approximate travel-time estimate for this route.
    var estimate: TravelEstimate {
        TravelEstimate(stops: totalStops, transfers: transferCount)
    }
}

import Foundation
import CoreGraphics
import MetroDomain

/// Computes normalized [0,1] planar positions for every station by projecting
/// geographic coordinates (the source has no schematic layout data, so we derive
/// an organic diagram from real coordinates). Latitude is flipped so north is up.
struct SchematicLayout {
    let positions: [StationID: CGPoint]   // normalized 0...1
    /// Per-line ordered point sequences (trunk + branches) for drawing strokes.
    let polylines: [(line: LineID, colorHex: String, points: [StationID])]

    init(network: MetroNetwork) {
        let coords = network.stations.mapValues { $0.coordinate }
        let lats = coords.values.map(\.latitude)
        let lons = coords.values.map(\.longitude)
        let minLat = lats.min() ?? 0, maxLat = lats.max() ?? 1
        let minLon = lons.min() ?? 0, maxLon = lons.max() ?? 1
        let latSpan = max(maxLat - minLat, 0.0001)
        let lonSpan = max(maxLon - minLon, 0.0001)

        var pts: [StationID: CGPoint] = [:]
        for (id, c) in coords {
            let x = (c.longitude - minLon) / lonSpan
            let y = (maxLat - c.latitude) / latSpan   // flip
            pts[id] = CGPoint(x: x, y: y)
        }
        self.positions = pts

        var lines: [(LineID, String, [StationID])] = []
        for line in network.sortedLines {
            lines.append((line.id, line.colorHex, line.orderedStations))
            for branch in line.branches where branch.count > 1 {
                lines.append((line.id, line.colorHex, branch))
            }
        }
        self.polylines = lines.map { ($0.0, $0.1, $0.2) }
    }

    /// Map a normalized point into a drawing rect with scale + offset applied.
    func point(_ id: StationID, in size: CGSize, scale: CGFloat, offset: CGSize, inset: CGFloat) -> CGPoint? {
        guard let p = positions[id] else { return nil }
        let w = size.width - inset * 2
        let h = size.height - inset * 2
        let base = CGPoint(x: inset + p.x * w, y: inset + p.y * h)
        let cx = size.width / 2, cy = size.height / 2
        return CGPoint(
            x: cx + (base.x - cx) * scale + offset.width,
            y: cy + (base.y - cy) * scale + offset.height
        )
    }

    /// Find the station nearest to a tap location (within a hit radius).
    func nearestStation(to location: CGPoint, in size: CGSize, scale: CGFloat, offset: CGSize, inset: CGFloat, hitRadius: CGFloat = 22) -> StationID? {
        var best: StationID?
        var bestDist = hitRadius
        for id in positions.keys {
            guard let p = point(id, in: size, scale: scale, offset: offset, inset: inset) else { continue }
            let d = hypot(p.x - location.x, p.y - location.y)
            if d < bestDist { bestDist = d; best = id }
        }
        return best
    }
}

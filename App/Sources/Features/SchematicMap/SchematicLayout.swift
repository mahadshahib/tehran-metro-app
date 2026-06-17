import Foundation
import CoreGraphics
import MetroDomain

/// Projects station coordinates into an **aspect-correct** plane (longitude is
/// scaled by cos(latitude) so the city isn't horizontally stretched) and fits
/// them uniformly into the drawing area. This is what makes the diagram look
/// like a real 2D metro map rather than a distorted blob.
struct SchematicLayout {
    /// Raw aspect-correct projected points (y points up in geo terms; we flip
    /// for screen at draw time).
    private let projected: [StationID: CGPoint]
    private let bounds: CGRect
    /// Per-line ordered point sequences (trunk + branches) for drawing strokes.
    let polylines: [(line: LineID, colorHex: String, points: [StationID])]

    init(network: MetroNetwork) {
        let coords = network.stations.mapValues(\.coordinate)
        let meanLat = (coords.values.map(\.latitude).reduce(0, +)) / Double(max(coords.count, 1))
        let k = cos(meanLat * .pi / 180)

        var pts: [StationID: CGPoint] = [:]
        for (id, c) in coords {
            // x grows east, y grows north; screen flip happens in screenPoint().
            pts[id] = CGPoint(x: c.longitude * k, y: c.latitude)
        }
        projected = pts

        let xs = pts.values.map(\.x), ys = pts.values.map(\.y)
        let minX = xs.min() ?? 0, maxX = xs.max() ?? 1
        let minY = ys.min() ?? 0, maxY = ys.max() ?? 1
        bounds = CGRect(x: minX, y: minY,
                        width: max(maxX - minX, 0.0001),
                        height: max(maxY - minY, 0.0001))

        var lines: [(LineID, String, [StationID])] = []
        for line in network.sortedLines {
            lines.append((line.id, line.colorHex, line.orderedStations))
            for branch in line.branches where branch.count > 1 {
                lines.append((line.id, line.colorHex, branch))
            }
        }
        polylines = lines.map { ($0.0, $0.1, $0.2) }
    }

    /// Uniform scale that fits the whole network into `size` minus `padding`.
    private func baseScale(in size: CGSize, padding: CGFloat) -> CGFloat {
        let w = max(size.width - padding * 2, 1)
        let h = max(size.height - padding * 2, 1)
        return min(w / bounds.width, h / bounds.height)
    }

    /// Screen position for a station, with zoom (around the view center) and pan.
    func screenPoint(_ id: StationID, in size: CGSize, zoom: CGFloat, pan: CGSize, padding: CGFloat) -> CGPoint? {
        guard let p = projected[id] else { return nil }
        let scale = baseScale(in: size, padding: padding)
        // Center the bounds in the view; flip Y so north is up.
        let drawW = bounds.width * scale, drawH = bounds.height * scale
        let originX = (size.width - drawW) / 2
        let originY = (size.height - drawH) / 2
        let base = CGPoint(
            x: originX + (p.x - bounds.minX) * scale,
            y: originY + (bounds.maxY - p.y) * scale
        )
        let cx = size.width / 2, cy = size.height / 2
        return CGPoint(
            x: cx + (base.x - cx) * zoom + pan.width,
            y: cy + (base.y - cy) * zoom + pan.height
        )
    }

    /// Nearest station to a tap location within a hit radius.
    func nearestStation(to location: CGPoint, in size: CGSize, zoom: CGFloat, pan: CGSize,
                        padding: CGFloat, hitRadius: CGFloat = 24) -> StationID? {
        var best: StationID?
        var bestDist = hitRadius
        for id in projected.keys {
            guard let p = screenPoint(id, in: size, zoom: zoom, pan: pan, padding: padding) else { continue }
            let d = hypot(p.x - location.x, p.y - location.y)
            if d < bestDist { bestDist = d; best = id }
        }
        return best
    }
}

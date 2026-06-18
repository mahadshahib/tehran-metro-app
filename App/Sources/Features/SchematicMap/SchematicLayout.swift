import Foundation
import CoreGraphics
import MetroDomain

/// Generates an **evenly-spaced schematic layout** for the metro diagram.
///
/// The source data has no schematic coordinates, so we compute one with a
/// deterministic force-directed algorithm (Fruchterman–Reingold): adjacent
/// stations are pulled toward a uniform edge length while all stations repel
/// each other. Seeded from real geography so the result keeps Tehran's rough
/// orientation, but the dense city centre spreads out so **every station is
/// separated and visible** — unlike a raw geographic plot. Runs once, cached.
struct SchematicLayout: Sendable {
    /// A single drawable line segment chain (a line's trunk or one branch).
    struct Polyline: Sendable {
        let line: LineID
        let colorHex: String
        let points: [StationID]
    }

    /// Normalized positions in a y-down space (0,0 top-left of the bounds).
    private let positions: [StationID: CGPoint]
    private let bounds: CGRect
    /// Per-line ordered point sequences (trunk + branches) for drawing strokes.
    let polylines: [Polyline]

    init(network: MetroNetwork) {
        let ids = network.stations.keys.sorted()   // sorted ⇒ deterministic
        let n = ids.count
        var indexOf: [StationID: Int] = [:]
        for (i, id) in ids.enumerated() { indexOf[id] = i }

        var pos = Self.seedFromGeography(ids: ids, network: network)
        let edges = Self.edges(ids: ids, indexOf: indexOf, network: network)
        Self.relax(&pos, edges: edges, count: n)

        // Build dictionary + bounds.
        var dict: [StationID: CGPoint] = [:]
        var minX = CGFloat.greatestFiniteMagnitude, minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude, maxY = -CGFloat.greatestFiniteMagnitude
        for (i, id) in ids.enumerated() {
            dict[id] = pos[i]
            minX = min(minX, pos[i].x); maxX = max(maxX, pos[i].x)
            minY = min(minY, pos[i].y); maxY = max(maxY, pos[i].y)
        }
        positions = dict
        bounds = CGRect(x: minX, y: minY,
                        width: max(maxX - minX, 0.0001), height: max(maxY - minY, 0.0001))

        var lines: [Polyline] = []
        for line in network.sortedLines {
            lines.append(Polyline(line: line.id, colorHex: line.colorHex, points: line.orderedStations))
            for branch in line.branches where branch.count > 1 {
                lines.append(Polyline(line: line.id, colorHex: line.colorHex, points: branch))
            }
        }
        polylines = lines
    }

    // MARK: - Layout computation

    private static func seedFromGeography(ids: [StationID], network: MetroNetwork) -> [CGPoint] {
        let coords = ids.map { network.stations[$0]!.coordinate }
        let meanLat = coords.map(\.latitude).reduce(0, +) / Double(max(coords.count, 1))
        let k = cos(meanLat * .pi / 180)
        let xs = coords.map { $0.longitude * k }
        let ys = coords.map { -$0.latitude }          // y-down: north on top
        let minX = xs.min() ?? 0, maxX = xs.max() ?? 1
        let minY = ys.min() ?? 0, maxY = ys.max() ?? 1
        let spanX = max(maxX - minX, 1e-6), spanY = max(maxY - minY, 1e-6)
        return ids.indices.map { i in
            CGPoint(
                x: CGFloat((xs[i] - minX) / spanX) + CGFloat(i % 7) * 1e-4,
                y: CGFloat((ys[i] - minY) / spanY) + CGFloat(i % 5) * 1e-4
            )
        }
    }

    private static func edges(ids: [StationID], indexOf: [StationID: Int], network: MetroNetwork) -> [(Int, Int)] {
        var result: [(Int, Int)] = []
        for id in ids {
            let i = indexOf[id]!
            for neighbor in network.stations[id]?.neighbors ?? [] {
                if let j = indexOf[neighbor], i < j { result.append((i, j)) }
            }
        }
        return result
    }

    /// Fruchterman–Reingold relaxation toward uniform edge lengths.
    private static func relax(_ pos: inout [CGPoint], edges: [(Int, Int)], count n: Int) {
        guard n > 1 else { return }
        let ideal = 1.1 * sqrt(1.0 / Double(n))     // target spacing in unit area
        var temp = 0.10
        let iterations = 350

        for _ in 0..<iterations {
            var dispX = [Double](repeating: 0, count: n)
            var dispY = [Double](repeating: 0, count: n)

            // Repulsion between all pairs.
            for i in 0..<n {
                let xi = Double(pos[i].x), yi = Double(pos[i].y)
                for j in (i + 1)..<n {
                    var dx = xi - Double(pos[j].x)
                    var dy = yi - Double(pos[j].y)
                    var dist = (dx * dx + dy * dy).squareRoot()
                    if dist < 1e-6 { dist = 1e-6; dx = 1e-6; dy = 0 }
                    let force = ideal * ideal / dist
                    let fx = dx / dist * force, fy = dy / dist * force
                    dispX[i] += fx; dispY[i] += fy
                    dispX[j] -= fx; dispY[j] -= fy
                }
            }

            // Attraction along edges.
            for (i, j) in edges {
                var dx = Double(pos[i].x) - Double(pos[j].x)
                var dy = Double(pos[i].y) - Double(pos[j].y)
                var dist = (dx * dx + dy * dy).squareRoot()
                if dist < 1e-6 { dist = 1e-6; dx = 1e-6; dy = 0 }
                let force = dist * dist / ideal
                let fx = dx / dist * force, fy = dy / dist * force
                dispX[i] -= fx; dispY[i] -= fy
                dispX[j] += fx; dispY[j] += fy
            }

            // Apply, capped by the (cooling) temperature.
            for i in 0..<n {
                let d = (dispX[i] * dispX[i] + dispY[i] * dispY[i]).squareRoot()
                if d > 1e-9 {
                    let limited = min(d, temp)
                    pos[i].x += CGFloat(dispX[i] / d * limited)
                    pos[i].y += CGFloat(dispY[i] / d * limited)
                }
            }
            temp = max(temp * 0.985, 0.002)
        }
    }

    // MARK: - Screen mapping (uniform fit + zoom/pan)

    private func baseScale(in size: CGSize, padding: CGFloat) -> CGFloat {
        let w = max(size.width - padding * 2, 1)
        let h = max(size.height - padding * 2, 1)
        return min(w / bounds.width, h / bounds.height)
    }

    func screenPoint(_ id: StationID, in size: CGSize, zoom: CGFloat, pan: CGSize, padding: CGFloat) -> CGPoint? {
        guard let p = positions[id] else { return nil }
        let scale = baseScale(in: size, padding: padding)
        let drawW = bounds.width * scale, drawH = bounds.height * scale
        let originX = (size.width - drawW) / 2
        let originY = (size.height - drawH) / 2
        let base = CGPoint(x: originX + (p.x - bounds.minX) * scale,
                           y: originY + (p.y - bounds.minY) * scale)
        let cx = size.width / 2, cy = size.height / 2
        return CGPoint(x: cx + (base.x - cx) * zoom + pan.width,
                       y: cy + (base.y - cy) * zoom + pan.height)
    }

    func nearestStation(to location: CGPoint, in size: CGSize, zoom: CGFloat, pan: CGSize,
                        padding: CGFloat, hitRadius: CGFloat = 26) -> StationID? {
        var best: StationID?
        var bestDist = hitRadius
        for id in positions.keys {
            guard let p = screenPoint(id, in: size, zoom: zoom, pan: pan, padding: padding) else { continue }
            let d = hypot(p.x - location.x, p.y - location.y)
            if d < bestDist { bestDist = d; best = id }
        }
        return best
    }
}

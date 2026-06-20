import Foundation
import MetroDomain

/// Reconstructs `Line` models from the station graph. The source data has **no
/// explicit station order** — order is recovered by walking each line's relation
/// chain. Lines with a real-world fork (Line 1 → Kahrizak/Parand, Line 4 →
/// Mehrabad spur) are split into a trunk plus branch sequences.
///
/// Line colors are passed in from the data layer (read from each station's
/// parallel `colors` array), so color remains data-driven — nothing is hardcoded.
enum LineBuilder {

    static func buildLines(
        stations: [StationID: Station],
        lineColors: [LineID: String]
    ) -> [LineID: Line] {
        var members: [LineID: [StationID]] = [:]
        for station in stations.values {
            for line in station.lines {
                members[line, default: []].append(station.id)
            }
        }

        var result: [LineID: Line] = [:]
        for (lineID, memberIDs) in members {
            result[lineID] = buildLine(
                id: lineID,
                colorHex: lineColors[lineID] ?? "#888888",
                memberIDs: memberIDs,
                stations: stations
            )
        }
        return result
    }

    private static func buildLine(
        id: LineID, colorHex: String, memberIDs: [StationID], stations: [StationID: Station]
    ) -> Line {
        let memberSet = Set(memberIDs)

        func lineNeighbors(_ stationID: StationID) -> [StationID] {
            guard let station = stations[stationID] else { return [] }
            return station.neighbors.filter { memberSet.contains($0) }
        }

        // Endpoints: degree 0 or 1.
        let terminals = memberIDs.filter { lineNeighbors($0).count <= 1 }.sorted()

        // Trunk: the longest shortest-path between two endpoints.
        var trunk: [StationID] = []
        if terminals.count >= 2 {
            var best: [StationID] = []
            for start in terminals {
                let (_, parents, farthest) = bfs(from: start, neighbors: lineNeighbors)
                let path = reconstruct(to: farthest, parents: parents)
                if path.count > best.count { best = path }
            }
            trunk = best
        } else if let only = memberIDs.first {
            let (_, parents, farthest) = bfs(from: only, neighbors: lineNeighbors)
            trunk = reconstruct(to: farthest, parents: parents)
        }

        // Branches: walk in from each off-trunk endpoint to the trunk.
        let trunkSet = Set(trunk)
        var branches: [[StationID]] = []
        var covered = trunkSet
        for terminal in terminals where !trunkSet.contains(terminal) {
            var path: [StationID] = []
            var current: StationID? = terminal
            var visited = Set<StationID>()
            while let node = current, visited.insert(node).inserted {
                path.append(node)
                if trunkSet.contains(node) { break }
                current = lineNeighbors(node).first { !visited.contains($0) }
            }
            if path.count >= 2 {
                branches.append(path)
                covered.formUnion(path)
            }
        }

        // Any leftover isolated members (e.g. the disabled `Chaharbagh` anomaly)
        // are appended as singleton branches so they are never silently lost.
        for member in memberIDs.sorted() where !covered.contains(member) {
            branches.append([member])
            covered.insert(member)
        }

        return Line(
            id: id, colorHex: colorHex,
            orderedStations: trunk, branches: branches, terminals: terminals
        )
    }

    /// BFS returning distances, parent pointers, and the farthest node.
    private static func bfs(
        from start: StationID, neighbors: (StationID) -> [StationID]
    ) -> (dist: [StationID: Int], parents: [StationID: StationID], farthest: StationID) {
        var dist: [StationID: Int] = [start: 0]
        var parents: [StationID: StationID] = [:]
        var queue = [start]
        var head = 0
        var farthest = start
        while head < queue.count {
            let node = queue[head]; head += 1
            if dist[node]! > dist[farthest]! { farthest = node }
            for neighbor in neighbors(node) where dist[neighbor] == nil {
                dist[neighbor] = dist[node]! + 1
                parents[neighbor] = node
                queue.append(neighbor)
            }
        }
        return (dist, parents, farthest)
    }

    private static func reconstruct(to end: StationID, parents: [StationID: StationID]) -> [StationID] {
        var path = [end]
        var node = end
        while let p = parents[node] {
            path.append(p)
            node = p
        }
        return path.reversed()
    }
}

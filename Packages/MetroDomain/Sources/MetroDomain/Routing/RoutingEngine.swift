import Foundation

/// Computes optimal journeys over the metro network.
///
/// The graph is **line-aware**: each node is a `(station, line)` state. Riding
/// one stop on a line is an edge between two such states; changing line at an
/// interchange is a *transfer edge* carrying a penalty. This lets the engine
/// produce "board Line X toward terminal Y, ride N stops, transfer at Z"
/// directions and optimize for either fewest transfers or fewest stops.
///
/// Out-of-service (`disabled`) stations are excluded from routing.
public struct RoutingEngine: Sendable {
    private let network: MetroNetwork

    public init(network: MetroNetwork) {
        self.network = network
    }

    public enum RoutingError: Error, Equatable, Sendable {
        case unknownStation(StationID)
        case stationOutOfService(StationID)
        case sameStation
        case noRouteFound
    }

    private struct State: Hashable {
        let station: StationID
        let line: LineID
    }

    // MARK: - Public API

    /// Plan a route from `origin` to `destination` under the given mode.
    public func route(from origin: StationID, to destination: StationID, mode: RouteMode) throws -> Route {
        guard let originStation = network.station(origin) else { throw RoutingError.unknownStation(origin) }
        guard let destStation = network.station(destination) else { throw RoutingError.unknownStation(destination) }
        guard origin != destination else { throw RoutingError.sameStation }
        guard originStation.isInService else { throw RoutingError.stationOutOfService(origin) }
        guard destStation.isInService else { throw RoutingError.stationOutOfService(destination) }

        let (rideWeight, transferWeight) = weights(for: mode)

        var dist: [State: Double] = [:]
        var prev: [State: State] = [:]
        var heap = MinHeap<State>()

        // Boarding any line the origin serves is free (no initial transfer cost).
        for line in originStation.lines {
            let s = State(station: origin, line: line)
            dist[s] = 0
            heap.push(s, priority: 0)
        }

        var best: State?
        while let (current, currentDist) = heap.pop() {
            if currentDist > (dist[current] ?? .infinity) { continue }
            if current.station == destination {
                best = current
                break
            }
            guard let station = network.station(current.station) else { continue }

            // Ride edges: move to an adjacent station on the same line.
            for neighborID in station.neighbors {
                guard let neighbor = network.station(neighborID),
                      neighbor.isInService,
                      neighbor.lines.contains(current.line) else { continue }
                relax(
                    to: State(station: neighborID, line: current.line),
                    weight: rideWeight,
                    from: current, currentDist: currentDist,
                    dist: &dist, prev: &prev, heap: &heap
                )
            }

            // Transfer edges: change line at the same (interchange) station.
            if station.lines.count > 1 {
                for otherLine in station.lines where otherLine != current.line {
                    relax(
                        to: State(station: current.station, line: otherLine),
                        weight: transferWeight,
                        from: current, currentDist: currentDist,
                        dist: &dist, prev: &prev, heap: &heap
                    )
                }
            }
        }

        guard let terminalState = best else { throw RoutingError.noRouteFound }
        let path = reconstructPath(to: terminalState, prev: prev)
        return buildRoute(origin: origin, destination: destination, path: path, mode: mode)
    }

    /// Plan both supported modes; returns whichever are computable.
    public func routes(from origin: StationID, to destination: StationID) -> [Route] {
        RouteMode.allCases.compactMap { try? route(from: origin, to: destination, mode: $0) }
    }

    // MARK: - Dijkstra helpers

    private func weights(for mode: RouteMode) -> (ride: Double, transfer: Double) {
        switch mode {
        case .fewestStops:
            // Stops dominate; transfers act only as a near-zero tiebreak.
            return (1.0, 0.001)
        case .fewestTransfers:
            // Transfers dominate; stops act as a tiebreak among equal-transfer routes.
            return (1.0, 1000.0)
        }
    }

    private func relax(
        to next: State, weight: Double, from current: State, currentDist: Double,
        dist: inout [State: Double], prev: inout [State: State], heap: inout MinHeap<State>
    ) {
        let newDist = currentDist + weight
        if newDist < (dist[next] ?? .infinity) {
            dist[next] = newDist
            prev[next] = current
            heap.push(next, priority: newDist)
        }
    }

    private func reconstructPath(to end: State, prev: [State: State]) -> [State] {
        var path: [State] = [end]
        var node = end
        while let p = prev[node] {
            path.append(p)
            node = p
        }
        return path.reversed()
    }

    // MARK: - Leg assembly

    private func buildRoute(origin: StationID, destination: StationID, path: [State], mode: RouteMode) -> Route {
        var legs: [RouteLeg] = []
        var currentLine: LineID? = nil
        var currentStations: [StationID] = []

        func closeLeg() {
            guard let line = currentLine, currentStations.count >= 2 else {
                currentLine = nil; currentStations = []
                return
            }
            let colorHex = network.color(of: line) ?? "#888888"
            let toward = forwardTerminal(line: line, legStations: currentStations)
            legs.append(RouteLeg(
                id: legs.count, line: line, colorHex: colorHex,
                stations: currentStations, towardTerminal: toward
            ))
            currentLine = nil; currentStations = []
        }

        for i in 0..<path.count {
            let state = path[i]
            if i == 0 {
                currentLine = state.line
                currentStations = [state.station]
                continue
            }
            let prev = path[i - 1]
            if state.line == prev.line && state.station != prev.station {
                // Ride edge on the same line.
                if currentLine == nil { currentLine = state.line; currentStations = [prev.station] }
                currentStations.append(state.station)
            } else {
                // Transfer edge (same station, line changed).
                closeLeg()
                currentLine = state.line
                currentStations = [state.station]
            }
        }
        closeLeg()

        return Route(origin: origin, destination: destination, legs: legs, mode: mode)
    }

    /// Determine which terminal the train heads toward for a leg, using
    /// unweighted distances on the line's own subgraph. The forward terminal `T`
    /// is the one for which the leg's start `s0` reaches `T` *through* the leg's
    /// end `sn` (i.e. `sn` lies on the s0→T path), maximizing distance to keep a
    /// deterministic choice on branched lines.
    private func forwardTerminal(line: LineID, legStations: [StationID]) -> StationID {
        guard let s0 = legStations.first, let sn = legStations.last, let lineModel = network.line(line) else {
            return legStations.last ?? ""
        }
        let onLine = Set(lineModel.allStations)
        let distFromS0 = lineDistances(from: s0, line: line, members: onLine)
        let distFromSn = lineDistances(from: sn, line: line, members: onLine)

        var bestTerminal = sn
        var bestScore = -1
        for terminal in lineModel.terminals {
            guard let d0 = distFromS0[terminal], let dn = distFromSn[terminal],
                  let d0sn = distFromS0[sn] else { continue }
            // `sn` is between `s0` and `terminal`.
            if d0 == d0sn + dn, d0 > bestScore {
                bestScore = d0
                bestTerminal = terminal
            }
        }
        return bestTerminal
    }

    /// BFS distances on the subgraph induced by a single line.
    private func lineDistances(from start: StationID, line: LineID, members: Set<StationID>) -> [StationID: Int] {
        var dist: [StationID: Int] = [start: 0]
        var queue = [start]
        var head = 0
        while head < queue.count {
            let node = queue[head]; head += 1
            let d = dist[node]!
            guard let station = network.station(node) else { continue }
            for neighborID in station.neighbors where members.contains(neighborID) {
                guard let neighbor = network.station(neighborID), neighbor.lines.contains(line) else { continue }
                if dist[neighborID] == nil {
                    dist[neighborID] = d + 1
                    queue.append(neighborID)
                }
            }
        }
        return dist
    }
}

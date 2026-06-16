import XCTest
@testable import MetroData
import MetroDomain

final class MetroDataLoaderTests: XCTestCase {

    private static let network: MetroNetwork = {
        do { return try MetroDataLoader.loadBundledNetwork() }
        catch { fatalError("Failed to load bundled network: \(error)") }
    }()

    private var net: MetroNetwork { Self.network }

    // MARK: - Decoding & inventory

    func testDecodesAll150Stations() {
        XCTAssertEqual(net.stations.count, 150)
    }

    func testInServiceCount() {
        // 17 stations are disabled in the source data.
        XCTAssertEqual(net.serviceStations.count, 150 - 17)
    }

    func testSevenLinesWithVerifiedColors() {
        let expected: [LineID: String] = [
            1: "#E0001F", 2: "#2F4389", 3: "#67C5F5",
            4: "#F8E100", 5: "#007E46", 6: "#EF639F", 7: "#7F0B74"
        ]
        XCTAssertEqual(Set(net.lines.keys), Set(expected.keys))
        for (id, color) in expected {
            XCTAssertEqual(net.line(id)?.colorHex, color, "Line \(id) color mismatch")
        }
    }

    func testInterchangeCount() {
        // 18 stations serve more than one line.
        let interchanges = net.stations.values.filter(\.isInterchange)
        XCTAssertEqual(interchanges.count, 18)
    }

    // MARK: - Graph integrity

    func testGraphIsConnected() {
        // BFS over the full undirected graph must reach all 150 stations.
        guard let start = net.stations.keys.first else { return XCTFail("empty") }
        var seen: Set<StationID> = [start]
        var queue = [start]
        var head = 0
        while head < queue.count {
            let node = queue[head]; head += 1
            for n in net.station(node)?.neighbors ?? [] where seen.insert(n).inserted {
                queue.append(n)
            }
        }
        XCTAssertEqual(seen.count, net.stations.count, "Graph is not fully connected")
    }

    func testAdjacencyIsSymmetric() {
        for station in net.stations.values {
            for neighbor in station.neighbors {
                XCTAssertTrue(
                    net.station(neighbor)?.neighbors.contains(station.id) ?? false,
                    "Asymmetric edge \(station.id) -> \(neighbor)"
                )
            }
        }
    }

    func testNoSelfEdges() {
        for station in net.stations.values {
            XCTAssertFalse(station.neighbors.contains(station.id), "\(station.id) has a self-edge")
        }
    }

    func testEveryStationHasValidCoordinate() {
        for station in net.stations.values {
            XCTAssert((35.0...36.5).contains(station.coordinate.latitude))
            XCTAssert((50.5...52.0).contains(station.coordinate.longitude))
        }
    }

    func testLineOrderingHasTwoTerminalsMinimum() {
        for line in net.sortedLines {
            XCTAssertGreaterThanOrEqual(line.terminals.count, 2, "Line \(line.id) has too few terminals")
            XCTAssertFalse(line.orderedStations.isEmpty, "Line \(line.id) has no ordered stations")
        }
    }
}

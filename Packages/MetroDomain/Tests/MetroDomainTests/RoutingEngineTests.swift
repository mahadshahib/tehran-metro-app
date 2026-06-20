import XCTest
@testable import MetroDomain

final class RoutingEngineTests: XCTestCase {

    func testDirectRouteSameLine() throws {
        let engine = RoutingEngine(network: SyntheticNetwork.make())
        let route = try engine.route(from: "A", to: "D", mode: .fewestTransfers)
        XCTAssertEqual(route.legs.count, 1)
        XCTAssertEqual(route.transferCount, 0)
        XCTAssertEqual(route.totalStops, 3)               // A→B→C→D
        XCTAssertEqual(route.legs[0].line, 1)
        XCTAssertEqual(route.legs[0].towardTerminal, "E") // heading toward E end
    }

    func testFewestTransfersAvoidsTransfer() throws {
        let engine = RoutingEngine(network: SyntheticNetwork.make())
        let route = try engine.route(from: "A", to: "E", mode: .fewestTransfers)
        XCTAssertEqual(route.transferCount, 0)
        XCTAssertEqual(route.legs.count, 1)
        XCTAssertEqual(route.totalStops, 4)               // straight down Line 1
        XCTAssertEqual(route.legs[0].line, 1)
    }

    func testFewestStopsTakesShorterTransferRoute() throws {
        let engine = RoutingEngine(network: SyntheticNetwork.make())
        let route = try engine.route(from: "A", to: "E", mode: .fewestStops)
        XCTAssertEqual(route.totalStops, 3)               // A→P→Z then Z→E
        XCTAssertEqual(route.transferCount, 1)
        XCTAssertEqual(route.legs.map(\.line), [2, 3])
    }

    func testTransferStationReported() throws {
        let engine = RoutingEngine(network: SyntheticNetwork.make())
        let route = try engine.route(from: "A", to: "E", mode: .fewestStops)
        XCTAssertEqual(route.transferStations, ["Z"])
    }

    func testSameStationThrows() {
        let engine = RoutingEngine(network: SyntheticNetwork.make())
        XCTAssertThrowsError(try engine.route(from: "A", to: "A", mode: .fewestStops)) { error in
            XCTAssertEqual(error as? RoutingEngine.RoutingError, .sameStation)
        }
    }

    func testUnknownStationThrows() {
        let engine = RoutingEngine(network: SyntheticNetwork.make())
        XCTAssertThrowsError(try engine.route(from: "A", to: "ZZZ", mode: .fewestStops)) { error in
            XCTAssertEqual(error as? RoutingEngine.RoutingError, .unknownStation("ZZZ"))
        }
    }

    func testDisabledStationExcludedFromRouting() throws {
        // Disabling Z forces the only A→E route onto Line 1.
        let engine = RoutingEngine(network: SyntheticNetwork.make(disable: ["Z"]))
        let route = try engine.route(from: "A", to: "E", mode: .fewestStops)
        XCTAssertEqual(route.legs.map(\.line), [1])
        XCTAssertEqual(route.totalStops, 4)
    }

    func testRoutingToDisabledStationThrows() {
        let engine = RoutingEngine(network: SyntheticNetwork.make(disable: ["E"]))
        XCTAssertThrowsError(try engine.route(from: "A", to: "E", mode: .fewestStops)) { error in
            XCTAssertEqual(error as? RoutingEngine.RoutingError, .stationOutOfService("E"))
        }
    }

    func testTravelEstimateApproximate() throws {
        let engine = RoutingEngine(network: SyntheticNetwork.make())
        let route = try engine.route(from: "A", to: "E", mode: .fewestStops)
        let estimate = route.estimate
        XCTAssertTrue(estimate.isApproximate)
        // 3 stops * 120 + 1 transfer * 240 = 600s = 10 min
        XCTAssertEqual(estimate.totalMinutes, 10)
    }
}

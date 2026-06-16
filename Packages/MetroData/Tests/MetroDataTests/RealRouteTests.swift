import XCTest
@testable import MetroData
import MetroDomain

/// Asserts several known real-world routes end-to-end on the actual data. The
/// expected stop/transfer counts were derived directly from the source graph.
final class RealRouteTests: XCTestCase {

    private static let network: MetroNetwork = {
        try! MetroDataLoader.loadBundledNetwork()
    }()
    private var engine: RoutingEngine { RoutingEngine(network: Self.network) }

    func testTajrishToImamKhomeiniDirectOnLine1() throws {
        let route = try engine.route(from: "Tajrish", to: "Imam Khomeini", mode: .fewestTransfers)
        XCTAssertEqual(route.transferCount, 0)
        XCTAssertEqual(route.legs.count, 1)
        XCTAssertEqual(route.legs[0].line, 1)
        XCTAssertEqual(route.totalStops, 15)
        // Travelling south from Tajrish — the forward terminal is not Tajrish.
        XCTAssertNotEqual(route.legs[0].towardTerminal, "Tajrish")
    }

    func testTajrishToAzadeganSingleTransfer() throws {
        let route = try engine.route(from: "Tajrish", to: "Azadegan", mode: .fewestStops)
        XCTAssertEqual(route.transferCount, 1)
        XCTAssertEqual(route.totalStops, 22)
        XCTAssertEqual(route.origin, "Tajrish")
        XCTAssertEqual(route.destination, "Azadegan")
    }

    func testSohrevardiToSadeghiyehTwoTransfers() throws {
        let route = try engine.route(from: "Sohrevardi", to: "Tehran (Sadeghiyeh)", mode: .fewestTransfers)
        XCTAssertEqual(route.transferCount, 2)
        XCTAssertEqual(route.totalStops, 11)
        // Legs must be contiguous: each leg's end equals the next leg's start.
        for i in 1..<route.legs.count {
            XCTAssertEqual(route.legs[i - 1].to, route.legs[i].from)
        }
    }

    func testAdjacentStationsAreOneStop() throws {
        let route = try engine.route(from: "Tajrish", to: "Gheytariyeh", mode: .fewestStops)
        XCTAssertEqual(route.totalStops, 1)
        XCTAssertEqual(route.transferCount, 0)
    }

    func testRouteIsReversible() throws {
        let forward = try engine.route(from: "Tajrish", to: "Azadegan", mode: .fewestStops)
        let backward = try engine.route(from: "Azadegan", to: "Tajrish", mode: .fewestStops)
        XCTAssertEqual(forward.totalStops, backward.totalStops)
        XCTAssertEqual(forward.transferCount, backward.transferCount)
    }

    func testSearchFindsTajrishAcrossLanguages() {
        XCTAssertEqual(Self.network.search("tajrish").first?.id, "Tajrish")
        // Persian query (with Persian yeh) finds the station.
        XCTAssertEqual(Self.network.search("تجریش").first?.id, "Tajrish")
    }

    func testNearestStationToTajrishCoordinateIsTajrish() {
        let tajrish = Self.network.station("Tajrish")!
        let nearest = Self.network.nearestStations(to: tajrish.coordinate, limit: 1).first
        XCTAssertEqual(nearest?.id, "Tajrish")
    }
}

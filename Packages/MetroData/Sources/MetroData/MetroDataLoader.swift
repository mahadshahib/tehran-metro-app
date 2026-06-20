import Foundation
import MetroDomain

/// Loads the bundled `stations.json`, repairs known data issues in-memory, and
/// builds an immutable `MetroNetwork`. The source file is never mutated.
///
/// Repairs applied (documented in DATA_REPORT.md):
///   - Adjacency edges are **symmetrized** (heals the `Shahid Sadr` self-edge
///     and the 2 asymmetric relations).
///   - Self-edges are dropped.
///   - `disabled` is inverted into `isInService`.
public enum MetroDataLoader {

    public enum LoadError: Error {
        case resourceNotFound
        case decodingFailed(Error)
        case invalidCoordinate(StationID)
    }

    /// Build the network from the JSON bundled in this package.
    public static func loadBundledNetwork() throws -> MetroNetwork {
        guard let url = Bundle.module.url(forResource: "stations", withExtension: "json") else {
            throw LoadError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        return try buildNetwork(from: data)
    }

    /// Build the network from raw JSON data (used by tests and the app).
    public static func buildNetwork(from data: Data) throws -> MetroNetwork {
        let dtos: [String: StationDTO]
        do {
            dtos = try JSONDecoder().decode([String: StationDTO].self, from: data)
        } catch {
            throw LoadError.decodingFailed(error)
        }

        // 1. Symmetrize adjacency, dropping self-edges.
        var neighborSets: [StationID: Set<StationID>] = [:]
        for (key, dto) in dtos {
            neighborSets[key, default: []].formUnion(dto.relations.filter { $0 != key })
        }
        for (key, dto) in dtos {
            for neighbor in dto.relations where neighbor != key && dtos[neighbor] != nil {
                neighborSets[neighbor, default: []].insert(key)
            }
        }

        // 2. Map DTOs → domain stations, and read line colors from the parallel
        //    `colors` array (keeps color fully data-driven).
        var lineColors: [LineID: String] = [:]
        for dto in dtos.values {
            for (line, color) in zip(dto.lines, dto.colors) where lineColors[line] == nil {
                lineColors[line] = color
            }
        }

        var stations: [StationID: Station] = [:]
        stations.reserveCapacity(dtos.count)
        for (key, dto) in dtos {
            guard let lat = Double(dto.latitude), let lon = Double(dto.longitude) else {
                throw LoadError.invalidCoordinate(key)
            }
            let neighbors = (neighborSets[key] ?? []).sorted()
            stations[key] = Station(
                id: key,
                nameEN: dto.name,
                nameFA: dto.translations.fa,
                lines: dto.lines,
                coordinate: Coordinate(latitude: lat, longitude: lon),
                addressFA: dto.address,
                isInService: !dto.disabled,
                neighbors: neighbors,
                facilities: Facilities(
                    restroom: dto.wc, elevator: dto.elevator, tactilePaving: dto.blindPath,
                    atm: dto.atm, coffeeShop: dto.coffeeShop, fastFood: dto.fastFood,
                    groceryStore: dto.groceryStore, cleanFood: dto.cleanFood,
                    bicycleParking: dto.bicycleParking, creditTicketSales: dto.creditTicketSales,
                    waitingChair: dto.waitingChair, cctv: dto.camera, metroPolice: dto.metroPolice,
                    fireExtinguisher: dto.fireExtinguisher, fireSuppression: dto.fireSuppressionSystem,
                    trashCan: dto.trashCan, freeWifi: dto.freeWifi, prayerRoom: dto.prayerRoom,
                    waterCooler: dto.waterCooler, smokingAllowed: dto.smoking, petsAllowed: dto.petsAllowed
                )
            )
        }

        // 3. Build lines (color + ordered stations + branches) from the graph.
        let lines = LineBuilder.buildLines(stations: stations, lineColors: lineColors)

        return MetroNetwork(stations: stations, lines: lines)
    }
}

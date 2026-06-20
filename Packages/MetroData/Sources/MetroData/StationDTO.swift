import Foundation

/// Decodable mirror of one station object in `stations.json`. This is the only
/// type that knows the raw on-disk shape (string coordinates, `disabled` flag,
/// per-station `colors`, the `fastFoodn` typo, nullable amenities, etc.).
struct StationDTO: Decodable {
    let name: String
    let translations: Translations
    let lines: [Int]
    let colors: [String]
    let longitude: String
    let latitude: String
    let address: String?
    let disabled: Bool
    let relations: [String]

    // Amenities — all optional Bool? so a JSON `null` or a missing key both
    // decode to `nil` ("no data") rather than a fabricated `false`.
    let wc: Bool?
    let elevator: Bool?
    let blindPath: Bool?
    let atm: Bool?
    let coffeeShop: Bool?
    let fastFood: Bool?
    let groceryStore: Bool?
    let cleanFood: Bool?
    let bicycleParking: Bool?
    let creditTicketSales: Bool?
    let waitingChair: Bool?
    let camera: Bool?
    let metroPolice: Bool?
    let fireExtinguisher: Bool?
    let fireSuppressionSystem: Bool?
    let trashCan: Bool?
    let freeWifi: Bool?
    let prayerRoom: Bool?
    let waterCooler: Bool?
    let smoking: Bool?
    let petsAllowed: Bool?

    struct Translations: Decodable {
        let fa: String
    }
}

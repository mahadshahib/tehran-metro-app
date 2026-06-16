import Foundation

/// Station amenities, mapped from the source data's many boolean flags.
///
/// Every value is an optional `Bool` so that the three states present in the
/// source are preserved faithfully:
///   - `true`  → amenity present
///   - `false` → amenity absent
///   - `nil`   → no data (the source stores `null`, e.g. `waterCooler` is
///               null on 145/150 stations)
///
/// The presentation layer should render `nil` as "no data", never as "absent".
public struct Facilities: Hashable, Sendable, Codable {
    public var restroom: Bool?
    public var elevator: Bool?
    public var tactilePaving: Bool?      // source: blindPath
    public var atm: Bool?
    public var coffeeShop: Bool?
    public var fastFood: Bool?
    public var groceryStore: Bool?
    public var cleanFood: Bool?
    public var bicycleParking: Bool?
    public var creditTicketSales: Bool?
    public var waitingChair: Bool?
    public var cctv: Bool?               // source: camera
    public var metroPolice: Bool?
    public var fireExtinguisher: Bool?
    public var fireSuppression: Bool?
    public var trashCan: Bool?
    public var freeWifi: Bool?
    public var prayerRoom: Bool?
    public var waterCooler: Bool?
    public var smokingAllowed: Bool?
    public var petsAllowed: Bool?

    public init(
        restroom: Bool? = nil, elevator: Bool? = nil, tactilePaving: Bool? = nil,
        atm: Bool? = nil, coffeeShop: Bool? = nil, fastFood: Bool? = nil,
        groceryStore: Bool? = nil, cleanFood: Bool? = nil, bicycleParking: Bool? = nil,
        creditTicketSales: Bool? = nil, waitingChair: Bool? = nil, cctv: Bool? = nil,
        metroPolice: Bool? = nil, fireExtinguisher: Bool? = nil, fireSuppression: Bool? = nil,
        trashCan: Bool? = nil, freeWifi: Bool? = nil, prayerRoom: Bool? = nil,
        waterCooler: Bool? = nil, smokingAllowed: Bool? = nil, petsAllowed: Bool? = nil
    ) {
        self.restroom = restroom; self.elevator = elevator; self.tactilePaving = tactilePaving
        self.atm = atm; self.coffeeShop = coffeeShop; self.fastFood = fastFood
        self.groceryStore = groceryStore; self.cleanFood = cleanFood; self.bicycleParking = bicycleParking
        self.creditTicketSales = creditTicketSales; self.waitingChair = waitingChair; self.cctv = cctv
        self.metroPolice = metroPolice; self.fireExtinguisher = fireExtinguisher; self.fireSuppression = fireSuppression
        self.trashCan = trashCan; self.freeWifi = freeWifi; self.prayerRoom = prayerRoom
        self.waterCooler = waterCooler; self.smokingAllowed = smokingAllowed; self.petsAllowed = petsAllowed
    }
}

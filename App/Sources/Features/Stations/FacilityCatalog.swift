import Foundation
import MetroDomain

/// Maps the `Facilities` flags to display labels + SF Symbols. Only amenities
/// that are present (`true`) are shown; `nil` (no data) and `false` are omitted.
enum FacilityCatalog {
    struct Item { let label: String; let symbol: String }

    static func available(in f: Facilities, language: AppLanguage) -> [Item] {
        var items: [Item] = []
        func add(_ value: Bool?, _ text: LocalizedText, _ symbol: String) {
            if value == true { items.append(Item(label: text.string(for: language), symbol: symbol)) }
        }
        add(f.elevator, .init(en: "Elevator", fa: "آسانسور"), "figure.roll")
        add(f.tactilePaving, .init(en: "Tactile paving", fa: "مسیر نابینایان"), "figure.walk.motion")
        add(f.restroom, .init(en: "Restroom", fa: "سرویس بهداشتی"), "toilet")
        add(f.atm, .init(en: "ATM", fa: "خودپرداز"), "creditcard")
        add(f.creditTicketSales, .init(en: "Ticket sales", fa: "فروش بلیط"), "ticket")
        add(f.freeWifi, .init(en: "Free Wi-Fi", fa: "وای‌فای رایگان"), "wifi")
        add(f.coffeeShop, .init(en: "Coffee shop", fa: "کافی‌شاپ"), "cup.and.saucer")
        add(f.fastFood, .init(en: "Fast food", fa: "فست‌فود"), "takeoutbag.and.cup.and.straw")
        add(f.groceryStore, .init(en: "Grocery", fa: "خواربار"), "cart")
        add(f.cleanFood, .init(en: "Clean food", fa: "غذای سالم"), "leaf")
        add(f.bicycleParking, .init(en: "Bike parking", fa: "پارک دوچرخه"), "bicycle")
        add(f.waitingChair, .init(en: "Seating", fa: "صندلی انتظار"), "chair")
        add(f.prayerRoom, .init(en: "Prayer room", fa: "نمازخانه"), "moon.stars")
        add(f.waterCooler, .init(en: "Water cooler", fa: "آب‌سردکن"), "drop")
        add(f.metroPolice, .init(en: "Metro police", fa: "پلیس مترو"), "shield")
        add(f.cctv, .init(en: "CCTV", fa: "دوربین مدار بسته"), "video")
        add(f.fireExtinguisher, .init(en: "Fire extinguisher", fa: "کپسول آتش‌نشانی"), "flame")
        add(f.petsAllowed, .init(en: "Pets allowed", fa: "ورود حیوانات"), "pawprint")
        return items
    }
}

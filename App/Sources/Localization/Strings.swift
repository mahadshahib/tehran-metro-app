import Foundation
import MetroDomain

/// All user-facing copy, in both languages. Grouped by feature.
enum Loc {
    // Tabs
    static let tabLines = LocalizedText(en: "Lines", fa: "خطوط")
    static let tabMap = LocalizedText(en: "Map", fa: "نقشه")
    static let tabJourney = LocalizedText(en: "Journey", fa: "مسیریابی")
    static let tabNearby = LocalizedText(en: "Nearby", fa: "نزدیک من")
    static let tabSettings = LocalizedText(en: "Settings", fa: "تنظیمات")

    // General
    static let appName = LocalizedText(en: "Tehran Metro", fa: "مترو تهران")
    static let search = LocalizedText(en: "Search", fa: "جستجو")
    static let searchStations = LocalizedText(en: "Search stations", fa: "جستجوی ایستگاه")
    static let cancel = LocalizedText(en: "Cancel", fa: "انصراف")
    static let done = LocalizedText(en: "Done", fa: "تمام")
    static let close = LocalizedText(en: "Close", fa: "بستن")
    static let noResults = LocalizedText(en: "No results", fa: "نتیجه‌ای یافت نشد")
    static let share = LocalizedText(en: "Share", fa: "اشتراک‌گذاری")

    // Lines / stations
    static let lines = LocalizedText(en: "Lines", fa: "خطوط")
    static let line = LocalizedText(en: "Line", fa: "خط")
    static let stations = LocalizedText(en: "Stations", fa: "ایستگاه‌ها")
    static let station = LocalizedText(en: "Station", fa: "ایستگاه")
    static let interchange = LocalizedText(en: "Interchange", fa: "تقاطع")
    static let terminal = LocalizedText(en: "Terminal", fa: "ایستگاه پایانه")
    static let notInService = LocalizedText(en: "Not yet open", fa: "هنوز افتتاح نشده")
    static let facilities = LocalizedText(en: "Facilities", fa: "امکانات")
    static let address = LocalizedText(en: "Address", fa: "نشانی")
    static let linesServed = LocalizedText(en: "Lines served", fa: "خطوط عبوری")
    static let location = LocalizedText(en: "Location", fa: "موقعیت")

    // Journey
    static let planJourney = LocalizedText(en: "Plan a journey", fa: "برنامه‌ریزی سفر")
    static let from = LocalizedText(en: "From", fa: "مبدأ")
    static let to = LocalizedText(en: "To", fa: "مقصد")
    static let origin = LocalizedText(en: "Origin", fa: "مبدأ")
    static let destination = LocalizedText(en: "Destination", fa: "مقصد")
    static let selectOrigin = LocalizedText(en: "Select origin", fa: "انتخاب مبدأ")
    static let selectDestination = LocalizedText(en: "Select destination", fa: "انتخاب مقصد")
    static let swap = LocalizedText(en: "Swap", fa: "جابجایی")
    static let findRoute = LocalizedText(en: "Find route", fa: "یافتن مسیر")
    static let fewestTransfers = LocalizedText(en: "Fewest transfers", fa: "کمترین تعویض")
    static let fewestStops = LocalizedText(en: "Fewest stops", fa: "کمترین ایستگاه")
    static let board = LocalizedText(en: "Board", fa: "سوار شوید")
    static let toward = LocalizedText(en: "toward", fa: "به سمت")
    static let transferAt = LocalizedText(en: "Transfer at", fa: "تعویض در")
    static let alightAt = LocalizedText(en: "Get off at", fa: "پیاده شوید در")
    static let ride = LocalizedText(en: "Ride", fa: "سوار بمانید")
    static let approxTime = LocalizedText(en: "Approx. time", fa: "زمان تقریبی")
    static let approximate = LocalizedText(en: "Approximate", fa: "تقریبی")
    static let noRoute = LocalizedText(en: "No route found between these stations.",
                                       fa: "مسیری بین این دو ایستگاه یافت نشد.")
    static let sameStationMsg = LocalizedText(en: "Origin and destination are the same.",
                                              fa: "مبدأ و مقصد یکسان هستند.")
    static let walkToOrigin = LocalizedText(en: "Walk to origin station", fa: "پیاده‌روی تا مبدأ")

    // Nearby / maps
    static let nearestStations = LocalizedText(en: "Nearest stations", fa: "نزدیک‌ترین ایستگاه‌ها")
    static let directions = LocalizedText(en: "Directions to entrance", fa: "مسیر تا ورودی")
    static let openInNeshan = LocalizedText(en: "Open in Neshan", fa: "باز کردن در نشان")
    static let openInAppleMaps = LocalizedText(en: "Open in Apple Maps", fa: "باز کردن در نقشه اپل")
    static let openInGoogleMaps = LocalizedText(en: "Open in Google Maps", fa: "باز کردن در گوگل مپ")
    static let locationUnavailable = LocalizedText(en: "Location unavailable. Pick a station manually.",
                                                   fa: "موقعیت در دسترس نیست. یک ایستگاه انتخاب کنید.")
    static let enableLocation = LocalizedText(en: "Enable location access in Settings to find nearby stations.",
                                              fa: "برای یافتن ایستگاه‌های نزدیک، دسترسی موقعیت را فعال کنید.")
    static let useMyLocation = LocalizedText(en: "Use my location", fa: "استفاده از موقعیت من")

    // Live location / nearest-on-map (offline-first)
    static let myLocation = LocalizedText(en: "My location", fa: "موقعیت من")
    static let exploreMap = LocalizedText(en: "Explore map", fa: "کاوش نقشه")
    static let nearestStation = LocalizedText(en: "Nearest station", fa: "نزدیک‌ترین ایستگاه")
    static let live = LocalizedText(en: "Live", fa: "زنده")
    static let offline = LocalizedText(en: "Offline", fa: "آفلاین")
    static let online = LocalizedText(en: "Online", fa: "آنلاین")
    static let recenter = LocalizedText(en: "Recenter", fa: "بازگشت به مرکز")
    static let planFromHere = LocalizedText(en: "Plan journey from here", fa: "مسیریابی از اینجا")
    static let panToExplore = LocalizedText(
        en: "Pan the map — the crosshair finds the nearest station to any point, even offline.",
        fa: "نقشه را جابه‌جا کنید — نشانگر، نزدیک‌ترین ایستگاه به هر نقطه را حتی به‌صورت آفلاین پیدا می‌کند."
    )
    static let offlineMapNote = LocalizedText(
        en: "No connection: map tiles may not load, but finding stations works fully offline.",
        fa: "بدون اتصال: کاشی‌های نقشه ممکن است بارگذاری نشوند، اما یافتن ایستگاه‌ها کاملاً آفلاین کار می‌کند."
    )
    static let locationDenied = LocalizedText(
        en: "Location access is off. Use Explore map to find stations without GPS.",
        fa: "دسترسی موقعیت خاموش است. برای یافتن ایستگاه بدون GPS از کاوش نقشه استفاده کنید."
    )

    static func walkMinutes(_ value: Int, language: AppLanguage) -> String {
        let n = Numerals.string(value, language: language)
        return language == .farsi ? "\(n) دقیقه پیاده" : "\(value) min walk"
    }

    // Favorites / recents
    static let favorites = LocalizedText(en: "Favorites", fa: "علاقه‌مندی‌ها")
    static let addFavorite = LocalizedText(en: "Add to favorites", fa: "افزودن به علاقه‌مندی‌ها")
    static let removeFavorite = LocalizedText(en: "Remove from favorites", fa: "حذف از علاقه‌مندی‌ها")
    static let savedRoutes = LocalizedText(en: "Saved routes", fa: "مسیرهای ذخیره‌شده")
    static let saveRoute = LocalizedText(en: "Save route", fa: "ذخیره مسیر")
    static let recents = LocalizedText(en: "Recent", fa: "اخیر")
    static let noFavorites = LocalizedText(en: "No favorite stations yet.", fa: "هنوز ایستگاه مورد علاقه‌ای ندارید.")
    static let noSavedRoutes = LocalizedText(en: "No saved routes yet.", fa: "هنوز مسیری ذخیره نشده است.")

    // Settings
    static let language = LocalizedText(en: "Language", fa: "زبان")
    static let languageEnglish = LocalizedText(en: "English", fa: "انگلیسی")
    static let languageFarsi = LocalizedText(en: "Persian", fa: "فارسی")
    static let appearance = LocalizedText(en: "Appearance", fa: "ظاهر")
    static let themeSystem = LocalizedText(en: "System", fa: "سیستم")
    static let themeLight = LocalizedText(en: "Light", fa: "روشن")
    static let themeDark = LocalizedText(en: "Dark", fa: "تیره")
    static let nameDisplay = LocalizedText(en: "Station names", fa: "نمایش نام ایستگاه")
    static let nameAuto = LocalizedText(en: "Match language", fa: "هماهنگ با زبان")
    static let nameEnglish = LocalizedText(en: "English", fa: "انگلیسی")
    static let nameFarsi = LocalizedText(en: "Persian", fa: "فارسی")
    static let about = LocalizedText(en: "About", fa: "درباره")
    static let dataSource = LocalizedText(en: "Data source", fa: "منبع داده")
    static let dataDisclaimer = LocalizedText(
        en: "Times are approximate. Metro data is community-maintained and may not reflect live service.",
        fa: "زمان‌ها تقریبی هستند. داده‌های مترو توسط جامعه نگهداری می‌شود و ممکن است با سرویس زنده مطابقت نداشته باشد."
    )

    // Counts (functions)
    static func stopsLabel(_ count: Int, language: AppLanguage) -> String {
        let n = Numerals.string(count, language: language)
        if language == .farsi { return "\(n) ایستگاه" }
        return count == 1 ? "1 stop" : "\(count) stops"
    }

    static func transfersLabel(_ count: Int, language: AppLanguage) -> String {
        let n = Numerals.string(count, language: language)
        if language == .farsi { return count == 0 ? "بدون تعویض" : "\(n) تعویض" }
        return count == 1 ? "1 transfer" : "\(count) transfers"
    }

    static func lineName(_ id: Int, language: AppLanguage) -> String {
        let n = Numerals.string(id, language: language)
        return language == .farsi ? "خط \(n)" : "Line \(id)"
    }
}

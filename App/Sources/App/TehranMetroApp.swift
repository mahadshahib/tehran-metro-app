import SwiftUI
import SwiftData

@main
struct TehranMetroApp: App {
    @State private var model = AppModel()
    @State private var settings = AppSettings()

    init() {
        FontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
                .environment(\.locale, settings.language.swiftUILocale)
                .preferredColorScheme(settings.colorScheme)
                .tint(.accentColor)
        }
        .modelContainer(for: [FavoriteStation.self, SavedRoute.self, RecentStation.self])
    }
}

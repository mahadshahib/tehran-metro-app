import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings

    var body: some View {
        if let error = model.loadError {
            ContentUnavailableView {
                Label("Data failed to load", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error).font(.footnote)
            }
        } else {
            TabView {
                // Ordered by how often a commuter reaches for them.
                JourneyPlannerView()
                    .tabItem { Label(Loc.tabJourney.string(for: settings.language), systemImage: "point.topleft.down.to.point.bottomright.curvepath.fill") }
                NearbyView()
                    .tabItem { Label(Loc.tabNearby.string(for: settings.language), systemImage: "location.fill") }
                SchematicMapView()
                    .tabItem { Label(Loc.tabMap.string(for: settings.language), systemImage: "map.fill") }
                LinesView()
                    .tabItem { Label(Loc.tabLines.string(for: settings.language), systemImage: "tram.fill") }
                SettingsView()
                    .tabItem { Label(Loc.tabSettings.string(for: settings.language), systemImage: "gearshape.fill") }
            }
        }
    }
}

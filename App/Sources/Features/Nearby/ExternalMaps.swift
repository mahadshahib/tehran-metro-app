import Foundation
import UIKit
import MetroDomain

/// Deep-links to external map apps for walking directions to a station entrance.
/// Priority for Iran: **Neshan → Apple Maps → Google Maps** (§12.4). Only the
/// final handoff needs network; everything else in the app is offline.
enum ExternalMaps {

    enum Provider: CaseIterable {
        case neshan, apple, google

        var displayName: LocalizedText {
            switch self {
            case .neshan: return Loc.openInNeshan
            case .apple: return Loc.openInAppleMaps
            case .google: return Loc.openInGoogleMaps
            }
        }
    }

    /// Whether a provider's app is installed (Apple Maps always is).
    static func isAvailable(_ provider: Provider) -> Bool {
        switch provider {
        case .apple: return true
        case .neshan: return canOpen("nmp://")
        case .google: return canOpen("comgooglemaps://")
        }
    }

    /// Open the highest-priority available provider directly.
    static func openDirections(to station: Station, name: String) {
        for provider in Provider.allCases where isAvailable(provider) {
            if open(provider, to: station, name: name) { return }
        }
        _ = open(.apple, to: station, name: name) // universal fallback
    }

    /// Open a specific provider. Returns whether the URL was handed off.
    @discardableResult
    static func open(_ provider: Provider, to station: Station, name: String) -> Bool {
        guard let url = url(for: provider, station: station, name: name) else { return false }
        guard UIApplication.shared.canOpenURL(url) || provider == .apple else { return false }
        UIApplication.shared.open(url)
        return true
    }

    static func url(for provider: Provider, station: Station, name: String) -> URL? {
        let lat = station.coordinate.latitude
        let lon = station.coordinate.longitude
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        switch provider {
        case .neshan:
            // Neshan deep link with destination + walking mode.
            return URL(string: "nmp://routing?lat=\(lat)&lng=\(lon)&type=foot")
                ?? URL(string: "https://neshan.org/maps/@\(lat),\(lon),16z")
        case .apple:
            return URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=w&q=\(encodedName)")
        case .google:
            return URL(string: "comgooglemaps://?daddr=\(lat),\(lon)&directionsmode=walking")
                ?? URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lon)&travelmode=walking")
        }
    }

    private static func canOpen(_ scheme: String) -> Bool {
        guard let url = URL(string: scheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

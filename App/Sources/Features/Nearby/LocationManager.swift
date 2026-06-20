import Foundation
import CoreLocation
import Observation
import MetroDomain

/// CoreLocation wrapper supporting **live tracking** (continuous updates so the
/// user's position follows them as they move). GPS is poor underground, so it
/// degrades gracefully: it keeps the last-known coordinate, exposes the
/// authorization state, and never blocks the offline station-finding features.
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus
    var lastCoordinate: Coordinate?
    var isTracking = false
    /// Horizontal accuracy of the most recent fix, in meters (for UI hints).
    var accuracy: Double?

    /// Set when the user has asked to start, so we begin updates as soon as
    /// authorization is granted.
    private var wantsTracking = false

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10   // update every ~10 m of movement
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    /// Begin live tracking, requesting permission first if needed.
    func startTracking() {
        wantsTracking = true
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            beginUpdates()
        default:
            break
        }
    }

    func stopTracking() {
        wantsTracking = false
        isTracking = false
        manager.stopUpdatingLocation()
    }

    private func beginUpdates() {
        isTracking = true
        manager.startUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isAuthorized && wantsTracking { beginUpdates() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastCoordinate = Coordinate(latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude)
        accuracy = location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep last-known coordinate; underground failures are expected.
    }
}

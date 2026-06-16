import Foundation
import MetroDomain

/// Renders a route as shareable plain text in the current language.
enum RouteFormatter {
    static func shareText(_ route: Route, model: AppModel, settings: AppSettings) -> String {
        let lang = settings.language
        func name(_ id: StationID) -> String { model.station(id).map { settings.stationName($0) } ?? id }

        var lines: [String] = []
        lines.append("\(name(route.origin)) → \(name(route.destination))")
        lines.append("\(Loc.stopsLabel(route.totalStops, language: lang)) · \(Loc.transfersLabel(route.transferCount, language: lang)) · \(Numerals.minutes(route.estimate.totalMinutes, language: lang)) (\(Loc.approximate.string(for: lang)))")
        lines.append("")
        for (index, leg) in route.legs.enumerated() {
            let step = Numerals.string(index + 1, language: lang)
            lines.append("\(step). \(Loc.lineName(leg.line, language: lang)) — \(Loc.toward.string(for: lang)) \(name(leg.towardTerminal))")
            lines.append("   \(Loc.board.string(for: lang)): \(name(leg.from)) → \(name(leg.to)) (\(Loc.stopsLabel(leg.stopCount, language: lang)))")
        }
        lines.append("")
        lines.append(Loc.appName.string(for: lang))
        return lines.joined(separator: "\n")
    }
}

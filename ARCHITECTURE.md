# Architecture

A native iOS app (Swift + SwiftUI, iOS 17+) for the Tehran Metro, built as a
daily-driver commuter app. Clean three-layer separation with the domain layer
kept free of any Apple UI frameworks so the routing engine and data logic are
unit-testable in isolation.

```
┌──────────────────────────────────────────────────────────────┐
│ Presentation (App/Sources)                                     │
│   SwiftUI views + @Observable view models (MVVM)               │
│   DesignSystem · Localization · Persistence (SwiftData)        │
└───────────────▲───────────────────────────▲──────────────────┘
                │ depends on                 │ depends on
┌───────────────┴───────────┐   ┌────────────┴───────────────────┐
│ MetroData (SPM)            │   │ MetroDomain (SPM)               │
│   StationDTO + decoder     │──▶│   Station, Line, Coordinate     │
│   MetroDataLoader          │   │   MetroNetwork (graph)          │
│   LineBuilder              │   │   RoutingEngine (Dijkstra)      │
│   bundles stations.json    │   │   PersianNormalizer, estimates  │
└────────────────────────────┘   └─────────────────────────────────┘
        knows the file format          pure Swift, framework-free
```

## Layers

### Domain — `Packages/MetroDomain` (pure Swift, no UIKit/SwiftUI/MapKit)
- **Models**: `Station`, `Line`, `Coordinate`, `Facilities`, `AppLanguage`.
- **`MetroNetwork`**: immutable graph container; search + nearest-station queries.
- **`RoutingEngine`**: line-aware Dijkstra over `(station, line)` states with a
  transfer penalty; two modes (`fewestTransfers`, `fewestStops`); produces
  `Route` → `RouteLeg`s with "board line X toward terminal Y" directions.
- **`PersianNormalizer`**: yeh/kaf normalization, ZWNJ, digits, diacritics.
- **`TravelEstimate`**: assumption-based time (no timetable exists), clearly
  flagged approximate.

### Data — `Packages/MetroData` (knows the JSON shape; nothing above it does)
- **`StationDTO`**: `Decodable` mirror of the raw file (string coords, `disabled`,
  the `fastFoodn` typo, nullable amenities).
- **`MetroDataLoader`**: loads bundled `stations.json`, **symmetrizes** adjacency
  edges (heals the `Shahid Sadr` self-edge / asymmetries), inverts `disabled` →
  `isInService`, maps DTO → domain, caches the network. The source file is never
  mutated.
- **`LineBuilder`**: reconstructs each line's station order from the relation
  chain and splits real-world forks (Line 1, Line 4) into trunk + branches.

### Presentation — `App/Sources`
- `AppModel` (network + engine), `AppSettings` (`@Observable`, persisted).
- `DesignSystem`: hex colors, tokens, `LineBadge`/`StationRow`, Vazirmatn font.
- `Localization`: bilingual `Loc` strings + locale-aware `Numerals`.
- `Persistence`: SwiftData models (`FavoriteStation`, `SavedRoute`,
  `RecentStation`) + `UserDataStore`.
- `Features`: Lines, SchematicMap, Journey, Nearby, Settings, Favorites.

## Key decisions
- **Offline-first**: all core features (browse, search, schematic map, routing)
  run with zero network. Only the external-maps handoff (Neshan → Apple → Google)
  and live MapKit tiles use the network.
- **Per-app language override** independent of the system language; numerals and
  calendars go through locale-aware system formatters.
- **Color is data-driven** (read from each station's `colors` array) and always
  paired with a line number — never color alone.
- **Disabled stations** are shown in browse with a "not yet open" badge but are
  excluded from routing.

## Project generation & CI
- The Xcode project is generated from `project.yml` via **XcodeGen** (no fragile
  `.pbxproj` in git). The two SPM packages are referenced as local packages.
- **GitHub Actions** (`.github/workflows/ios-ci.yml`):
  - `package-tests`: `swift test` for `MetroDomain` and `MetroData`, plus a check
    that the bundled data matches `data/stations.json`.
  - `ios-build`: `xcodegen generate` then `xcodebuild` for the iOS Simulator.

## Testing
- Routing (synthetic network + several known real routes incl. multi-transfer),
  data decoding (150 stations, connectivity, symmetry, line/color consistency),
  Persian search normalization, and numeral formatting.
```

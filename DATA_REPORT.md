# DATA_REPORT.md — Tehran Metro Data Assessment (Phase 0)

> Source of truth: `data/stations.json` in this repository. No values below are
> invented — every figure was derived by parsing the actual file. Where the data
> is missing, ambiguous, or self-contradictory, it is flagged explicitly as an
> **open question / data bug** rather than papered over.

---

## 1. File Inventory

| Item | Finding |
|---|---|
| Data files | A single file: **`data/stations.json`** |
| Format | JSON (a single top-level **object/dictionary**, not an array) |
| Size | ~153 KB (152,801 bytes), 4,791 pretty-printed lines |
| Encoding | UTF-8, valid JSON, Persian text stored as native Unicode |
| Other repo assets | `visualization/index.html` (a standalone D3-style force-graph web demo — **not** reusable in iOS, but useful as a reference for how edges/colors are interpreted); `readme.md`, `LICENSE.md`, tooling (`package.json`, `.prettierrc`, pnpm lockfile). |

**Organization.** The JSON is keyed by the station's **English name** (e.g. `"Tajrish"`,
`"Imam Khomeini"`). The key doubles as the station's unique ID *and* as the token
used inside other stations' `relations` arrays. There is no separate `lines.json`
or `id` field — line and adjacency information is embedded per-station.

---

## 2. Schema

### 2.1 Station object — fields actually present

Parsed across all **150** stations. "Coverage" = how many of the 150 stations have the key.

| Field | Type | Coverage | Notes |
|---|---|---|---|
| `name` | String | 150/150 | English name; equals the dictionary key. |
| `translations` | Object | 150/150 | **Only key present is `fa`.** No `en` inside (English lives in `name`). No other languages despite README implying extensibility. |
| `translations.fa` | String | 150/150 | Persian name. Present & non-empty for **every** station. |
| `lines` | Array&lt;Int&gt; | 150/150 | Line numbers (1–7). Multi-element ⇒ interchange. |
| `colors` | Array&lt;String&gt; | 150/150 | Hex colors, **positionally parallel to `lines`** (verified: 0 length mismatches). |
| `latitude` | String | 150/150 | **Stored as a string**, e.g. `"35.804501"`. Needs parsing. |
| `longitude` | String | 150/150 | Same. All 150 parse to valid coords inside the Tehran bounding box. |
| `address` | String | **147/150** | Persian address. Missing on `Allameh Jafari`, `Chaharbagh`, `Ayatollah Kashani` (all in the disabled cluster — see §4). |
| `relations` | Array&lt;String&gt; | 150/150 | Adjacency list (neighbor station keys). **This is the graph.** See §5. |
| `disabled` | Bool | 150/150 | **Means "station not in service / under construction", NOT wheelchair accessibility.** 17 stations are `true`. |

### 2.2 Facility / amenity flags (all Bool unless noted)

Present on essentially all stations, a few nullable:

`wc` (147), `elevator` (150), `blindPath` (150, tactile paving), `atm` (148),
`coffeeShop` (148), `fastFood` (147), `groceryStore` (148), `cleanFood` (150),
`bicycleParking` (150), `creditTicketSales` (150), `waitingChair` (150),
`camera` (150), `metroPolice` (150), `fireExtinguisher` (150),
`fireSuppressionSystem` (150), `trashCan` (150), `smoking` (150),
`petsAllowed` (150), `freeWifi` (150),
`prayerRoom` (Bool **or null** — null on 19), `waterCooler` (Bool **or null** — null on **145**, i.e. almost always null).

**Typo field:** `fastFoodn` appears on exactly **one** station (`Ayatollah Taleghani`) — clearly a misspelling of `fastFood`. Will be ignored/normalized.

### 2.3 Confirmation of the §3 checklist items

| Required-by-brief | Present? | Detail |
|---|---|---|
| Persian (fa) name | ✅ | `translations.fa`, 150/150. |
| English (en) name | ✅ | `name` (and dict key), 150/150. |
| Line membership | ✅ | `lines`, 150/150. |
| **Station order within a line** | ⚠️ **Implicit only** | No index/sequence field. Order must be **reconstructed by walking the `relations` chain filtered to a line.** Viable but see branch caveat (§5). |
| Interchange / transfer stations | ✅ (derivable) | A station with `lines.count > 1` is an interchange. **18** such stations found. Transfers are *not* separate edges — they are implicit at the shared node. |
| Coordinates | ✅ | lat/lng (strings). 150/150 valid. |
| Accessibility | ⚠️ Partial | `elevator`, `blindPath` exist. **No** dedicated wheelchair/step-free flag. (`disabled` ≠ accessibility.) |
| Parking | ⚠️ | Only `bicycleParking`. No car-park flag. |
| Restrooms | ✅ | `wc`. |
| First/last train times | ❌ **Absent** | No timetable data at all. |
| Fare info | ❌ **Absent** | None. |
| Line colors | ✅ | Per-station `colors`, consistent per line (§3). |
| Official line identifiers | ⚠️ | Only the integer line number (1–7). No official names/codes beyond the number + color. |

---

## 3. Line ↔ Color Mapping (derived, 100% internally consistent)

Every station's `colors[i]` matches its `lines[i]`. Aggregating across all stations,
each line maps to **exactly one** color (no conflicts):

| Line | Color (hex) | Station count | Terminals (deg-1 nodes) |
|---|---|---|---|
| **1** | `#E0001F` (red) | 33 | Tajrish — Kahrizak / **Shahr-e Parand** (branch) |
| **2** | `#2F4389` (dark blue) | 22 | Farhangsara — Tehran (Sadeghiyeh) |
| **3** | `#67C5F5` (light blue) | 25 | Qa'em — Azadegan |
| **4** | `#F8E100` (yellow) | 23 | Shahid Kolahdooz — Mehrabad T4&6 / Allameh Jafari (branch) |
| **5** | `#007E46` (green) | 12 | Tehran (Sadeghiyeh) — Shahid Sepahbod Qasem Soleimani |
| **6** | `#EF639F` (pink) | 31 | Haram-e Hazrat-e Abdol Azim — Kouhsar |
| **7** | `#7F0B74` (purple) | 22 | Varzeshgah-e Takhti — Meydan-e Ketab |

This matches the brief's rough reference list (1 red, 2 dark blue, 3 light blue,
4 yellow, 5 green, 6 pink, 7 purple) — **confirmed against data, exact hex values
above will be the single source of color truth.** (Line 5 is the express/suburban line.)

**18 interchange stations:** Shahid Beheshti [1,3], Darvazeh Dolat [1,4], Imam Khomeini
[1,2], Meydan-e Mohammadiyeh [1,7], Imam Hossein [2,6], Darvazeh Shemiran [2,4],
Shahid Navab-e Safavi [2,7], Shademan [2,4], Tehran (Sadeghiyeh) [2,5], Teatr-e Shahr
[3,4], Mahdiyeh [3,7], Towhid [4,7], Eram-e Sabz [4,5], Shohada-ye Hefdah-e Shahrivar
[6,7], Meydan-e Shohada [4,6], Shohada-ye Haftom-e Tir [1,6], Meydan-e Hazrat Vali Asr
[3,6], Daneshgah-e Tarbiat Modarres [6,7]. *(All [a,b] pairs — no triple interchanges.)*

---

## 4. Data Quality

**Good news:** Persian text is already normalized to **Persian** glyphs — 0 names contain
Arabic yeh (`ي`) or Arabic kaf (`ك`). 9 names contain a ZWNJ/half-space. No duplicate
English names, no duplicate Persian names. All coordinates parse and fall inside Tehran.
The full relation graph is **a single connected component (150/150 nodes).**

**Issues found (will be handled in the data layer, source file left untouched unless you approve a fix):**

1. **Self-referential relation bug — `Shahid Sadr`.** Its `relations` are
   `["Gheytariyeh", "Shahid Sadr"]` — it lists **itself**. It almost certainly
   should list `Qolhak` (because `Qolhak` lists `Shahid Sadr`, but the reverse edge
   is missing). This is the source of 1 of 2 graph asymmetries. **Recommended fix:**
   treat the graph as undirected (symmetrize edges) at load time, which auto-repairs
   this; optionally also drop self-edges. → repairs cleanly.

2. **`Chaharbagh` / `Ayatollah Kashani` / `Allameh Jafari` cluster (disabled NW segment).**
   - `Chaharbagh` is tagged line **4** but its only relations point to line-6 stations,
     leaving it **isolated within line 4** and producing 3 cross-line relation edges.
   - `Ayatollah Kashani` (line 6) ↔ `Allameh Jafari` (line 4) is a cross-line edge with
     no return edge.
   - All three are in the `disabled` set and lack addresses. This looks like a
     half-entered future extension. **Recommended:** by default exclude `disabled`
     stations from routing/graph, which sidesteps the inconsistency; surface them in
     browse with a "not yet open" badge. Flag for your call (§12.7).

3. **17 `disabled` (closed / under-construction) stations**, including some tagged as
   interchanges (e.g. Shohada-ye Hefdah-e Shahrivar). Routing must **exclude** these by
   default or it will plan journeys through non-existent service.

4. **3 missing addresses** and **typo field `fastFoodn`** (1 station) — cosmetic;
   handled by optional fields + ignoring the typo key.

5. **`waterCooler` is null on 145/150**, `prayerRoom` null on 19 — model these as
   optional `Bool?` (null = "unknown", render as "no data" rather than "absent").

None of these block the core app. **I propose to keep `data/stations.json` byte-for-byte
as shipped and do all repair/normalization in the loader**, so we stay in sync with
upstream. (Alternative: commit a corrected copy — your call, §12.7.)

---

## 5. Graph Viability (the make-or-break question for the journey planner)

**Verdict: ✅ A connected, routable transit graph CAN be built.**

- **Nodes** = stations. **Edges** = `relations` (adjacency), treated as **undirected**
  (symmetrized to auto-heal the 2 asymmetric/self edges).
- **Transfers are implicit:** an interchange is a single node carrying multiple lines,
  so a path can change lines "for free" at that node. To apply a **transfer penalty**
  and to produce "board line X toward terminal Y" directions, routing must be
  **line-aware**: expand each node into per-line states (or detect line changes along
  the path and charge a penalty + emit a transfer step). I recommend modeling routing
  over **(station, line) states** with intra-station transfer edges carrying the penalty.
- **Station order within a line is reconstructed by walking the relation chain** filtered
  to that line — verified to work: each line is a path from one terminal to another.

**Important caveat — branches (real, not a bug):**
- **Line 1** branches at `Shahed - BagherShahr` → toward **Kahrizak** vs **Shahr-e Parand**
  (3 terminals; the real southern Y-split).
- **Line 4** branches at `Bimeh` → toward **Mehrabad Airport T4&6** (3 terminals; the real
  airport spur).

Branches mean "direction toward terminal" is **not** a single terminal per line — the
planner must compute the *correct* terminal for the rider's actual travel direction along
the branch they're on, not just "the end of the line." This is handled, but it's the one
piece of genuine routing nuance, so I'm calling it out now.

**Estimated travel time:** with no timetable in the data, time can only be an
**assumption-based estimate** (fixed seconds/stop + seconds/transfer), clearly labeled
"approx." (see §12.5).

---

## 6. Proposed Swift Data Model (maps 1:1 to source; domain layer, framework-free)

```swift
// ---------- Domain (pure, no SwiftUI/MapKit) ----------

struct Station: Identifiable, Hashable, Sendable {
    let id: StationID            // = English key, stable unique id
    let nameEN: String
    let nameFA: String
    let lines: [Line.ID]         // 1...7
    let coordinate: Coordinate   // parsed from string lat/lng
    let addressFA: String?       // optional (3 missing)
    let isInService: Bool        // = !disabled
    let neighbors: [StationID]   // raw relations (symmetrized at load)
    let facilities: Facilities
    var isInterchange: Bool { lines.count > 1 }
}

struct Coordinate: Hashable, Sendable { let latitude: Double; let longitude: Double }

struct Line: Identifiable, Hashable, Sendable {
    let id: Int                  // 1...7
    let color: Hex               // exact hex from data, single source of truth
    let nameEN: String           // "Line 1"
    let nameFA: String           // "خط ۱"
    let orderedStations: [StationID] // reconstructed; branches modeled explicitly
    let terminals: [StationID]
}

// Facilities: optional Bool so null = unknown, false = absent, true = present
struct Facilities: Hashable, Sendable {
    let restroom, elevator, tactilePaving, atm, coffeeShop, fastFood,
        groceryStore, cleanFood, bicycleParking, creditTicketSales,
        waitingChair, cctv, metroPolice, fireExtinguisher,
        fireSuppression, trashCan, freeWifi: Bool?
    let prayerRoom, waterCooler: Bool?     // frequently null
    let smokingAllowed, petsAllowed: Bool?
}

// ---------- Data layer (knows the file format) ----------
// StationDTO: Decodable mirror of the raw JSON (latitude/longitude as String,
// `disabled`, `fastFoodn` tolerated, etc.) → mapped into the domain types above.
// MetroGraph: adjacency built once, cached; provides line-aware edges + transfer penalty.
```

Rationale: keep `lat/lng` parsing, the `disabled→isInService` flip, edge symmetrization,
and the `fastFoodn` typo entirely inside the data layer so the domain stays clean and
the source file is untouched.

---

## 7. Proposed Architecture & Folder Layout

Clean 3-layer separation; domain is framework-free and unit-testable. I recommend two
**local SPM packages** to enforce the boundary, with the app target on top.

```
TehranMetro/                      (Xcode project, iOS 17+)
├─ App/                           App entry, root tabs, DI composition
├─ Packages/
│  ├─ MetroDomain/   (SPM)        Pure Swift: Station, Line, MetroGraph,
│  │                              RoutingEngine (Dijkstra, modes), search
│  │                              normalization. NO SwiftUI/MapKit. Fully tested.
│  └─ MetroData/     (SPM)        StationDTO + decoder, loads bundled stations.json,
│                                 maps DTO→domain, symmetrizes graph, caches.
├─ Features/                      SwiftUI + @Observable view models (MVVM)
│  ├─ Lines/  Stations/  SchematicMap/  Journey/  NearbyMap/  Favorites/  Settings/
├─ DesignSystem/                  Color/spacing/type tokens, reusable components,
│                                 Vazirmatn font, line badges
├─ Persistence/                   SwiftData models (favorites, recents, saved routes)
├─ Resources/                     stations.json, Vazirmatn fonts, Localizable.xcstrings
└─ Tests/                         Swift Testing: routing, loading, graph, search/numerals
```

- **Data layer:** `MetroData` — only place that knows the JSON shape.
- **Domain layer:** `MetroDomain` — models, graph, routing, Persian search normalization.
  No Apple UI frameworks → testable in isolation, fast.
- **Presentation:** `Features/*` SwiftUI views (dumb) + `@Observable` view models.
- **Persistence:** SwiftData for *user* data only; static metro data stays immutable & bundled.

---

## 8. Open Decisions (§12) — my recommendations

| # | Decision | Recommendation | Why |
|---|---|---|---|
| 1 | Min iOS | **iOS 17** | Enables `@Observable`, SwiftData, String Catalogs cleanly. |
| 2 | Devices | **iPhone first, iPad later** | Focus the core; adaptive layout comes in Stretch. |
| 3 | Schematic map RTL | **Geography fixed, surrounding chrome mirrors** | Maps shouldn't flip; UI should. Industry norm. |
| 4 | External maps priority | **Neshan → Apple → Google** | Neshan is the dominant, locally-accurate maps app in Iran. |
| 5 | Time estimates | **Assumption-based, clearly labeled "approx."** | No timetable exists in data; e.g. ~2 min/stop + ~4 min/transfer, tunable, surfaced as an explicit assumption. |
| 6 | User-data persistence | **SwiftData** | First-party, integrates with `@Observable`/SwiftUI; favorites/recents/saved-routes are simple models. Not overkill at this scope. |
| 7 | Data-bug handling | **Repair in loader (symmetrize edges, exclude `disabled` from routing), keep `stations.json` untouched** | Stays in sync with upstream fork; no fabricated values. Alternative is committing a corrected copy — your call. |

**Additional decisions surfaced by the data (need your steer):**
- **(A) Disabled stations:** exclude from routing by default and show in browse with a
  "not yet open" badge? (recommended) — or hide entirely?
- **(B) Accessibility filter:** data only has `elevator` + `blindPath` (no true step-free
  flag). OK to present "step-free" as "has elevator" with a caveat, rather than a hard
  guarantee?
- **(C) Branch direction labels:** for Line 1 / Line 4 branches, confirm we should show the
  *branch* terminal (e.g. "toward Shahr-e Parand") rather than a generic line end.

---

## 9. What I Did NOT Do

- Wrote **no app/feature code** (per Phase 0 gate).
- Did **not** modify `data/stations.json`.
- Did **not** invent any station, line, coordinate, color, time, or fare.

## 10. Proposed Next Step (Phase 1 — only after your approval)

Project scaffold (iOS 17, the two SPM packages), `StationDTO` + loader with
edge-symmetrization, domain models, the first unit tests (decode 150 stations, graph is
connected, color/line consistency), localization infra (`.xcstrings`), design tokens, and
Vazirmatn integration. Stop for review at the end.

**Awaiting your approval (and answers to §8 items 1–7 + A/B/C) before writing any code.**
</content>
</invoke>

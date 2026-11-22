# Architecture — Algor Field (Concept)

Mock-data-only Flutter prototype. Every decision referenced here has a registry entry in
`docs/decisions.md`. Code stays comment-free; this document is the contract.

## Layers and dependency direction

```
core/domain      pure Dart: models, fictional data, temperature math (no Flutter imports)
core/scenario    immutable ScenarioState + pure transitions, controller, providers
shared/widgets   presentation-only widgets, data in via constructor params
features/*       screens; read providers, dispatch controller commands
routing, app     MaterialApp.router + shell (footer + excursion overlay)
```

`domain` ← `scenario` ← `features`. Shared widgets import `domain` types only.
`flutter_map` and `fl_chart` never appear in `core/`. Two shared widgets read providers:
`DemoTray` (demo controls) and `CallSheet` (simulated call log). (D9 amended)

## State machine

```dart
enum TripPhase { driving, excursionActive, excursionAcknowledged, delivered }
```

| From | Command | Guard | To |
| --- | --- | --- | --- |
| driving | `triggerExcursion()` | always (jumps tick to ≥ 130) | excursionActive |
| excursionActive | `acknowledge(reason, note)` | — | excursionAcknowledged |
| driving / excursionAcknowledged | auto e-POD rule (signature + online + all 3 captures synced) | — | delivered |
| any | `reset()` | — | initial (role picker) |

`nextTick()` order: freeze when delivered → tick+1 (or `lastFeedTick` stays frozen
during a telemetry gap) → reconcile the scripted dead-zone corridor → sync one queue promotion
when online (pending→syncing→synced, or pending→failed when the one-shot failure control is
armed) → decrement escalation when excursionActive (expiry sets `escalated`) → evaluate auto
e-POD rule. Corridor reconciliation also runs after the demo jumps (`triggerExcursion`,
`jumpToOutForDelivery`), so no jump can strand the state offline.

The dead-zone corridor covers ticks 47–140 (the ghat stretch to just past Nashik). Entry and
exit set `isOffline` and append System custody events; the driver's manual switch and the tray
toggle are overrides that hold between boundaries, while a boundary forces its value. The
canonical sample keeps its eight custody events, so event numbering and the PDF stay unchanged.
(D72)

Initial state: tick 45 (05:00), lastFeedTick 45, phase driving, vaccine band, custody
`[Dispatched · 04:15 · Mumbai (BOM)]`.

## Driver stepper

Five `PageView` pages: checklist → AWB scan → seal photo → signature → confirm. Continue is
gated per step, Back returns, and swipe is disabled. The signature page keeps a sticky footer:
**Done** while the signature is open, then "Signature captured · N of 3 synced" with an inline
Retry when a promotion fails. When the e-POD exists the screen advances to the confirm step by
itself; Continue and Back remain for manual navigation. Checklist rows carry a concept thumbnail
and the hint names the tap interaction. (D34 amended, D35 amended, D60–D63)

## Scenario state fields

`tick`, `lastFeedTick`, `telemetryGap`, `phase`, `band`, `checklist` (4 confirmed flags),
`scanned`, `sealNumber`, `sealVerified`, `signature` (record: bytes/name/tick/note), `isOffline`,
`queue` (sealed `ChecklistQueued | ScanQueued | SealPhotoQueued`, each with `eventId`),
`failNextSync`, `epod`, `excursion`, `escalationSecondsLeft`, `escalationDuration`,
`driftStartedTick`, `custody` (each event with `eventId`, `source`, `actor`), `eventSeq`.

Capture commands append a queue item and a custody event sharing one event ID; each capture
gets a unique `EVT-NNN`. Queue promotions: one item one step per tick while online; a failed
item offers Retry and blocks delivery until synced.

## Two clocks and one owner per fact

`tick` is the app/scenario clock (escalation, ETA, custody stamps, capture-time labels). `lastFeedTick`
is the last received sensor packet; temperature, truck position, charts, PDF curves and the
seal-photo/signature location stamps read it. The demo tray's **Telemetry gap** freezes
`lastFeedTick` while `tick` continues, so every feed-derived view goes stale together and the
readout says "Stale · last received HH:MM". Triggering an excursion refreshes the feed once; the
two time jumps clear the gap. The driver evidence queue (offline toggle) is a separate channel
from the sensor feed.

## Product bands

`BandProfile` (`vaccine 2–8`, `blood 1–6`, `crt 15–25`, `frozen −30…−20`) owns the
base/excursion/floor values, drift/decay rates, axis range/interval, product label and
excursion title. The chart, readout bar and PDF painter all read the same profile. An
`ExcursionEvent` stores the peak reading and band label captured at detection; the alert, banner
and PDF render that stored value, so a band preview cannot rewrite an incident. Switching bands
from the demo tray previews the live feed and report band; captured records, checklist readings
and timestamps are not rewritten. The canonical demo and the sample remain vaccine 2–8.

## Temperature math

`temperatureAt(tick, band, driftFrom, acknowledgedAt, pinFromTick)`: base + seeded noise
(seed 42, ±0.3) → while drifting add `band.driftRate × (tick − driftFrom)` → from the excursion
start onward the reading pins at `band.excursion` → after ack decay `band.decayRate` per tick
toward `band.floor`, then noise only. Vaccine values reproduce the original dossier curve.
`meanKineticTemperature(series)`: Arrhenius, Ea 83.144 kJ/mol, R 8.314462618.

## Providers

```dart
final scenarioControllerProvider = NotifierProvider<ScenarioController, ScenarioState>(...);
final truckPositionProvider = Provider<({double lat, double lng})>(... lastFeedTick);
final chartReadingsProvider = Provider<List<TempReading>>(... trailing 60 to lastFeedTick, band);
```

Controller: `build()` returns `ScenarioState.initial()`, starts a 1 Hz timer when
`autoStartTicker`, cancels in `ref.onDispose`. Commands map 1:1 to state methods.

## Routing and shell

`/` role picker · `/ops` monitor · `/driver` stepper · `/client` list · `/client/live` ·
`/client/sample`. All routes live under one `ShellRoute`; the shell is
`Scaffold(body: Stack(routeChild, ExcursionOverlay, ExcursionPushBanner),
bottomNavigationBar: ConceptFooter)`. The push banner fires on the
driving→excursionActive transition (suppressed on `/client/sample`), auto-dismisses after
5 s and is dismiss-only. Footer long-press opens the demo tray. Every non-root app bar offers a
**Switch role** action returning to `/`.

## Ops monitor

Read-only and single-trip. The header is a feed strip (FEED LIVE / FEED STALE / FEED CLOSED, the
scenario clock, and a last-received or delivered stamp). While an excursion is active the alert is
the first block, showing the detected reading and band with a full-width danger **Call driver**
primary; once resolved a "Last alert HH:MM · X.X °C · acknowledged" line keeps the incident
visible. Calls placed from ops are recorded with source "Control room". (D67, D68)

## Shared widget contracts

| Widget | Parameters | Notes |
| --- | --- | --- |
| `TempBandChart` | readings, band, excursionTick, height | band-relative fixed axis, band via range annotation |
| `MapPanel` | truckPosition, isExcursion, height | OSM tiles, attribution, fallback grid on tile failure |
| `TempReadout` | celsius, band, phase, sourceLabel, stale, showChip | 36 px w600 value, band bar, optional status chip, feed/stale row |
| `CountdownRing` | secondsLeft, totalSeconds, size | arc painter, mm:ss label |
| `StatusChip` | phase | In transit / Excursion! / Excursion acknowledged / Delivered |
| `MilestoneTimeline` | events | custody events, newest first; tap expands event ID, actor and source |
| `SyncQueueSheet` | queue, onRetry | event ID + per-item status; failed rows retry |
| `CallSheet` | title, subtitle, custodyTitle | 2 s ringing → Connected, appends custody |
| `ExcursionPushBanner` | enabled | simulated push card, 5 s auto-dismiss |
| `ConceptFooter` | — | long-press opens demo tray |
| `DemoTray` | — | grouped sheet with D26 actions plus v2 controls |

## Theme

`ColorScheme.fromSeed(seedColor: #00C2D1, brightness: dark).copyWith(surface: #0A2540)`.
No `useMaterial3` flag. `AppColors` exposes navy/cyan/teal/success/danger/queued constants.
Body copy uses Material text roles; compact 10–13 px labels are allowed in chips, metadata,
map captions and the footer, while the 36 px w600 temperature readout is the only display size
(D43 amended). Bottom sheets share a navy `surfaceRaised` background.

## PDF

`buildAuditPdf(ScenarioState) → Future<Uint8List>` with `pw.MultiPage`:
header + shipment table (band product label, logger calibration); full-trip curve ending at
`lastFeedTick` (≤ 240 points, band-relative axis, shaded band, red excursion dots);
min/max/mean/MKT/in-band strip; excursion summary (detected, reading, location, ack time,
reason, note, escalation, delivery note); custody table; then a forced new page for e-POD
(signature image, delivery note), capture verification with event IDs and report notes;
per-page footer "Concept prepared for Algor — mock data only". Fonts:
`assets/fonts/Roboto-Regular.ttf`, `Roboto-Bold.ttf`. Share via `Printing.sharePdf`
with filename `algor-field-audit-172-45678901.pdf`. (D27 amended for the two-page layout)
Custody `source`/`actor` stays app-only: the PDF keeps its ratified two-page contract (D66).

## Testability

All transitions pure on `ScenarioState`. `ScenarioController(autoStartTicker: false)` in
tests; `advanceTick()` drives time. Widget tests pump `ProviderScope` overrides and provide
a `MaterialApp` wrapper. Smoke suite: `temperature_test.dart`, `band_test.dart`,
`scenario_state_test.dart`, `driver_flow_test.dart`, `push_banner_test.dart`,
`client_detail_test.dart`, `ops_monitor_test.dart`, `audit_pdf_test.dart`.

## Conventions (latest Flutter 3.47 / Dart 3.13)

| Avoid | Use |
| --- | --- |
| `Color.withOpacity()` | `Color.withValues(alpha:)` |
| `useMaterial3: true` | omit (M3 default) |
| legacy buttons | `FilledButton` / `FilledButton.tonal` / `SegmentedButton` |
| `MediaQuery.of(context).size` | `MediaQuery.sizeOf(context)` |
| `MaterialApp` + `onGenerateRoute` | `MaterialApp.router` + go_router |
| `StateProvider` / `ChangeNotifierProvider` | `Notifier` + `NotifierProvider` |
| ad-hoc literals | `fictional_data.dart` constants |
| comments as documentation | this doc + `docs/decisions.md` |

Also: `const` constructors, `super.key`, sealed unions with `switch` patterns, enhanced
enums, `dart format` (tall style), zero `// ignore:` suppressions.

## Concept versus pilot scope

This build is a single-truck, mock-data concept tuned for a 60-second demo. The following are
deliberately deferred to a pilot rather than missing pieces:

- **Fleet views** — a shipment list or trip switcher in the ops monitor, an attention filter and a
  cross-shipment "last alert" strip. The state machine is one immutable trip by design (D1).
- **Ops-side acknowledgement and escalation** — acknowledgement is a driver-owned fact; an ops
  action needs an operator identity in the custody actor model.
- **Search and filtering** in the client list — two cards are seeded (live and sample).
- **Platform connectivity detection** — the concept simulates the dead zone from the trip clock
  (D72); a pilot reads the real radio state and keeps the scenario override in the tray only.
- **Driver trip list** — the dossier's §6.2 first bullet, alongside the already-deferred
  per-customer PDF templates, FCM push, a local database, SSO and localisation.
- **Field legibility** — 10–11 px metadata reads well on the recording emulator; a pilot tests a
  larger base on mid-range devices in daylight.

Recorded as D71.

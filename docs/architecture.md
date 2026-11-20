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

`nextTick()` order: freeze when delivered → tick+1 → sync one queue promotion when online →
decrement escalation when excursionActive (expiry sets `escalated`) → evaluate auto e-POD rule.

Initial state: tick 45 (05:00), phase driving, custody `[Dispatched · 04:15 · Mumbai (BOM)]`.

## Scenario state fields

`tick`, `phase`, `checklist` (4 confirmed flags), `scanned`, `sealNumber`,
`sealVerified`, `signature` (record: bytes/name/tick), `isOffline`, `queue` (sealed
`ChecklistQueued | ScanQueued | SealPhotoQueued`), `epod`, `excursion`, `escalationSecondsLeft`,
`escalationDuration`, `driftStartedTick`, `custody`.

Capture commands append queue items; each capture appends a custody event.
Queue promotions: one item one step per tick while online.

## Temperature math

`temperatureAt(tick, driftFrom, acknowledgedAt, excursionPin)`:
base 4.2 + seeded noise (seed 42, ±0.3) → while drifting add 0.35 × (tick − driftFrom) →
while an unacknowledged excursion exists the reading pins at 8.9 → after ack decay
−0.8 × (tick − ackTick) toward 4.5, then noise only.
`meanKineticTemperature(series)`: Arrhenius, Ea 83.144 kJ/mol, R 8.314462618.

## Providers

```
scenarioControllerProvider : NotifierProvider<ScenarioController, ScenarioState>
truckPositionProvider      : Provider<({double lat, double lng})>
chartReadingsProvider      : Provider<List<TempReading>>   (trailing 60)
```

Controller: `build()` returns `ScenarioState.initial()`, starts a 1 Hz timer when
`autoStartTicker`, cancels in `ref.onDispose`. Commands map 1:1 to state methods.

## Routing and shell

`/` role picker · `/ops` monitor · `/driver` stepper · `/client` list · `/client/live` ·
`/client/sample`. All routes live under one `ShellRoute`; the shell is
`Scaffold(body: Stack(routeChild, ExcursionOverlay), bottomNavigationBar: ConceptFooter)`.
Footer long-press opens the demo tray. Every app bar has a home icon returning to `/`.

## Shared widget contracts

| Widget | Parameters | Notes |
| --- | --- | --- |
| `TempBandChart` | readings, bandMin, bandMax, excursionTick, height | fixed 0–10 Y-axis, band via range annotation |
| `MapPanel` | truckPosition, isExcursion, height | OSM tiles, attribution, fallback grid on tile failure |
| `TempReadout` | celsius, bandMin, bandMax, phase | 36 px w600 value, band bar, status chip |
| `CountdownRing` | secondsLeft, totalSeconds, size | arc painter, mm:ss label |
| `StatusChip` | phase | In transit / Excursion! / Excursion acknowledged / Delivered |
| `MilestoneTimeline` | events | custody events, newest first |
| `SyncQueueSheet` | queue | per-item status rows |
| `CallSheet` | title, subtitle, custodyTitle | 2 s ringing → Connected, appends custody |
| `ConceptFooter` | — | long-press opens demo tray |
| `DemoTray` | — | sheet with D26 actions |

## Theme

`ColorScheme.fromSeed(seedColor: #00C2D1, brightness: dark).copyWith(surface: #0A2540)`.
No `useMaterial3` flag. `AppColors` exposes navy/cyan/teal/success/danger/queued constants.
Body copy uses Material text roles; compact 10–13 px labels are allowed in chips, metadata,
map captions and the footer, while the 36 px w600 temperature readout is the only display size
(D43 amended). Bottom sheets share a navy `surfaceRaised` background.

## PDF

`buildAuditPdf(ScenarioState) → Future<Uint8List>` with `pw.MultiPage`:
header + shipment table; full-trip curve (≤ 240 points, shaded band, red excursion dot);
min/max/mean/MKT/in-band strip; excursion summary (detected, location, ack time, reason,
note, escalation); custody table; then a forced new page for e-POD (signature image),
capture verification and report notes; per-page footer
"Concept prepared for Algor — mock data only". Fonts:
`assets/fonts/Roboto-Regular.ttf`, `Roboto-Bold.ttf`. Share via `Printing.sharePdf`
with filename `algor-field-audit-172-45678901.pdf`. (D27 amended for the two-page layout)

## Testability

All transitions pure on `ScenarioState`. `ScenarioController(autoStartTicker: false)` in
tests; `advanceTick()` drives time. Widget tests pump `ProviderScope` overrides and provide
a `MaterialApp` wrapper. Smoke suite: `temperature_test.dart`, `scenario_state_test.dart`,
`driver_flow_test.dart`, `audit_pdf_test.dart`.

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

# Implementation notes — Algor Field (Concept)

This document records the technical difficulties encountered while building the concept and how
each was resolved. It is the narrative companion to [`decisions.md`](decisions.md): the registry
remains the append-only source of truth, and every entry here cites its decision IDs. Sources
are the execution-time amendments in the registry, the [`architecture.md`](architecture.md)
contract, and the implementation itself.

Each entry has the same shape: **the problem**, **how it was resolved**, **where to see it** in
the code, and **decision references**.

| # | Difficulty | Resolution | Decisions |
| --- | --- | --- | --- |
| 1 | One time basis for every screen | Single scenario epoch and clock; all times derived from the tick | D11, D31, D32 |
| 2 | Live-looking but deterministic temperature | Seeded noise and fixed thermal rates; Arrhenius MKT | D21 |
| 3 | Testing a ticking app without timers | Injectable ticker; manual `advanceTick()` in tests | D20, D28 |
| 4 | Impossible states from out-of-order taps | Immutable state, guarded pure transitions, fixed tick order | D10, D12, D17 |
| 5 | Escalation countdown dead-ends | Expiry records escalation; acknowledgement stays open | D16 |
| 6 | Offline queue and delivery that are truthful | Three real queue items, one promotion per tick, automatic e-POD | D13, D14, D15, D33 |
| 7 | Excursion overlay ownership and sheet context | Overlay mounted in the shell `Stack`; route-based visibility | D18 |
| 8 | Live versus sample client rendering | Explicit live/sample routes over one `sampleDelivered()` factory | D19, D40 |
| 9 | Temperature band across fl_chart versions | `HorizontalRangeAnnotation` on a fixed 0–10 °C axis | D22, D39 |
| 10 | Audit PDF from any state | Pure `(state) → bytes` builder with per-page footer | D27, D28, D41 |
| 11 | Camera, geotag and signature without permissions | Simulated scan, composited watermark, live signature pad | D7, D24, D36 |
| 12 | Map that works without network | Tile-failure fallback to route grid and "Offline map preview" | D47 |
| 13 | Artwork when image generation was unavailable | Programmatic PIL artwork at the planned asset paths | D30 |
| 14 | Strict analysis with zero comments or suppressions | Modern idioms adopted up front; registry as documentation | D29, D44 |
| 15 | Provider-free shared widgets | Constructor-only data; two sanctioned provider exceptions | D9 |

## Time, determinism and testability

### 1. One clock for every displayed time

**Problem.** An 18.5-hour journey has to compress into minutes, but every surface shows a time —
clock chips, charts, custody stamps, map position, photo watermarks and the PDF. Two clocks
(wall time and trip time) would produce an audit app whose own records contradict each other.

**Resolution.** One scenario epoch — 21 Nov 2026 04:15 IST is tick 0 — driven by a single 1 Hz
timer. The initial tick is 45 (05:00) with 45 readings of prior history, so the chart is alive on
the first frame. Every displayed time is derived from the tick; wall time is never shown. Demo
time jumps move the same tick (`triggerExcursion()` to at least tick 130 = 06:25,
`jumpToOutForDelivery()` to at least tick 1050 = 21:45), so the map position, alert copy and
custody stamps stay coherent.

**Where.** `lib/core/domain/fictional_data.dart` (`scenarioTime`, `initialTick`,
`excursionJumpTick`, `outForDeliveryTick`, `deliveredTick`, `etaTick`) ·
`lib/core/scenario/scenario_controller.dart` (the 1 Hz `Timer.periodic`) ·
`lib/core/util/formatters.dart` (`formatClock`, `formatDateTime`, `formatWatermark`).

**Decisions.** D11, D31, D32.

### 2. Temperature that looks alive but replays identically

**Problem.** The readout must wobble like real telemetry, yet be identical on every take and unit
test — and the mean kinetic temperature (MKT) must be honest math, not decoration.

**Resolution.** Seeded noise (seed 42, ±0.3 °C) over a 4.2 °C base. Drift adds 0.35 °C per tick;
the excursion pins at 8.9 °C; after acknowledgement the curve decays 0.8 °C per tick toward
4.5 °C. MKT uses the Arrhenius equation with Ea 83.144 kJ/mol and R 8.314462618.

**Where.** `lib/core/domain/temperature.dart`.

**Decisions.** D21.

### 3. Testing a ticking app without real timers

**Problem.** The controller owns a `Timer.periodic`; real timers make widget tests slow and
flaky, and time-dependent assertions impossible to keep stable.

**Resolution.** `ScenarioController({bool autoStartTicker = true})`. Tests override the
provider with `autoStartTicker: false` and drive `advanceTick()` by hand. All transitions are
pure methods on the state object, so the state machine is unit-testable without any widget.

**Where.** `lib/core/scenario/scenario_controller.dart` · `test/temperature_test.dart` ·
`test/scenario_state_test.dart` · `test/driver_flow_test.dart` · `test/audit_pdf_test.dart`.

**Decisions.** D20, D28.

## State machine robustness

### 4. Demo-proof state transitions

**Problem.** Demo audiences tap in nonsensical orders — trigger the alarm after delivery,
acknowledge twice, jump while offline. A naive implementation forks into impossible states such
as delivered-without-signature or excursion-over-a-closed-trip.

**Resolution.** One immutable `ScenarioState` with a four-phase enum and pure, guarded
transitions. Excursion triggers only from `driving`; acknowledgement only from
`excursionActive`; captures are ignored once delivered. `nextTick()` runs in a fixed order:
freeze when delivered → increment the tick → promote one queue item when online → step the
escalation countdown → evaluate the automatic e-POD rule. Every command that fails its guard is
a silent no-op, so the machine cannot be broken by tapping.

**Where.** `lib/core/scenario/scenario_state.dart` (all transition methods and `nextTick`) ·
`lib/core/scenario/scenario_controller.dart` (1:1 command dispatch).

**Decisions.** D10, D12, D17.

### 5. Escalation that never dead-ends

**Problem.** A countdown that expires could trap the flow — the driver would be stuck on an
alarm that refuses acknowledgement.

**Resolution.** Expiry sets `escalated` and appends a custody event ("Escalated — control room
notified") but acknowledgement remains available indefinitely afterwards.

**Where.** `lib/core/scenario/scenario_state.dart` (`_escalationStep`, `acknowledge`).

**Decisions.** D16.

## Offline capture and delivery

### 6. A truthful offline queue and self-closing delivery

**Problem.** "Three items queued" must be state, not a banner: captures must persist offline,
sync visibly, and block delivery until complete — and the sync has to be watchable in a demo
without looking instant. Delivery also must not hinge on a manual "mark delivered" button.

**Resolution.** The queue holds exactly three capture items. While online, one item advances one
status per tick (`pending → syncing → synced`), producing a one-per-second drain.
`canDeliver` requires a signature, an online connection and a fully synced queue; the e-POD then
generates automatically inside `nextTick()` and the trip becomes delivered. Signing while
offline shows "e-POD held locally — will send on reconnect". The offline banner renders the live
queue count, not a fixed string (an amendment during execution).

**Where.** `lib/core/domain/models.dart` (sealed queue item types) ·
`lib/core/scenario/scenario_state.dart` (`nextTick` order, `_syncStep`, `canDeliver`,
`_autoDeliver`) · `lib/features/driver_flow/driver_flow_screen.dart` (offline banner) ·
`lib/features/driver_flow/steps/confirm_step.dart` (capture queue) ·
`lib/core/domain/fictional_data.dart` (`offlineBanner`, `epodHeldLabel`).

**Decisions.** D13, D14, D15, D33; D5 amended.

## Routing and screen ownership

### 7. The excursion overlay that belongs to one role

**Problem.** The alarm must appear over whatever the driver is doing (any of the five stepper
pages, sheets open), never behave like a route, never leak onto the ops or client screens, and
its action sheets need a valid Navigator context. This one was amended twice during execution.

**Resolution.** The overlay is mounted once in the shared shell above the routed child, inside a
`Stack`, so its sheets resolve against the root Navigator. It is not a route and not a dialog.
Visibility is route-based: the overlay is enabled only on `/driver` and shows only while the
phase is `excursionActive`, so a stale role cannot render it over the client view.

**Where.** `lib/shared/widgets/app_shell.dart` (`Stack(routeChild, ExcursionOverlay)`) ·
`lib/features/excursion/excursion_overlay.dart` (`enabled` parameter) ·
`lib/routing/app_router.dart`.

**Decisions.** D18 (amended twice).

### 8. Live versus sample rendering without duplication

**Problem.** The client list needs two cards — the live shipment and a finished sample — and
both details should render through the same logic. The initial routing only had a list route;
the live-detail route had to be added explicitly during execution.

**Resolution.** Explicit `/client/live` and `/client/sample` routes both build
`ClientShipmentDetail`, with a `sample` flag choosing the data source. The sample is backed by a
`sampleDelivered()` factory that bakes the canonical run (excursion 06:25, acknowledged 06:26,
out for delivery 21:45, delivered 21:48), so sample and live paths share identical rendering
code.

**Where.** `lib/routing/app_router.dart` · `lib/features/client_view/client_shipments_screen.dart`
· `lib/features/client_view/client_shipment_detail.dart` ·
`lib/core/scenario/scenario_state.dart` (`sampleDelivered`).

**Decisions.** D19 (amended), D40.

## Charts and the audit PDF

### 9. Temperature band rendering across fl_chart versions

**Problem.** The 2–8 °C band has to sit behind the temperature line. Positioned-overlay hacks
are fragile across layout changes and fl_chart API revisions, and both the live chart and the
PDF curve must stay readable.

**Resolution.** The band uses fl_chart 1.3's `HorizontalRangeAnnotation` on a fixed 0–10 °C
Y-axis. The live chart shows a trailing 60-reading window; the PDF curve shows the full trip
downsampled to at most 240 points, with the excursion marked by a red dot.

**Where.** `lib/shared/widgets/temp_band_chart.dart` · `lib/core/scenario/providers.dart`
(`chartReadingsProvider`, trailing 60) · `lib/features/client_view/audit_pdf_service.dart`.

**Decisions.** D22 (amended), D39.

### 10. The audit PDF from any state

**Problem.** The report must build from both the live state and the canned sample, carry the
concept footer on every page, embed the signature image, and not regress silently. During
execution the font licence label also needed correcting, and the layout moved to two pages.

**Resolution.** A pure `(ScenarioState) → Future<Uint8List>` builder using `pw.MultiPage`: header
and shipment table, full-trip curve via `pw.CustomPaint`, statistics strip, excursion summary,
custody table, a forced new page for the e-POD and capture verification, and a per-page footer.
Fonts are bundled Roboto Regular and Bold (Apache-2.0; the plan's OFL label was corrected during
execution). Sharing goes through `Printing.sharePdf` with the filename
`algor-field-audit-172-45678901.pdf`. A dedicated PDF-generation test was added to the smoke
suite to guard the output.

**Where.** `lib/features/client_view/audit_pdf_service.dart` · `assets/fonts/` ·
`test/audit_pdf_test.dart`.

**Decisions.** D27 (amended), D28 (amended), D41.

## Media, assets and permissions

### 11. Scan, geotag and signature with zero runtime permissions

**Problem.** The story needs a barcode scan, a geotagged seal photo and a signature. Real
camera and GPS access would require runtime permission prompts, slow down recording, and raise
privacy questions the concept deliberately avoids.

**Resolution.** The scan is a 1.2-second simulated animation that resolves to a manifest match.
The seal "photo" is bundled concept artwork with a watermark composited from live route
interpolation, the scenario clock and the truck plate — for example
"20.00° N, 73.79° E · 21 Nov 2026 06:25 IST · MH 04 KF 4001". Only the signature pad is a real
capture. The release build asks for no runtime permissions.

**Where.** `lib/features/driver_flow/steps/scan_step.dart` ·
`lib/features/driver_flow/steps/seal_photo_step.dart` ·
`lib/features/driver_flow/steps/signature_step.dart` ·
`lib/core/domain/route.dart` (`positionOnRoute`) ·
`lib/core/util/formatters.dart` (`formatWatermark`).

**Decisions.** D7, D24, D36.

### 12. A map that survives without network

**Problem.** OpenStreetMap tiles are the app's only network dependency, and demos often happen
offline or in a dead zone. The map must never block the walkthrough.

**Resolution.** The release manifest ships only the normal `INTERNET` permission, used solely
for tiles. A grid is painted behind the tile layer; after repeated tile failures the panel shows
"Offline map preview". The route polyline and truck marker render regardless, and map
interaction is disabled so the camera stays framed on the route.

**Where.** `lib/shared/widgets/map_panel.dart` (`errorTileCallback`, `_GridPainter`) ·
`android/app/src/main/AndroidManifest.xml`.

**Decisions.** D47.

### 13. Artwork when image generation was unavailable

**Problem.** Image generation failed at build time with a provider credential error, leaving the
concept without reefer, seal, pre-cool or launcher artwork.

**Resolution.** The four fictional images were produced programmatically with PIL at the exact
planned asset paths, so they can be replaced by real photographs later with no code changes.

**Where.** `assets/images/reefer_door_seal.png` · `assets/images/precool_reefer.png` ·
`assets/images/signature_sample.png` · `assets/icon/af_icon.png`.

**Decisions.** D30.

## Engineering discipline

### 14. Strict analysis with zero comments and suppressions

**Problem.** The project targets the latest Flutter/Dart with `strict-casts`,
`strict-inference` and `strict-raw-types`, while the documentation policy forbids explanatory
code comments and `// ignore:` suppressions.

**Resolution.** Modern idioms were adopted up front — `Color.withValues(alpha:)` instead of
`withOpacity`, `Notifier`/`NotifierProvider` instead of `StateProvider`, `MaterialApp.router`
with go_router, `MediaQuery.sizeOf`, Material 3 defaults — and all rationale lives in the
registry rather than in code. `flutter analyze` stays clean without suppressions.

**Where.** `analysis_options.yaml` · `docs/architecture.md` (conventions table) ·
`docs/decisions.md`.

**Decisions.** D29, D44.

### 15. Provider-free shared widgets with two sanctioned exceptions

**Problem.** Widgets that read providers leak coupling and become hard to test — yet the demo
tray and the simulated call sheet genuinely need controller access. The call sheet also needed
to append its simulated call to the custody trail during execution.

**Resolution.** Shared widgets take data through constructor parameters only, and the
dependency direction is strictly `domain ← scenario ← features`. Exactly two shared widgets may
read providers: `DemoTray` (demo controls) and `CallSheet` (which logs its simulated call to
custody).

**Where.** `lib/shared/widgets/` · `lib/shared/widgets/demo_tray.dart` ·
`lib/shared/widgets/call_sheet.dart`.

**Decisions.** D9 (amended).

## Amendment trail

Registry entries that changed during execution, kept here so the history is easy to audit.

| Decision | Amendment |
| --- | --- |
| D5 | Offline banner copy renders the live queue count instead of a fixed number |
| D9 | `CallSheet` also appends its simulated call to the custody trail |
| D15 | e-POD unlock refined to signature + online + all three captures synced |
| D18 | Overlay mount point fixed for sheet context; visibility made route-based |
| D19 | Explicit `/client/live` detail route added |
| D22 | Band rendering moved to fl_chart 1.3 `HorizontalRangeAnnotation` |
| D27 | Font licence corrected to Apache-2.0; two-page layout |
| D28 | PDF generation test added to the smoke suite |
| D43 | Compact 10–13 px metadata labels allowed; single 36 px display readout |

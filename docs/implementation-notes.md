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
| 1 | One time basis for every screen | App clock plus a separate sensor-feed clock with a visible stale state | D11, D31, D32, D48 |
| 2 | Live-looking but deterministic temperature | Seeded noise and per-band thermal profiles; Arrhenius MKT | D21, D53 |
| 3 | Testing a ticking app without timers | Injectable ticker; manual `advanceTick()` in tests | D20, D28 |
| 4 | Impossible states from out-of-order taps | Immutable state, guarded pure transitions, fixed tick order | D10, D12, D17 |
| 5 | Escalation countdown dead-ends | Expiry records escalation; acknowledgement stays open | D16 |
| 6 | Offline queue and delivery that are truthful | Three real queue items, one promotion per tick, automatic e-POD | D13, D14, D15, D33 |
| 7 | Excursion overlay ownership and sheet context | Overlay mounted in the shell `Stack`; route-based visibility | D18 |
| 8 | Live versus sample client rendering | Explicit live/sample routes over one `sampleDelivered()` factory | D19, D40 |
| 9 | Temperature band across fl_chart versions | `HorizontalRangeAnnotation` on a band-relative fixed axis | D22, D39, D53 |
| 10 | Audit PDF from any state | Pure `(state) → bytes` builder with per-page footer | D27, D28, D41 |
| 11 | Camera, geotag and signature without permissions | Simulated scan, composited watermark, live signature pad | D7, D24, D36 |
| 12 | Map that works without network | Tile-failure fallback to route grid and "Offline map preview" | D47 |
| 13 | Artwork when image generation was unavailable | Programmatic PIL artwork at the planned asset paths | D30 |
| 14 | Strict analysis with zero comments or suppressions | Modern idioms adopted up front; registry as documentation | D29, D44 |
| 15 | Provider-free shared widgets | Constructor-only data; two sanctioned provider exceptions | D9 |
| 16 | Action and sync feedback hidden below the fold | Sticky Done footer that becomes the capture status; auto-advance on e-POD | D34, D35, D60, D61, D62, D63 |
| 17 | Report access below the fold and anonymous custody | App-bar PDF action, delivery-pack header, expandable provenance rows | D64, D65, D66 |
| 18 | Ops alerts and role switching buried | Alert pinned first, feed strip, last-alert line, Switch role action | D67, D68, D69, D70 |
| 19 | A driver who forgets to mark a dead zone | Scripted corridor toggles coverage and logs system events; toggles are overrides | D72 |

## Time, determinism and testability

### 1. One app clock plus one sensor-feed clock

**Problem.** An 18.5-hour journey has to compress into minutes, but every surface shows a time —
clock chips, charts, custody stamps, map position, photo watermarks and the PDF. Wall time and
trip time must not mix, yet a stale sensor feed must never masquerade as live.

**Resolution.** One scenario epoch — 21 Nov 2026 04:15 IST is tick 0 — driven by a single 1 Hz
timer. The initial tick is 45 (05:00) with 45 readings of prior history, so the chart is alive on
the first frame. App-side times (escalation, ETA, custody stamps, capture labels) use `tick`;
sensor-derived views (temperature, map, charts, PDF curves, photo/signature location) use
`lastFeedTick`. The demo tray can freeze the feed while the app clock continues, and the readout
labels the gap. Demo time jumps move the same tick (`triggerExcursion()` to at least tick
130 = 06:25, `jumpToOutForDelivery()` to at least tick 1050 = 21:45), so the map position, alert
copy and custody stamps stay coherent.

**Where.** `lib/core/domain/fictional_data.dart` (`scenarioTime`, `initialTick`,
`excursionJumpTick`, `outForDeliveryTick`, `deliveredTick`, `etaTick`) ·
`lib/core/scenario/scenario_controller.dart` (the 1 Hz `Timer.periodic`) ·
`lib/core/scenario/scenario_state.dart` (`lastFeedTick`, `telemetryGap`) ·
`lib/core/util/formatters.dart` (`formatClock`, `formatDateTime`, `formatWatermark`,
`formatFeedLabel`).

**Decisions.** D11, D31, D32, D48.

### 2. Temperature that looks alive but replays identically

**Problem.** The readout must wobble like real telemetry, yet be identical on every take and unit
test — and the mean kinetic temperature (MKT) must be honest math, not decoration.

**Resolution.** Seeded noise (seed 42, ±0.3 °C) over a per-band base. Each `BandProfile` owns its
base, excursion pin, floor and drift/decay rates; the vaccine profile reproduces the original
4.2 → 8.9 → 4.5 curve (0.35 drift, 0.8 decay). MKT uses the Arrhenius equation with Ea
83.144 kJ/mol and R 8.314462618.

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
status per tick (`pending → syncing → synced`), producing a one-per-second drain. Each capture
carries a unique `EVT-NNN` ID shared with its custody entry. A one-shot demo control can turn the
next promotion into `failed`; the queue offers Retry, and delivery stays blocked until the item
syncs. `canDeliver` requires a signature, an online connection and a fully synced queue; the
e-POD then generates automatically inside `nextTick()` and the trip becomes delivered. Signing
while offline shows "e-POD held locally — will send on reconnect". The offline banner renders the
live queue count, not a fixed string (an amendment during execution).

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
phase is `excursionActive`, so a stale role cannot render it over the client view. A second shell
widget fires a simulated heads-up banner on the driving→excursionActive transition (auto-dismiss
5 s, dismiss-only, suppressed on `/client/sample`), so the alert reads as a push without any
notification permission.

**Where.** `lib/shared/widgets/app_shell.dart` (`Stack(routeChild, ExcursionOverlay,
ExcursionPushBanner)`) · `lib/features/excursion/excursion_overlay.dart` (`enabled` parameter) ·
`lib/features/excursion/excursion_push_banner.dart` · `lib/routing/app_router.dart`.

**Decisions.** D18 (amended twice), D49.

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

**Problem.** The temperature band has to sit behind the line, positioned-overlay hacks are
fragile across layout changes and fl_chart API revisions, and the same chart must serve four
product bands with very different ranges.

**Resolution.** The band uses fl_chart 1.3's `HorizontalRangeAnnotation`. The Y-axis is fixed
per `BandProfile` (vaccine 0–10, blood 0–8, CRT 10–30, frozen −35…−10) and is shared by the live
chart, the readout bar and the PDF painter. The live chart shows a trailing 60-reading window;
the PDF curve shows the full trip downsampled to at most 240 points, ending at the last received
reading, with excursions marked by red dots.

**Where.** `lib/core/domain/band.dart` · `lib/shared/widgets/temp_band_chart.dart` ·
`lib/shared/widgets/temp_readout.dart` · `lib/core/scenario/providers.dart`
(`chartReadingsProvider`, trailing 60) · `lib/features/client_view/audit_pdf_service.dart`.

**Decisions.** D22 (amended twice), D39, D53.

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

## v2 concept alignment (dossier v2)

### 16. A stale feed that cannot look live

**Problem.** The dossier requires a "last updated" signal so a cached reading is never mistaken
for live telemetry. Freezing only the temperature would leave the map, chart and PDF telling a
different story.

**Resolution.** Introduced `lastFeedTick` and a demo-tray **Telemetry gap**. The readout says
"Stale · last received HH:MM · N min ago", the ops badge flips LIVE→STALE (and CLOSED when
delivered), the map and chart freeze, and the PDF ends at the last received reading. The driver
evidence queue remains a separate channel.

**Where.** `lib/core/scenario/scenario_state.dart` · `lib/shared/widgets/temp_readout.dart` ·
`lib/features/ops_monitor/ops_monitor_screen.dart` · `lib/shared/widgets/demo_tray.dart`.

**Decisions.** D48.

### 17. An alert that reads as a push without notification permission

**Problem.** The excursion is described as a pushed alert, but runtime notification permission
would break the zero-permission guardrail and slow the demo.

**Resolution.** A simulated heads-up card appears on the driving→excursionActive transition,
auto-dismisses after five seconds, dismisses on tap or close, and is suppressed on the static
sample screen. The full-screen driver overlay still owns acknowledgement. The alert also gained
a one-tap **SMS control room** GSM fallback that logs a custody event and works while the data
toggle is offline.

**Where.** `lib/features/excursion/excursion_push_banner.dart` ·
`lib/features/excursion/excursion_overlay.dart` · `lib/core/scenario/scenario_state.dart`
(`smsControlRoom`).

**Decisions.** D38 (amended), D49, D50.

### 18. A sync path that can fail safely

**Problem.** A queue that can only succeed is not a credible offline contract. The dossier names
pending, synced and failed, with retries and idempotent event IDs.

**Resolution.** Every capture gets an `EVT-NNN` ID shared with its custody entry. The queue adds
`failed`, a one-shot "Fail next sync" demo control arms the next promotion, failed rows offer
Retry, and delivery stays blocked until all three captures synced. Event IDs appear in the queue
sheet and the PDF capture-verification table; they are presented as retry identity, never as
tamper evidence.

**Where.** `lib/core/domain/models.dart` · `lib/core/scenario/scenario_state.dart` (`_syncStep`,
`retryItem`, `armSyncFailure`) · `lib/shared/widgets/sync_queue_sheet.dart` ·
`lib/features/client_view/audit_pdf_service.dart`.

**Decisions.** D14 (amended), D51, D52.

### 19. Four product bands without four charts

**Problem.** The dossier demos vaccine, blood, CRT and frozen ranges. Duplicating chart, readout
and PDF math per band would drift immediately.

**Resolution.** One `BandProfile` owns range, base/excursion/floor, thermal rates, axis, labels
and product copy; the chart, readout bar and PDF painter consume it. Band switching previews the
live feed only; captured records are untouched. An excursion stores the peak reading at detection
so a later preview cannot rewrite the incident. The signature step optionally records a delivery
note; the client and PDF surface logger calibration, ETA and DPDP-aligned design copy.

**Where.** `lib/core/domain/band.dart` · `lib/core/domain/temperature.dart` ·
`lib/core/domain/models.dart` (`ExcursionEvent.reading`) ·
`lib/features/client_view/client_shipment_detail.dart` · `lib/features/about/about_concept_sheet.dart`.

**Decisions.** D21 (amended), D53, D54, D55, D56, D57, D59.

## Post-review concept polish (D60–D71)

### 20. Post-signature feedback without scrolling

**Problem.** Done lived below the delivery-note chips, so shorter screens needed a scroll before
the driver could commit, and the sync count was only visible after advancing to the confirm step.
The review called both the top pilot friction.

**Resolution.** The signature step became a `Column` with a scrollable body and a sticky footer.
While the signature is open the footer is a full-width **Done**; after capture the same footer
reads "Signature captured · N of 3 synced", turns red with "Sync failed" and an inline Retry when
a promotion fails, and gives way to the auto-advance once the e-POD exists. The screen-level
primary hides until the signature is captured, and a `ref.listen` transition advances the stepper
on delivery. All four checklist rows gained 56 px thumbnails so the evidence story is consistent,
and the hint now names the tap.

**Where.** `lib/features/driver_flow/steps/signature_step.dart` (`_SignatureFooter`) ·
`lib/features/driver_flow/driver_flow_screen.dart` (`_goToStep`, `ref.listen`) ·
`lib/features/driver_flow/steps/checklist_step.dart` ·
`assets/images/logger_armed.png` · `assets/images/reefer_clean.png`.

**Decisions.** D34 (amended), D35 (amended), D60, D61, D62, D63.

### 21. One-tap report access and honest provenance

**Problem.** The audit PDF sat at the bottom of a long scrolling detail, and custody rows carried
an event ID but no actor or source — so the demo could not show *who* or *which system* produced
an entry, and an ops-initiated call would have looked identical to a driver one. The delivered
page also still called itself "Live shipment".

**Resolution.** The detail's app bar gained a PDF action that shares the bottom CTA's handler and
error path; the header consolidated into a delivery-pack card with an explicit "Final record ·
delivered HH:MM IST" line, and the title becomes "Final record" once delivered. `CustodyEvent`
gained `source` and `actor`; every construction site is tagged, with ops calls recorded as
"Control room" and sensor detections as "Sensor feed". Timeline rows expand on tap to reveal
event ID, actor and source, and the ops preview inherits the shared widget. The audit PDF
deliberately stays unchanged.

**Where.** `lib/features/client_view/client_shipment_detail.dart` (`_AuditPdfIconButton`, delivery
pack card) · `lib/core/domain/models.dart` · `lib/core/scenario/scenario_state.dart` ·
`lib/core/domain/fictional_data.dart` (custody source constants) ·
`lib/shared/widgets/call_sheet.dart` · `lib/shared/widgets/milestone_timeline.dart` ·
`lib/shared/widgets/temp_readout.dart` (`showChip`).

**Decisions.** D64, D65, D66.

### 22. An ops screen that leads with the alert

**Problem.** The ops monitor is deliberately read-only and single-truck, but the alert sat below
the map, feed health lived in a small badge, a resolved incident vanished from the top of the
screen, and the only way back to the role picker was an unlabelled home icon.

**Resolution.** While an excursion is active the banner is the first element, showing the
reading and band captured at detection, with a full-width danger Call driver. The header became a
FEED LIVE/STALE/CLOSED strip carrying the clock and a last-received or delivered stamp; a resolved
excursion leaves a compact last-alert line rendered from the stored reading. Every deep app bar now
exposes a Switch role action, and the About sheet closes with a muted presenter tip.

**Where.** `lib/features/ops_monitor/ops_monitor_screen.dart` (`_FeedStrip`, `_ExcursionBanner`) ·
the four app bars · `lib/features/about/about_concept_sheet.dart` ·
`lib/core/domain/models.dart` (`ExcursionEvent.rangeLabel`).

**Decisions.** D67, D68, D69, D70.

### 23. Coverage that marks itself

**Problem.** The offline switch was a demo control. A driver in a dead zone should never have to
remember to flip it, and a forgotten flip would make queued captures look online — or worse,
pretend a sync happened where there was no signal.

**Resolution.** The scenario owns the dead zone: ticks 47–140 (the ghat stretch to just past
Nashik) reconcile `isOffline` on every tick move, including the demo jumps, and append System
custody events on entry and exit. The manual switch and the tray toggle remain overrides that
hold between boundaries; a boundary forces its value. When coverage returns the queue drains on
its own, and the e-POD still waits for the signature. The canonical sample keeps its eight
events, so EVT numbering and the PDF contract stay stable.

**Where.** `lib/core/domain/fictional_data.dart` (`deadZoneStartTick`, `deadZoneEndTick`) ·
`lib/core/scenario/scenario_state.dart` (`inDeadZone`, `_corridorStep`, `offlineAuto`,
`setOffline`) · `test/scenario_state_test.dart` · `test/driver_flow_test.dart`.

**Decisions.** D72 (amends D71's scope wording).

## Amendment trail

Registry entries that changed during execution, kept here so the history is easy to audit.

| Decision | Amendment |
| --- | --- |
| D5 | Offline banner copy renders the live queue count instead of a fixed number |
| D9 | `CallSheet` also appends its simulated call to the custody trail |
| D14 | Sync can fail into a retryable `failed` state; delivery stays blocked until synced |
| D15 | e-POD unlock refined to signature + online + all three captures synced |
| D18 | Overlay mount point fixed for sheet context; visibility made route-based |
| D19 | Explicit `/client/live` detail route added |
| D21 | Temperature values moved into per-band profiles (vaccine curve unchanged) |
| D22 | Band rendering moved to fl_chart 1.3 `HorizontalRangeAnnotation`; axis made band-relative |
| D27 | Font licence corrected to Apache-2.0; two-page layout |
| D28 | PDF generation test added to the smoke suite |
| D34 | Every checklist row carries a thumbnail (D63) |
| D35 | Stepper auto-advances to the confirm step on e-POD generation (D62) |
| D38 | SMS fallback added beside the simulated call |
| D39 | Axis made band-relative under `BandProfile` (vaccine remains 0–10; D53) |
| D43 | Compact 10–13 px metadata labels allowed; single 36 px display readout |
| D48–D59 | v2 alignment: feed clock, push banner, SMS, event IDs, retry, bands, calibration, ETA, delivery note, DPDP copy, stored excursion reading |

# Decision registry — Algor Field (Concept)

Append-only. Every implementation decision lives here, never in code comments.
When implementation forces a new micro-decision, add a row — do not annotate code.

| ID | Decision | Rationale |
| --- | --- | --- |
| **Product & branding** | | |
| D1 | Working title "Algor Field (Concept)"; no Algor logo; palette inspired, not copied | Dossier §8.1 branding caution |
| D2 | Dark-only theme: navy `#0A2540` surface, cyan `#00C2D1` primary, teal `#0891B2`, success `#22C55E`, danger `#E5484D`, queued-amber `#F59E0B` | Control-tower look, consistent on video |
| D3 | Fictional identifiers: AWB 172-45678901 · plate MH 04 KF 4001 · driver S. Pawar · consignee "DelPharma Distribution Hub, Gurugram" · seal SL-2291 · logger LG-2214 cal. Oct 2026 | No real brands, people or plates |
| D4 | Language: "audit-trail-backed", "supports GDP documentation"; never "CDSCO-compliant"/"tamper-proof"; concept footer on every screen and every PDF page | Dossier §4/§9.7 |
| D5 | Verbatim copy: "Offline mode: highway dead zone — {n} items queued, will sync" · "Reefer 8.9 °C — outside 2–8 °C band" · "Near Nashik hub · MH 04 KF 4001" · Acknowledge / Log action / Call control room · "Download audit PDF" | Dossier §8.1. (Amended: `{n}` renders the live queue count; the canonical demo path yields 3) |
| **Platform & scope** | | |
| D6 | Android-only, minSdk 26, portrait, English-only; zero codegen; no CI, flavors or native code | Prototype floor per §6.1 |
| D7 | Zero runtime permissions: scan and push are simulated, photos are bundled, PDF leaves via the share sheet | Recording reliability and speed |
| D8 | Dependencies resolved via `flutter pub add` at latest stable: flutter_riverpod 3.5, go_router 18.1, flutter_map 8.3, latlong2, fl_chart 1.3, signature 6.4, pdf 3.13, printing 5.15, intl; dev: flutter_lints 6, flutter_launcher_icons | No version pinning in the plan |
| D9 | Dependency direction: `domain` ← `scenario` ← `features`; shared widgets are provider-free; `DemoTray` and `CallSheet` are the sole shared widgets allowed to read providers | One source of truth, testable core. (Amended: CallSheet logs its simulated call to custody) |
| **Architecture & state** | | |
| D10 | Single immutable `ScenarioState`; all transitions are pure methods; the controller owns only the timer and command dispatch; custody list is append-only | ALCOA+ story; unit-testable without widgets |
| D11 | One 1 Hz timer; 1 tick = 1 real second = 1 scenario minute. Scenario epoch 21 Nov 2026 04:15 IST = tick 0. Initial tick 45 (05:00) with 45 readings of history and a baked "Dispatched 04:15" custody event | Single clock; chart is alive on first frame |
| D12 | `TripPhase`: driving, excursionActive, excursionAcknowledged, delivered. Initial phase `driving`; milestones derive from custody events | Minimal honest enum; no dead states |
| D13 | Queue = exactly 3 capture items (checklist, scan, seal photo); the signature rides with the e-POD | Matches dossier "3 items queued" |
| D14 | Sync automatic when online; exactly one status promotion per tick (`pending → syncing → synced`); visual stagger is widget-level animation | Deterministic, animatable |
| D15 | e-POD unlock: signature captured AND (online with queue fully synced). On unlock the e-POD generates automatically and the trip becomes delivered — there is no manual "deliver" button | Matches "e-POD generated in seconds" video beat. (Refined during execution) |
| D16 | Escalation 120 s default, 30 s demo, toggled from the demo tray; expiry sets `escalated` + custody event; acknowledge remains possible | Never dead-ends; video pacing |
| D17 | Excursion guards: trigger only from `driving`; reading pinned at 8.9; acknowledge only from `excursionActive`; after ack the curve decays −0.8 °C/tick toward 4.5 | State-machine integrity |
| D18 | Excursion is an overlay, never a route; it is mounted in the shared shell above the routed child so its sheets resolve against the Navigator; visible only on the `/driver` route | Appears over any driver screen without routing hacks. (Amended twice: mount point fixed for sheet context; visibility is route-based so a stale role cannot show it over the client view) |
| D19 | go_router routes `/`, `/ops`, `/driver`, `/client` (shipment list), `/client/live`, `/client/sample`; `sampleDelivered()` factory backs the sample card and its PDF | Clean list/detail split. (Amended: explicit live-detail route added) |
| D20 | `ScenarioController({bool autoStartTicker = true})`; tests override the provider with `autoStartTicker: false` and drive `advanceTick()` manually | No real timers in tests |
| **Math** | | |
| D21 | Seed 42; noise ±0.3; base 4.2; drift +0.35 °C/tick; excursion pin 8.9; decay −0.8 °C/tick to 4.5; MKT via Arrhenius with Ea 83.144 kJ/mol, computed from the series | Deterministic runs, honest MKT |
| D22 | Chart Y-axis fixed 0–10; the 2–8 band renders via fl_chart `HorizontalRangeAnnotation` | Native API is more robust than a positioned overlay. (Amended for fl_chart 1.3) |
| **Flows & UX** | | |
| D23 | Driver stepper: one PageView, 5 steps, "Step x of 5", targets ≥ 48 dp, gated Continue | Dossier §6.2 driver-friendly UX |
| D24 | Simulated scan: tap → 1.2 s scan animation → match card. Seal photo = bundled asset + composited watermark. Signature pad is live | Zero permissions, deterministic |
| D25 | "Call control room" opens an in-app simulated sheet; never a real number, never Algor's published line | Guardrail |
| D26 | Demo tray (long-press footer): reset · offline on/off · start drift · trigger excursion · jump to out-for-delivery · jump to delivered · countdown 2:00/0:30 | §8.2 script support |
| D27 | PDF fonts: bundled Roboto Regular + Bold (Apache-2.0; the plan's OFL label was corrected), curve drawn with `pw.CustomPaint`, footer on every page, pure `(ScenarioState) → bytes` | Works for live and sample states |
| D28 | Smoke suite: temperature math, scenario state machine, driver flow widget test, PDF generation | Agreed scope plus a cheap PDF guard. (Amended during execution) |
| D29 | Comment policy: zero-comment target, ≤ 5 comments citing D-IDs, no `///`, no `// ignore:`, no TODO; this file is the sole rationale registry | Documentation-first |
| D30 | Image generation was unavailable (provider credential error at build time), so the four fictional images were produced programmatically (PIL) as concept artwork at the planned paths: `assets/images/reefer_door_seal.png`, `assets/images/precool_reefer.png`, `assets/images/signature_sample.png`, `assets/icon/af_icon.png`. Any of them can be replaced by real photos later without code changes | Build continuity; drop-in replacements |
| **Clock, jumps & canonical run** | | |
| D31 | Every displayed time uses the scenario clock (epoch + tick minutes); the ops clock chip is never wall time | Deterministic, coherent stamps |
| D32 | Demo time jumps: `triggerExcursion()` sets tick to max(tick, 130) = 06:25, near Nashik; `jumpToOutForDelivery()` sets tick to max(tick, 1050) = 21:45 with custody "Out for delivery". ETA fixed at 22:45; remaining chip computes ETA − now | Map position and alert text agree |
| D33 | Post-signature offline state reads "e-POD held locally — will send on reconnect"; on reconnect the 3 items sync, then the e-POD sends and delivers | Coherent offline story |
| D34 | Checklist rows are label + read-only reading + confirm control; pre-cool thumbnail on row 1 only; the seal number belongs to the seal-photo step exclusively | No duplicated inputs |
| D35 | Stepper navigation is buttons only (Continue/Back); PageView swipe disabled; Continue gated per step | Predictable gating |
| D36 | Seal-photo watermark = live interpolated position + scenario time + plate, e.g. "20.00° N, 73.79° E · 21 Nov 2026 06:25 IST · MH 04 KF 4001" | Geotag proof without permissions |
| D37 | "Acknowledge" acks with default reason "Driver acknowledged"; "Log action" acks with a reason code + note (note required for "Other"); both reach `excursionAcknowledged` | Fast path and evidence path |
| D38 | Call sheets (control room from excursion, driver from ops) are in-app, 2 s simulated ringing → "Connected", and append a custody event | Simulated, never dials |
| D39 | Chart window = trailing 60 readings; PDF curve = full trip downsampled to ≤ 240 points; both 0–10 fixed Y-axis | Readable curves |
| D40 | `sampleDelivered()` bakes the canonical run: excursion 06:25 → ack 06:26 (compressor reset) → out for delivery 21:45 → delivered + e-POD 21:48 | Sample and live render identical logic |
| D41 | e-POD is in-app only (no share); sharing exists solely via the client audit PDF named `algor-field-audit-172-45678901.pdf` | Agreed scope |
| D42 | Reset returns to the role picker with fresh initial state (tick 45, role cleared) | Repeatable demos |
| D43 | Typography: Material text roles for body copy; compact 10–13 px labels are allowed for chips, metadata, map captions and the footer; the 36 px w600 temperature readout is the only display size | Video legibility without a second type scale. (Amended during execution) |
| D44 | `analysis_options.yaml`: `include: package:flutter_lints/flutter.yaml` plus `strict-casts`, `strict-inference`, `strict-raw-types` | Latest analysis defaults |
| D45 | Launcher config: `flutter_launcher_icons` with `assets/icon/af_icon.png`, adaptive background `#0A2540` | On-brand icon, no logo |
| D46 | Formats via intl: `HH:mm`, `21 Nov 2026`, `4.2 °C` | Consistent display |
| D47 | Release manifest ships the normal `INTERNET` permission solely for OpenStreetMap tiles; no runtime prompt and no other permission. If tiles are unavailable the map falls back to the route grid and an "Offline map preview" note | Map keeps context online, demo still works offline |

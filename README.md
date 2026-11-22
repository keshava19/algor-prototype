# Algor Field (Concept)

A mock-data Flutter prototype for **Algor Supply Chain Solutions**: one codebase for a live
shipment monitor, an offline-first driver e-POD flow, temperature-excursion response, and a
client QA view with an audit PDF.

This is a concept prepared for Algor. It contains no live data, no connection to Algor
systems, and no client information. Vehicle, driver, consignee, seal and AWB details are
fictional.

## What is inside

- **Live Shipment Monitor** — scenario clock, temperature readout against a 2–8 °C band,
  route map (Mumbai → Nashik → Dhule → Indore → Gwalior → Agra → Delhi), ETA, custody preview,
  simulated driver call. The sensor feed can be marked stale from the demo tray; the readout,
  map and chart freeze together and show "last received".
- **Driver & e-POD** — five-step stepper: pre-trip checklist with a photo on every row, AWB
  scan, geotagged seal photo, consignee signature with an optional delivery note, e-POD
  confirmation. **Done** lives in a sticky footer that becomes a live "N of 3 synced" count;
  when the e-POD generates, the screen advances itself. Offline captures queue locally with
  unique event IDs and sync one item per second when connectivity returns; a sync can fail and
  be retried inline or from the queue. The e-POD generates automatically once the signature is
  captured, the device is online, and all three captures are synced.
- **Excursion response** — simulated push alert, overlay pinned at 8.9 °C, countdown to
  escalation, Acknowledge / Log action / Call control room / one-tap SMS fallback.
  Acknowledging starts the decay back into the band; escalation still allows acknowledgement.
- **Client QA view** — live curve with the 2–8 °C band, min/max/mean/MKT, in-band percentage,
  ETA, seal and logger-calibration badges, custody trail, e-POD card, and a one-tap audit PDF
  (full-trip curve, excursion record, custody table, signature, capture verification with event
  IDs, delivery note, concept footer on every page).
- **Multi-band preview** — vaccine 2–8, blood 1–6, controlled room temperature 15–25 and frozen
  −30…−20 °C. Chart, bar, labels and PDF share one band profile.

## Run it

Requires Flutter 3.47+ (Dart 3.13) and an Android device or emulator (minSdk 26, portrait).

```bash
flutter pub get
flutter run
```

Tests and static analysis:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Release APK:

```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

Launcher icons are generated with `dart run flutter_launcher_icons`.

## Demo controls

Long-press the concept footer on any screen to open the demo tray:

- reset to the role picker at 05:00
- offline on/off (driver evidence queue only)
- telemetry gap to freeze the sensor feed
- start a temperature drift
- trigger the 06:25 excursion near Nashik
- jump to out-for-delivery (21:45)
- jump to the canonical delivered sample (21:48)
- arm a one-shot sync failure for the retry demo
- preview vaccine, blood, CRT or frozen product bands
- switch the escalation countdown between 2:00 and 0:30

The scenario clock advances one scenario minute per real second (1 Hz). All displayed times
come from the scenario clock. See [`docs/demo-script.md`](docs/demo-script.md) for the
60-second and 3-minute scripts, and
[`docs/demo-script-layperson.md`](docs/demo-script-layperson.md) for a ~5-minute walkthrough
aimed at viewers new to cold-chain logistics. To record the 60-second cut on an emulator, follow
[`docs/video-recording-plan.md`](docs/video-recording-plan.md).

## Structure

```
lib/core/domain       fictional data, models, route interpolation, temperature math
lib/core/scenario     immutable ScenarioState, pure transitions, controller, providers
lib/core/theme        dark navy/cyan theme
lib/features          role picker, driver flow, excursion overlay, ops monitor, client view, PDF
lib/shared/widgets    provider-free presentation widgets (DemoTray and CallSheet excepted)
lib/routing           go_router shell
tools/video           emulator take script, caption track, ffmpeg render
docs/                 decisions registry, architecture contract, demo scripts, implementation notes, video recording plan
test/                 temperature, state-machine, driver-flow and PDF smoke tests
```

`docs/decisions.md` is the append-only rationale registry; `docs/architecture.md` is the
implementation contract. Code carries no explanatory comments by design.

## Data and privacy guardrails

- No real brands, people, phone numbers or plates; no Algor logo.
- No runtime permissions. The release manifest uses the normal `INTERNET` permission only for
  OpenStreetMap tiles; the map falls back to a route grid when tiles are unavailable.
- Photos are bundled concept artwork and scan/call actions are simulated.
- Language stays at "audit-trail-backed" and "supports GDP documentation"; the build does not
  claim regulatory compliance or tamper resistance. DPDP copy says "designed with DPDP
  obligations in mind".
- Event IDs exist for safe retries and traceability; they are not presented as tamper evidence.
- The concept footer appears on every screen and every PDF page.

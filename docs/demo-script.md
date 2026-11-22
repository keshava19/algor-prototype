# Demo script — Algor Field (Concept)

Two cuts: a 60-second version for LinkedIn and a ~3-minute walkthrough for a live call.
All data is simulated; the footer "Concept prepared for Algor — mock data only" stays visible
throughout.

## Pre-flight

1. Install the release APK on the recording phone and open it once while online so map tiles
   cache. Tiles are the only network dependency; the route still renders offline with the
   fallback grid.
2. Set screen brightness to maximum, font scale to default, and enable Do Not Disturb.
3. Long-press the footer to open **Demo controls**. Keep the escalation countdown at **2:00**
   for a live walkthrough, or switch to **0:30** to show escalation inside a short clip. The
   tray also previews the **product band** (vaccine, blood, CRT, frozen), the **telemetry gap**
   and a one-shot **Fail next sync**; all three are preview controls and never rewrite captured
   records.
4. Leave the app on the **Driver & e-POD** screen before triggering the excursion — the alert
   overlay is driver-only by design.
5. The scenario clock starts at **05:00** and advances one scenario minute per real second.
   Any time you linger, the clock moves. Use **Reset** between takes.

## 60-second video beats

| Time | On screen | Do this |
| --- | --- | --- |
| 0–5 s | Role picker | Open **Driver & e-POD**. Say: "A pharma truck leaves Mumbai at 4 °C; the driver is in a highway dead zone." |
| 5–16 s | Checklist | Toggle **Offline (dead zone)** on. Confirm the four rows (pre-cooled 4.0 °C, logger armed, seal intact, reefer clean). Tap **Continue**. |
| 16–22 s | Scan + seal | Tap **Tap to scan** (1.2 s animation), **Continue**; tap **Capture seal photo**, **Seal verified**, **Continue**. The banner now reads "3 items queued, will sync". |
| 22–32 s | Excursion | Long-press the footer → **Trigger excursion**. Overlay: "Reefer 8.9 °C — outside 2–8 °C band · Near Nashik hub · MH 04 KF 4001". Tap **Call control room** (rings 2 s → Connected → Close); tap **Log action**, choose **Compressor reset**, add "Compressor restarted, set-point restored", save. |
| 32–40 s | Recovery + signature | Toggle offline **off**. The three queued items sync one per second. Sign on the pad — **Done** is always in the sticky footer — and tap **Done**. The footer counts the syncs. |
| 40–46 s | e-POD | The footer reaches 3 of 3; the screen advances itself to "e-POD generated". Tap **View client view**. |
| 46–56 s | Client QA | Live shipment: delivery-pack header, temperature curve, excursion acknowledged card, custody trail. Tap **Download audit PDF** in the top bar (or the big button at the bottom); show the share sheet and filename `algor-field-audit-172-45678901.pdf`. |
| 56–60 s | Close | Say: "One Flutter codebase on top of your existing tracking data. Happy to walk Nitesh's team through the integration approach in 15 minutes." |

If the take runs long, replace the signature and delivery block with the tray's
**Jump to delivered**, then open **Client QA view → Completed sample**; it renders the
canonical run (excursion 06:25, ack 06:26, out for delivery 21:45, e-POD 21:48).

## Optional v2 beats (30–60 s)

- **Push origin (5 s).** Trigger the excursion while on the role picker or ops screen. The
  simulated heads-up card ("ALGOR FIELD · EXCURSION ALERT") arrives above the app and
  auto-dismisses; tapping it dismisses immediately. It never requests notification permission.
- **Stale feed (10 s).** In the tray enable **Telemetry gap**, close it and show the readout:
  "Stale · last received … · N min ago", with the map marker and chart frozen together while
  the scenario clock keeps moving. Disable the gap to catch up.
- **SMS fallback (5 s).** Trigger an excursion while **Offline (dead zone)** is on. Tap
  **SMS control room**: the button becomes "SMS sent · GSM fallback" and a custody event is
  logged, demonstrating the GSM path when data is weak.
- **Failed sync + retry (12 s).** Offline, capture all three items and sign. Arm **Fail next
  sync** in the tray, switch online: the next promotion turns red with an event ID. The e-POD
  stays blocked; tap **Retry** in the capture queue, then let it sync and deliver.
- **Product-band preview (10 s).** In the tray switch to **CRT 15–25** or **Frozen -30 to -20**.
  The readout, band bar, chart, client detail and PDF re-anchor; the checklist keeps its
  original captured readings. Switch back to **Vaccine 2–8** before the canonical take.

## 3-minute walkthrough

1. **Control tower (20 s).** From the role picker open **Live Shipment Monitor**. Point out the
   scenario clock, 4.2 °C readout, 2–8 °C band, route progress, ETA 22:45 and the custody
   preview. "The same data the client sees, one clock."
2. **Offline driver capture (50 s).** Open the driver flow, switch offline, confirm the
   checklist, scan the AWB (`172-45678901`), capture and verify the seal (`SL-2291`). Open the
   banner copy: "Offline mode: highway dead zone — 3 items queued, will sync."
3. **Excursion (45 s).** Long-press the footer → **Trigger excursion** (jumps to 06:25 near
   Nashik). Show 8.9 °C, the countdown ring and escalation language. Use **Call control room**
   to show the simulated call, then **Log action** to capture reason code + note. Mention that
   **Acknowledge** is the one-tap fast path.
4. **Escalation expiry (optional, 35 s).** With the countdown at 0:30, wait for "Escalated —
   control room notified" before acknowledging. The custody trail gains an escalation entry.
5. **Recovery and e-POD (40 s).** Switch online, watch the queue promote, sign, and let the
   e-POD generate automatically. "No manual deliver button; the record closes itself."
6. **Client QA and PDF (40 s).** Open **Client QA view → Live shipment**. Show the full curve,
   in-band %, MKT, excursion card and custody trail. Download the audit PDF and open it in the
   share sheet preview: shipment table, full-trip curve, excursion record, custody table, e-POD
   signature, capture verification and per-page concept footer.
7. **Canonical sample (15 s).** Back to the list → **Completed sample** shows the clean
   end-to-end run for a PDF without recording the full flow.

## Reset and fallbacks

- **Reset:** long-press footer → **Reset** → role picker with a fresh 05:00 state.
- **No map tiles:** the panel shows the route line on a grid with "Offline map preview".
- **No share target:** choose **Print** in the share sheet to preview or save the PDF.
- **Wrong role showing the alert:** the excursion overlay only appears in the driver role;
  open **Driver & e-POD** or use **Reset**.

## Language guardrails

Use "audit-trail-backed" and "supports GDP documentation". Never claim regulatory compliance,
certification or tamper resistance, and never imply a live connection to Algor systems. Describe
the app as "designed with DPDP obligations in mind" rather than DPDP-compliant. The concept
footer must remain on screen and on every PDF page.

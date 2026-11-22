# Layperson demo script — Algor Field (Concept)

A ~5-minute live walkthrough for someone with **no background in logistics, pharma or cold
chain**. Every term is explained in plain language the first time it appears. Everything on
screen is simulated.

[`demo-script.md`](demo-script.md) holds the industry-facing 60-second and 3-minute cuts.
This file is the zero-knowledge version: a short main script, optional beats for depth, and a
3-minute cut.

- **Audience:** a smart adult who has never seen a cold-chain product.
- **Format:** live, phone in hand.
- **Length:** ~5 minutes; optional beats and an extended tour follow the main script.
- **One-line story:** *One truckload of medicine crosses the country, three people watch it,
  and the whole trip becomes a signed proof document.*

## Pre-flight

1. Install the release APK and open it once while online so map tiles cache. Tiles are the
   only network dependency; offline, the route still renders on the fallback grid.
2. Set screen brightness to maximum, font scale to default, and enable Do Not Disturb.
3. Long-press the concept footer on any screen to open **Demo controls**. Keep the
   escalation countdown at **2:00**; **0:30** is only for the escalation-expiry optional beat.
4. Tap **Reset** for a fresh trip at **05:00**. The scenario clock advances one scenario
   minute per real second, so lingering moves the story; Reset is the undo button between
   takes.
5. Dry-run once. The footer long-press is your remote.

## Presenter's remote

Be upfront with the viewer that the demo has a remote; it explains the time jumps.

| Control | What it does |
| --- | --- |
| **Reset** | Returns to the role picker with a fresh 05:00 trip |
| **Offline (dead zone)** | Toggles network loss for driver evidence; captures queue locally and sync one per second on reconnect |
| **Telemetry gap (stale feed)** | Freezes the sensor feed; the readout, map and chart show "last received" and a STALE badge |
| **Start drift** | Starts a gradual temperature climb, slower than the excursion trigger |
| **Trigger excursion** | Jumps the clock to 06:25 near Nashik, pins the reading at 8.9 °C, and closes the tray |
| **Jump to out-for-delivery** | Jumps to 21:45 and opens the driver flow |
| **Jump to delivered** | Loads the canonical delivered sample (21:48) and opens the client view |
| **Fail next sync** | Arms a one-shot failure so the next queue promotion lands in `failed` and can be retried |
| **Vaccine / blood / CRT / frozen** | Previews the live feed and report band; captured records are untouched |
| **2:00 / 0:30** | Sets the escalation countdown length |

## Demo route (~5 minutes)

| Time | Screen | Beat |
| --- | --- | --- |
| 0:00–0:20 | Role picker | The story: medicine versus warmth; three pairs of eyes on one truck |
| 0:20–0:50 | Live Shipment Monitor | Clock trick, 4.2 °C inside the 2–8 °C band, map and ETA, custody diary |
| 0:50–2:05 | Driver & e-POD, offline | Offline on; checklist; AWB scan; seal photo; three captures queued |
| 2:05–3:05 | Driver & e-POD, excursion | Trigger; 8.9 °C; countdown ring; Log action and save; recovery begins |
| 3:05–3:50 | Driver & e-POD, delivery | Jump to 21:45; offline off; queue drains; viewer signs; e-POD closes itself |
| 3:50–4:40 | Client QA view and PDF | Curve, excursion card, diary, signature, audit PDF |
| 4:40–4:55 | Close | Flows are real, data is fiction; honesty footer |

## Fallbacks

- **Map tiles do not load:** the route renders on a grid with "Offline map preview"; keep
  narrating.
- **No share or PDF app:** choose **Print** in the share sheet to preview or save the PDF.
- **The red alarm does not appear:** the overlay is driver-only, or the trip is no longer in
  the driving phase. Reset, open **Driver & e-POD**, and retry.
- **Running long:** tray → **Jump to delivered** → **Client QA view** → **Completed sample**.

## Language and honesty guardrails

- Say **"every value is simulated"** up front and point at the concept footer once. It is on
  every screen and every PDF page on purpose.
- Say the app **"supports GDP documentation"** and is **"audit-trail-backed"**. Never claim
  certification, regulatory compliance or tamper resistance.
- The calls, the SMS fallback and the camera are simulated. Nothing connects to Algor systems.

## The script

**Do** cues are actions; quoted lines are spoken. Keep Say blocks short and let the screen
breathe.

### 0:00–0:20 — Opening (role picker)

**Do.** Start on a fresh **Reset**. Hold the phone so the three role cards are visible.

**Say.**

> This is a concept app for a supply-chain company called Algor — everything you will see is
> simulated, which is what the footer at the bottom says. It follows a truck full of vaccines
> from Mumbai to Delhi, and the medicine has one enemy: warmth. Three cards, three pairs of
> eyes on the same truck: the company's control room, the driver, and the medicine company
> paying the bill.

### 0:20–0:50 — Control room (Live Shipment Monitor)

**Do.** Tap **Live Shipment Monitor**. Let the clock tick a few seconds, then scroll to the
map.

**Say.**

> This is the company's air-traffic control — the red LIVE dot means the truck is being
> watched right now, and every real second here is one minute of trip time. The reading is
> 4.2 degrees, inside the green 2–8 band — fridge temperature — and the truck on the map is
> due in Delhi at 22:45. The list below is the trip's diary: every event stamped with who and
> when.

### 0:50–2:05 — Driver offline (checklist, scan, seal)

**Do.** Go home, tap **Driver & e-POD**, and flip **Offline (dead zone)** on. Tap all four
checklist rows while talking, then tap **Continue**.

**Say.**

> This is the driver's phone, heading into highway dead zones with no signal — so the app is
> built to work offline first. Everything he captures now is saved on the phone and sent
> later. The checklist: fridge pre-cooled, recorder armed, seal intact, compartment clean —
> tap, tap, tap, tap, and every row is stamped with his name and the time.

**Do.** Tap **Tap to scan**, wait for the 1.2-second animation, then **Continue**.

**Say.**

> He scans the barcode on the shipping papers — this long number is the shipment's tracking
> number, like the code on a courier parcel. Now the phone knows he is carrying the right
> load.

**Do.** Tap **Capture seal photo**, point at the watermark strip, then tap **Seal verified**
(the number SL-2291 is pre-filled).

**Say.**

> This is the truck's tamper seal — like the ring that proves a milk bottle was never opened.
> He photographs it, and the app burns the GPS location, the time and the truck's plate into
> the picture. That is three captures queued on the phone now, waiting for signal.

### 2:05–3:05 — The emergency (excursion)

**Do.** Long-press the footer, tap **Trigger excursion**. The tray closes itself and the red
overlay is already waiting, with a simulated push alert card at the top for five seconds.

**Say.**

> Full disclosure — I have a remote control: I long-pressed the footer to make something go
> wrong on purpose. Six hours in, near Nashik, the truck's fridge fails: 8.9 degrees, outside
> the safe band — and the phone gets an alert, the same way a push notification would arrive.
> The ring is a promise clock — if nobody responds in two minutes, the app escalates to the
> control room by itself.

**Do.** Tap **Log action**, leave **Compressor reset** selected, type "Compressor restarted,
set-point restored", and tap **Save acknowledgement**.

**Say.**

> The compressor is the engine that makes cold air; the driver logs a reset and a short note.
> The moment he saves, the app stamps who responded and when — and the temperature starts
> walking back down on its own.

### 3:05–3:50 — The delivery

**Do.** Open the tray, tap **Jump to out-for-delivery**, flip **Offline** off, then tap
**Continue** three times to reach **Step 4 of 5** and hand the phone to the viewer.

**Say.**

> Fast-forward to 21:45 at the delivery hub outside Delhi — and back in signal, the queue
> drains: checklist, scan, seal photo, one by one. Now you are the pharmacist receiving the
> medicine — sign with your finger.

**Do.** After they sign, optionally add a **delivery note**, then tap **Done** — it is always in
the sticky footer, no scrolling. The footer counts the captures syncing, and the screen advances
to Step 5 by itself when the e-POD is ready.

**Say.**

> And here is the detail I love: there is no "delivered" button — the moment the signature is
> in and everything has synced, the app generates the proof of delivery and closes its own
> file. That is what lets the invoice go out.

### 3:50–4:40 — Client view and PDF

**Do.** Tap **View client view**, open the top shipment card, and scroll slowly.

**Say.**

> This is the medicine company's view — and everything here was created on the driver's phone
> minutes ago. The full temperature journey with the safe band, the excursion card with the
> reason and the driver's note, the whole diary, and your signature. The stats include
> in-band — the share of the trip inside the safe zone — and MKT, an average that weighs warm
> moments more heavily.

**Do.** Tap **Download audit PDF** in the top bar (or the big button at the bottom), show the
share sheet with the filename `algor-field-audit-172-45678901.pdf`, and open the preview.

**Say.**

> One tap turns the entire trip into this PDF — full curve, incident record, diary, signature
> — and every page carries the honesty footer.

### 4:40–4:55 — Close

**Say.**

> The flows are real, the data is fiction: same trip, three screens, one record of the truth.

## Optional beats

- **Call control room:** from the alarm, show the simulated call (rings about two seconds,
  then Connected); the call is recorded in the diary.
- **SMS fallback:** with **Offline** on, tap **SMS control room**; the button becomes "SMS sent
  · GSM fallback" and the diary gains an entry — evidence that the weak-signal path works.
- **Stale feed:** enable **Telemetry gap** in the tray. The reading, map and chart freeze; the
  readout says "Stale · last received …", and the ops badge flips to STALE. Switch it off to
  catch up.
- **Failed sync:** offline, capture and sign, arm **Fail next sync**, then go online. One row
  turns red with an event ID; the e-POD waits. Tap **Retry** in the capture queue and let it
  finish.
- **Band preview:** switch the tray to **CRT 15–25** or **Frozen -30 to -20**; the readout,
  chart, client detail and PDF re-anchor, while the checklist keeps its captured readings.
  Switch back to **Vaccine 2–8** before the canonical run.
- **Escalation expiry:** set the tray countdown to **0:30**, stay silent; the alarm reads
  "Escalated — control room notified" and the diary gains an entry. Acknowledging still
  works.
- **Watch recovery:** after acknowledging, open **Client QA view** for about ten seconds and
  watch the reading fall back toward the band.
- **Canned ending:** tray → **Jump to delivered** → **Client QA view** → **Completed sample**
  for a finished trip and PDF without playing the flow.
- **About sheet:** the info icon explains what is real and what is mock data.

## Extended tour (~9 minutes)

Same script, but dwell longer and add:

- **Role picker:** linger on "three pairs of eyes" and point out the concept footer.
- **Control room:** read the map, ETA and full custody diary; tap **Call driver** once.
- **Driver:** read each checklist row aloud, show the scan animation and the seal watermark
  close-up, then open the final step's **Capture queue** list.
- **Emergency:** acknowledge with the one-tap **Acknowledge** instead of **Log action**, then
  watch the decay on the client view; or run the escalation-expiry beat.
- **Delivery:** explain the queue draining item by item and read the **Delivered** card
  ("invoice hand-off ready").
- **Client view:** explain Min, Max, In band and MKT in full; open the e-POD card and the
  custody trail.
- **Wrap:** show **Completed sample** and the **About** sheet before finishing.

## 3-minute cut

| Time | Beat |
| --- | --- |
| 0:00–0:20 | Role picker; the "fridge truck full of medicine, Mumbai to Delhi" story; open **Live Shipment Monitor**: clock trick, 4 °C inside the green band |
| 0:20–1:20 | Driver flow with offline on: tap the four checklist rows, scan, capture the seal and verify; "all queued in the dead zone" |
| 1:20–1:50 | Tray → **Trigger excursion**: 8.9 °C, countdown ring, **Log action → Compressor reset → save**; "stamped and recovering" |
| 1:50–2:35 | Offline off; tray → **Jump to out-for-delivery**; viewer signs; e-POD generates itself |
| 2:35–3:00 | **View client view**: curve, diary, signature; **Download audit PDF**; close on the honesty footer |

## Q&A cheat sheet

| Question | Answer in plain words |
| --- | --- |
| "Is this real?" | A working prototype. The screens and flows are real code; every name, number, temperature and call is fictional. Nothing touches real systems. |
| "Why 2–8 °C?" | Vaccines, insulin and many biologics survive only at fridge temperature. Too warm or frozen and the medicine may be unusable, so the whole trip is a race to keep a fridge cold. |
| "What is a reefer?" | A truck with a refrigerator built into its cargo box. A fridge on wheels. |
| "What is an AWB?" | The shipment's tracking number, like the code on a courier parcel. Here: 172-45678901. |
| "What if the driver ignores the alarm?" | After the countdown (2 minutes by default) it escalates to the control room automatically, and that is recorded too, so the incident never disappears silently. Acknowledging still works after escalation. |
| "Does the driver need signal?" | No. It is offline-first: the phone stores every capture and drips them to the server when signal returns. Delivery only completes once everything has arrived. |
| "What is MKT?" | A weighted average temperature that punishes warm spikes harder than a plain average would. |
| "What is GDP?" | Good Distribution Practice: the rulebook for moving medicine properly. The app produces the records that support that paperwork; it does not certify compliance itself. |
| "Who is this for?" | The transport company (their control room), their drivers, and the pharma client who pays for safe delivery. |
| "Why is there text at the bottom of everything?" | The honesty stamp. It keeps a concept demo from ever being mistaken for a live product. |

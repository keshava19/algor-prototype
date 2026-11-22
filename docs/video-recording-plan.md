# Video recording plan — 60-second cut (emulator)

Record the 60-second cut from [`demo-script.md`](demo-script.md) as one continuous screen
recording on the Android emulator: silent, 1080×1920, with burned-in captions. The scenario
clock advances one trip-minute per real second, so the take must be one unbroken run —
stitched segments would contradict the clock, chart and custody stamps.

Companion files: [`../tools/video/beats.ass`](../tools/video/beats.ass) (captions),
[`../tools/video/take.sh`](../tools/video/take.sh) (scripted take),
[`../tools/video/render.sh`](../tools/video/render.sh) (render).

## Pinned environment

- AVD `algor_video`: Pixel profile, **1080×1920**, `system-images;android-35;google_apis;x86_64`.
  The `google_apis` image is used instead of `google_apis_playstore` to avoid Play onboarding
  noise. The emulator has no rotation sensor, so it stays portrait.
- KVM required: `emulator -accel-check` must pass.
- Release APK: `flutter build apk --release`, installed with `adb install -r`.
- The take records on-device to `/sdcard/algor-take.mp4` and is pulled afterwards, so the host
  never owns the encoder lifecycle.

## Pre-flight (one time)

1. Create the AVD if missing:
   `avdmanager create avd -n algor_video -k "system-images;android-35;google_apis;x86_64" -d pixel`
2. Boot cold: `emulator -avd algor_video -no-snapshot -no-boot-anim`
3. Wait for `sys.boot_completed=1`, then build and install the release APK.
4. Launch the app and confirm `wm size` reports `1080x1920`.
5. Calibrate once: walk the flow with `MODE=calibrate tools/video/take.sh`, read the
   screenshots in `build/video/cal/`, and correct the coordinate constants at the top of
   `take.sh`. **Recalibrate after any UI change** — the phase-8 demo tray (Network / Actions /
   band / escalation) is scrollable and the signature step keeps Done in a sticky footer, so
   older constants are invalid. Run calibration twice; the second run
   starts from the delivered state (share sheet open) and proves the reset/retake loop.
6. Warm up: `MODE=dry tools/video/take.sh` runs the full choreography without recording. It
   validates every tap and caches the client-detail map tiles in-process. Do not kill the app
   between the dry run and the real take.

## Master timeline (1080×1920, t = raw seconds)

| t | Action | Caption |
| --- | --- | --- |
| 0.0–2.5 | Opening hold on the role picker | 1 |
| 2.5 | Tap **Driver & e-POD** | 2 |
| 3.0–4.5 | The scripted dead zone opens by itself; the amber banner appears | 2 → 3 |
| 4.5, 5.5, 6.5, 7.5 | Tap the four checklist rows | 3 |
| 8.7 | **Continue** | 4 |
| 10.0 | **Tap to scan** (1.2 s animation) | 4 |
| 11.8 | **Continue** | 4 |
| 13.0 | **Capture seal photo** | 5 |
| 13.6 | Scroll the seal step to reveal the verify button | 5 |
| 14.3 | **Seal verified** (SL-2291 is pre-filled; the note is skipped) | 5 |
| 15.3 | **Continue** to the signature step | 5 |
| 16.5 | Long-press the footer (same-point swipe, 900 ms) | 6 |
| 17.8 | **Trigger excursion** — the tray closes itself and the push banner appears | 6 |
| 18.4–20.8 | Hold on the overlay; the banner auto-dismisses about 22.8 | 7 |
| 20.8 | **Call control room** | 8 |
| 23.6 | **Close** (enabled after the 2 s ring; 0.8 s margin) | 8 |
| 24.8 | **Log action** | 9 |
| 26.0 | **Save acknowledgement** (Compressor reset is pre-selected) | 9 |
| 28.8 | The dead zone closes past Nashik; the queue drains by itself, last sync about 34.6 | 10 |
| 29.0–29.4 | Two signature strokes (400 ms each) | 10 → 11 |
| 29.8 | **Done** — sticky footer, no scroll | 11 |
| 29.8–38.0 | Hold; the footer counts 1→3 of 3 synced, the e-POD fires about 33.2, and the screen advances itself about 33.3 | 12 |
| 38.0 | **View client view** | 12 → 13 |
| 39.5 | Open the top shipment card | 13 |
| 40.9, 42.3, 43.7, 45.1 | Four slow scrolls (over-scroll is harmless) | 13 |
| 46.5 | **Download audit PDF** in the app bar (pinned while scrolled) | 14 |
| 47.0–60.0 | Hold; spinner then share sheet about 48–49 | 14 → 15 |
| 60.0 | Recording finalizes at the time limit; pull and clean up | 15 ends |

## Captions

| # | In → Out | Text |
| --- | --- | --- |
| 1 | 0.0 → 2.5 | A pharma truck leaves Mumbai at 4 °C. |
| 2 | 2.5 → 4.5 | The driver is entering a highway dead zone. |
| 3 | 4.5 → 8.7 | Offline-first — each check is stamped with who and when. |
| 4 | 8.9 → 12.4 | Scan the AWB — the shipment's tracking number. |
| 5 | 12.6 → 15.6 | Photograph the tamper seal — GPS, time and plate burned in. |
| 6 | 16.6 → 18.4 | The fridge fails: 8.9 °C. |
| 7 | 18.6 → 20.8 | Two minutes to respond — then the control room is notified. |
| 8 | 21.0 → 23.6 | Every call lands in the audit trail. |
| 9 | 24.6 → 26.6 | Log the fix — who, when, what was done. |
| 10 | 27.8 → 29.8 | Back in signal — the captures sync one by one. |
| 11 | 29.9 → 33.4 | The receiver signs on the device. |
| 12 | 33.6 → 36.5 | No "delivered" button — the e-POD closes itself. |
| 13 | 36.7 → 44.9 | The client sees everything the driver captured. |
| 14 | 45.2 → 48.8 | One tap — the full audit PDF. |
| 15 | 49.2 → 59.95 | One Flutter codebase, built on your tracking data. |

Style: white Roboto 56 with a 3 px navy `#0A2540` outline and a soft shadow, bottom-centred
with `MarginV 380` so captions clear the button row and the concept footer. The outline variant
is used because the ASS translucent-box style (`BorderStyle: 3`) did not render a visible box in
libass; the outline reads on both the dark app screens and the light share sheet. Fonts come
from `assets/fonts` via the subtitles `fontsdir` option, so no system font is required. Long
lines carry explicit `\N` breaks.

## Render

The emulator encoder records only on screen damage (VFR), so the raw file ends at the last
visual change — around 45–55 s — even though `screenrecord` runs the full 60 s. The container
may report a longer duration (the recorder's stop time), so `render.sh` takes the last frame's
timestamp, trims to it, and holds that final frame to exactly 60 s with `tpad`:

```bash
PAD=$(awk -v d="$DUR" 'BEGIN { printf "%.3f", 60 - d }')
ffmpeg -y -i build/video/take-raw.mp4 \
  -vf "tpad=stop_mode=clone:stop_duration=$PAD,subtitles=tools/video/beats.ass:fontsdir=assets/fonts" \
  -c:v libx264 -crf 18 -preset slow -movflags +faststart build/video/out.mp4
```

`render.sh` guards the input (exists, 1080×1920, 40–60.5 s) and reports the final duration.

## QA gates

After each take, extract these raw frames and read them:

| Frame | Must show |
| --- | --- |
| Raw 1.0 s | Role picker |
| Raw 5.5 s | Checklist with the offline banner |
| Raw 19.0 s | Excursion overlay at 8.9 °C with the push banner still visible |
| Raw 26.5 s | Signature step, overlay gone |
| Raw 29.9 s | Signature drawn; Done in the sticky footer, no scroll |
| Raw 33.4 s | Confirm step with "e-POD generated" and three synced event IDs (the frame is held until the client list at ~36.6 s) |
| Raw 37.0 s | Client list, "Latest shipment · Delivered" |
| Raw 47.4 s | Share sheet with `algor-field-audit-172-45678901.pdf` |
| Rendered 50 s | Held share sheet, caption above the footer |
| Rendered 58 s | Closing caption above the footer |

Any failure: fix the named constant or sleep in `take.sh`, re-run the dry run, then retake.
After rendering, check a caption frame (about 50 s) clears the button row and footer. The
screenrecord encoder writes no frames while the screen is static, so a player holds the last
frame across those gaps; when sampling with ffmpeg, pick a timestamp at or just before the
previous transition (for example 33.3 s for the confirm step) rather than the middle of a hold.

## Fallbacks

- **Map tiles blank:** the route renders on the grid with "Offline map preview". Re-run the
  dry run and retake only if the host is online; the grid is acceptable otherwise.
- **Empty share sheet:** hold on whatever the system shows; only the filename matters.
- **Alarm does not appear:** the overlay only exists on `/driver`; the reset step in
  `take.sh` returns there via the role picker.
- **Take runs long:** retake — each attempt costs exactly one minute.

## Manual take

To perform the beats by hand (for example if the emulator automation is unavailable), follow
the 60-second beats in [`demo-script.md`](demo-script.md) and the caption table above. Set the
escalation countdown to **0:30** in the demo tray for manual pacing; the scripted take does not
need it. **Done** lives in the sticky footer of the signature step on every screen height, so no
scroll is needed before committing the signature.

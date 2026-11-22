#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/build/video"
CAL="$OUT/cal"
ADB="${ADB:-adb}"
MODE="${MODE:-take}"
DEV_RAW="/sdcard/algor-take.mp4"
RAW="$OUT/take-raw.mp4"
PKG="$(sed -n 's/.*applicationId[[:space:]]*=[[:space:]]*"\(.*\)".*/\1/p' "$ROOT"/android/app/build.gradle* | head -1)"

# Coordinates for 1080x1920. Re-run `MODE=calibrate` after any UI change and update these.
FOOTER_X=540;    FOOTER_Y=1800
TRAY_RESET_X=132;   TRAY_RESET_Y=864
TRAY_TRIGGER_X=710; TRAY_TRIGGER_Y=864
ROLE_DRIVER_X=540; ROLE_DRIVER_Y=865
OFFLINE_X=960;   OFFLINE_Y=285
ROW1_X=540; ROW1_Y=851
ROW2_X=540; ROW2_Y=1087
ROW3_X=540; ROW3_Y=1323
ROW4_X=540; ROW4_Y=1550
CONTINUE_X=660;  CONTINUE_Y=1680
SCAN_X=540;      SCAN_Y=1333
SEAL_CAPTURE_X=540; SEAL_CAPTURE_Y=1470
SEAL_VERIFY_X=540;  SEAL_VERIFY_Y=1495
OVERLAY_CALL_X=540; OVERLAY_CALL_Y=1407
CALL_CLOSE_X=540;   CALL_CLOSE_Y=1731
OVERLAY_LOG_X=540;  OVERLAY_LOG_Y=1265
SAVE_ACK_X=540;     SAVE_ACK_Y=1669
SIGN1_X1=400; SIGN1_Y1=1000; SIGN1_X2=700; SIGN1_Y2=860
SIGN2_X1=430; SIGN2_Y1=1030; SIGN2_X2=760; SIGN2_Y2=930
SIGN_MS=400
DONE_X=540; DONE_Y=1520
VIEW_CLIENT_X=660; VIEW_CLIENT_Y=1680
CLIENT_CARD_X=540; CLIENT_CARD_Y=630
SCROLL_X=540; SCROLL_FROM_Y=1500; SCROLL_TO_Y=500; SCROLL_MS=400
PDF_X=765; PDF_Y=137

tap()  { "$ADB" shell input tap "$1" "$2" >/dev/null; }
press() { "$ADB" shell input swipe "$1" "$2" "$1" "$2" 900 >/dev/null; }
swipe() { "$ADB" shell input swipe "$1" "$2" "$3" "$4" "${5:-400}" >/dev/null; }
shot() { "$ADB" exec-out screencap -p > "$CAL/$1.png"; }
back() { "$ADB" shell input keyevent 4 >/dev/null; }

booted() { [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; }
at() {
  local now target d ms
  ms=$(awk -v t="$1" 'BEGIN { printf "%d", t * 1000 }')
  now=$(date +%s%3N)
  target=$(( T0 + ms ))
  d=$(( target - now ))
  if [ "$d" -gt 0 ]; then
    sleep "$(( d / 1000 )).$(printf '%03d' $(( d % 1000 )))"
  fi
}

preflight() {
  booted || { echo "emulator not booted"; exit 1; }
  "$ADB" shell wm size | grep -q "1080x1920" || { echo "expected wm size 1080x1920"; exit 1; }
  "$ADB" shell pm list packages | grep -qx "package:$PKG" || { echo "app not installed: $PKG"; exit 1; }
  "$ADB" shell settings put system show_touches 0 >/dev/null 2>&1 || true
  "$ADB" shell cmd notification set_dnd priority >/dev/null 2>&1 || true
  "$ADB" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
  sleep 1
}

reset_app() {
  press "$FOOTER_X" "$FOOTER_Y"
  sleep 1.2
  tap "$TRAY_RESET_X" "$TRAY_RESET_Y"
  sleep 1.2
}

check_coords() {
  local name value
  for name in TRAY_RESET_Y TRAY_TRIGGER_X TRAY_TRIGGER_Y ROLE_DRIVER_Y OFFLINE_Y \
    ROW1_Y ROW2_Y ROW3_Y ROW4_Y CONTINUE_Y SCAN_Y SEAL_CAPTURE_Y SEAL_VERIFY_Y \
    OVERLAY_CALL_Y CALL_CLOSE_Y OVERLAY_LOG_Y SAVE_ACK_Y DONE_Y VIEW_CLIENT_Y \
    CLIENT_CARD_Y PDF_Y; do
    value="${!name}"
    [ "$value" != "0" ] || { echo "unfilled coordinate: $name"; exit 1; }
  done
}

calibrate() {
  mkdir -p "$CAL"
  preflight
  reset_app
  shot 00-role-picker
  tap "$ROLE_DRIVER_X" "$ROLE_DRIVER_Y"; sleep 1.2; shot 01-driver
  tap "$OFFLINE_X" "$OFFLINE_Y"; sleep 0.8; shot 02-offline
  tap "$ROW4_X" "$ROW4_Y"; sleep 0.5
  tap "$ROW3_X" "$ROW3_Y"; sleep 0.5
  tap "$ROW2_X" "$ROW2_Y"; sleep 0.5
  tap "$ROW1_X" "$ROW1_Y"; sleep 0.8; shot 03-checklist
  tap "$CONTINUE_X" "$CONTINUE_Y"; sleep 1.2; shot 04-scan
  tap "$SCAN_X" "$SCAN_Y"; sleep 2.0; shot 05-scanned
  tap "$CONTINUE_X" "$CONTINUE_Y"; sleep 1.2; shot 06-seal
  tap "$SEAL_CAPTURE_X" "$SEAL_CAPTURE_Y"; sleep 1.2; shot 07-seal-photo
  swipe 540 1450 540 1050 350; sleep 0.8; shot 08-seal-scrolled
  tap "$SEAL_VERIFY_X" "$SEAL_VERIFY_Y"; sleep 1.2; shot 09-seal-verified
  tap "$CONTINUE_X" "$CONTINUE_Y"; sleep 1.2; shot 10-signature
  press "$FOOTER_X" "$FOOTER_Y"; sleep 1.4; shot 11-tray
  tap "$TRAY_TRIGGER_X" "$TRAY_TRIGGER_Y"; sleep 1.2; shot 12-overlay
  tap "$OVERLAY_CALL_X" "$OVERLAY_CALL_Y"; sleep 3.0; shot 13-call
  tap "$CALL_CLOSE_X" "$CALL_CLOSE_Y"; sleep 1.2; shot 14-after-call
  tap "$OVERLAY_LOG_X" "$OVERLAY_LOG_Y"; sleep 1.2; shot 15-log
  tap "$SAVE_ACK_X" "$SAVE_ACK_Y"; sleep 1.8; shot 16-acked
  tap "$OFFLINE_X" "$OFFLINE_Y"; sleep 1.5; shot 17-online
  swipe "$SIGN1_X1" "$SIGN1_Y1" "$SIGN1_X2" "$SIGN1_Y2" "$SIGN_MS"; sleep 0.3
  swipe "$SIGN2_X1" "$SIGN2_Y1" "$SIGN2_X2" "$SIGN2_Y2" "$SIGN_MS"; sleep 0.5
  shot 18-signed
  tap "$DONE_X" "$DONE_Y"; sleep 1.0; shot 19-signed-card
  sleep 2.0; shot 19b-sync-chip
  sleep 5.0; shot 20-confirm
  tap "$VIEW_CLIENT_X" "$VIEW_CLIENT_Y"; sleep 1.5; shot 21-client-list
  tap "$CLIENT_CARD_X" "$CLIENT_CARD_Y"; sleep 1.8; shot 22-client-detail
  swipe "$SCROLL_X" "$SCROLL_FROM_Y" "$SCROLL_X" "$SCROLL_TO_Y" "$SCROLL_MS"; sleep 0.4
  swipe "$SCROLL_X" "$SCROLL_FROM_Y" "$SCROLL_X" "$SCROLL_TO_Y" "$SCROLL_MS"; sleep 0.4
  swipe "$SCROLL_X" "$SCROLL_FROM_Y" "$SCROLL_X" "$SCROLL_TO_Y" "$SCROLL_MS"; sleep 0.4
  swipe "$SCROLL_X" "$SCROLL_FROM_Y" "$SCROLL_X" "$SCROLL_TO_Y" "$SCROLL_MS"; sleep 0.8
  shot 23-client-bottom
  echo "calibration screenshots in $CAL"
}

run_take() {
  local record="$1"
  preflight
  reset_app
  mkdir -p "$OUT"
  if [ "$record" = "1" ]; then
    "$ADB" shell screenrecord --time-limit 60 --bit-rate 12000000 "$DEV_RAW" &
    REC_PID=$!
  fi
  T0=$(date +%s%3N)

  at 2.5;  tap "$ROLE_DRIVER_X" "$ROLE_DRIVER_Y"
  at 3.7;  tap "$OFFLINE_X" "$OFFLINE_Y"
  at 4.5;  tap "$ROW4_X" "$ROW4_Y"
  at 5.5;  tap "$ROW3_X" "$ROW3_Y"
  at 6.5;  tap "$ROW2_X" "$ROW2_Y"
  at 7.5;  tap "$ROW1_X" "$ROW1_Y"
  at 8.7;  tap "$CONTINUE_X" "$CONTINUE_Y"
  at 10.0; tap "$SCAN_X" "$SCAN_Y"
  at 11.8; tap "$CONTINUE_X" "$CONTINUE_Y"
  at 13.0; tap "$SEAL_CAPTURE_X" "$SEAL_CAPTURE_Y"
  at 13.6; swipe 540 1450 540 1050 350
  at 14.3; tap "$SEAL_VERIFY_X" "$SEAL_VERIFY_Y"
  at 15.3; tap "$CONTINUE_X" "$CONTINUE_Y"
  at 16.5; press "$FOOTER_X" "$FOOTER_Y"
  at 17.8; tap "$TRAY_TRIGGER_X" "$TRAY_TRIGGER_Y"
  at 20.8; tap "$OVERLAY_CALL_X" "$OVERLAY_CALL_Y"
  at 23.6; tap "$CALL_CLOSE_X" "$CALL_CLOSE_Y"
  at 24.8; tap "$OVERLAY_LOG_X" "$OVERLAY_LOG_Y"
  at 26.0; tap "$SAVE_ACK_X" "$SAVE_ACK_Y"
  at 27.8; tap "$OFFLINE_X" "$OFFLINE_Y"
  at 29.0; swipe "$SIGN1_X1" "$SIGN1_Y1" "$SIGN1_X2" "$SIGN1_Y2" "$SIGN_MS"
  at 29.4; swipe "$SIGN2_X1" "$SIGN2_Y1" "$SIGN2_X2" "$SIGN2_Y2" "$SIGN_MS"
  at 29.8; tap "$DONE_X" "$DONE_Y"
  at 35.8; tap "$VIEW_CLIENT_X" "$VIEW_CLIENT_Y"
  at 37.3; tap "$CLIENT_CARD_X" "$CLIENT_CARD_Y"
  at 38.7; swipe "$SCROLL_X" "$SCROLL_FROM_Y" "$SCROLL_X" "$SCROLL_TO_Y" "$SCROLL_MS"
  at 40.1; swipe "$SCROLL_X" "$SCROLL_FROM_Y" "$SCROLL_X" "$SCROLL_TO_Y" "$SCROLL_MS"
  at 41.5; swipe "$SCROLL_X" "$SCROLL_FROM_Y" "$SCROLL_X" "$SCROLL_TO_Y" "$SCROLL_MS"
  at 42.9; swipe "$SCROLL_X" "$SCROLL_FROM_Y" "$SCROLL_X" "$SCROLL_TO_Y" "$SCROLL_MS"
  at 44.3; tap "$PDF_X" "$PDF_Y"

  if [ "$record" = "1" ]; then
    at 60.0
    wait "$REC_PID"
    "$ADB" pull "$DEV_RAW" "$RAW" >/dev/null
    "$ADB" shell rm "$DEV_RAW" >/dev/null
    back
    echo "raw take: $RAW"
    ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$RAW"
  else
    sleep 3
    back
    echo "dry run complete; app left delivered with map tiles warmed"
  fi
}

case "$MODE" in
  calibrate) check_coords; calibrate ;;
  dry)       check_coords; run_take 0 ;;
  take)      check_coords; run_take 1 ;;
  *)         echo "usage: MODE=calibrate|dry|take tools/video/take.sh"; exit 1 ;;
esac

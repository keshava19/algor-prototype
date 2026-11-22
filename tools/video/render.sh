#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

RAW="${1:-build/video/take-raw.mp4}"
OUT="${2:-build/video/out.mp4}"
TARGET=60

[ -f "$RAW" ] || { echo "missing input: $RAW"; exit 1; }

DIMS="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$RAW")"
[ "$DIMS" = "1080x1920" ] || { echo "expected 1080x1920, got $DIMS"; exit 1; }

DUR="$(ffprobe -v error -select_streams v:0 -show_entries frame=pts_time -of csv=p=0 "$RAW" | tail -1)"
awk -v d="$DUR" 'BEGIN { exit !(d >= 40 && d <= 60.5) }' || { echo "visual duration $DUR s outside 40-60.5 s (screenrecord stopped early?)"; exit 1; }

PAD="$(awk -v d="$DUR" -v t="$TARGET" 'BEGIN { printf "%.3f", t - d }')"

ffmpeg -y -i "$RAW" \
  -vf "trim=duration=$DUR,tpad=stop_mode=clone:stop_duration=$PAD,subtitles=tools/video/beats.ass:fontsdir=assets/fonts" \
  -c:v libx264 -crf 18 -preset slow -movflags +faststart \
  "$OUT"

OUT_DUR="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$OUT")"
echo "rendered: $OUT (${OUT_DUR}s)"

#!/usr/bin/env bash
# Boots an iPhone and an iPad simulator, launches Daybook with demo data in
# each theme and on each tab, and saves a screenshot of every combination.
set -euo pipefail
APP="$1"
OUT="$2"
BUNDLE=com.aaron.daybook
mkdir -p "$OUT"

pick() {
  xcrun simctl list devices available -j |
    jq -r --arg re "$1" '[.devices | to_entries[] | select(.key | test("iOS")) | .value[] | select(.name | test($re))] | last | .udid'
}

shoot_device() {
  local udid="$1" label="$2"
  xcrun simctl boot "$udid" || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 || true
  xcrun simctl install "$udid" "$APP"

  for theme in paper bold retro; do
    for tab in 0 1 2 3 4; do
      xcrun simctl terminate "$udid" "$BUNDLE" 2>/dev/null || true
      xcrun simctl launch "$udid" "$BUNDLE" -theme "$theme" -startTab "$tab" -demoData YES >/dev/null
      sleep 5
      xcrun simctl io "$udid" screenshot "$OUT/$label-$theme-$tab.png" >/dev/null
    done
  done

  for page in focus breathe settings; do
    xcrun simctl terminate "$udid" "$BUNDLE" 2>/dev/null || true
    xcrun simctl launch "$udid" "$BUNDLE" -theme paper -startTab 4 -startPage "$page" -demoData YES >/dev/null
    sleep 4
    xcrun simctl io "$udid" screenshot "$OUT/$label-paper-more-$page.png" >/dev/null
  done
  xcrun simctl shutdown "$udid" || true
}

PHONE=$(pick '^iPhone 1[0-9] Pro$')
[ "$PHONE" = "null" ] && PHONE=$(pick '^iPhone')
PAD=$(pick '^iPad Pro 11')
[ "$PAD" = "null" ] && PAD=$(pick '^iPad')
echo "iPhone: $PHONE  iPad: $PAD"

shoot_device "$PHONE" iphone
shoot_device "$PAD" ipad
ls "$OUT"

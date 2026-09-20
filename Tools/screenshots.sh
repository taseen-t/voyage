#!/bin/sh
# Capture every screen in both themes. Uses the DEBUG launch arguments in
# AppModel rather than tapping through: twelve launches is sixty taps
# otherwise, and a tap landing a pixel off captures the wrong screen without
# saying so.
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
app=$("$root/Tools/build.sh")
udid=$(xcrun simctl list devices available -j | python3 -c "
import json,sys
for r, ds in sorted(json.load(sys.stdin)['devices'].items()):
    for d in ds:
        if d['name'] == '${VOYAGE_SIM:-iPhone 17 Pro}': print(d['udid']); raise SystemExit
")
out="$root/Screenshots"
mkdir -p "$out"
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl install "$udid" "$app"

shoot() { # name, settle-seconds, then launch args
    name=$1; settle=$2; shift 2
    xcrun simctl terminate "$udid" com.voyage.app 2>/dev/null || true
    xcrun simctl launch "$udid" com.voyage.app "$@" >/dev/null
    sleep "$settle"
    xcrun simctl io "$udid" screenshot --type=png "$out/$name.png" >/dev/null 2>&1
    echo "  $name"
}

for theme in light dark; do
    xcrun simctl ui "$udid" appearance "$theme"
    echo "$theme:"
    shoot "$theme-1-splash"      0.9 -voyageTheme "$theme" -voyageStep splash
    shoot "$theme-2-onboarding1" 2.2 -voyageTheme "$theme" -voyageStep onboarding -voyagePage 0
    shoot "$theme-3-onboarding2" 2.2 -voyageTheme "$theme" -voyageStep onboarding -voyagePage 1
    shoot "$theme-4-onboarding3" 2.2 -voyageTheme "$theme" -voyageStep onboarding -voyagePage 2
    shoot "$theme-5-auth"        2.2 -voyageTheme "$theme" -voyageStep auth
    shoot "$theme-6-home"        2.2 -voyageTheme "$theme" -voyageStep home
    shoot "$theme-7-past"        2.2 -voyageTheme "$theme" -voyageStep home -voyageTab past
    shoot "$theme-8-detail"      2.4 -voyageTheme "$theme" -voyageRoute detail
    shoot "$theme-9-flights"     2.4 -voyageTheme "$theme" -voyageRoute flights
    shoot "$theme-10-newtrip"    2.4 -voyageTheme "$theme" -voyageRoute new
    shoot "$theme-11-stays"      2.4 -voyageTheme "$theme" -voyageRoute stays
    shoot "$theme-12-budget"     2.4 -voyageTheme "$theme" -voyageRoute budget
    shoot "$theme-13-documents"  2.4 -voyageTheme "$theme" -voyageRoute docs
    shoot "$theme-14-profile"    2.4 -voyageTheme "$theme" -voyageRoute profile
    shoot "$theme-15-saved"      2.4 -voyageTheme "$theme" -voyageRoute saved
done
echo "wrote $(ls "$out" | wc -l | tr -d ' ') screenshots to Screenshots/"

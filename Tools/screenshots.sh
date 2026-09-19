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
        if d['name'] == '${SONDER_SIM:-iPhone 17 Pro}': print(d['udid']); raise SystemExit
")
out="$root/Screenshots"
mkdir -p "$out"
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl install "$udid" "$app"

shoot() { # name, settle-seconds, then launch args
    name=$1; settle=$2; shift 2
    xcrun simctl terminate "$udid" com.sonder.app 2>/dev/null || true
    xcrun simctl launch "$udid" com.sonder.app "$@" >/dev/null
    sleep "$settle"
    xcrun simctl io "$udid" screenshot --type=png "$out/$name.png" >/dev/null 2>&1
    echo "  $name"
}

for theme in light dark; do
    xcrun simctl ui "$udid" appearance "$theme"
    echo "$theme:"
    shoot "$theme-1-splash"      0.9 -sonderTheme "$theme" -sonderStep splash
    shoot "$theme-2-onboarding1" 2.2 -sonderTheme "$theme" -sonderStep onboarding -sonderPage 0
    shoot "$theme-3-onboarding2" 2.2 -sonderTheme "$theme" -sonderStep onboarding -sonderPage 1
    shoot "$theme-4-onboarding3" 2.2 -sonderTheme "$theme" -sonderStep onboarding -sonderPage 2
    shoot "$theme-5-auth"        2.2 -sonderTheme "$theme" -sonderStep auth
    shoot "$theme-6-home"        2.2 -sonderTheme "$theme" -sonderStep home
    shoot "$theme-7-past"        2.2 -sonderTheme "$theme" -sonderStep home -sonderTab past
    shoot "$theme-8-detail"      2.4 -sonderTheme "$theme" -sonderRoute detail
    shoot "$theme-9-flights"     2.4 -sonderTheme "$theme" -sonderRoute flights
    shoot "$theme-10-newtrip"    2.4 -sonderTheme "$theme" -sonderRoute new
    shoot "$theme-11-stays"      2.4 -sonderTheme "$theme" -sonderRoute stays
    shoot "$theme-12-budget"     2.4 -sonderTheme "$theme" -sonderRoute budget
    shoot "$theme-13-documents"  2.4 -sonderTheme "$theme" -sonderRoute docs
    shoot "$theme-14-profile"    2.4 -sonderTheme "$theme" -sonderRoute profile
    shoot "$theme-15-saved"      2.4 -sonderTheme "$theme" -sonderRoute saved
done
echo "wrote $(ls "$out" | wc -l | tr -d ' ') screenshots to Screenshots/"

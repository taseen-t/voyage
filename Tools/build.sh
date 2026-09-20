#!/bin/sh
# Build Voyage for the simulator.
#
# Derived data deliberately lives OUTSIDE the project. This repository sits on
# the Desktop, which is synced by iCloud Drive, and the file provider stamps
# `com.apple.FinderInfo` onto the built .app — which codesign then refuses:
#
#   Voyage.app: resource fork, Finder information, or similar detritus not allowed
#   Command CodeSign failed with a nonzero exit code
#
# It fails *after* a clean compile, so it reads as a code error rather than a
# filesystem one, and it is intermittent because it depends on when iCloud
# happens to walk the directory. Building outside the synced tree removes the
# cause rather than racing it.
#
# The destination is resolved to a UDID rather than passed as a name: a name
# matching no available runtime makes xcodebuild fall back to My Mac and report
# a platform mismatch, which says nothing about the real problem.
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
want=${VOYAGE_SIM:-iPhone 17 Pro}
derived=${VOYAGE_DERIVED:-$HOME/Library/Developer/Xcode/DerivedData/Voyage-build}

udid=$(xcrun simctl list devices available -j | python3 -c "
import json,sys
want = sys.argv[1]
for runtime, devices in sorted(json.load(sys.stdin)['devices'].items()):
    for dev in devices:
        if dev['name'] == want:
            print(dev['udid']); raise SystemExit
raise SystemExit(f'no available simulator named {want!r}')
" "$want")

xattr -cr "$root" 2>/dev/null || true
xcodebuild -project "$root/Voyage.xcodeproj" -scheme Voyage \
    -destination "id=$udid" -derivedDataPath "$derived" "$@" build >/dev/null

echo "$derived/Build/Products/Debug-iphonesimulator/Voyage.app"

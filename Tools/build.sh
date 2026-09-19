#!/bin/sh
# Build for the simulator.
#
# The `xattr -cr` is not incidental. Files written into a folder on the Desktop
# pick up extended attributes from macOS, and codesign refuses a bundle that
# carries them ("resource fork, Finder information, or similar detritus not
# allowed") — after the compile has already succeeded, which makes it look like
# a code error rather than a filesystem one.
#
# The destination is resolved to a UDID rather than passed as a name: a name
# that matches no available runtime makes xcodebuild fall back to My Mac and
# report a platform mismatch, which says nothing about the real problem.
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
want=${SONDER_SIM:-iPhone 17 Pro}

udid=$(xcrun simctl list devices available -j | python3 -c "
import json,sys
want = sys.argv[1]
d = json.load(sys.stdin)['devices']
for runtime, devices in sorted(d.items()):
    for dev in devices:
        if dev['name'] == want:
            print(dev['udid']); raise SystemExit
raise SystemExit(f'no available simulator named {want!r}')
" "$want")

echo "building for $want ($udid)"
xattr -cr "$root" 2>/dev/null || true
xcodebuild -project "$root/Sonder.xcodeproj" -scheme Sonder \
    -destination "id=$udid" -derivedDataPath "$root/build" "$@" build

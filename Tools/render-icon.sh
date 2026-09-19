#!/bin/sh
# The app icon is generated, never hand-drawn, so it always matches the mark in
# Sonder/Design/MarkGeometry.swift. Re-run after changing that file.
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
swiftc -O -sdk "$(xcrun --show-sdk-path --sdk macosx)" \
    "$root/Sonder/Design/MarkGeometry.swift" \
    "$root/Tools/RenderIcon.swift" \
    -o "$tmp/render-icon"
"$tmp/render-icon" "$root/Sonder/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
rm -rf "$tmp"

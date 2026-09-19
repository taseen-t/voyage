#!/bin/sh
# Regenerate the app icon and the in-app mark from Art/sonder-mark-source.png.
exec python3 "$(dirname "$0")/render-icon.py"

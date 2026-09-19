# Sonder

A native iOS trip planner, built in SwiftUI from a twelve-screen design — six
screens in light and dark — with **no third-party dependencies at all**.

![Sonder, light and dark](Screenshots/contact-sheet.png)

> **Every trip, one place.** Flights, stays, itineraries and budgets, instead
> of a dozen browser tabs and a camera roll full of screenshots.

## Running it

```sh
Tools/build.sh                 # build for the simulator
Tools/screenshots.sh           # capture every screen in both themes
Tools/render-icon.sh           # regenerate the app icon from the mark
```

Xcode 16+, iOS 17+, iPhone portrait. No packages to resolve, no API keys, no
network calls — it runs offline on a clean machine.

## What is interesting in here

**Colour is declared as light/dark pairs on one line each.**

```swift
static let control = Pair(light: 0x1D1E21, dark: 0xF6F6F7)
```

The primary control is always the *inverse* of the page — near-black on the
light theme, near-white on the dark. Keeping both values adjacent is what stops
one theme being updated without the other.

**The app icon is generated from the same geometry the app draws.**
`Design/MarkGeometry.swift` imports CoreGraphics only, so `Tools/render-icon.sh`
compiles the very same paths the splash screen renders. The icon cannot drift
away from the mark.

**The mark itself was recovered, not traced.** It exists in the source design at
65×65 px — too small to upscale to 1024. So the tile was thresholded into a
mask and the cubic path whose stroke best covers it was searched for, reaching
an intersection-over-union of 0.76. Judging the shape by eye had produced
something measurably wrong twice.

**Photography ships at the size it is displayed.** Twelve CC0 destinations, as
1020×850 cards and 240×240 tiles — 1.7 MB in total, against roughly 90 MB of
originals. Nothing is resampled at runtime. Provenance for every image is in
[`CREDITS.json`](CREDITS.json).

**Screens are captured through debug launch arguments**, not by tapping:

```sh
-sonderStep onboarding -sonderPage 2
```

Twelve launches instead of sixty taps, and a tap landing a pixel off cannot
silently photograph the wrong screen.

## Layout

```
Sonder/
  App/        @main, the step machine, the one observable model
  Design/     colour, type, controls, haptics, mark geometry
  Models/     Destination (the image seam), Trip
  Components/ AppMark, TripCard
  Screens/    one file per screen
Tools/        build, screenshots, icon rendering, vault link check
```

## What is not real yet

There is no backend, no account and no session. The auth screen validates an
email's shape and continues; Google and Apple are not wired; `+`, the open
arrow and "Book a Flight" are controls without destinations. The full list is
honest and kept up to date in `Sonder open items` — see below.

## Documentation

Sonder's notes live in an Obsidian vault at `~/Desktop/Obsidian/Claude Apps`,
in one graph alongside two other projects, so the lessons are shared rather
than learned three times:

- **Sonder** — the hub
- **Sonder architecture** · **Sonder design system** · **Sonder mark** ·
  **Sonder photography** · **Sonder screens** · **Sonder open items**

`Tools/check-vault-links.py` asserts every wikilink in that vault resolves.

## Licence

Code: see the repository owner. Photography: CC0 — see
[`CREDITS.json`](CREDITS.json).

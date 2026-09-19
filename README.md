# Sonder

A native iOS trip planner, built in SwiftUI from a twelve-screen design and
carried on into the screens that design implies — **eleven screens, each in
light and dark**, with **no third-party dependencies at all**.

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

**The icon and the in-app mark come from one file.** `Tools/render-icon.py`
crops the supplied logo out of its white canvas, fills the rounded corners back
in with the tile's own colour, and writes a 1024px icon and a 640px in-app
asset. Both are full-bleed squares — iOS masks the icon itself, and an icon
that rounds its own corners shows a hairline of background inside that mask.

**The card deck deals in.** Five trip cards start further off the left edge
than a card is wide, fly in on staggered springs, and land fanned over the mark
with the front card nearest centre — so no card is ever caught half-entering at
the screen edge, and the eye finishes where the copy begins.

**Photography ships at the size it is displayed.** Twelve CC0 destinations, as
1020×850 cards and 240×240 tiles — 1.7 MB in total, against roughly 90 MB of
originals. Nothing is resampled at runtime. Provenance for every image is in
[`CREDITS.json`](CREDITS.json).

**Screens are captured through debug launch arguments**, not by tapping:

```sh
-sonderStep onboarding -sonderPage 2
-sonderRoute flights
```

Twenty-two launches instead of a hundred-odd taps, and a tap landing a pixel
off cannot silently photograph the wrong screen.

**Flights and itineraries are generated from a seed derived from the trip**, so
the same trip always offers the same options. A results list that reshuffles on
every open makes "the one I saw a minute ago" impossible to find again.

## Layout

```
Art/          the supplied logo, the source the icon is derived from
Sonder/
  App/        @main, the step machine, the one observable model
  Design/     colour, type, controls, haptics
  Models/     Destination (the image seam), Trip, Flight, Itinerary
  Components/ AppMark, TripCard
  Screens/    one file per screen
Tools/        build, screenshots, icon rendering, vault link check
```

## What is not real yet

Every control goes somewhere; none of them reaches a server, because there is
no server. The auth screen validates an email's shape and continues, Google and
Apple are not wired, flight results are generated rather than searched, and
nothing but the onboarding flag survives a relaunch. Selecting a flight saves
it to the trip rather than buying it, and the screen says so — a checkout that
appears to charge someone is worse than an honest dead end.

The full list is kept honest in `Sonder open items` — see below.

## Documentation

Sonder's notes live in an Obsidian vault at `~/Desktop/Obsidian/Claude Apps`,
in one graph alongside two other projects, so the lessons are shared rather
than learned three times:

- **Sonder** — the hub
- **Sonder architecture** · **Sonder design system** · **Sonder mark** ·
  **Sonder motion** · **Sonder photography** · **Sonder screens** ·
  **Sonder open items**

`Tools/check-vault-links.py` asserts every wikilink in that vault resolves.

## Licence

Code: see the repository owner. Photography: CC0 — see
[`CREDITS.json`](CREDITS.json).

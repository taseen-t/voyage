#!/usr/bin/env python3
"""Derive the app icon and the in-app mark from the source artwork.

`Art/sonder-mark-source.png` is the supplied logo: the tile sits on a white
canvas with its own rounded corners. Neither output wants that white.

  * The **app icon** must be full-bleed and square. iOS applies the home screen
    mask itself, and an icon that rounds its own corners shows a hairline of
    background inside that mask.
  * The **in-app mark** is clipped to a rounded rectangle by SwiftUI, so it
    wants the same full-bleed square.

So both are the tile cropped to its own bounds with the corners filled back in
using the tile's own colour — which is sampled from the artwork rather than
assumed, so re-exporting the logo in a different black needs no code change.
"""
import pathlib
import sys

import numpy as np
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "Art/sonder-mark-source.png"
ICON = ROOT / "Sonder/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
MARK = ROOT / "Sonder/Assets.xcassets/mark.imageset/mark.png"

# The tile's corner radius as a fraction of its side, measured off the artwork.
CORNER = 0.223


def main() -> int:
    if not SOURCE.exists():
        print(f"no artwork at {SOURCE}", file=sys.stderr)
        return 2

    im = Image.open(SOURCE).convert("RGB")

    # Find the tile: the dark mass inside the white canvas.
    grey = np.asarray(im.convert("L"), dtype=int)
    ys, xs = np.where(grey < 120)
    box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    tile = im.crop(box)
    side = min(tile.size)
    tile = tile.crop((0, 0, side, side))

    # The tile's base colour. Sampling a fixed point is unreliable — the swoosh
    # sweeps to all four edges — so take the most common of the darkest tones,
    # which is the tile itself rather than the swoosh sitting on it.
    px = np.asarray(tile).reshape(-1, 3)
    darkest = px[px.sum(axis=1) < np.percentile(px.sum(axis=1), 40)]
    fill = tuple(int(v) for v in np.median(darkest, axis=0).round())

    # Paint the rounded corners back in, so the square bleeds to its edges.
    # Inset by a few pixels: the artwork's corner is antialiased against white,
    # and a mask drawn on the exact boundary keeps those part-white pixels,
    # leaving a pale ghost of the original corner inside the filled square.
    bleed = max(3, round(side * 0.004))
    mask = Image.new("L", (side, side), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (bleed, bleed, side - 1 - bleed, side - 1 - bleed),
        radius=int(side * CORNER), fill=255
    )
    flat = Image.new("RGB", (side, side), fill)
    flat.paste(tile, (0, 0), mask)

    for path, px in ((ICON, 1024), (MARK, 640)):
        path.parent.mkdir(parents=True, exist_ok=True)
        flat.resize((px, px), Image.LANCZOS).save(path, "PNG", optimize=True)
        print(f"wrote {path.relative_to(ROOT)}  {px}x{px}  tile #{fill[0]:02X}{fill[1]:02X}{fill[2]:02X}")

    (MARK.parent / "Contents.json").write_text(
        '{\n  "images" : [\n    { "filename" : "mark.png", "idiom" : "universal", "scale" : "3x" }\n  ],\n'
        '  "info" : { "author" : "xcode", "version" : 1 }\n}\n'
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

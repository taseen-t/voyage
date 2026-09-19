import CoreGraphics

/// The Sonder mark: a swoosh, a compass bezel, and a needle.
///
/// Defined once in a unit square and scaled by whoever draws it. This file
/// imports **CoreGraphics only** — no SwiftUI, no UIKit — so the command line
/// tool that renders the app icon (`Tools/RenderIcon.swift`) compiles the very
/// same geometry the app draws on screen. The icon and the splash therefore
/// cannot drift apart.
///
/// The composition constants live here too, for the same reason: a mark whose
/// proportions are re-typed at each call site is a mark with three versions.
public enum SonderMark {

    // MARK: Composition

    /// Stroke weight of the swoosh, as a fraction of the tile's side. It is
    /// heavy on purpose — the swoosh reads as a mass, not a line.
    public static let swooshWidth: CGFloat = 0.156

    /// Centre of the bezel, and its radius, as fractions of the tile.
    public static let bezelCentre = CGPoint(x: 0.500, y: 0.475)
    public static let bezelRadius: CGFloat = 0.176
    public static let bezelWidth: CGFloat = 0.020
    /// The bezel is filled before it is stroked, so the needle sits on a clean
    /// disc rather than on whatever part of the swoosh happens to pass behind.
    public static let bezelFillInset: CGFloat = 0.012

    /// The needle's box, centred on the bezel.
    public static let needleSize: CGFloat = 0.155

    // MARK: Tones

    /// Near-black, not black: the tile keeps a little warmth against a pure
    /// white home screen, and gives the swoosh somewhere to sit.
    public static let tile: UInt32 = 0x0D0D0E
    /// Barely lighter than the tile. The swoosh is meant to be *found*, not
    /// announced — raising this contrast is the fastest way to lose the mark.
    public static let swoosh: UInt32 = 0x333336
    public static let bezel: UInt32 = 0x4C4C50
    public static let needle: UInt32 = 0x525258

    // MARK: Paths

    /// The swoosh — a wide `S`, stroked as an open path so its weight stays
    /// even through the curves instead of thinning where they tighten.
    ///
    /// These control points are **fitted, not drawn**. The mark exists in the
    /// source design at 65 px, far too small to upscale into a 1024 px icon, so
    /// the shape was recovered instead: threshold that tile into a swoosh mask
    /// and search for the stroke that best covers it. The fit reaches an
    /// intersection-over-union of 0.76 against the original.
    ///
    /// Several points sit outside the unit square. That is deliberate — the
    /// swoosh bleeds off all four edges in the design, so its caps are meant to
    /// fall outside the tile and be clipped by it.
    public static func swoosh(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        let p = { (x: CGFloat, y: CGFloat) in
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        path.move(to: p(-0.140, 0.548))
        path.addCurve(to: p(1.287, 0.064),
                      control1: p(0.233, -0.152), control2: p(0.893, 0.190))
        path.addCurve(to: p(0.572, 0.479),
                      control1: p(0.989, 0.249), control2: p(1.206, 0.525))
        path.addCurve(to: p(-0.168, 0.918),
                      control1: p(0.353, 0.654), control2: p(-0.011, 0.239))
        path.addCurve(to: p(1.083, 0.327),
                      control1: p(0.125, 0.914), control2: p(1.097, 1.028))
        return path
    }

    /// The needle — the location arrow, pointing up and to the left. Concave at
    /// the base, which is what separates a compass needle from a plain triangle
    /// once it is only a few points across.
    public static func needle(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        let p = { (x: CGFloat, y: CGFloat) in
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        path.move(to: p(0.140, 0.140))   // tip
        path.addLine(to: p(0.830, 0.455)) // trailing wing
        path.addLine(to: p(0.520, 0.520)) // the notch, on the arrow's own axis
        path.addLine(to: p(0.455, 0.830)) // leading wing
        path.closeSubpath()
        return path
    }

    /// Corner radius of the tile, as a fraction of its side — close enough to
    /// the iOS home screen squircle that the system mask is invisible.
    public static let tileCornerFraction: CGFloat = 0.2237
}

import SwiftUI

/// The app mark, drawn from the geometry in `SonderMark` — the same paths the
/// icon renderer compiles. Sizes are all fractions of `side`, so the mark is
/// identical at 44pt on the splash and at 210pt behind the onboarding cards.
struct AppMark: View {
    var side: CGFloat
    /// The splash and the onboarding hero draw the mark on its own tile. The
    /// scatter illustration draws it without one.
    var showsTile: Bool = true

    var body: some View {
        Canvas(rendersAsynchronously: false) { ctx, size in
            let rect = CGRect(origin: .zero, size: size)

            if showsTile {
                ctx.fill(Path(rect), with: .color(Color(rgb: SonderMark.tile)))
            }

            ctx.drawLayer { layer in
                layer.clip(to: Path(rect))
                layer.stroke(
                    Path(SonderMark.swoosh(in: rect)),
                    with: .color(Color(rgb: SonderMark.swoosh)),
                    style: StrokeStyle(lineWidth: size.width * SonderMark.swooshWidth,
                                       lineCap: .round, lineJoin: .round)
                )
            }

            let centre = CGPoint(x: SonderMark.bezelCentre.x * size.width,
                                 y: SonderMark.bezelCentre.y * size.height)
            let r = size.width * SonderMark.bezelRadius
            let bezel = CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2)

            ctx.fill(
                Path(ellipseIn: bezel.insetBy(dx: size.width * SonderMark.bezelFillInset,
                                              dy: size.width * SonderMark.bezelFillInset)),
                with: .color(Color(rgb: SonderMark.tile))
            )
            ctx.stroke(Path(ellipseIn: bezel),
                       with: .color(Color(rgb: SonderMark.bezel)),
                       lineWidth: size.width * SonderMark.bezelWidth)

            let n = size.width * SonderMark.needleSize
            ctx.fill(
                Path(SonderMark.needle(in: CGRect(x: centre.x - n / 2, y: centre.y - n / 2,
                                                  width: n, height: n))),
                with: .color(Color(rgb: SonderMark.needle))
            )
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: side * SonderMark.tileCornerFraction,
                                    style: .continuous))
    }
}

#Preview {
    VStack(spacing: 24) {
        AppMark(side: 78)
        AppMark(side: 160)
    }
    .padding(40)
    .background(Color.surface)
}

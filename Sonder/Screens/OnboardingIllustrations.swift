import SwiftUI

// MARK: - Page 1 — stacked cards

/// Trip cards fanned over the mark. They run off the bottom of the frame on
/// purpose: the point is that there are more of them than fit.
struct StackedCardsIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let card = CGSize(width: w * 0.44, height: w * 0.55)

            ZStack {
                AppMark(side: w * 0.50)
                    .offset(x: w * 0.03, y: -w * 0.17)

                MiniTripCard(destination: .santorini, badge: nil, tint: nil)
                    .frame(width: card.width, height: card.height)
                    .rotationEffect(.degrees(-14))
                    .offset(x: -w * 0.38, y: w * 0.16)

                MiniTripCard(destination: .kyoto, badge: "Today", tint: .green)
                    .frame(width: card.width, height: card.height)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -w * 0.20, y: w * 0.13)

                MiniTripCard(destination: .lisbon, badge: "In 32 days", tint: nil)
                    .frame(width: card.width, height: card.height)
                    .rotationEffect(.degrees(-2))
                    .offset(x: w * 0.06, y: w * 0.10)
            }
            .frame(width: w, height: geo.size.height, alignment: .center)
        }
    }
}

/// A trip card at illustration scale. Not the real `TripCard` — at half size
/// its controls would be unreadable clutter, so this shows only what survives
/// being small: the photograph, the badge, the place and the date.
private struct MiniTripCard: View {
    let destination: Destination
    let badge: String?
    let tint: Color?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(destination.card)
                .resizable()
                .scaledToFill()

            LinearGradient(colors: [.black.opacity(0.42), .clear],
                           startPoint: .top, endPoint: .center)

            VStack(alignment: .leading, spacing: 5) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(tint ?? .black.opacity(0.42), in: Capsule())
                }
                Spacer().frame(height: 2)
                Text(destination.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Nov 12 – 19, 2026")
                    .font(.system(size: 7.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
    }
}

// MARK: - Page 2 — the route

/// A route across a schematic map. The map is drawn rather than rendered from
/// tiles: this screen is an argument about itineraries, not a map view, and a
/// real one would cost a dependency, a network call and an API key to say the
/// same thing.
struct RouteMapIllustration: View {
    /// Fractions of the frame, so the stops hold their relationship at any size.
    private let stops: [CGPoint] = [
        CGPoint(x: 0.17, y: 0.20),
        CGPoint(x: 0.82, y: 0.42),
        CGPoint(x: 0.47, y: 0.72),
    ]
    private let photos: [Destination] = [.cappadocia, .banff, .dolomites]

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Canvas { ctx, size in roads(&ctx, size) }

                Path { p in
                    let pts = stops.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
                    p.move(to: pts[0])
                    p.addLine(to: pts[1])
                    p.addLine(to: pts[2])
                    p.closeSubpath()
                }
                .stroke(Color.ink.opacity(0.85),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                ForEach(Array(stops.enumerated()), id: \.offset) { i, stop in
                    RoutePin(number: i + 1,
                             destination: photos[i],
                             side: size.width * (i == 2 ? 0.30 : 0.19))
                        .position(x: stop.x * size.width, y: stop.y * size.height)
                }
            }
        }
    }

    /// Streets. Laid out from a fixed seed so the "map" is the same every
    /// launch — a background that reshuffles itself reads as a bug.
    private func roads(_ ctx: inout GraphicsContext, _ size: CGSize) {
        var seed: UInt64 = 0x5EED
        func next() -> CGFloat {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return CGFloat((seed >> 33) % 1000) / 1000
        }
        let ink = Color.inkFaint.opacity(0.28)
        for i in 0..<9 {
            let y = (CGFloat(i) / 8) * size.height + (next() - 0.5) * 18
            var p = Path()
            p.move(to: CGPoint(x: -10, y: y))
            p.addCurve(to: CGPoint(x: size.width + 10, y: y + (next() - 0.5) * 40),
                       control1: CGPoint(x: size.width * 0.33, y: y + (next() - 0.5) * 52),
                       control2: CGPoint(x: size.width * 0.66, y: y + (next() - 0.5) * 52))
            ctx.stroke(p, with: .color(ink), lineWidth: i % 3 == 0 ? 2.4 : 1.2)
        }
        for i in 0..<7 {
            let x = (CGFloat(i) / 6) * size.width + (next() - 0.5) * 18
            var p = Path()
            p.move(to: CGPoint(x: x, y: -10))
            p.addCurve(to: CGPoint(x: x + (next() - 0.5) * 40, y: size.height + 10),
                       control1: CGPoint(x: x + (next() - 0.5) * 46, y: size.height * 0.33),
                       control2: CGPoint(x: x + (next() - 0.5) * 46, y: size.height * 0.66))
            ctx.stroke(p, with: .color(ink), lineWidth: i % 3 == 1 ? 2.4 : 1.2)
        }
    }
}

private struct RoutePin: View {
    let number: Int
    let destination: Destination
    let side: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(destination.tile)
                .resizable()
                .scaledToFill()
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: side * 0.22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
                        .stroke(.white, lineWidth: 2.5)
                )
                .shadow(color: .black.opacity(0.22), radius: 8, y: 3)

            Text("\(number)")
                .font(.system(size: side * 0.17, weight: .bold))
                .foregroundStyle(Color.surface)
                .frame(width: side * 0.29, height: side * 0.29)
                .background(Color.ink, in: Circle())
                .offset(x: -side * 0.10, y: side * 0.13)
        }
    }
}

// MARK: - Page 3 — the scatter

/// Destinations orbiting the mark. Two rings, each tile rotated a little off
/// square, so the arrangement reads as scattered rather than plotted.
struct ScatterIllustration: View {
    private struct Tile {
        let destination: Destination
        /// Clock angle in degrees, distance as a fraction of the frame's width,
        /// size as a fraction, and a small rotation.
        let angle: Double, radius: CGFloat, scale: CGFloat, tilt: Double
    }

    private let tiles: [Tile] = [
        .init(destination: .cappadocia, angle: 152, radius: 0.33, scale: 0.155, tilt: -8),
        .init(destination: .dolomites,  angle:  92, radius: 0.34, scale: 0.150, tilt:  6),
        .init(destination: .banff,      angle:  34, radius: 0.35, scale: 0.160, tilt: -4),
        .init(destination: .norway,     angle: 198, radius: 0.30, scale: 0.135, tilt: 10),
        .init(destination: .iceland,    angle: 342, radius: 0.31, scale: 0.140, tilt: -7),
        .init(destination: .hallstatt,  angle: 246, radius: 0.33, scale: 0.150, tilt:  5),
        .init(destination: .queenstown, angle: 298, radius: 0.34, scale: 0.145, tilt: -9),
        .init(destination: .fuji,       angle: 128, radius: 0.455, scale: 0.135, tilt:  7),
        .init(destination: .santorini,  angle:  58, radius: 0.455, scale: 0.140, tilt: -6),
        .init(destination: .kyoto,      angle: 222, radius: 0.455, scale: 0.130, tilt:  9),
        .init(destination: .lisbon,     angle: 316, radius: 0.455, scale: 0.135, tilt: -5),
        .init(destination: .marrakesh,  angle:   4, radius: 0.450, scale: 0.125, tilt:  8),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let centre = CGPoint(x: w / 2, y: geo.size.height / 2)

            ZStack {
                ForEach([0.30, 0.44, 0.58], id: \.self) { r in
                    Circle()
                        .stroke(Color.inkFaint.opacity(0.14), lineWidth: 1)
                        .frame(width: w * r * 2, height: w * r * 2)
                        .position(centre)
                }

                AppMark(side: w * 0.21).position(centre)

                ForEach(Array(tiles.enumerated()), id: \.offset) { _, t in
                    let a = t.angle * .pi / 180
                    Image(t.destination.tile)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w * t.scale, height: w * t.scale)
                        .clipShape(RoundedRectangle(cornerRadius: w * t.scale * 0.24,
                                                    style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: w * t.scale * 0.24,
                                             style: .continuous)
                                .stroke(.white.opacity(0.9), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 7, y: 3)
                        .rotationEffect(.degrees(t.tilt))
                        .position(x: centre.x + cos(a) * w * t.radius,
                                  y: centre.y + sin(a) * w * t.radius)
                }
            }
        }
    }
}

#Preview("Cards") { StackedCardsIllustration().frame(height: 380) }
#Preview("Route") { RouteMapIllustration().frame(height: 380) }
#Preview("Scatter") { ScatterIllustration().frame(height: 380) }

import SwiftUI

// MARK: - Page 1 — the pair

/// Two trip cards over the mark, measured off the design: each card is 62% of
/// the frame's width, they overlap in the middle, and both bleed off their own
/// edge. The mark sits large behind and above them.
///
/// They deal in from the left and run off the bottom of the frame: the point
/// is that there are more of them than fit.
struct StackedCardsIllustration: View {
    /// Driven by the parent so the deal replays whenever this page becomes
    /// visible again, rather than only on the very first appearance.
    var deal: Bool

    private struct Card {
        let destination: Destination
        let badge: String
        let green: Bool
        let dates: String
        /// Fractions of the frame's width, so the pair holds its shape at any
        /// size.
        let x: CGFloat, y: CGFloat
        let tilt: Double
    }

    /// Last in the array lands last and sits on top.
    private let cards: [Card] = [
        .init(destination: .kyoto, badge: "Today", green: true,
              dates: "Oct 3 – 10, 2026", x: -0.235, y: 0.265, tilt: -3),
        .init(destination: .lisbon, badge: "In 32 days", green: false,
              dates: "Nov 12 – 19, 2026", x: 0.205, y: 0.250, tilt: -1),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let card = CGSize(width: w * 0.62, height: w * 0.725)

            ZStack {
                AppMark(side: w * 0.72)
                    .offset(y: -w * 0.15)
                    .opacity(deal ? 1 : 0)
                    .scaleEffect(deal ? 1 : 0.92)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8), value: deal)

                ForEach(Array(cards.enumerated()), id: \.offset) { i, c in
                    MiniTripCard(destination: c.destination, badge: c.badge,
                                 tint: c.green ? Color(rgb: 0x2E9E5B) : nil, dates: c.dates)
                        .frame(width: card.width, height: card.height)
                        .rotationEffect(.degrees(deal ? c.tilt : c.tilt - 10))
                        // Off the left edge by more than a card's width, so a
                        // card is never seen part-way through its own entrance.
                        .offset(x: deal ? w * c.x : -w * 1.3,
                                y: deal ? w * c.y : w * (c.y + 0.06))
                        .opacity(deal ? 1 : 0)
                        .animation(
                            .spring(response: 0.62, dampingFraction: 0.78)
                                .delay(0.12 + Double(i) * 0.12),
                            value: deal
                        )
                }
            }
            .frame(width: w, height: geo.size.height, alignment: .center)
        }
    }
}

/// A trip card at illustration scale. Not the real `TripCard` — this one drops
/// the controls that would be unreadable clutter at this size and keeps what
/// survives: the photograph, the badge, the place, the date, and one action to
/// show that a card is a thing you act on.
///
/// The photograph is a **background**, not a sibling in a `ZStack`.
/// `scaledToFill` deliberately reports a size larger than the one it was
/// offered, so a stack containing it adopts that larger size — and an outer
/// `.frame(width:height:)` then centres an oversized card instead of shrinking
/// it. As a background it cannot affect layout at all, and the `clipShape`
/// below trims the overflow.
private struct MiniTripCard: View {
    let destination: Destination
    let badge: String
    let tint: Color?
    let dates: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(badge)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(tint ?? .black.opacity(0.42), in: Capsule())

            Spacer().frame(height: 13)

            Text(destination.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(dates)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.top, 3)

            Spacer(minLength: 8)

            Label {
                Text("Book a Flight").font(.system(size: 11, weight: .semibold))
            } icon: {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial.opacity(0.85), in: Capsule())
            .environment(\.colorScheme, .dark)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            Image(destination.card)
                .resizable()
                .scaledToFill()
        }
        .background(alignment: .top) {
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.58), location: 0.00),
                    .init(color: .black.opacity(0.34), location: 0.26),
                    .init(color: .black.opacity(0.06), location: 0.46),
                    .init(color: .clear, location: 0.58),
                ], startPoint: .top, endPoint: .bottom
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.24), radius: 14, y: 6)
    }
}

// MARK: - Page 2 — the route

/// A route across a schematic map. The map is drawn rather than rendered from
/// tiles: this screen is an argument about itineraries, not a map view, and a
/// real one would cost a dependency, a network call and an API key to say the
/// same thing.
struct RouteMapIllustration: View {
    /// Set when this page is on screen, so the route draws itself each time it
    /// is reached rather than only on the first visit.
    var draw: Bool

    /// Fractions of the frame, so the stops hold their relationship at any size.
    private let stops: [CGPoint] = [
        CGPoint(x: 0.17, y: 0.20),
        CGPoint(x: 0.82, y: 0.42),
        CGPoint(x: 0.47, y: 0.72),
    ]
    private let photos: [Destination] = [.cappadocia, .banff, .dolomites]

    /// How long the line takes to travel the whole route.
    private let duration: Double = 1.15

    /// Where each stop falls along that route, by arc length — so a pin lands
    /// exactly as the line arrives at it rather than on a guessed delay.
    private var arrivals: [Double] {
        let pts = stops + [stops[0]]
        let legs = (0..<3).map { i -> Double in
            let a = pts[i], b = pts[i + 1]
            return Double(hypot(b.x - a.x, b.y - a.y))
        }
        let total = legs.reduce(0, +)
        var running = 0.0
        return legs.map { leg in
            defer { running += leg }
            return running / total
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Canvas { ctx, size in roads(&ctx, size) }

                route(in: size)
                    .trim(from: 0, to: draw ? 1 : 0)
                    .stroke(Color.ink.opacity(0.85),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .animation(.easeInOut(duration: duration), value: draw)

                ForEach(Array(stops.enumerated()), id: \.offset) { i, stop in
                    RoutePin(number: i + 1,
                             destination: photos[i],
                             side: size.width * (i == 2 ? 0.30 : 0.19))
                        .scaleEffect(draw ? 1 : 0.6)
                        .opacity(draw ? 1 : 0)
                        .animation(
                            .spring(response: 0.42, dampingFraction: 0.68)
                                .delay(arrivals[i] * duration),
                            value: draw
                        )
                        .position(x: stop.x * size.width, y: stop.y * size.height)
                }
            }
        }
    }

    private func route(in size: CGSize) -> Path {
        Path { p in
            let pts = stops.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
            p.move(to: pts[0])
            p.addLine(to: pts[1])
            p.addLine(to: pts[2])
            p.closeSubpath()
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
    /// Set when this page is on screen, so the tiles settle each time it is
    /// reached rather than only on the first visit.
    var settle: Bool

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
        .init(destination: .marrakesh,  angle:   4, radius: 0.395, scale: 0.125, tilt:  8),
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

                AppMark(side: w * 0.21)
                    .scaleEffect(settle ? 1 : 0.86)
                    .opacity(settle ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: settle)
                    .position(centre)

                ForEach(Array(tiles.enumerated()), id: \.offset) { i, t in
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
                        .rotationEffect(.degrees(settle ? t.tilt : t.tilt - 12))
                        .scaleEffect(settle ? 1 : 0.4)
                        .opacity(settle ? 1 : 0)
                        // Ordered by ring, so the orbit fills outward.
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.72)
                                .delay(0.14 + Double(i) * 0.045),
                            value: settle
                        )
                        .position(x: centre.x + cos(a) * w * t.radius,
                                  y: centre.y + sin(a) * w * t.radius)
                }
            }
        }
    }
}

#Preview("Cards") { StackedCardsIllustration(deal: true).frame(height: 380) }
#Preview("Route") { RouteMapIllustration(draw: true).frame(height: 380) }
#Preview("Scatter") { ScatterIllustration(settle: true).frame(height: 380) }

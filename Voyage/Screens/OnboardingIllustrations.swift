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

/// Three stops pinned on a city.
///
/// The map is **drawn**, not rendered from tiles. Waka reached for MapLibre
/// because its geography is functional and had to be themed — MapKit offers no
/// stylesheet at all, only `.standard`/`.hybrid`/`.imagery`. Here the map is
/// scenery for an argument about itineraries, so a real one would cost a
/// dependency, a network call and an API key to say the same thing, and stock
/// Apple Maps would look nothing like this design.
struct RouteMapIllustration: View {
    /// Set when this page is on screen, so the route draws itself each time it
    /// is reached rather than only on the first visit.
    var draw: Bool

    /// Photo centres, as fractions of the frame.
    private let stops: [CGPoint] = [
        CGPoint(x: 0.19, y: 0.17),
        CGPoint(x: 0.78, y: 0.35),
        CGPoint(x: 0.43, y: 0.44),
    ]
    /// Pin sizes, as fractions of the frame's width. The middle stop is the
    /// one you are looking at, so it is the big one.
    private let sizes: [CGFloat] = [0.21, 0.29, 0.39]
    private let photos: [Destination] = [.cappadocia, .banff, .dolomites]

    private let duration: Double = 1.15

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                StreetMap()
                    .mask(
                        LinearGradient(stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black, location: 0.72),
                            .init(color: .clear, location: 1.0),
                        ], startPoint: .top, endPoint: .bottom)
                    )

                // Drawn before the pins, so it passes behind them.
                route(in: size)
                    .trim(from: 0, to: draw ? 1 : 0)
                    .stroke(Color.ink.opacity(0.9),
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round,
                                               lineJoin: .round))
                    .animation(.easeInOut(duration: duration), value: draw)

                ForEach(Array(stops.enumerated()), id: \.offset) { i, stop in
                    MapPin(number: i + 1, destination: photos[i],
                           side: size.width * sizes[i])
                        .scaleEffect(draw ? 1 : 0.6, anchor: .bottom)
                        .opacity(draw ? 1 : 0)
                        .animation(
                            .spring(response: 0.42, dampingFraction: 0.68)
                                .delay(arrivals[i] * duration),
                            value: draw
                        )
                        // Positioned by the photo's centre; the tail hangs below.
                        .position(x: stop.x * size.width, y: stop.y * size.height)
                }
            }
        }
    }

    /// Where a pin's tail tip falls, which is where its number sits and where
    /// the route has to meet it.
    private func tip(_ i: Int, _ size: CGSize) -> CGPoint {
        let side = size.width * sizes[i]
        return CGPoint(x: stops[i].x * size.width,
                       y: stops[i].y * size.height + side / 2 + side * MapPin.tailDrop)
    }

    /// 1 → 2 → 3, an open path: it is a route, and a route has an end.
    private func route(in size: CGSize) -> Path {
        Path { p in
            let pts = [tip(0, size), tip(1, size), tip(2, size)]
            p.move(to: pts[0])
            p.addLine(to: pts[1])
            p.addLine(to: pts[2])
        }
    }

    /// Where each stop falls along the route by arc length, so a pin lands
    /// exactly as the line reaches it rather than on a guessed delay.
    private var arrivals: [Double] {
        let unit = (0..<3).map { tip($0, CGSize(width: 1, height: 1)) }
        let legs = (0..<2).map { hypot(unit[$0 + 1].x - unit[$0].x,
                                       unit[$0 + 1].y - unit[$0].y) }
        let total = legs.reduce(0, +)
        var running = 0.0
        var out = [0.0]
        for leg in legs {
            running += leg
            out.append(running / max(total, 0.0001))
        }
        return out
    }
}

/// A flat city block plan: grey blocks, pale streets between them.
///
/// Built by splitting the frame recursively and insetting each block, so the
/// streets are the gaps. That gives an irregular, organic layout — a regular
/// grid reads as graph paper, not as a city.
private struct StreetMap: View {
    var body: some View {
        Canvas { ctx, size in
            // Streets are the ground; blocks are cut out of it.
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color.surface))

            var seed: UInt64 = 0xC17
            func rand() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat((seed >> 33) % 1000) / 1000
            }

            var blocks: [CGRect] = []
            func split(_ r: CGRect, _ depth: Int) {
                let tooSmall = r.width < size.width * 0.19 && r.height < size.width * 0.19
                if depth == 0 || tooSmall {
                    blocks.append(r); return
                }
                // Cut across the longer side, off-centre, so blocks vary.
                let t = 0.32 + rand() * 0.36
                if r.width >= r.height {
                    let x = r.minX + r.width * t
                    split(CGRect(x: r.minX, y: r.minY, width: x - r.minX, height: r.height), depth - 1)
                    split(CGRect(x: x, y: r.minY, width: r.maxX - x, height: r.height), depth - 1)
                } else {
                    let y = r.minY + r.height * t
                    split(CGRect(x: r.minX, y: r.minY, width: r.width, height: y - r.minY), depth - 1)
                    split(CGRect(x: r.minX, y: y, width: r.width, height: r.maxY - y), depth - 1)
                }
            }
            // Oversized, so the streets run off every edge rather than
            // stopping in a frame.
            split(CGRect(origin: .zero, size: size).insetBy(dx: -size.width * 0.12,
                                                            dy: -size.height * 0.12), 5)

            // A street is a fixed width. Scaling the inset with the block
            // made small blocks mostly street, which read as confetti rather
            // than as a city.
            let street = size.width * 0.011
            let block = Color.inkFaint.opacity(0.26)
            for b in blocks {
                let inset = b.insetBy(dx: street, dy: street)
                guard inset.width > 2, inset.height > 2 else { continue }
                ctx.fill(
                    Path(roundedRect: inset, cornerRadius: size.width * 0.005),
                    with: .color(block)
                )
            }
        }
    }
}

/// A photo on a map pin: rounded tile, thick collar, and a tail that points at
/// the place. The number sits on the tip, where the route meets it.
private struct MapPin: View {
    let number: Int
    let destination: Destination
    let side: CGFloat

    /// How far the tail hangs below the tile, as a fraction of `side`.
    static let tailDrop: CGFloat = 0.30

    var body: some View {
        ZStack(alignment: .top) {
            PinShape(tailDrop: Self.tailDrop)
                .fill(Color.inkFaint.opacity(0.55))
                .frame(width: side, height: side * (1 + Self.tailDrop))
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)

            Image(destination.tile)
                .resizable()
                .scaledToFill()
                .frame(width: side * 0.86, height: side * 0.86)
                .clipShape(RoundedRectangle(cornerRadius: side * 0.20,
                                            style: .continuous))
                .padding(.top, side * 0.07)
        }
        .overlay(alignment: .bottom) {
            Text("\(number)")
                .font(.system(size: side * 0.20, weight: .bold))
                .foregroundStyle(Color.surface)
                .frame(width: side * 0.34, height: side * 0.34)
                .background(Color.ink, in: Circle())
                .offset(y: side * 0.17)
        }
        // The tile is what sits at the coordinate; the tail hangs past it.
        .offset(y: side * Self.tailDrop / 2)
    }
}

/// Rounded tile with a tapering tail, as one outline — two overlapping
/// subpaths would cancel where they meet under the non-zero fill rule, which
/// is the seam Waka's map pin shipped with once.
private struct PinShape: Shape {
    let tailDrop: CGFloat

    func path(in rect: CGRect) -> Path {
        let side = rect.width
        let tile = CGRect(x: rect.minX, y: rect.minY, width: side, height: side)
        let r = side * 0.26
        let tipY = rect.maxY
        let halfMouth = side * 0.13

        var p = Path()
        p.move(to: CGPoint(x: tile.minX + r, y: tile.minY))
        p.addLine(to: CGPoint(x: tile.maxX - r, y: tile.minY))
        p.addQuadCurve(to: CGPoint(x: tile.maxX, y: tile.minY + r),
                       control: CGPoint(x: tile.maxX, y: tile.minY))
        p.addLine(to: CGPoint(x: tile.maxX, y: tile.maxY - r))
        p.addQuadCurve(to: CGPoint(x: tile.maxX - r, y: tile.maxY),
                       control: CGPoint(x: tile.maxX, y: tile.maxY))
        p.addLine(to: CGPoint(x: tile.midX + halfMouth, y: tile.maxY))
        p.addQuadCurve(to: CGPoint(x: tile.midX, y: tipY),
                       control: CGPoint(x: tile.midX + halfMouth * 0.5, y: tipY))
        p.addQuadCurve(to: CGPoint(x: tile.midX - halfMouth, y: tile.maxY),
                       control: CGPoint(x: tile.midX - halfMouth * 0.5, y: tipY))
        p.addLine(to: CGPoint(x: tile.minX + r, y: tile.maxY))
        p.addQuadCurve(to: CGPoint(x: tile.minX, y: tile.maxY - r),
                       control: CGPoint(x: tile.minX, y: tile.maxY))
        p.addLine(to: CGPoint(x: tile.minX, y: tile.minY + r))
        p.addQuadCurve(to: CGPoint(x: tile.minX + r, y: tile.minY),
                       control: CGPoint(x: tile.minX, y: tile.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Page 3 — the scatter

/// Destinations orbiting the mark, on soft rings.
///
/// The rings are **blurred**, not hairlines: they are meant to read as depth
/// behind the tiles — a ripple the photographs are floating on — rather than
/// as a diagram of concentric circles.
struct ScatterIllustration: View {
    /// Set when this page is on screen, so the tiles settle each time it is
    /// reached rather than only on the first visit.
    var settle: Bool

    /// Ring radii as fractions of the frame's width. **One array drives both
    /// the drawn rings and the tile positions**, so a tile provably sits on a
    /// ring rather than near where one happens to have been drawn.
    private let rings: [CGFloat] = [0.20, 0.315, 0.44, 0.57]

    private struct Tile {
        let destination: Destination
        /// Clock angle in degrees.
        let angle: Double
        /// Which ring it belongs to.
        let ring: Int
        /// How far off that ring it sits, as a fraction of the frame. This is
        /// the deliberate part: the tiles follow the rings, and each one is
        /// nudged just far enough off to say it was placed rather than
        /// computed.
        let drift: CGFloat
        let scale: CGFloat
        let tilt: Double
    }

    /// Eight on the middle ring at 45° apart, four on the outer ring sitting
    /// in their gaps. Even angles, uneven everything else.
    private let tiles: [Tile] = [
        .init(destination: .banff,      angle:  -78, ring: 1, drift:  0.028, scale: 0.185, tilt:  -6),
        .init(destination: .iceland,    angle:  -33, ring: 1, drift: -0.022, scale: 0.150, tilt:   9),
        .init(destination: .queenstown, angle:   12, ring: 1, drift:  0.034, scale: 0.170, tilt:  -9),
        .init(destination: .dolomites,  angle:   57, ring: 1, drift: -0.030, scale: 0.155, tilt:   6),
        .init(destination: .fuji,       angle:  102, ring: 1, drift:  0.024, scale: 0.175, tilt: -11),
        .init(destination: .hallstatt,  angle:  147, ring: 1, drift: -0.018, scale: 0.140, tilt:   8),
        .init(destination: .norway,     angle:  192, ring: 1, drift:  0.031, scale: 0.165, tilt:  -5),
        .init(destination: .cappadocia, angle:  237, ring: 1, drift: -0.026, scale: 0.150, tilt:  11),

        .init(destination: .lisbon,     angle:  -12, ring: 2, drift: -0.030, scale: 0.150, tilt:  -7),
        .init(destination: .santorini,  angle:   78, ring: 2, drift:  0.026, scale: 0.135, tilt:  10),
        .init(destination: .kyoto,      angle:  168, ring: 2, drift: -0.034, scale: 0.145, tilt:  -8),
        .init(destination: .marrakesh,  angle:  258, ring: 2, drift:  0.022, scale: 0.130, tilt:   7),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let centre = CGPoint(x: w / 2, y: geo.size.height / 2)

            ZStack {
                rings(w: w, centre: centre)

                AppMark(side: w * 0.24)
                    .scaleEffect(settle ? 1 : 0.86)
                    .opacity(settle ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: settle)
                    .position(centre)

                ForEach(Array(tiles.enumerated()), id: \.offset) { i, t in
                    let a = t.angle * .pi / 180
                    let r = rings[t.ring] + t.drift
                    Image(t.destination.tile)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w * t.scale, height: w * t.scale)
                        .clipShape(RoundedRectangle(cornerRadius: w * t.scale * 0.26,
                                                    style: .continuous))
                        .shadow(color: .black.opacity(0.28), radius: 12, y: 6)
                        .rotationEffect(.degrees(settle ? t.tilt : t.tilt - 12))
                        .scaleEffect(settle ? 1 : 0.4)
                        .opacity(settle ? 1 : 0)
                        // Ordered by ring, so the orbit fills outward.
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.72)
                                .delay(0.14 + Double(i) * 0.045),
                            value: settle
                        )
                        .position(x: centre.x + cos(a) * w * r,
                                  y: centre.y + sin(a) * w * r)
                }
            }
        }
    }

    /// Four rings, each blurred more than the last. Stroked and then blurred
    /// rather than drawn faint, so they bleed into the page instead of ending
    /// on a hard edge.
    private func rings(w: CGFloat, centre: CGPoint) -> some View {
        ForEach(Array(rings.enumerated()), id: \.offset) { i, r in
            Circle()
                .stroke(Color.inkFaint.opacity(0.55 - Double(i) * 0.09),
                        lineWidth: w * (0.020 + CGFloat(i) * 0.010))
                .frame(width: w * r * 2, height: w * r * 2)
                .blur(radius: w * 0.011)
                .position(centre)
        }
    }
}

#Preview("Cards") { StackedCardsIllustration(deal: true).frame(height: 380) }
#Preview("Route") { RouteMapIllustration(draw: true).frame(height: 380) }
#Preview("Scatter") { ScatterIllustration(settle: true).frame(height: 380) }

import SwiftUI

/// Where the card's arrow goes. The photograph carries the header and shrinks
/// as the itinerary scrolls up over it.
struct TripDetailView: View {
    let trip: Trip
    var onBook: () -> Void
    var onSave: () -> Void
    var onClose: () -> Void
    /// Handed a route rather than three closures: the detail screen is only
    /// forwarding a choice, and it should not have to know what any of them
    /// present.
    var onSection: (AppModel.Route) -> Void

    @State private var appeared = false
    /// The fade is only wanted once the photograph has scrolled away; over the
    /// hero it would just dull the image.
    @State private var scrolledPastHero = false

    private var days: [ItineraryDay] { ItineraryDay.plan(for: trip) }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                Color.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        hero
                        facts
                        sections
                        itinerary
                    }
                    .padding(.bottom, 132)   // clears the bar floating over it
                }
                .ignoresSafeArea(edges: .top)

                topFade
                navBar
            }

            barFade
            bookBar
        }
        .onAppear { withAnimation(.easeOut(duration: 0.45).delay(0.05)) { appeared = true } }
    }

    // MARK: Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geo in
                // Stretches rather than gapping when the scroll view is pulled
                // down past its top.
                let y = geo.frame(in: .global).minY
                let _ = DispatchQueue.main.async {
                    let past = y < -180
                    if past != scrolledPastHero { scrolledPastHero = past }
                }
                Image(trip.destination.card)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width,
                           height: geo.size.height + max(y, 0))
                    .clipped()
                    .offset(y: -max(y, 0))
            }
            .frame(height: 340)

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.55), location: 0),
                    .init(color: .black.opacity(0.05), location: 0.45),
                    .init(color: .black.opacity(0.65), location: 1),
                ], startPoint: .top, endPoint: .bottom
            )
            .frame(height: 340)
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 6) {
                Text(trip.countdown())
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11).padding(.vertical, 6)
                    .background(.ultraThinMaterial.opacity(0.9), in: Capsule())
                    .environment(\.colorScheme, .dark)

                Text(trip.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(trip.destination.blurb)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 20)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
        }
        .frame(height: 340)
    }

    // MARK: Facts

    private var facts: some View {
        HStack(spacing: 0) {
            fact("Dates", trip.dateRange())
            divider
            fact("Nights", "\(nights)")
            divider
            fact("Budget", trip.budgetLabel, accent: true)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, Metrics.gutter)
    }

    private var nights: Int {
        Calendar.current.dateComponents([.day], from: trip.start, to: trip.end).day ?? 0
    }

    private func fact(_ label: String, _ value: String, accent: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.inkFaint)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent ? Color.accent : Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .padding(.horizontal, 6)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(Color.hairline).frame(width: 1, height: 26)
    }

    // MARK: Sections

    /// Stays, budget and documents. Three taps the trip already implies and
    /// had nowhere to send anyone.
    private var sections: some View {
        HStack(spacing: 10) {
            section("Stays", "bed.double", value: trip.stay?.name) { onSection(.stays(trip)) }
            section("Budget", "creditcard", value: trip.budgetLabel) { onSection(.budget(trip)) }
            section("Documents", "doc.text", value: nil) { onSection(.documents(trip)) }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 22)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    /// `value` is what has been chosen, if anything. A tile that looks the
    /// same before and after a choice is why the flow read as a loop.
    private func section(_ title: String, _ symbol: String, value: String?,
                         action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.tap(); action() }) {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.inkMuted)
                if let value {
                    Text(value)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.surfaceElevated,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Itinerary

    private var itinerary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Itinerary")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, Metrics.gutter)

            ForEach(Array(days.enumerated()), id: \.element.id) { i, day in
                DayRow(day: day)
                    .padding(.horizontal, Metrics.gutter)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(.easeOut(duration: 0.4).delay(0.12 + Double(i) * 0.05),
                               value: appeared)
            }

            whatIsLeft
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 6)
        }
    }

    /// The end of the itinerary used to be the end of the screen — you read to
    /// the last day and there was nowhere to go. This says what is still
    /// missing and takes you there, from state the trip already holds.
    @ViewBuilder
    private var whatIsLeft: some View {
        if trip.stay == nil {
            nextStep("Nowhere to stay yet",
                     "Pick one and it lands on day one.",
                     "Choose a stay") { onSection(.stays(trip)) }
        } else if trip.flight == nil {
            nextStep("No flight yet",
                     "Five options from LHR on your dates.",
                     "See flights", action: onBook)
        } else {
            VStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(rgb: 0x2E9E5B))
                Text("\(trip.destination.city) is planned.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Text("Flight and stay are on day one. Nothing is actually booked "
                     + "— there is no booking partner behind this.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkFaint)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    /// The whole row is the control.
    ///
    /// It was a small `Button` with the padding, frame and background applied
    /// *outside* it, which leaves the hit area as the bare text and the pill
    /// drawn around something that is not tappable. The section tiles above get
    /// this right — the button wraps its own styling — so this now matches them.
    private func nextStep(_ title: String, _ detail: String, _ cta: String,
                          action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                Text(cta)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color.controlLabel)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(Color.control, in: Capsule())
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Color.surfaceElevated,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Chrome

    private var navBar: some View {
        HStack {
            circleButton("chevron.left", label: "Back", action: onClose)
            Spacer()
            circleButton(trip.isSaved ? "bookmark.fill" : "bookmark",
                         label: trip.isSaved ? "Remove from saved" : "Save trip",
                         action: onSave)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, Metrics.sheetTop)
    }

    /// Blur falling from the top edge, behind the nav buttons.
    ///
    /// The hero runs edge to edge by design, so the scroll passes under these
    /// controls — and once it is the itinerary rather than the photograph
    /// underneath, a day's number collided with the back button. Same idea as
    /// the band at the bottom of the home list, the other way up.
    private var topFade: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask(
                LinearGradient(stops: [
                    .init(color: .black, location: 0.0),
                    .init(color: .black.opacity(0.65), location: 0.45),
                    .init(color: .clear, location: 1.0),
                ], startPoint: .top, endPoint: .bottom)
            )
            .frame(height: 96)
            .frame(maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .opacity(scrolledPastHero ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: scrolledPastHero)
    }

    private func circleButton(_ symbol: String, label: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 38, height: 38)
        }
        .buttonStyle(GlassButtonStyle(shape: AnyShape(Circle())))
        .accessibilityLabel(label)
    }

    /// Reflects whether a flight has been chosen.
    ///
    /// It used to read "Book a Flight" forever, so saving one returned you to a
    /// bar inviting you to do the thing you had just done — a loop with no
    /// exit and no sign anything had happened.
    @ViewBuilder
    private var bookBar: some View {
        if let flight = trip.flight {
            HStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.controlLabel)
                    .frame(width: 24, height: 24)
                    .background(Color(rgb: 0x2E9E5B), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(flight.airline) \(flight.number)")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Text("\(flight.window) · \(flight.stopsLabel) · \(Money.label(flight.price))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.inkFaint)
                }

                Spacer(minLength: 8)

                Button("Change", action: onBook)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .frame(height: Metrics.buttonHeight)
            .background(Color.surfaceElevated,
                        in: RoundedRectangle(cornerRadius: Metrics.buttonRadius,
                                             style: .continuous))
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 6)
        } else {
            Button(action: onBook) {
                Label("Book a Flight", systemImage: "airplane.departure")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 6)
        }
    }

    /// Blur rising from the **physical** bottom edge.
    ///
    /// Two earlier attempts leaked. `.bar` drew a hard near-black band with the
    /// page visible either side of it; a masked fade in the bar's own
    /// `background` could not reach past the safe-area inset the bar lived in,
    /// so the itinerary carried on below the card. This is the home list's
    /// band, which had both problems and neither now.
    private var barFade: some View {
        Rectangle()
            .fill(.regularMaterial)
            .mask(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: .black.opacity(0.22), location: 0.26),
                    .init(color: .black.opacity(0.72), location: 0.52),
                    .init(color: .black, location: 0.74),
                    .init(color: .black, location: 1.00),
                ], startPoint: .top, endPoint: .bottom)
            )
            .frame(height: 160)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

private struct DayRow: View {
    let day: ItineraryDay

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 2) {
                Text("\(day.number)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.controlLabel)
                    .frame(width: 30, height: 30)
                    .background(Color.control, in: Circle())
                Rectangle()
                    .fill(Color.hairline)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(TripFormat.dayLine.string(from: day.date))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.inkFaint)

                ForEach(day.items) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.kind.symbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.inkMuted)
                            .frame(width: 26, height: 26)
                            .background(Color.fieldFill, in: RoundedRectangle(
                                cornerRadius: 8, style: .continuous))
                        Text(item.title)
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundStyle(Color.ink)
                        Spacer(minLength: 8)
                        Text(item.time)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.inkFaint)
                            .monospacedDigit()
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

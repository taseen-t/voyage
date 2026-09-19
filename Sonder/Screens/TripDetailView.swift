import SwiftUI

/// Where the card's arrow goes. The photograph carries the header and shrinks
/// as the itinerary scrolls up over it.
struct TripDetailView: View {
    let trip: Trip
    var onBook: () -> Void
    var onSave: () -> Void
    var onClose: () -> Void

    @State private var appeared = false

    private var days: [ItineraryDay] { ItineraryDay.plan(for: trip) }

    var body: some View {
        ZStack(alignment: .top) {
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    hero
                    facts
                    itinerary
                }
                .padding(.bottom, 110)
            }
            .ignoresSafeArea(edges: .top)

            navBar
        }
        .safeAreaInset(edge: .bottom) { bookBar }
        .onAppear { withAnimation(.easeOut(duration: 0.45).delay(0.05)) { appeared = true } }
    }

    // MARK: Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geo in
                // Stretches rather than gapping when the scroll view is pulled
                // down past its top.
                let y = geo.frame(in: .global).minY
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
        }
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
        .padding(.top, 4)
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

    private var bookBar: some View {
        Button(action: onBook) {
            Label("Book a Flight", systemImage: "airplane.departure")
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 6)
        .background(.bar)
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

import SwiftUI

/// Somewhere to sleep. Reached from the trip.
struct StaysView: View {
    let trip: Trip
    var onClose: () -> Void

    init(trip: Trip, onClose: @escaping () -> Void) {
        self.trip = trip
        self.onClose = onClose
        _stays = State(initialValue: Stay.options(for: trip))
    }

    @State private var selected: Stay.ID?
    /// Generated once, in `init`. Regenerating from a computed property means
    /// a fresh list on every body pass, which is wasted work even once the ids
    /// are stable.
    @State private var stays: [Stay]
    @State private var appeared = false


    private var nights: Int {
        Calendar.current.dateComponents([.day], from: trip.start, to: trip.end).day ?? 1
    }

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(stays.enumerated()), id: \.element.id) { i, stay in
                        StayRow(stay: stay, nights: nights, isSelected: selected == stay.id) {
                            Haptics.tap()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selected = selected == stay.id ? nil : stay.id
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(.easeOut(duration: 0.38).delay(Double(i) * 0.06),
                                   value: appeared)
                    }

                    Text("Nothing here is bookable. Sonder has no accommodation "
                         + "partner, so choosing one saves it to the trip.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.horizontal, 12)
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .safeAreaInset(edge: .top, spacing: 0) { header }
        }
        .safeAreaInset(edge: .bottom) {
            Button(selected == nil ? "Select a stay" : "Save to trip") {
                Haptics.confirm(); onClose()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selected == nil)
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 6)
            .background(.bar)
        }
        .onAppear { appeared = true }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .frame(width: 36, height: 36)
                        .background(Color.fieldFill, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                Spacer()
            }
            Text("Stays in \(trip.destination.city)")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.ink)
            Text("\(nights) nights · \(TripFormat.dayMonth.string(from: trip.start)) – "
                 + "\(TripFormat.dayMonth.string(from: trip.end))")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.inkFaint)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 14)
        .background(Color.surface)
    }
}

private struct StayRow: View {
    let stay: Stay
    let nights: Int
    let isSelected: Bool
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            HStack(spacing: 12) {
                Image(stay.kind.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(stay.name)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)

                    Text("\(stay.kind.label) · \(stay.area)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.inkMuted)

                    HStack(spacing: 5) {
                        Text(stay.ratingLabel)
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(Color.controlLabel)
                            .padding(.horizontal, 6).padding(.vertical, 2.5)
                            .background(Color.control, in: RoundedRectangle(
                                cornerRadius: 5, style: .continuous))
                        Text("\(stay.reviews) reviews")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.inkFaint)
                    }

                    Text(stay.perks.joined(separator: " · "))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.inkFaint)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Money.label(stay.perNight))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.accent)
                    Text("a night")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(Color.inkFaint)
                    Text(Money.label(stay.perNight * nights))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.inkMuted)
                        .padding(.top, 3)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.surfaceElevated))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color.ink : Color.hairline,
                        lineWidth: isSelected ? 2.5 : 1))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.controlLabel)
                        .frame(width: 22, height: 22)
                        .background(Color.control, in: Circle())
                        .offset(x: 7, y: -7)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(isSelected ? 1.012 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(stay.name), \(stay.kind.label) in \(stay.area), "
                            + "rated \(stay.ratingLabel), \(Money.label(stay.perNight)) a night")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

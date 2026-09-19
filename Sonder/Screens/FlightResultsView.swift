import SwiftUI

/// Where "Book a Flight" goes.
///
/// It stops short of taking money: selecting a flight marks it on the trip and
/// says plainly that payment is not wired. A fake checkout that appears to
/// charge someone is worse than an honest dead end.
struct FlightResultsView: View {
    let trip: Trip
    var onClose: () -> Void

    @State private var selected: Flight.ID?
    @State private var appeared = false

    private var flights: [Flight] { Flight.options(for: trip) }

    var body: some View {
        ZStack(alignment: .top) {
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(flights.enumerated()), id: \.element.id) { i, flight in
                        FlightRow(flight: flight, isSelected: selected == flight.id) {
                            Haptics.tap()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selected = selected == flight.id ? nil : flight.id
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(.easeOut(duration: 0.38).delay(Double(i) * 0.06),
                                   value: appeared)
                    }

                    note.padding(.top, 8)
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .safeAreaInset(edge: .top, spacing: 0) { header }
        }
        .safeAreaInset(edge: .bottom) { selectBar }
        .onAppear { appeared = true }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
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

            HStack(spacing: 8) {
                Text("LHR").font(.system(size: 22, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.inkFaint)
                Text(trip.destination.airport).font(.system(size: 22, weight: .bold))
            }
            .foregroundStyle(Color.ink)

            Text("\(TripFormat.dayLine.string(from: trip.start)) · "
                 + "\(flights.count) options · one way")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.inkFaint)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 14)
        .background(Color.surface)
    }

    private var note: some View {
        Text("Prices are illustrative. Sonder has no booking partner wired up yet, "
             + "so selecting a flight saves it to the trip rather than buying it.")
            .font(.system(size: 11))
            .foregroundStyle(Color.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    private var selectBar: some View {
        Button(selected == nil ? "Select a flight" : "Save to trip") {
            Haptics.confirm()
            onClose()
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(selected == nil)
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 6)
        .background(.bar)
    }
}

private struct FlightRow: View {
    let flight: Flight
    let isSelected: Bool
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(flight.airline)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Text(flight.number)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.inkFaint)
                    Spacer()
                    Text(Money.label(flight.price))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.accent)
                }

                HStack(spacing: 10) {
                    Text(flight.window)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .monospacedDigit()
                    Spacer()
                    Text(flight.duration)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                    Text("·").foregroundStyle(Color.inkFaint)
                    Text(flight.stopsLabel)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(flight.stops == 0 ? Color.ink : Color.inkMuted)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.ink : Color.hairline,
                            lineWidth: isSelected ? 2.5 : 1)
            )
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
            .scaleEffect(isSelected ? 1.015 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(flight.airline) \(flight.number), \(flight.window), "
                            + "\(flight.stopsLabel), \(Money.label(flight.price))")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

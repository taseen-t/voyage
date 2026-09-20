import SwiftUI

/// Shown after a flight or a stay is added to a trip.
///
/// Saving used to drop you back on the trip with the change made but nothing
/// said — correct, and silent enough that people asked whether it had worked.
/// This says what happened and offers the one step that follows it.
///
/// What it says is **derived from the trip**, not passed in: there is no state
/// here that could disagree with the trip it is describing.
struct TripConfirmView: View {
    let trip: Trip
    /// Take the step this suggests — choose a stay, see flights, or keep it.
    var onContinue: () -> Void
    var onHome: () -> Void

    @State private var appeared = false

    private var isComplete: Bool { trip.flight != nil && trip.stay != nil }

    private var title: String {
        if isComplete { "Your trip is complete." }
        else if trip.flight != nil { "Flight added." }
        else { "Stay added." }
    }

    private var detail: String {
        if isComplete {
            "Flight and stay are both on day one. Keep it and it will be waiting "
                + "in your saved trips."
        } else if trip.flight != nil {
            "It's on day one of your itinerary. A place to stay is the other half."
        } else {
            "It's on day one of your itinerary. You still need a way there."
        }
    }

    private var cta: String {
        if isComplete { "Keep this trip" }
        else if trip.flight != nil { "Choose a stay" }
        else { "See flights" }
    }

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.controlLabel)
                    .frame(width: 54, height: 54)
                    .background(Color(rgb: 0x2E9E5B), in: Circle())
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)

                Text(title)
                    .font(.display)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 18)
                    .padding(.horizontal, Metrics.gutter)

                Text(detail)
                    .font(.body)
                    .foregroundStyle(Color.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, Metrics.gutter + 6)

                summary
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.top, 26)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    Button(cta, action: onContinue)
                        .buttonStyle(PrimaryButtonStyle())
                    Button("Back to home", action: onHome)
                        .buttonStyle(ProviderButtonStyle())
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 8)
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appeared = true }
        }
    }

    /// What is on the trip so far, so the claim above it can be checked.
    private var summary: some View {
        VStack(spacing: 0) {
            if let flight = trip.flight {
                row("airplane", "\(flight.airline) \(flight.number)",
                    "\(flight.window) · \(flight.stopsLabel) · \(Money.label(flight.price))")
            }
            if let stay = trip.stay {
                if trip.flight != nil { Divider().overlay(Color.hairline) }
                row("bed.double", stay.name,
                    "\(stay.kind.label) · \(stay.area) · \(Money.label(stay.perNight)) a night")
            }
        }
        .background(Color.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func row(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.inkMuted)
                .frame(width: 34, height: 34)
                .background(Color.fieldFill, in: RoundedRectangle(
                    cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkFaint)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
    }
}

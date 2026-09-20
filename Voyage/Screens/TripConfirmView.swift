import SwiftUI

/// The one confirmation screen: shown after a trip is created, and after a
/// flight or a stay is added to one.
///
/// It carries the **real `TripCard`**, so what you are shown here is exactly
/// what you will find in the list — a summary drawn specially for this screen
/// would be a second thing to keep in agreement with the first.
///
/// What it says is **derived**, never passed in, so the words cannot disagree
/// with the trip they are describing.
struct TripConfirmView: View {
    enum Reason {
        /// Finished the new-trip flow.
        case created
        /// Added a flight or a stay to an existing trip.
        case added
    }

    let trip: Trip
    var reason: Reason = .added
    /// Take the step this suggests — open it, choose a stay, see flights, or
    /// keep it.
    var onContinue: () -> Void
    var onHome: () -> Void

    @State private var appeared = false

    private var isComplete: Bool { trip.flight != nil && trip.stay != nil }

    private var title: String {
        switch reason {
        case .created: "Trip created."
        case .added:
            if isComplete { "Your trip is complete." }
            else if trip.flight != nil { "Flight added." }
            else { "Stay added." }
        }
    }

    private var detail: String {
        switch reason {
        case .created:
            "It's in Upcoming, \(trip.countdown().lowercased())."
        case .added:
            if isComplete {
                "Flight and stay are both on your itinerary. Keep it and it will "
                    + "be waiting in your saved trips."
            } else if trip.flight != nil {
                "It's on your itinerary. A place to stay is the other half."
            } else {
                "It's on your itinerary. You still need a way there."
            }
        }
    }

    private var cta: String {
        switch reason {
        case .created: "View itinerary"
        case .added:
            if isComplete { "Keep this trip" }
            else if trip.flight != nil { "Choose a stay" }
            else { "See flights" }
        }
    }

    private var dismiss: String {
        reason == .created ? "Done" : "Back to home"
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
                    .padding(.top, 6)
                    .padding(.horizontal, Metrics.gutter + 6)

                TripCard(trip: trip, onSave: {}, onOpen: onContinue, onBook: onContinue)
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.top, 26)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    Button(cta, action: onContinue)
                        .buttonStyle(PrimaryButtonStyle())
                    Button(dismiss, action: onHome)
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
}

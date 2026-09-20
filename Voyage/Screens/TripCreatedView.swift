import SwiftUI

/// Confirmation after `+`. Without it, creating a trip dismissed the sheet and
/// nothing visibly happened: the list is sorted by date, so a trip a few months
/// out lands below the fold.
struct TripCreatedView: View {
    let trip: Trip
    var onOpen: () -> Void
    var onDone: () -> Void

    @State private var appeared = false

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

                Text("Trip created.")
                    .font(.display)
                    .foregroundStyle(Color.ink)
                    .padding(.top, 18)

                Text("It's in Upcoming, \(trip.countdown().lowercased()).")
                    .font(.body)
                    .foregroundStyle(Color.inkMuted)
                    .padding(.top, 6)

                // The real card, so what you are shown here is exactly what you
                // will find in the list.
                TripCard(trip: trip, onSave: {}, onOpen: onOpen, onBook: onOpen)
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.top, 26)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    Button("View itinerary", action: onOpen)
                        .buttonStyle(PrimaryButtonStyle())
                    Button("Done", action: onDone)
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

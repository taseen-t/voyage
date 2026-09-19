import SwiftUI

/// The trip card: a photograph with everything a traveller checks at a glance
/// laid over it — when, where, how much, and the one action worth taking now.
struct TripCard: View {
    let trip: Trip
    var onSave: () -> Void
    var onOpen: () -> Void

    var body: some View {
        ZStack {
            Image(trip.destination.card)
                .resizable()
                .scaledToFill()

            // Two scrims rather than one across the whole card: the copy sits
            // at the top and the controls at the bottom, and darkening the
            // middle as well would flatten the photograph for nothing.
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.66), location: 0.00),
                    .init(color: .black.opacity(0.52), location: 0.34),
                    .init(color: .black.opacity(0.10), location: 0.58),
                    .init(color: .black.opacity(0.00), location: 0.68),
                    .init(color: .black.opacity(0.42), location: 1.00),
                ],
                startPoint: .top, endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    countdownBadge
                    Spacer(minLength: 8)
                    saveButton
                }

                Spacer().frame(height: 14)

                Text(trip.title)
                    .font(.cardTitle)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(trip.dateRange())
                    .font(.label)
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.top, 3)

                Spacer(minLength: 8)

                Text(trip.budgetLabel)
                    .font(.price)
                    .foregroundStyle(Color.accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 4)
                    .padding(.bottom, 10)

                actionBar
            }
            .padding(16)
        }
        .aspectRatio(1020.0 / 850.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(trip.title), \(trip.dateRange()), budget \(trip.budgetLabel)")
    }

    private var countdownBadge: some View {
        let soon = trip.countdown() == "Today" || trip.countdown() == "Tomorrow"
        return Text(trip.countdown())
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background {
                if soon {
                    Capsule().fill(Color(rgb: 0x2E9E5B))
                } else {
                    Capsule().fill(.ultraThinMaterial.opacity(0.9))
                        .environment(\.colorScheme, .dark)
                }
            }
    }

    private var saveButton: some View {
        Button(action: onSave) {
            Image(systemName: trip.isSaved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 34, height: 34)
        }
        .buttonStyle(GlassButtonStyle(shape: AnyShape(Circle())))
        .accessibilityLabel(trip.isSaved ? "Remove from saved" : "Save trip")
    }

    private var actionBar: some View {
        HStack(spacing: 0) {
            Label {
                Text("Book a Flight").font(.system(size: 13.5, weight: .semibold))
            } icon: {
                Image(systemName: "airplane.departure").font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.leading, 16)

            Spacer(minLength: 12)

            Button(action: onOpen) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(GlassButtonStyle(shape: AnyShape(Circle())))
            .padding(.trailing, 6)
            .accessibilityLabel("Open \(trip.title)")
        }
        .frame(height: 46)
        .background(.ultraThinMaterial.opacity(0.85), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 0.5))
        .environment(\.colorScheme, .dark)
    }
}

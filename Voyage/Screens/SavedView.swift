import SwiftUI

/// The trips the bookmark writes to. Without this the bookmark stored state
/// that nothing on earth could read back.
struct SavedView: View {
    @Bindable var model: AppModel
    var onOpen: (Trip) -> Void
    var onHome: () -> Void
    var onClose: () -> Void

    private var saved: [Trip] {
        model.trips.filter(\.isSaved).sorted { $0.start < $1.start }
    }

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(saved) { trip in
                        TripCard(trip: trip,
                                 onSave: { Haptics.tap(); model.toggleSaved(trip) },
                                 onOpen: { onOpen(trip) },
                                 onBook: { onOpen(trip) })
                            .onTapGesture { onOpen(trip) }
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    }
                    if saved.isEmpty { empty }

                    Button("Back to home", action: onHome)
                        .buttonStyle(ProviderButtonStyle())
                        .padding(.top, 8)
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 6)
                .padding(.bottom, 40)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: saved)
            }
            .safeAreaInset(edge: .top, spacing: 0) { header }
        }
    }

    private var header: some View {
        HStack {
            Text("Saved")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.ink)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 36, height: 36)
                    .background(Color.fieldFill, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, Metrics.sheetTop)
        .padding(.bottom, 12)
        .background(Color.surface)
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: "bookmark")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Color.inkFaint)
            Text("Nothing saved yet.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.ink)
            Text("Tap the bookmark on a trip and it will wait for you here.")
                .font(.body)
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 90)
        .padding(.horizontal, 24)
    }
}

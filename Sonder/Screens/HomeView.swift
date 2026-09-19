import SwiftUI

struct HomeView: View {
    @Bindable var model: AppModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                // Lazy, so a traveller with forty trips pays for the three on
                // screen. Each card holds a decoded photograph; building them
                // all eagerly is the difference between a smooth first scroll
                // and a stutter.
                LazyVStack(spacing: 16) {
                    ForEach(trips) { trip in
                        TripCard(trip: trip,
                                 onSave: { Haptics.tap(); model.toggleSaved(trip) },
                                 onOpen: { Haptics.tap() })
                    }
                    if trips.isEmpty { emptyState }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 10)
                .padding(.bottom, 96)   // clears the button floating over the list
            }
            .safeAreaInset(edge: .top, spacing: 0) { header }

            bottomFade
            addButton
        }
    }

    private var trips: [Trip] { model.trips(for: model.tab) }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center, spacing: 14) {
                ForEach(HomeTab.allCases) { tab in
                    Button {
                        guard model.tab != tab else { return }
                        Haptics.step()
                        withAnimation(.easeInOut(duration: 0.22)) { model.tab = tab }
                    } label: {
                        Text(tab.rawValue)
                            .font(.tab)
                            .foregroundStyle(model.tab == tab ? Color.ink : Color.inkFaint)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(model.tab == tab ? [.isSelected] : [])
                }

                Spacer(minLength: 8)

                // The system's own person glyph rather than a bundled portrait:
                // there is no account behind this screen yet, and a stock face
                // would imply one.
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 31))
                    .foregroundStyle(Color.inkFaint, Color.fieldFill)
                    .accessibilityLabel("Account")
            }

            Text(TripFormat.header.string(from: .now))
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Color.inkFaint)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 12)
        .background(Color.surface)
    }

    /// Blur rising from the bottom edge, so the add button always has the
    /// same backdrop no matter which photograph has scrolled under it.
    private var bottomFade: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.7), location: 0.45),
                    .init(color: .black, location: 1.0),
                ], startPoint: .top, endPoint: .bottom)
            )
            .frame(height: 104)
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .bottom)
    }

    private var addButton: some View {
        Button {
            Haptics.confirm()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.controlLabel)
                .frame(width: 46, height: 46)
                .background(Color.control, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 6)
        .accessibilityLabel("Plan a new trip")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text(model.tab == .upcoming ? "Nothing booked yet." : "No trips behind you yet.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.ink)
            Text(model.tab == .upcoming
                 ? "Tap + and the itinerary builds itself around your dates."
                 : "Trips move here on the day they end.")
                .font(.body)
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
        .padding(.horizontal, 20)
    }
}

#Preview { HomeView(model: AppModel()) }

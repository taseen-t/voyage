import SwiftUI

struct HomeView: View {
    @Bindable var model: AppModel

    /// Drives the list's entrance, once. It is deliberately **not** reset when
    /// the tab changes: replaying the staggered deal on every press read as
    /// the screen reloading itself. Switching tabs now animates the rows that
    /// actually differ, which is a change rather than a refresh.
    @State private var shown = false
    @Namespace private var tabPill

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.surface.ignoresSafeArea()

            ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                // Lazy, so a traveller with forty trips pays for the three on
                // screen. Each card holds a decoded photograph; building them
                // all eagerly is the difference between a smooth first scroll
                // and a stutter.
                LazyVStack(spacing: 16) {
                    ForEach(Array(trips.enumerated()), id: \.element.id) { i, trip in
                        TripCard(
                            trip: trip,
                            onSave: { Haptics.tap(); model.toggleSaved(trip) },
                            onOpen: { open(.detail(trip)) },
                            onBook: { open(.flights(trip)) }
                        )
                        .id(trip.id)
                        .overlay(
                            RoundedRectangle(cornerRadius: Metrics.cardRadius,
                                             style: .continuous)
                                .stroke(Color.accent, lineWidth: 3)
                                .opacity(model.highlight == trip.id ? 1 : 0)
                        )
                        .onTapGesture { open(.detail(trip)) }
                        .opacity(shown ? 1 : 0)
                        .offset(y: shown ? 0 : 26)
                        .animation(.spring(response: 0.5, dampingFraction: 0.85)
                            .delay(Double(min(i, 6)) * 0.06), value: shown)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    }
                    if trips.isEmpty { emptyState }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 10)
                .padding(.bottom, 96)   // clears the button floating over the list
            }
            .safeAreaInset(edge: .top, spacing: 0) { header }
            .onChange(of: model.highlight) { _, id in
                guard let id else { return }
                withAnimation(.easeInOut(duration: 0.45)) {
                    proxy.scrollTo(id, anchor: .center)
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(1400))
                    withAnimation(.easeOut(duration: 0.4)) { model.highlight = nil }
                }
            }
            }

            bottomFade
            addButton
        }
        .onAppear { shown = true }
        .sheet(item: $model.route) { route in
            switch route {
            case .detail(let trip):
                TripDetailView(
                    trip: model.trips.first { $0.id == trip.id } ?? trip,
                    onBook: { model.route = .flights(trip) },
                    onSave: { Haptics.tap(); model.toggleSaved(trip) },
                    onClose: { model.route = nil },
                    onSection: { model.route = $0 }
                )
            case .flights(let trip):
                FlightResultsView(trip: trip, onClose: { model.route = nil })
            case .stays(let trip):
                StaysView(trip: trip, onClose: { model.route = nil })
            case .budget(let trip):
                BudgetView(trip: trip, onClose: { model.route = nil })
            case .documents(let trip):
                DocumentsView(trip: trip, onClose: { model.route = nil })
            case .created(let trip):
                TripCreatedView(
                    trip: model.trips.first { $0.id == trip.id } ?? trip,
                    onOpen: { model.route = .detail(trip) },
                    onDone: { model.route = nil; model.highlight = trip.id }
                )
            case .saved:
                SavedView(model: model,
                          onOpen: { model.route = .detail($0) },
                          onClose: { model.route = nil })
            case .newTrip:
                NewTripView(
                    onCreate: { trip in
                        model.add(trip)
                        model.route = .created(trip)
                    },
                    onClose: { model.route = nil }
                )
            case .profile:
                ProfileView(model: model,
                            onSaved: { model.route = .saved },
                            onClose: { model.route = nil })
            }
        }
    }

    private var trips: [Trip] { model.trips(for: model.tab) }

    private func open(_ route: AppModel.Route) {
        Haptics.tap()
        model.route = route
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center, spacing: 14) {
                segmentedTabs

                Spacer(minLength: 8)

                // The system's own person glyph rather than a bundled portrait:
                // there is no account behind this screen yet, and a stock face
                // would imply one.
                Button { open(.profile) } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 31))
                        .foregroundStyle(Color.inkFaint, Color.fieldFill)
                }
                .buttonStyle(.plain)
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

    /// Upcoming and Past, as a control rather than two words. The selected
    /// pill is one view moved between the two with `matchedGeometryEffect`, so
    /// it slides across instead of one fading out while another fades in.
    private var segmentedTabs: some View {
        HStack(spacing: 4) {
            ForEach(HomeTab.allCases) { tab in
                let selected = model.tab == tab
                Button {
                    guard !selected else { return }
                    Haptics.step()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        model.tab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(selected ? Color.controlLabel : Color.inkMuted)
                        .padding(.horizontal, 17)
                        .frame(height: 34)
                        .background {
                            if selected {
                                Capsule()
                                    .fill(Color.control)
                                    .matchedGeometryEffect(id: "tabPill", in: tabPill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.fieldFill))
    }

    /// Blur rising from the bottom edge, so the add button always has the
    /// same backdrop no matter which photograph has scrolled under it.
    ///
    /// The band is pinned to the **physical** bottom, not the safe area's.
    /// A fixed-height view aligned to the bottom of a safe-area-respecting
    /// stack stops short of the home indicator, which left the last card
    /// rendering sharp underneath it — the blur then read as a grey rectangle
    /// laid over the photograph rather than as the screen edge softening.
    private var bottomFade: some View {
        Rectangle()
            // Thicker than the glass used on the cards: this one has to make
            // whatever scrolls under it read as texture rather than as a
            // headline competing with the button on top of it.
            .fill(.regularMaterial)
            .mask(
                // A long, soft ramp. The earlier one reached full strength by
                // 45% of a short band, so its leading edge was a visible line.
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: .black.opacity(0.22), location: 0.26),
                    .init(color: .black.opacity(0.72), location: 0.52),
                    .init(color: .black, location: 0.74),
                    .init(color: .black, location: 1.00),
                ], startPoint: .top, endPoint: .bottom)
            )
            .frame(height: 150)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    private var addButton: some View {
        Button { open(.newTrip) } label: {
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

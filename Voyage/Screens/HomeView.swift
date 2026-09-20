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
            }
            }

            BottomFade(height: 150)
            addButton
        }
        .onAppear { shown = true }
        // Where a close button goes.
        //
        // One level, no stack: anything opened *from* a trip returns to that
        // trip, and the trip itself returns home. Saving and closing had been
        // going to different places from the same screen — Save landed on the
        // trip, the close chevron went all the way home — which is what made
        // the flow feel like it had no shape.
        .sheet(item: $model.route) { route in
            // A sheet is its own presentation container, so the
            // `preferredColorScheme` set on the root does not reach it — pick
            // Light on the account screen and the sheet it is sitting in stays
            // dark. Re-declaring it here covers every sheet in the app,
            // because they all come through this one presenter.
            Group {
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
                    FlightResultsView(
                        trip: trip,
                        onChoose: { flight in
                            model.choose(flight, for: trip)
                            model.route = .confirm(trip)
                        },
                        onClose: { model.route = .detail(trip) }
                    )
                case .stays(let trip):
                    StaysView(
                        trip: trip,
                        onChoose: { stay in
                            model.choose(stay, for: trip)
                            model.route = .confirm(trip)
                        },
                        onClose: { model.route = .detail(trip) }
                    )
                case .budget(let trip):
                    BudgetView(trip: trip, onClose: { model.route = .detail(trip) })
                case .documents(let trip):
                    DocumentsView(trip: trip, onClose: { model.route = .detail(trip) })
                case .created(let trip):
                    TripConfirmView(
                        trip: model.trips.first { $0.id == trip.id } ?? trip,
                        reason: .created,
                        onContinue: { model.route = .detail(trip) },
                        onHome: { model.route = nil; model.highlight = trip.id }
                    )
                case .confirm(let trip):
                    // Re-read the trip: the payload was captured before the
                    // choice that triggered this screen was written.
                    let live = model.trips.first { $0.id == trip.id } ?? trip
                    TripConfirmView(
                        trip: live,
                        onContinue: {
                            if live.flight != nil && live.stay != nil {
                                model.markSaved(live)
                                model.route = .saved(fromProfile: false)
                            } else if live.flight != nil {
                                model.route = .stays(live)
                            } else {
                                model.route = .flights(live)
                            }
                        },
                        onHome: { model.route = nil }
                    )
            case .saved(let fromProfile):
                    SavedView(model: model,
                              onOpen: { model.route = .detail($0) },
                              onHome: { model.route = nil },
                              onClose: { model.route = fromProfile ? .profile : nil })
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
                                onSaved: { model.route = .saved(fromProfile: true) },
                                onClose: { model.route = nil })
                }
            }
            .preferredColorScheme(model.appearance.colorScheme)
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

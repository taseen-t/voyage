import SwiftUI

/// Where `+` goes. Three steps in one sheet — where, when, how much — because
/// the pitch on the last onboarding page promises an itinerary "in under a
/// minute", and three taps and a drag is what that has to mean.
struct NewTripView: View {
    var onCreate: (Trip) -> Void
    var onClose: () -> Void

    private enum Stage: Int, CaseIterable { case where_, when, budget }

    @State private var stage: Stage = .where_
    @State private var destination: Destination?
    @State private var start = Calendar.current.date(byAdding: .day, value: 21, to: .now) ?? .now
    @State private var nights = 7
    @State private var budget = 1800

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Group {
                    switch stage {
                    case .where_: destinationGrid
                    case .when: dates
                    case .budget: money
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))

                footer
            }
        }
    }

    // MARK: Chrome

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Button(action: stage == .where_ ? onClose : back) {
                    Image(systemName: stage == .where_ ? "xmark" : "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .frame(width: 36, height: 36)
                        .background(Color.fieldFill, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(stage == .where_ ? "Cancel" : "Back")

                Spacer()

                Text("Step \(stage.rawValue + 1) of 3")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkFaint)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.hairline)
                    Capsule().fill(Color.ink)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 3)

            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.opacity)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 18)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: stage)
    }

    private var progress: CGFloat { CGFloat(stage.rawValue + 1) / 3 }

    private var title: String {
        switch stage {
        case .where_: "Where to?"
        case .when: "When?"
        case .budget: "What's the budget?"
        }
    }

    private var footer: some View {
        Button(stage == .budget ? "Create trip" : "Continue", action: forward)
            .buttonStyle(PrimaryButtonStyle())
            .disabled(stage == .where_ && destination == nil)
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 8)
    }

    // MARK: Step 1

    private var destinationGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Destination.allCases) { d in
                    Button {
                        Haptics.tap()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            destination = d
                        }
                    } label: {
                        ZStack(alignment: .bottomLeading) {
                            Image(d.card)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 104)
                                .clipped()
                            LinearGradient(colors: [.clear, .black.opacity(0.62)],
                                           startPoint: .center, endPoint: .bottom)
                            Text(d.city)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(10)
                        }
                        .frame(height: 104)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.ink, lineWidth: destination == d ? 3 : 0)
                        )
                        .scaleEffect(destination == d ? 0.97 : 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(d.title)
                    .accessibilityAddTraits(destination == d ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 20)
        }
    }

    // MARK: Step 2

    private var dates: some View {
        VStack(spacing: 22) {
            DatePicker("Leaving", selection: $start, in: Date()...,
                       displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Color.accent)
                .padding(.horizontal, 6)

            VStack(spacing: 10) {
                HStack {
                    Text("Nights")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Text("\(nights)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                Slider(value: .init(get: { Double(nights) },
                                    set: { nights = Int($0.rounded()) }),
                       in: 2...21, step: 1)
                    .tint(Color.accent)

                Text("Back on \(TripFormat.dayLine.string(from: end))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color.surfaceElevated,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Metrics.gutter)
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: nights)
    }

    private var end: Date {
        Calendar.current.date(byAdding: .day, value: nights, to: start) ?? start
    }

    // MARK: Step 3

    private var money: some View {
        VStack(spacing: 26) {
            Text(Money.label(budget))
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(Color.accent)
                .monospacedDigit()
                .contentTransition(.numericText())
                .padding(.top, 20)

            Slider(value: .init(get: { Double(budget) },
                                set: { budget = Int(($0 / 50).rounded()) * 50 }),
                   in: 300...12000, step: 50)
                .tint(Color.accent)

            Text("Roughly \(Money.label(perDay)) a day across \(nights) nights.")
                .font(.system(size: 12))
                .foregroundStyle(Color.inkMuted)

            if let destination {
                summary(destination)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Metrics.gutter)
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: budget)
    }

    private var perDay: Int { budget / max(nights, 1) }

    private func summary(_ d: Destination) -> some View {
        HStack(spacing: 12) {
            Image(d.tile)
                .resizable().scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(d.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Text("\(TripFormat.dayMonth.string(from: start)) – "
                     + "\(TripFormat.dayMonth.string(from: end))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkFaint)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Navigation

    private func forward() {
        Haptics.step()
        switch stage {
        case .where_:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { stage = .when }
        case .when:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { stage = .budget }
        case .budget:
            guard let destination else { return }
            Haptics.confirm()
            onCreate(Trip(destination: destination, start: start, end: end, budget: budget))
        }
    }

    private func back() {
        Haptics.tap()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            stage = Stage(rawValue: stage.rawValue - 1) ?? .where_
        }
    }
}

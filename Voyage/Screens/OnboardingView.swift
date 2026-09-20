import SwiftUI

struct OnboardingPage: Identifiable {
    let id: Int
    let title: String
    let body: String
    let action: String
}

extension OnboardingPage {
    static let all: [OnboardingPage] = [
        .init(id: 0,
              title: "Every trip,\none place.",
              body: "Flights, stays, itineraries, and budgets, no more a dozen "
                  + "tabs and screenshots to keep track of.",
              action: "Next"),
        .init(id: 1,
              title: "Built for how you\nactually travel.",
              body: "Plans shift, flights delay, weather turns. Your itinerary "
                  + "should bend with you, not lock you in.",
              action: "Next"),
        .init(id: 2,
              title: "Less planning.\nMore going.",
              body: "You didn't book this trip to live in spreadsheets. Set up "
                  + "your first itinerary in under a minute.",
              action: "Get Started"),
    ]
}

struct OnboardingView: View {
    @Bindable var model: AppModel
    var onFinish: () -> Void

    /// Which page is currently playing its entrance. Held as the page number
    /// rather than a boolean so every page replays when it is reached again,
    /// forwards or back — not only the first one.
    @State private var playing: Int?

    var body: some View {
        ZStack(alignment: .top) {
            Color.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                // The illustration takes whatever height is left once the copy
                // and the button have taken theirs, so the three pages line up
                // on every device rather than only on the one it was drawn for.
                TabView(selection: $model.onboardingPage) {
                    ForEach(OnboardingPage.all) { page in
                        illustration(for: page.id)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: 12) {
                    Text(current.title)
                        .font(.display)
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(1)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(current.body)
                        .font(.body)
                        .foregroundStyle(Color.inkMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 22)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 22)
                // Re-fading the copy on each page keeps the eye on the words
                // while the illustration slides underneath it.
                .id(model.onboardingPage)
                .transition(.opacity.combined(with: .offset(y: 8)))

                dots.padding(.bottom, 18)

                Button(current.action, action: advance)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.bottom, 8)
            }

            header
        }
        .onAppear { play(model.onboardingPage) }
        .onChange(of: model.onboardingPage) { _, page in play(page) }
    }

    private var current: OnboardingPage { OnboardingPage.all[model.onboardingPage] }

    /// Back, and a skip straight to the end. Both are hidden on the first page
    /// rather than disabled — a back arrow with nothing behind it is a control
    /// that answers "no" to the only question it raises.
    private var header: some View {
        HStack {
            if model.onboardingPage > 0 {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .frame(width: 38, height: 38)
                        .background(Color.fieldFill, in: Circle())
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .accessibilityLabel("Back")
            }

            Spacer()

            AppearanceButton(model: model)

            if model.onboardingPage < OnboardingPage.all.count - 1 {
                Button("Skip") {
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        model.onboardingPage = OnboardingPage.all.count - 1
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.inkFaint)
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, Metrics.gutter)
        .animation(.easeInOut(duration: 0.22), value: model.onboardingPage)
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingPage.all) { page in
                Capsule()
                    .fill(page.id == model.onboardingPage ? Color.ink : Color.hairline)
                    .frame(width: page.id == model.onboardingPage ? 18 : 6, height: 6)
                    .animation(.spring(response: 0.36, dampingFraction: 0.75),
                               value: model.onboardingPage)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func illustration(for page: Int) -> some View {
        let active = playing == page
        switch page {
        case 0: StackedCardsIllustration(deal: active)
        case 1: RouteMapIllustration(draw: active)
        default: ScatterIllustration(settle: active)
        }
    }

    /// Clearing first is what makes an entrance replay: an animation running
    /// to the value it already holds does nothing at all.
    private func play(_ page: Int) {
        playing = nil
        DispatchQueue.main.async { playing = page }
    }

    private func advance() {
        Haptics.step()
        if model.onboardingPage < OnboardingPage.all.count - 1 {
            withAnimation(.easeInOut(duration: 0.34)) { model.onboardingPage += 1 }
        } else {
            onFinish()
        }
    }

    private func back() {
        Haptics.tap()
        withAnimation(.easeInOut(duration: 0.3)) { model.onboardingPage -= 1 }
    }
}

#Preview { OnboardingView(model: AppModel()) {} }

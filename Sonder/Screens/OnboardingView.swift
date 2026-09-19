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

    var body: some View {
        ZStack {
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
                .padding(.bottom, 26)
                // Re-fading the copy on each page keeps the eye on the words
                // while the illustration slides underneath it.
                .id(model.onboardingPage)
                .transition(.opacity)

                Button(current.action, action: advance)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.bottom, 8)
            }
        }
    }

    private var current: OnboardingPage { OnboardingPage.all[model.onboardingPage] }

    @ViewBuilder
    private func illustration(for page: Int) -> some View {
        switch page {
        case 0: StackedCardsIllustration()
        case 1: RouteMapIllustration()
        default: ScatterIllustration()
        }
    }

    private func advance() {
        Haptics.step()
        if model.onboardingPage < OnboardingPage.all.count - 1 {
            withAnimation(.easeInOut(duration: 0.34)) { model.onboardingPage += 1 }
        } else {
            onFinish()
        }
    }
}

#Preview { OnboardingView(model: AppModel()) {} }

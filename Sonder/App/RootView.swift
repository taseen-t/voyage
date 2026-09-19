import SwiftUI

struct RootView: View {
    @State private var model = AppModel()

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()

            switch model.step {
            case .splash:
                SplashView { advance(to: model.stepAfterSplash) }
                    .transition(.opacity)

            case .onboarding:
                OnboardingView(model: model) { advance(to: .auth) }
                    .transition(rise)

            case .auth:
                AuthView(model: model) {
                    model.markOnboarded()
                    advance(to: .home)
                }
                .transition(rise)

            case .home:
                HomeView(model: model)
                    .transition(rise)
            }
        }
        .animation(.easeInOut(duration: 0.34), value: model.step)
        .preferredColorScheme(model.appearance.colorScheme)
        .animation(.easeInOut(duration: 0.25), value: model.appearance)
    }

    /// The next screen scales up to meet the viewer while the last one fades
    /// past — the same gesture the splash makes, reused so the app has one
    /// idea about how it moves forward.
    private var rise: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.96).combined(with: .opacity),
            removal: .opacity
        )
    }

    private func advance(to step: Step) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            model.step = step
        }
    }
}

#Preview { RootView() }

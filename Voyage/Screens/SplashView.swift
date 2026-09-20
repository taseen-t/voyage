import SwiftUI

/// The launch moment: the mark alone on the page, then out. It holds long
/// enough to be seen and not a beat longer.
struct SplashView: View {
    var onFinish: () -> Void

    @State private var shown = false

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()
            AppMark(side: 78)
                .scaleEffect(shown ? 1 : 0.86)
                .opacity(shown ? 1 : 0)
        }
        .task {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.72)) { shown = true }
            try? await Task.sleep(for: .milliseconds(1250))
            onFinish()
        }
    }
}

#Preview { SplashView {} }

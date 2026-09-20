import SwiftUI

/// The primary action. Always the inverse of the page — near-black on the light
/// theme, near-white on the dark — which is the move the whole design rests on.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration)
    }

    /// Nested so it can read `isEnabled`, which a `ButtonStyle` cannot.
    /// Deliberately *not* named `Body`: that is `ButtonStyle`'s own associated
    /// type, so the compiler binds it and then reports the style as failing to
    /// conform — an error that names neither the cause nor this line.
    private struct PrimaryButtonBody: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.buttonLabel)
                // Disabled is drawn, not faded. Dropping the whole control
                // to a low opacity takes the label's contrast down with it,
                // which leaves the button unreadable rather than merely inert.
                .foregroundStyle(isEnabled ? Color.controlLabel : Color.inkFaint)
                .frame(maxWidth: .infinity)
                .frame(height: Metrics.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: Metrics.buttonRadius, style: .continuous)
                        .fill(isEnabled ? Color.control : Color.hairline)
                )
                .opacity(configuration.isPressed && isEnabled ? 0.82 : 1)
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
        }
    }
}

/// The identity providers. Quiet by design: they are alternatives to the
/// primary action, not competitors with it.
struct ProviderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonLabel)
            .foregroundStyle(Color.inkMuted)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: Metrics.buttonRadius, style: .continuous)
                    .fill(Color.fieldFill)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

/// A control drawn on top of a photograph. Uses a material rather than a flat
/// translucent fill so it picks up the colour of whatever it is sitting on,
/// which is what keeps it legible over both a bright sky and a dark street.
struct GlassButtonStyle: ButtonStyle {
    var shape: AnyShape = AnyShape(Capsule())

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(.ultraThinMaterial.opacity(0.82), in: shape)
            .overlay(shape.stroke(.white.opacity(0.22), lineWidth: 0.5))
            .environment(\.colorScheme, .dark)   // materials over photos read dark
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

/// The email field on the auth screen.
struct VoyageTextFieldStyle: TextFieldStyle {
    // swiftlint:disable:next identifier_name
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 14))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 16)
            .frame(height: Metrics.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous)
                    .fill(Color.fieldFill)
            )
    }
}

/// Blur rising from the **physical** bottom edge, behind a floating control.
///
/// Pinned past the safe area rather than attached to the control it sits under.
/// A bar in a `safeAreaInset` is laid out *inside* that inset, so a background
/// it carries stops there and the page keeps going below it — which is how the
/// trip detail ended up with its itinerary legible under the flight card.
///
/// `.regularMaterial`, not `.ultraThin`: this has to turn what scrolls under it
/// into texture rather than leave it competing with the control on top.
struct BottomFade: View {
    var height: CGFloat = 160

    var body: some View {
        Rectangle()
            .fill(.regularMaterial)
            .mask(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: .black.opacity(0.22), location: 0.26),
                    .init(color: .black.opacity(0.72), location: 0.52),
                    .init(color: .black, location: 0.74),
                    .init(color: .black, location: 1.00),
                ], startPoint: .top, endPoint: .bottom)
            )
            .frame(height: height)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

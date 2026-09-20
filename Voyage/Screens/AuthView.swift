import SwiftUI

struct AuthView: View {
    @Bindable var model: AppModel
    var onContinue: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    AppearanceButton(model: model)
                }
                .padding(.top, 4)

                Spacer(minLength: 0)

                Text("Your next trip starts here.")
                    .font(.display)
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 26)

                TextField("", text: $model.email,
                          prompt: Text("johndoe@acme.xyz")
                            .foregroundStyle(Color.inkFaint))
                    .textFieldStyle(VoyageTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.continue)
                    .focused($focused)
                    .onSubmit(submit)
                    .padding(.bottom, 12)

                Button("Continue", action: submit)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!model.emailLooksValid)

                divider.padding(.vertical, 20)

                VStack(spacing: 10) {
                    Button(action: { provider() }) {
                        Label { Text("Continue with Google") } icon: { GoogleGlyph() }
                    }
                    .buttonStyle(ProviderButtonStyle())

                    Button(action: { provider() }) {
                        Label("Continue with Apple", systemImage: "apple.logo")
                    }
                    .buttonStyle(ProviderButtonStyle())
                }

                Spacer(minLength: 0)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Metrics.gutter)
        }
        .contentShape(Rectangle())
        .onTapGesture { focused = false }
    }

    private var divider: some View {
        HStack(spacing: 14) {
            line
            Text("OR").font(.label).foregroundStyle(Color.inkFaint)
            line
        }
    }

    private var line: some View {
        Rectangle().fill(Color.hairline).frame(height: 1)
    }

    private func submit() {
        guard model.emailLooksValid else { return }
        focused = false
        Haptics.confirm()
        onContinue()
    }

    /// Nothing is wired to a real identity provider. Rather than pretend, these
    /// take the same path the email does — and the gap is written down in the
    /// docs instead of hidden behind a spinner.
    private func provider() {
        Haptics.confirm()
        onContinue()
    }
}

/// Google's mark is the one glyph SF Symbols has no stand-in for. Drawn rather
/// than bundled, so no third-party artwork ships in the binary.
/// Google's mark is the one glyph SF Symbols has no stand-in for, so it is
/// drawn rather than bundled — no third-party artwork ships in the binary.
///
/// > Note: Google's brand guidelines ask for their official asset, unmodified.
/// > A redrawn approximation is fine for a portfolio build with no real Google
/// > sign-in behind it, and would need replacing before shipping. See
/// > `Voyage open items`.
private struct GoogleGlyph: View {
    // Degrees, clockwise from three o'clock, in SwiftUI's y-down space.
    // The gap between `red` ending and `blue` beginning is the G's opening;
    // the bar fills it.
    private static let arcs: [(from: Double, to: Double, colour: UInt32)] = [
        (  45, 135, 0x34A853),   // green  — bottom
        ( 135, 212, 0xFBBC05),   // yellow — left
        ( 212, 337, 0xEA4335),   // red    — top
        ( 357, 405, 0x4285F4),   // blue   — right, continuing past 360
    ]

    var body: some View {
        Canvas { ctx, size in
            let side = min(size.width, size.height)
            let width = side * 0.26
            // Radius to the centre of the stroke, so the mark fills the frame
            // without the stroke spilling out of it.
            let r = (side - width) / 2
            let c = CGPoint(x: size.width / 2, y: size.height / 2)

            for arc in Self.arcs {
                var p = Path()
                p.addArc(center: c, radius: r,
                         startAngle: .degrees(arc.from), endAngle: .degrees(arc.to),
                         clockwise: false)
                ctx.stroke(p, with: .color(Color(rgb: arc.colour)),
                           style: StrokeStyle(lineWidth: width, lineCap: .butt))
            }

            // The crossbar. It reaches from the centre out to the ring's outer
            // edge, which is what turns the ring into a G.
            ctx.fill(
                Path(CGRect(x: c.x - width * 0.1, y: c.y - width / 2,
                            width: r + width / 2 + width * 0.1, height: width)),
                with: .color(Color(rgb: 0x4285F4))
            )
        }
        .frame(width: 16, height: 16)
        .accessibilityHidden(true)
    }
}

#Preview { AuthView(model: AppModel()) {} }

import SwiftUI

struct AuthView: View {
    @Bindable var model: AppModel
    var onContinue: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
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
                    .textFieldStyle(SonderTextFieldStyle())
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
private struct GoogleGlyph: View {
    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) / 2
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let quarters: [(Double, Double, Color)] = [
                (-45,   45, Color(rgb: 0x4285F4)),   // blue, right
                ( 45,  135, Color(rgb: 0x34A853)),   // green, bottom
                (135,  200, Color(rgb: 0xFBBC05)),   // yellow, left
                (200,  315, Color(rgb: 0xEA4335)),   // red, top
            ]
            for (from, to, colour) in quarters {
                var p = Path()
                p.addArc(center: c, radius: r * 0.78,
                         startAngle: .degrees(from), endAngle: .degrees(to), clockwise: false)
                ctx.stroke(p, with: .color(colour), style: StrokeStyle(lineWidth: r * 0.44))
            }
            // The bar and the notch that make it a G rather than a ring.
            ctx.fill(Path(CGRect(x: c.x, y: c.y - r * 0.20, width: r, height: r * 0.40)),
                     with: .color(Color(rgb: 0x4285F4)))
            ctx.fill(Path(CGRect(x: c.x + r * 0.30, y: c.y - r * 0.62,
                                 width: r * 0.80, height: r * 0.44)),
                     with: .color(.clear))
        }
        .frame(width: 15, height: 15)
    }
}

#Preview { AuthView(model: AppModel()) {} }

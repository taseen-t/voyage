import SwiftUI

/// Cycles system → light → dark. A single button rather than a three-way
/// control, because in the places it appears — over an illustration, beside a
/// Skip link — there is room for one glyph and not for three.
///
/// The full choice lives on the account screen, where it can be labelled.
struct AppearanceButton: View {
    @Bindable var model: AppModel

    var body: some View {
        Button {
            Haptics.tap()
            withAnimation(.easeInOut(duration: 0.25)) { model.appearance = model.appearance.next }
        } label: {
            Image(systemName: model.appearance.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.ink)
                .frame(width: 38, height: 38)
                .background(Color.fieldFill, in: Circle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Theme: \(model.appearance.label)")
        .accessibilityHint("Switches between system, light and dark")
    }
}

/// The labelled version, for the account screen.
struct AppearancePicker: View {
    @Bindable var model: AppModel

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Appearance.allCases) { option in
                let selected = model.appearance == option
                Button {
                    guard !selected else { return }
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.25)) { model.appearance = option }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: option.symbol)
                            .font(.system(size: 15, weight: .semibold))
                        Text(option.label)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(selected ? Color.controlLabel : Color.inkMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selected ? Color.control : Color.fieldFill)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
    }
}

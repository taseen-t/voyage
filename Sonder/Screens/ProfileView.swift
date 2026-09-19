import SwiftUI

/// Where the avatar goes. Deliberately short: there is no account behind it,
/// and a settings screen full of switches that do nothing would be a worse lie
/// than a screen that says so.
struct ProfileView: View {
    @Bindable var model: AppModel
    var onClose: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 76))
                        .foregroundStyle(Color.inkFaint, Color.fieldFill)
                        .padding(.top, 10)

                    VStack(spacing: 4) {
                        Text(model.email.isEmpty ? "Signed in" : model.email)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.ink)
                        Text("\(model.trips.count) trips · "
                             + "\(model.trips.filter(\.isSaved).count) saved")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.inkFaint)
                    }

                    stats

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Theme")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        AppearancePicker(model: model)
                    }

                    Text("There is no account service behind this screen yet — no "
                         + "backend, no session, nothing stored but whether you have "
                         + "seen the onboarding. It is listed honestly in the project "
                         + "notes rather than dressed up with switches that do nothing.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)

                    Button("Start over") {
                        Haptics.confirm()
                        model.reset()
                        onClose()
                    }
                    .buttonStyle(ProviderButtonStyle())
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 40)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.ink)
                            .frame(width: 36, height: 36)
                            .background(Color.fieldFill, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 6)
                .background(Color.surface)
            }
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            stat("\(model.trips(for: .upcoming).count)", "Upcoming")
            stat("\(model.trips(for: .past).count)", "Past")
            stat(Money.label(model.trips.reduce(0) { $0 + $1.budget }), "Budgeted")
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.ink)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

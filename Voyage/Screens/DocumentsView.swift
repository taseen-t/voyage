import SwiftUI

/// What you need in hand before you fly.
struct DocumentsView: View {
    let trip: Trip
    var onClose: () -> Void

    @State private var appeared = false

    private var documents: [TravelDocument] { TravelDocument.all(for: trip) }
    private var outstanding: Int { documents.filter { $0.state != .ready }.count }

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(documents.enumerated()), id: \.element.id) { i, doc in
                        DocumentRow(document: doc)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 14)
                            .animation(.easeOut(duration: 0.36).delay(Double(i) * 0.06),
                                       value: appeared)
                    }

                    Text("Entry requirements here are illustrative. Check the "
                         + "official guidance for your own passport before you travel.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        .padding(.horizontal, 10)
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 40)
            }
            .safeAreaInset(edge: .top, spacing: 0) { header }
        }
        .onAppear { appeared = true }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Documents")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.ink)
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
            Text(outstanding == 0
                 ? "Everything is in order for \(trip.destination.city)."
                 : "\(outstanding) still to sort before \(TripFormat.dayMonth.string(from: trip.start)).")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Color.inkFaint)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 14)
        .background(Color.surface)
    }
}

private struct DocumentRow: View {
    let document: TravelDocument

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: document.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.inkMuted)
                .frame(width: 38, height: 38)
                .background(Color.fieldFill, in: RoundedRectangle(
                    cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(document.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Text(document.detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Text(document.state.label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(document.state.tint)
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(document.state.tint.opacity(0.14), in: Capsule())
        }
        .padding(13)
        .background(Color.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

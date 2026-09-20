import SwiftUI

/// Where the money goes. The lines are derived from the trip's own budget
/// rather than stored beside it, so the parts always add up to the total the
/// traveller was shown.
struct BudgetView: View {
    let trip: Trip
    var onClose: () -> Void

    @State private var appeared = false

    private var lines: [BudgetLine] { BudgetLine.breakdown(for: trip) }
    private var committed: Int { lines.reduce(0) { $0 + $1.spent } }
    private var nights: Int {
        Calendar.current.dateComponents([.day], from: trip.start, to: trip.end).day ?? 1
    }

    var body: some View {
        ZStack {
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    total
                    bar
                    VStack(spacing: 10) {
                        ForEach(Array(lines.enumerated()), id: \.element.id) { i, line in
                            LineRow(line: line)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 14)
                                .animation(.easeOut(duration: 0.36).delay(0.15 + Double(i) * 0.06),
                                           value: appeared)
                        }
                    }
                    footnote
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 40)
            }
            .safeAreaInset(edge: .top, spacing: 0) { header }
        }
        .onAppear { appeared = true }
    }

    private var header: some View {
        HStack {
            Text("Budget")
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
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, Metrics.sheetTop)
        .padding(.bottom, 12)
        .background(Color.surface)
    }

    private var total: some View {
        VStack(spacing: 5) {
            Text(trip.budgetLabel)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Color.accent)
                .monospacedDigit()
            Text("\(Money.label(trip.budget / max(nights, 1))) a day across \(nights) nights")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Color.inkFaint)
        }
        .padding(.top, 6)
    }

    /// One bar, split by share. Reads as a whole being divided rather than as
    /// five unrelated numbers.
    private var bar: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(Array(lines.enumerated()), id: \.element.id) { i, line in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(tint(i))
                        .frame(width: max((geo.size.width - 8) * line.share * (appeared ? 1 : 0), 0))
                        .animation(.spring(response: 0.6, dampingFraction: 0.85)
                            .delay(Double(i) * 0.05), value: appeared)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: 12)
    }

    /// Five steps of the accent, so the bar is one idea rather than a rainbow.
    private func tint(_ i: Int) -> Color {
        Color.accent.opacity(1.0 - Double(i) * 0.17)
    }

    private var footnote: some View {
        VStack(spacing: 6) {
            Divider().overlay(Color.hairline)
            HStack {
                Text("Committed so far")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkMuted)
                Spacer()
                Text(Money.label(committed))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.ink)
            }
            Text("Shares are a starting split, not a recommendation — nothing "
                 + "here is priced against a real supplier.")
                .font(.system(size: 10.5))
                .foregroundStyle(Color.inkFaint)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        }
        .padding(.top, 4)
    }
}

private struct LineRow: View {
    let line: BudgetLine

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: line.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.inkMuted)
                .frame(width: 34, height: 34)
                .background(Color.fieldFill, in: RoundedRectangle(
                    cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(line.name)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Text(Money.label(line.amount))
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .monospacedDigit()
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.hairline)
                        Capsule().fill(Color.accent)
                            .frame(width: geo.size.width * line.spentShare)
                    }
                }
                .frame(height: 4)
                Text(line.spent == 0 ? "Nothing committed"
                                     : "\(Money.label(line.spent)) committed")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.inkFaint)
            }
        }
        .padding(12)
        .background(Color.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

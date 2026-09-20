import SwiftUI

// MARK: - Budget

/// Where the money goes. Split from the trip's own budget rather than stored,
/// so the two can never disagree about the total.
struct BudgetLine: Identifiable, Hashable {
    let name: String
    let symbol: String
    /// Fraction of the whole.
    let share: Double
    let amount: Int
    /// How much of this line is already committed.
    let spent: Int

    /// Derived, not minted — see the note on `Flight.id`. Line names are
    /// unique within a breakdown.
    var id: String { name }

    var spentShare: Double { amount == 0 ? 0 : Double(spent) / Double(amount) }
}

extension BudgetLine {
    static func breakdown(for trip: Trip) -> [BudgetLine] {
        // Rounded to whole dollars and the remainder given to the last line,
        // so the parts always add up to the total a traveller was shown.
        let plan: [(String, String, Double, Double)] = [
            ("Flights", "airplane", 0.32, 1.00),
            ("Stay", "bed.double", 0.34, 0.60),
            ("Food", "fork.knife", 0.18, 0.15),
            ("Activities", "figure.walk", 0.12, 0.10),
            ("Everything else", "bag", 0.04, 0.00),
        ]
        var remaining = trip.budget
        return plan.enumerated().map { i, line in
            let amount = i == plan.count - 1 ? remaining : Int((Double(trip.budget) * line.2).rounded())
            remaining -= amount
            return BudgetLine(name: line.0, symbol: line.1, share: line.2,
                              amount: amount, spent: Int(Double(amount) * line.3))
        }
    }
}

// MARK: - Documents

struct TravelDocument: Identifiable, Hashable {
    enum State: String {
        case ready, pending, missing

        var label: String {
            switch self {
            case .ready: "Ready"
            case .pending: "Waiting"
            case .missing: "Needed"
            }
        }

        var tint: Color {
            switch self {
            case .ready: Color(rgb: 0x2E9E5B)
            case .pending: Color(rgb: 0xE0A21C)
            case .missing: .accent
            }
        }
    }

    let name: String
    let detail: String
    let symbol: String
    let state: State

    /// Derived, not minted — see the note on `Flight.id`.
    var id: String { name }
}

extension TravelDocument {
    static func all(for trip: Trip) -> [TravelDocument] {
        let visaNeeded = trip.destination.needsVisa
        return [
            .init(name: "Passport", detail: "Expires Mar 2031 · 4 years left",
                  symbol: "person.text.rectangle", state: .ready),
            .init(name: visaNeeded ? "Visa" : "Visa not required",
                  detail: visaNeeded ? "Apply at least 15 days before you fly"
                                     : "Visa-free on a UK passport",
                  symbol: "doc.text", state: visaNeeded ? .missing : .ready),
            .init(name: "Boarding pass",
                  detail: "Opens 24 hours before departure",
                  symbol: "airplane.departure", state: .pending),
            .init(name: "Stay confirmation",
                  detail: "Nothing booked yet",
                  symbol: "bed.double", state: .missing),
            .init(name: "Travel insurance",
                  detail: "Annual policy · covers this trip",
                  symbol: "shield.lefthalf.filled", state: .ready),
        ]
    }
}

private extension Destination {
    /// Illustrative, and stated as such on the screen. Entry rules are not
    /// something to assert from a hardcoded table in a demo.
    var needsVisa: Bool {
        switch self {
        case .marrakesh, .cappadocia, .queenstown: true
        default: false
        }
    }
}

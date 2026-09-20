import Foundation

struct Trip: Identifiable, Hashable {
    let id: UUID
    let destination: Destination
    let start: Date
    let end: Date
    /// Whole dollars. A trip budget is never quoted to the cent, and storing it
    /// as an `Int` keeps the formatter from ever inventing one.
    let budget: Int
    var isSaved: Bool
    /// What has actually been chosen for this trip. Both stay `nil` until
    /// someone picks one — the buttons that set them said "Save to trip" and
    /// saved nothing at all until they existed.
    var flight: Flight?
    var stay: Stay?

    init(id: UUID = UUID(), destination: Destination, start: Date, end: Date,
         budget: Int, isSaved: Bool = false) {
        self.id = id
        self.destination = destination
        self.start = start
        self.end = end
        self.budget = budget
        self.isSaved = isSaved
    }

    var title: String { destination.title }
}

// MARK: - Presentation

extension Trip {
    /// "Oct 3 – Oct 10, 2026". Both ends carry their month because a trip that
    /// crosses one is the case a traveller most needs to see.
    func dateRange(_ calendar: Calendar = .current) -> String {
        let year = TripFormat.year.string(from: end)
        return "\(TripFormat.dayMonth.string(from: start)) – "
             + "\(TripFormat.dayMonth.string(from: end)), \(year)"
    }

    /// "Today" / "Tomorrow" / "In 32 days" / "Last month".
    func countdown(from now: Date = .now, calendar: Calendar = .current) -> String {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: start)
        ).day ?? 0

        switch days {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case 2...: return "In \(days) days"
        default:
            let ago = -days
            return ago < 30 ? "\(ago) days ago" : TripFormat.monthYear.string(from: start)
        }
    }

    /// A trip is upcoming until the day it ends is behind us — a traveller
    /// mid-trip should still find it under Upcoming, not under Past.
    func isUpcoming(from now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.startOfDay(for: end) >= calendar.startOfDay(for: now)
    }

    var budgetLabel: String { Money.label(budget) }
}

/// Money, formatted once.
///
/// The design sets prices without a thousands separator — "$2400", not
/// "$2,400" — and every amount goes through here so they cannot disagree.
///
/// This exists because they did. `Text("$\(amount)")` takes the
/// `LocalizedStringKey` overload, which groups the digits, while
/// `Text(someString)` does not — so the same number rendered "$1,800" on one
/// screen and "$1800" on another, from what looks like identical code.
enum Money {
    static func label(_ amount: Int) -> String { "$\(amount)" }
}

/// Formatters are built once. Creating a `DateFormatter` costs roughly as much
/// as formatting a hundred dates with one, and a list that builds them per row
/// pays that on every frame of a scroll.
enum TripFormat {
    static let dayMonth: DateFormatter = fixed("MMM d")
    static let year: DateFormatter = fixed("yyyy")
    static let monthYear: DateFormatter = fixed("MMM yyyy")
    /// The header's "Fri Sep 18, 2026".
    static let header: DateFormatter = fixed("EEE MMM d, yyyy")
    /// Flight departure and arrival.
    static let time: DateFormatter = fixed("HH:mm")
    /// Itinerary day rows — "Sat 3 Oct".
    static let dayLine: DateFormatter = fixed("EEE d MMM")

    private static func fixed(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate(format)
        f.dateFormat = format
        return f
    }
}

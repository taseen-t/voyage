import Foundation

struct Flight: Identifiable, Hashable, Codable {
    let airline: String
    let number: String
    let origin: String
    let destination: String
    let departs: Date
    let arrives: Date
    let stops: Int
    let price: Int

    /// Derived from the flight itself rather than stored as a `UUID`.
    ///
    /// A generated list is rebuilt every time the view's body runs, so a minted
    /// id is a *different* id on every render — which made selection look
    /// broken (the row never highlighted, while the button below it enabled
    /// because something was nominally selected) and made `ForEach` treat
    /// every row as new, rebuilding rather than animating.
    var id: String { "\(number)@\(Int(departs.timeIntervalSince1970))" }

    var duration: String {
        let minutes = Int(arrives.timeIntervalSince(departs) / 60)
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    var stopsLabel: String {
        switch stops {
        case 0: "Direct"
        case 1: "1 stop"
        default: "\(stops) stops"
        }
    }

    var window: String {
        "\(TripFormat.time.string(from: departs)) – \(TripFormat.time.string(from: arrives))"
    }
}

extension Flight {
    /// Plausible options for a trip, generated from a **seed derived from the
    /// trip itself**. The same trip therefore always offers the same flights:
    /// a results list that reshuffles every time it is opened reads as a bug,
    /// and makes "the one I saw a minute ago" impossible to find again.
    static func options(for trip: Trip, from origin: String = "LHR") -> [Flight] {
        var seed = Seed.value(for: trip)
        func next(_ bound: Int) -> Int {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Int((seed >> 33) % UInt64(max(bound, 1)))
        }

        let carriers = [
            ("Aer Vega", "VG"), ("Northwind", "NW"), ("Meridian", "MD"),
            ("Kestrel", "KS"), ("Lumen Air", "LM"),
        ]
        let calendar = Calendar.current

        return (0..<5).map { i in
            let carrier = carriers[(next(carriers.count) + i) % carriers.count]
            let departHour = 6 + next(13)
            let departs = calendar.date(
                bySettingHour: departHour, minute: next(4) * 15, second: 0, of: trip.start
            ) ?? trip.start
            let stops = i == 0 ? 0 : next(3) == 0 ? 0 : (next(4) == 0 ? 2 : 1)
            let hours = 7 + stops * 3 + next(4)
            return Flight(
                airline: carrier.0,
                // Banded by index so two options can never carry the same
                // number: the same route twice in a day under one number reads
                // as a bug, and `id` is built from the number and the time.
                number: "\(carrier.1) \(120 + i * 90 + next(80))",
                origin: origin,
                destination: trip.destination.airport,
                departs: departs,
                arrives: calendar.date(byAdding: .minute,
                                       value: hours * 60 + next(50), to: departs) ?? departs,
                stops: stops,
                price: 180 + next(9) * 55 + (stops == 0 ? 140 : 0)
            )
        }
        .sorted { $0.price < $1.price }
    }
}

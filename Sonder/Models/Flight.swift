import Foundation

struct Flight: Identifiable, Hashable {
    let id: UUID
    let airline: String
    let number: String
    let origin: String
    let destination: String
    let departs: Date
    let arrives: Date
    let stops: Int
    let price: Int

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
        var seed = UInt64(truncatingIfNeeded: trip.destination.rawValue.hashValue)
            ^ UInt64(trip.start.timeIntervalSince1970)
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
                id: UUID(),
                airline: carrier.0,
                number: "\(carrier.1) \(100 + next(880))",
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

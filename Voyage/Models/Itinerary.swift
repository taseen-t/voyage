import Foundation

struct ItineraryItem: Identifiable, Hashable {
    enum Kind: String {
        case flight, stay, activity, food

        var symbol: String {
            switch self {
            case .flight: "airplane"
            case .stay: "bed.double"
            case .activity: "figure.walk"
            case .food: "fork.knife"
            }
        }
    }

    let time: String
    let title: String
    let kind: Kind

    /// Derived, not minted — see the note on `Flight.id`.
    var id: String { "\(time)-\(kind.rawValue)-\(title)" }
}

struct ItineraryDay: Identifiable, Hashable {
    var id: Int { number }
    let number: Int
    let date: Date
    let items: [ItineraryItem]
}

extension ItineraryDay {
    /// A plan built from the trip's own shape: arrival on the first day,
    /// departure on the last, and something to do in between. Deterministic,
    /// for the same reason `Flight.options` is.
    static func plan(for trip: Trip) -> [ItineraryDay] {
        let calendar = Calendar.current
        let days = max(calendar.dateComponents([.day], from: trip.start, to: trip.end).day ?? 1, 1)
        var seed = Seed.value(for: trip, salt: 7)
        func next(_ bound: Int) -> Int {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Int((seed >> 33) % UInt64(max(bound, 1)))
        }

        let outings = trip.destination.outings
        let meals = ["Breakfast nearby", "Long lunch", "Dinner booked", "Street food crawl"]

        // Ninety minutes after landing, or the old placeholder when no flight
        // has been chosen yet.
        let checkIn = trip.flight.map { calendar.date(byAdding: .minute, value: 90,
                                                      to: $0.arrives) ?? $0.arrives }
        let checkInTime = checkIn.map { TripFormat.time.string(from: $0) } ?? "16:20"

        return (0...days).map { d in
            let date = calendar.date(byAdding: .day, value: d, to: trip.start) ?? trip.start
            var items: [ItineraryItem] = []

            if d == 0 {
                // A chosen flight or stay replaces the placeholder line, so
                // the itinerary shows what was actually picked rather than
                // the choice vanishing the moment the sheet closed.
                if let f = trip.flight {
                    items.append(.init(time: TripFormat.time.string(from: f.departs),
                                       title: "\(f.airline) \(f.number) to \(f.destination)",
                                       kind: .flight))
                } else {
                    items.append(.init(time: "09:40",
                                       title: "Fly to \(trip.destination.airport)", kind: .flight))
                }
                // Check-in follows the flight rather than sitting at a fixed
                // 16:20 — a red-eye landing at 01:00 had you checking in ten
                // minutes *before* take-off.
                if checkIn == nil || calendar.isDate(checkIn!, inSameDayAs: date) {
                    items.append(.init(time: checkInTime,
                                       title: trip.stay.map { "Check in at \($0.name)" } ?? "Check in",
                                       kind: .stay))
                }
                items.append(.init(time: "19:30", title: meals[next(meals.count)], kind: .food))
            } else if let checkIn, calendar.isDate(checkIn, inSameDayAs: date), d < days {
                items.append(.init(time: checkInTime,
                                   title: trip.stay.map { "Check in at \($0.name)" } ?? "Check in",
                                   kind: .stay))
                items.append(.init(time: "09:00", title: meals[0], kind: .food))
                items.append(.init(time: "13:30", title: outings[next(outings.count)], kind: .activity))
            } else if d == days {
                items.append(.init(time: "10:00", title: "Check out", kind: .stay))
                items.append(.init(time: "14:15", title: "Fly home", kind: .flight))
            } else {
                // The afternoon outing steps off the morning's rather than
                // drawing again, so a day cannot list the same place twice.
                let morning = next(outings.count)
                items.append(.init(time: "09:00", title: meals[0], kind: .food))
                items.append(.init(time: "10:30", title: outings[morning], kind: .activity))
                items.append(.init(time: "13:30", title: meals[1 + next(meals.count - 1)], kind: .food))
                if next(3) != 0 {
                    let afternoon = (morning + 1 + next(outings.count - 1)) % outings.count
                    items.append(.init(time: "16:00", title: outings[afternoon], kind: .activity))
                }
            }
            return ItineraryDay(number: d + 1, date: date, items: items)
        }
    }
}

private extension Destination {
    var outings: [String] {
        switch self {
        case .kyoto: ["Kiyomizu-dera at opening", "Fushimi Inari before the crowd",
                      "Philosopher's Path", "Nishiki Market", "Arashiyama bamboo"]
        case .lisbon: ["Tram 28 end to end", "Belém Tower", "Alfama on foot",
                       "LX Factory", "Miradouro at golden hour"]
        case .fuji: ["Lake Kawaguchi loop", "Chureito Pagoda", "Onsen with a view",
                     "Oshino Hakkai springs"]
        case .banff: ["Moraine Lake canoe", "Johnston Canyon", "Sulphur Mountain gondola",
                      "Lake Louise shoreline"]
        case .santorini: ["Oia at sunset", "Red Beach", "Akrotiri ruins",
                          "Caldera boat trip", "Winery tasting"]
        case .iceland: ["Goðafoss", "Seljalandsfoss walk-behind", "Black sand at Reynisfjara",
                        "Blue Lagoon", "Northern lights drive"]
        case .norway: ["Reine viewpoint", "Kayak the fjord", "Haukland beach",
                       "Fishing village walk"]
        case .queenstown: ["Skyline gondola", "Milford Sound day trip", "Bungy at Kawarau",
                           "Lake Wakatipu cruise"]
        case .hallstatt: ["Salt mine tour", "Skywalk viewpoint", "Boat across the lake",
                          "Dachstein ice caves"]
        case .marrakesh: ["Jemaa el-Fnaa after dark", "Bahia Palace", "Majorelle Garden",
                          "Souk without a map", "Hammam"]
        case .dolomites: ["Tre Cime loop", "Seceda ridgeline", "Lago di Braies at dawn",
                          "Alpe di Siusi"]
        case .cappadocia: ["Balloon at sunrise", "Göreme open-air museum",
                           "Red Valley hike", "Underground city", "Pottery in Avanos"]
        }
    }
}

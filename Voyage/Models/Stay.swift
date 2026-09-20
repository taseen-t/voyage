import SwiftUI

/// Somewhere to sleep.
///
/// Hardcoded, like the flights: there is no supplier behind this and inventing
/// one in the interface would be the lie. Names and areas are generated from
/// the destination so a stay in Kyoto is not offered on a street in Lisbon.
struct Stay: Identifiable, Hashable {
    enum Kind: String, CaseIterable {
        case hotel, apartment, ryokan, cabin, villa, hostel

        var label: String {
            switch self {
            case .hotel: "Hotel"
            case .apartment: "Apartment"
            case .ryokan: "Ryokan"
            case .cabin: "Cabin"
            case .villa: "Villa"
            case .hostel: "Hostel"
            }
        }

        var image: ImageResource {
            switch self {
            case .hotel: .stayHotel
            case .apartment: .stayApartment
            case .ryokan: .stayRyokan
            case .cabin: .stayCabin
            case .villa: .stayVilla
            case .hostel: .stayHostel
            }
        }
    }

    let name: String
    let kind: Kind
    let area: String
    let rating: Double
    let reviews: Int
    let perNight: Int
    let perks: [String]

    /// Derived, not minted — see the note on `Flight.id`.
    var id: String { "\(kind.rawValue)-\(name)-\(area)" }

    var ratingLabel: String { String(format: "%.1f", rating) }
}

extension Stay {
    /// Five options for a trip, seeded from the trip itself so the list is the
    /// same every time it is opened. See `Flight.options` — same reasoning.
    static func options(for trip: Trip) -> [Stay] {
        var seed = UInt64(truncatingIfNeeded: trip.destination.rawValue.hashValue) &+ 99
        func next(_ bound: Int) -> Int {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Int((seed >> 33) % UInt64(max(bound, 1)))
        }

        let areas = trip.destination.areas
        let kinds = trip.destination.stayKinds
        let names = ["The Quiet Hours", "Maison Vela", "Casa Brava", "The Longwalk",
                     "Hold Fast House", "Mirador", "Nine Lanterns", "The Gable"]
        let perkPool = [["Breakfast", "Free cancel"], ["Kitchen", "Washer"],
                        ["Onsen", "Breakfast"], ["Fireplace", "Parking"],
                        ["Pool", "Sea view"], ["Shared kitchen", "Lockers"]]

        // One offset, drawn once, then walked. Drawing a fresh index per row
        // let the same name come up twice — two "Hold Fast House" in one list
        // reads as a bug even though their ids differ.
        let firstName = next(names.count)

        return kinds.enumerated().map { i, kind in
            let base = [190, 120, 240, 150, 310, 42][Kind.allCases.firstIndex(of: kind) ?? 0]
            return Stay(
                name: names[(firstName + i) % names.count],
                kind: kind,
                area: areas[i % areas.count],
                rating: 8.2 + Double(next(16)) / 10,
                reviews: 60 + next(940),
                perNight: base + next(7) * 15,
                perks: perkPool[Kind.allCases.firstIndex(of: kind) ?? 0]
            )
        }
        .sorted { $0.perNight < $1.perNight }
    }
}

private extension Destination {
    /// Real neighbourhoods, so the list does not read as filler.
    var areas: [String] {
        switch self {
        case .kyoto: ["Gion", "Higashiyama", "Arashiyama", "Nakagyo"]
        case .lisbon: ["Alfama", "Chiado", "Príncipe Real", "Belém"]
        case .fuji: ["Kawaguchiko", "Fujiyoshida", "Yamanakako"]
        case .banff: ["Banff Avenue", "Tunnel Mountain", "Lake Louise"]
        case .santorini: ["Oia", "Fira", "Imerovigli", "Firostefani"]
        case .iceland: ["Akureyri", "Mývatn", "Húsavík"]
        case .norway: ["Reine", "Henningsvær", "Svolvær"]
        case .queenstown: ["Queenstown Hill", "Frankton", "Arrowtown"]
        case .hallstatt: ["Lahn", "Marktplatz", "Obertraun"]
        case .marrakesh: ["Medina", "Gueliz", "Hivernage", "Palmeraie"]
        case .dolomites: ["Ortisei", "Cortina", "Val Gardena"]
        case .cappadocia: ["Göreme", "Uçhisar", "Ürgüp"]
        }
    }

    /// What you can actually book there.
    var stayKinds: [Stay.Kind] {
        switch self {
        case .kyoto: [.ryokan, .hotel, .apartment, .hostel]
        case .fuji: [.ryokan, .cabin, .hotel]
        case .santorini, .marrakesh: [.villa, .hotel, .apartment, .hostel]
        case .banff, .norway, .dolomites, .hallstatt: [.cabin, .hotel, .apartment]
        case .iceland: [.cabin, .hotel, .hostel]
        default: [.hotel, .apartment, .hostel, .villa]
        }
    }
}

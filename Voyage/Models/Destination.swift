import SwiftUI

/// A place the app has photography for.
///
/// This is the seam the imagery sits behind. Every photograph is bundled at the
/// size it is actually displayed — a `card` at 3x of the trip card and a `tile`
/// at 3x of the small square used in the onboarding illustrations — so nothing
/// is resampled at runtime and no full-resolution original ships. Swapping the
/// photography means replacing two files per case and touching no view.
///
/// All twelve are CC0. Provenance is in `CREDITS.json` at the repository root.
enum Destination: String, CaseIterable, Identifiable, Codable {
    case kyoto, lisbon, fuji, banff, santorini, iceland
    case norway, queenstown, hallstatt, marrakesh, dolomites, cappadocia

    var id: String { rawValue }

    /// 1020×850 — the trip card at 3x.
    var card: ImageResource {
        switch self {
        case .kyoto: .kyoto
        case .lisbon: .lisbon
        case .fuji: .fuji
        case .banff: .banff
        case .santorini: .santorini
        case .iceland: .iceland
        case .norway: .norway
        case .queenstown: .queenstown
        case .hallstatt: .hallstatt
        case .marrakesh: .marrakesh
        case .dolomites: .dolomites
        case .cappadocia: .cappadocia
        }
    }

    /// 240×240 — the illustration tile at 3x.
    var tile: ImageResource {
        switch self {
        case .kyoto: .kyotoTile
        case .lisbon: .lisbonTile
        case .fuji: .fujiTile
        case .banff: .banffTile
        case .santorini: .santoriniTile
        case .iceland: .icelandTile
        case .norway: .norwayTile
        case .queenstown: .queenstownTile
        case .hallstatt: .hallstattTile
        case .marrakesh: .marrakeshTile
        case .dolomites: .dolomitesTile
        case .cappadocia: .cappadociaTile
        }
    }

    /// The airport a trip here flies into. Used to build flight results and the
    /// itinerary's first line.
    var airport: String {
        switch self {
        case .kyoto: "KIX"
        case .lisbon: "LIS"
        case .fuji: "HND"
        case .banff: "YYC"
        case .santorini: "JTR"
        case .iceland: "KEF"
        case .norway: "SVJ"
        case .queenstown: "ZQN"
        case .hallstatt: "SZG"
        case .marrakesh: "RAK"
        case .dolomites: "VCE"
        case .cappadocia: "ASR"
        }
    }

    /// Just the city, for places where the country would be repetition.
    var city: String { String(title.prefix(while: { $0 != "," })) }

    /// A line of the pitch, shown on the detail screen under the title.
    var blurb: String {
        switch self {
        case .kyoto: "Seventeen World Heritage sites and the best walking city in Japan."
        case .lisbon: "Seven hills, one river, and tram 28 doing all the work."
        case .fuji: "Clearest from the five lakes, and clearest in the morning."
        case .banff: "Glacial lakes that photograph like someone turned up the saturation."
        case .santorini: "The caldera at sunset is worth the crowd. Just about."
        case .iceland: "Waterfalls you can walk behind, an hour from the airport."
        case .norway: "Above the Arctic Circle, and green until October."
        case .queenstown: "The adventure capital, surrounded by a lake shaped like a Z."
        case .hallstatt: "Ninety minutes from Salzburg and worth every one of them."
        case .marrakesh: "Get lost in the medina on purpose. Everyone does."
        case .dolomites: "Limestone that turns pink twice a day."
        case .cappadocia: "Be in a balloon basket before sunrise or don't bother."
        }
    }

    /// What the card calls the place — city first, then country, as the design
    /// sets it.
    var title: String {
        switch self {
        case .kyoto: "Kyoto, Japan"
        case .lisbon: "Lisbon, Portugal"
        case .fuji: "Fuji, Japan"
        case .banff: "Banff, Canada"
        case .santorini: "Santorini, Greece"
        case .iceland: "Goðafoss, Iceland"
        case .norway: "Lofoten, Norway"
        case .queenstown: "Queenstown, NZ"
        case .hallstatt: "Hallstatt, Austria"
        case .marrakesh: "Marrakesh, Morocco"
        case .dolomites: "Dolomites, Italy"
        case .cappadocia: "Cappadocia, Türkiye"
        }
    }
}

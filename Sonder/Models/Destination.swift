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
enum Destination: String, CaseIterable, Identifiable {
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

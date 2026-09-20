import SwiftUI

/// San Francisco carries the interface. The headline sizes here are tight and
/// heavy — the design leans on one very large, very bold line per screen and
/// keeps everything else quiet, so the ramp has a deliberate gap in the middle.
extension Font {
    /// Onboarding and auth headlines — "Every trip, one place."
    static let display = Font.system(size: 30, weight: .bold)
    /// Card titles on the home list — "Kyoto, Japan".
    static let cardTitle = Font.system(size: 25, weight: .bold)
    /// Price.
    static let price = Font.system(size: 21, weight: .bold)
    /// Supporting paragraph under a headline.
    static let body = Font.system(size: 12.5, weight: .regular)
    /// Dates, captions, badges.
    static let label = Font.system(size: 11.5, weight: .medium)
    static let buttonLabel = Font.system(size: 15, weight: .semibold)
}

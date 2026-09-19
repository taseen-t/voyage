import UIKit

/// Physical feedback on the moments that matter. Cheap to add, and its absence
/// is a large part of why a build feels unfinished on device.
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Advancing a page, switching a tab.
    static func step() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8)
    }

    static func confirm() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

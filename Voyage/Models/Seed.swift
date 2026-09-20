import Foundation

/// A seed that survives a relaunch.
///
/// Flights, stays and itineraries are generated from the trip they belong to,
/// on the promise that the same trip always offers the same options — a list
/// that reshuffles makes "the one I saw a minute ago" impossible to find again.
///
/// That promise was broken, and invisibly. The seed was built from
/// `String.hashValue`, and **Swift randomises string hashing per process**: the
/// options were stable within one run and different on every launch, so a
/// flight saved to a trip could not be found in the list again the next day.
///
/// FNV-1a over the bytes instead — not a good hash, but a *fixed* one, which is
/// the only property that matters here.
enum Seed {
    static func value(for trip: Trip, salt: UInt64 = 0) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in trip.destination.rawValue.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        // The dates make two trips to the same place differ.
        hash ^= UInt64(bitPattern: Int64(trip.start.timeIntervalSince1970.rounded()))
        hash = hash &* 0x0000_0100_0000_01B3
        return hash &+ salt
    }
}

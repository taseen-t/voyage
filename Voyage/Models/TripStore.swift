import Foundation

/// Where the trips live between launches.
///
/// One JSON file, `Codable`, no schema and no migration story — which is the
/// right size for what this holds. SwiftData would bring a model container, a
/// context and a versioning plan to persist an array of seven structs.
///
/// Until this existed, **nothing survived a relaunch**: a trip created with
/// `+`, a bookmark, a flight or stay chosen for a trip all went back to the
/// sample data on the next launch. The app looked broken rather than
/// unfinished, because "save" is a word people take literally.
enum TripStore {
    private static let file: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory,
                                           in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("trips.json")
    }()

    /// Dates go over as ISO-8601 rather than as a floating-point interval, so a
    /// file written today still reads correctly if the encoder's default ever
    /// changes underneath it.
    private static var coders: (JSONEncoder, JSONDecoder) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (encoder, decoder)
    }

    static func load() -> [Trip]? {
        guard let data = try? Data(contentsOf: file) else { return nil }
        return try? coders.1.decode([Trip].self, from: data)
    }

    /// Failures are swallowed on purpose. There is nothing useful to do about a
    /// failed write here and nowhere to report it — losing a trip is bad, and
    /// crashing the app over it is worse.
    static func save(_ trips: [Trip]) {
        guard let data = try? coders.0.encode(trips) else { return }
        try? data.write(to: file, options: .atomic)
    }

    static func clear() {
        try? FileManager.default.removeItem(at: file)
    }
}

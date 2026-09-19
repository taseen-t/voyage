import Observation
import SwiftUI

enum Step: String {
    case splash, onboarding, auth, home
}

/// Which theme the app draws in.
///
/// `system` is the default and the honest one — it follows the device, which
/// is what a person has already told iOS they want. The two overrides exist
/// because both themes were designed, and someone should be able to see the
/// other one without changing a system setting to do it.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    /// `nil` hands the decision back to the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var next: Appearance {
        let all = Appearance.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }
}

@Observable
final class AppModel {
    var step: Step = .splash
    /// 0, 1, 2 — the three onboarding pages.
    var onboardingPage = 0
    var email = ""
    var tab: HomeTab = .upcoming
    var trips: [Trip] = Trip.sample

    /// Persisted, unlike almost everything else here: a theme someone chose
    /// and then had to choose again on every launch is worse than not offering
    /// the choice.
    var appearance: Appearance = Appearance(
        rawValue: UserDefaults.standard.string(forKey: Key.appearance) ?? ""
    ) ?? .system {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Key.appearance) }
    }

    /// Set once the user reaches home, so a returning user sees the splash and
    /// then their trips rather than the pitch again.
    private(set) var hasOnboarded = UserDefaults.standard.bool(forKey: Key.onboarded)

    /// Where the splash hands off to. The splash always plays — it is the
    /// launch moment — but it is the only thing a returning user sits through.
    var stepAfterSplash: Step { hasOnboarded ? .home : .onboarding }

    var emailLooksValid: Bool {
        let t = email.trimmingCharacters(in: .whitespaces)
        guard let at = t.firstIndex(of: "@"), at != t.startIndex else { return false }
        let domain = t[t.index(after: at)...]
        return domain.contains(".") && !domain.hasSuffix(".") && !domain.hasPrefix(".")
    }

    func markOnboarded() {
        guard !hasOnboarded else { return }
        hasOnboarded = true
        UserDefaults.standard.set(true, forKey: Key.onboarded)
    }

    /// Sheets and pushes the home screen can present. One optional rather than
    /// four booleans: only one of these can be up at a time, and four flags can
    /// disagree about that while an enum cannot.
    var route: Route?

    enum Route: Identifiable, Hashable {
        case detail(Trip)
        case flights(Trip)
        case newTrip
        case profile

        var id: String {
            switch self {
            case .detail(let t): "detail-\(t.id)"
            case .flights(let t): "flights-\(t.id)"
            case .newTrip: "new"
            case .profile: "profile"
            }
        }
    }

    func add(_ trip: Trip) {
        trips.append(trip)
        tab = trip.isUpcoming() ? .upcoming : .past
    }

    /// Back to a first launch. The only thing that survives a relaunch is the
    /// onboarding flag, so this is the whole of it.
    func reset() {
        // Appearance is deliberately kept: it is a preference, not session state.
        UserDefaults.standard.removeObject(forKey: Key.onboarded)
        hasOnboarded = false
        trips = Trip.sample
        email = ""
        onboardingPage = 0
        route = nil
        tab = .upcoming
        step = .onboarding
    }

    func toggleSaved(_ trip: Trip) {
        guard let i = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[i].isSaved.toggle()
    }

    func trips(for tab: HomeTab, now: Date = .now) -> [Trip] {
        trips
            .filter { $0.isUpcoming(from: now) == (tab == .upcoming) }
            .sorted { tab == .upcoming ? $0.start < $1.start : $0.start > $1.start }
    }

    private enum Key {
        static let onboarded = "sonder.hasOnboarded"
        static let appearance = "sonder.appearance"
    }

    #if DEBUG
    /// Jump straight to a screen: `-sonderStep auth`, or
    /// `-sonderStep onboarding -sonderPage 2`. Screenshotting six screens in
    /// two themes is twelve launches; without this it is also sixty taps, and
    /// a tap that lands a pixel off silently captures the wrong screen.
    init(launchArguments: [String] = CommandLine.arguments) {
        if let i = launchArguments.firstIndex(of: "-sonderStep"),
           i + 1 < launchArguments.count,
           let step = Step(rawValue: launchArguments[i + 1]) {
            self.step = step
            if step != .splash && step != .onboarding { markOnboarded() }
        }
        if let i = launchArguments.firstIndex(of: "-sonderTheme"),
           i + 1 < launchArguments.count,
           let a = Appearance(rawValue: launchArguments[i + 1]) {
            appearance = a
        }
        if launchArguments.contains("-sonderTab"),
           let i = launchArguments.firstIndex(of: "-sonderTab"),
           i + 1 < launchArguments.count,
           launchArguments[i + 1] == "past" {
            tab = .past
        }
        if let i = launchArguments.firstIndex(of: "-sonderRoute"),
           i + 1 < launchArguments.count {
            switch launchArguments[i + 1] {
            case "detail":  route = trips.first.map(Route.detail)
            case "flights": route = trips.first.map(Route.flights)
            case "new":     route = .newTrip
            case "profile": route = .profile
            default: break
            }
            if route != nil { step = .home; markOnboarded() }
        }
        if let i = launchArguments.firstIndex(of: "-sonderPage"),
           i + 1 < launchArguments.count,
           let page = Int(launchArguments[i + 1]), (0...2).contains(page) {
            onboardingPage = page
        }
    }
    #endif
}

enum HomeTab: String, CaseIterable, Identifiable {
    case upcoming = "Upcoming", past = "Past"
    var id: String { rawValue }
}

// MARK: - Sample itinerary

extension Trip {
    /// The two trips in the design, plus enough around them to give both tabs
    /// something to show and the list something to scroll.
    static var sample: [Trip] {
        let cal = Calendar.current
        func day(_ offset: Int) -> Date {
            cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: .now)) ?? .now
        }
        return [
            Trip(destination: .kyoto,      start: day(0),    end: day(7),    budget: 900,  isSaved: true),
            Trip(destination: .lisbon,     start: day(32),   end: day(39),   budget: 2400),
            Trip(destination: .iceland,    start: day(74),   end: day(81),   budget: 1850),
            Trip(destination: .banff,      start: day(126),  end: day(135),  budget: 3100, isSaved: true),
            Trip(destination: .santorini,  start: day(-48),  end: day(-41),  budget: 1600),
            Trip(destination: .marrakesh,  start: day(-120), end: day(-113), budget: 1200),
            Trip(destination: .queenstown, start: day(-260), end: day(-246), budget: 4200, isSaved: true),
        ]
    }
}

import Observation
import SwiftUI

enum Step: String {
    case splash, onboarding, auth, home
}

@Observable
final class AppModel {
    var step: Step = .splash
    /// 0, 1, 2 — the three onboarding pages.
    var onboardingPage = 0
    var email = ""
    var tab: HomeTab = .upcoming
    var trips: [Trip] = Trip.sample

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

    func toggleSaved(_ trip: Trip) {
        guard let i = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[i].isSaved.toggle()
    }

    func trips(for tab: HomeTab, now: Date = .now) -> [Trip] {
        trips
            .filter { $0.isUpcoming(from: now) == (tab == .upcoming) }
            .sorted { tab == .upcoming ? $0.start < $1.start : $0.start > $1.start }
    }

    private enum Key { static let onboarded = "sonder.hasOnboarded" }

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

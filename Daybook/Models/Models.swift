import Foundation
import SwiftData

extension Date {
    var day: Date { Calendar.current.startOfDay(for: self) }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
}

@Model
final class TaskItem {
    var title: String
    var dueDay: Date
    var isDone: Bool
    var doneAt: Date?
    var created: Date

    init(title: String, dueDay: Date = .now.day) {
        self.title = title
        self.dueDay = dueDay
        self.isDone = false
        self.doneAt = nil
        self.created = .now
    }

    /// Unfinished tasks from earlier days roll forward into today.
    var isCarried: Bool { !isDone && dueDay < Date.now.day }

    func toggle() {
        isDone.toggle()
        doneAt = isDone ? .now : nil
    }
}

@Model
final class Habit {
    var name: String
    var symbol: String
    var order: Int
    var created: Date
    var checks: [Date]

    init(name: String, symbol: String = "circle.dashed", order: Int = 0) {
        self.name = name
        self.symbol = symbol
        self.order = order
        self.created = .now
        self.checks = []
    }

    func isDone(on date: Date) -> Bool {
        let d = date.day
        return checks.contains { $0 == d }
    }

    func toggle(on date: Date = .now) {
        let d = date.day
        if let i = checks.firstIndex(of: d) {
            checks.remove(at: i)
        } else {
            checks.append(d)
        }
    }

    /// Consecutive days ending today, or ending yesterday if today isn't done yet.
    var streak: Int {
        let set = Set(checks)
        var cursor = Date.now.day
        if !set.contains(cursor) { cursor = cursor.adding(days: -1) }
        var count = 0
        while set.contains(cursor) {
            count += 1
            cursor = cursor.adding(days: -1)
        }
        return count
    }

    var best: Int {
        let sorted = Set(checks).sorted()
        var best = 0, run = 0
        var prev: Date?
        for d in sorted {
            if let p = prev, p.adding(days: 1) == d { run += 1 } else { run = 1 }
            best = max(best, run)
            prev = d
        }
        return best
    }
}

/// One record per calendar day: mood, water, the one-liner and longer notes.
@Model
final class DayLog {
    @Attribute(.unique) var day: Date
    var mood: Int
    var water: Int
    var line: String
    var notes: String
    var focusMinutes: Int = 0

    init(day: Date) {
        self.day = day.day
        self.mood = 0
        self.water = 0
        self.focusMinutes = 0
        self.line = ""
        self.notes = ""
    }

    var hasWriting: Bool {
        !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

@Model
final class Countdown {
    var title: String
    var date: Date
    var created: Date

    init(title: String, date: Date) {
        self.title = title
        self.date = date.day
        self.created = .now
    }

    var daysLeft: Int {
        Calendar.current.dateComponents([.day], from: Date.now.day, to: date.day).day ?? 0
    }
}

enum Mood: Int, CaseIterable {
    case rough = 1, meh, okay, good, great

    var word: String {
        switch self {
        case .rough: "rough"
        case .meh: "meh"
        case .okay: "okay"
        case .good: "good"
        case .great: "great"
        }
    }
}

extension ModelContext {
    /// Fetches today's (or any day's) log, creating it on first touch.
    func log(for date: Date) -> DayLog {
        let d = date.day
        let descriptor = FetchDescriptor<DayLog>(predicate: #Predicate { $0.day == d })
        if let existing = try? fetch(descriptor).first {
            return existing
        }
        let log = DayLog(day: d)
        insert(log)
        return log
    }
}

import Foundation
import SwiftData
import WidgetKit

enum WidgetSync {
    /// Writes what the widget shows into the app group and asks WidgetKit to redraw.
    @MainActor
    static func push(_ context: ModelContext) {
        let today = Date.now.day
        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.created)]))) ?? []
        let open = tasks.filter { !$0.isDone && $0.dueDay <= today }
        let done = tasks.filter { $0.isDone && ($0.doneAt ?? .distantPast) >= today }
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        SharedStore.saveSnapshot(WidgetSnapshot(
            tasks: open.prefix(4).map(\.title),
            openCount: open.count,
            doneCount: done.count,
            habitsDone: habits.filter { $0.isDone(on: today) }.count,
            habitsTotal: habits.count,
            updated: .now
        ))
        WidgetCenter.shared.reloadAllTimelines()
    }
}

enum DemoData {
    /// Seeds a realistic week so screenshots and first impressions aren't empty.
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Habit>())) ?? 0
        guard existing == 0 else { return }
        let today = Date.now.day

        let t1 = TaskItem(title: "Call the dentist", dueDay: today.adding(days: -1))
        let t2 = TaskItem(title: "Finish chem worksheet")
        let t3 = TaskItem(title: "Grab groceries: eggs, rice, limes")
        let t4 = TaskItem(title: "Clean room")
        t4.toggle()
        let t5 = TaskItem(title: "Plan Saturday", dueDay: today.adding(days: 1))
        [t1, t2, t3, t4, t5].forEach { context.insert($0) }

        let habits: [(String, String, [Int])] = [
            ("Workout", "figure.run", [0, 1, 2, 4, 5, 6]),
            ("Read", "book", [1, 2, 3, 4, 5, 6, 7, 8]),
            ("No phone in bed", "moon", [0, 2, 3]),
            ("Stretch", "figure.flexibility", [1, 3, 4]),
        ]
        for (i, h) in habits.enumerated() {
            let habit = Habit(name: h.0, symbol: h.1, order: i)
            habit.checks = h.2.map { today.adding(days: -$0) }
            context.insert(habit)
        }

        let lines = ["Good practice, legs are dead.", "Rainy, stayed in and read.", "Pizza with the crew.", "Long day but got it done."]
        for (i, line) in lines.enumerated() {
            let log = DayLog(day: today.adding(days: -(i + 1)))
            log.line = line
            log.mood = [4, 3, 5, 3][i]
            log.water = [6, 4, 7, 5][i]
            context.insert(log)
        }
        let old = DayLog(day: Calendar.current.date(byAdding: .month, value: -1, to: today)!)
        old.line = "First day trying this app thing."
        old.mood = 4
        context.insert(old)

        let todayLog = DayLog(day: today)
        todayLog.water = 3
        context.insert(todayLog)

        context.insert(Countdown(title: "Spring break", date: today.adding(days: 23)))
        context.insert(Countdown(title: "Mom's birthday", date: today.adding(days: 9)))
        context.insert(Countdown(title: "Concert", date: today.adding(days: 51)))
        try? context.save()
    }

    /// First launch without demo data: a few starter habits so the screen has shape.
    @MainActor
    static func seedStarter(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Habit>())) ?? 0
        guard existing == 0, !UserDefaults.standard.bool(forKey: "seededStarter") else { return }
        UserDefaults.standard.set(true, forKey: "seededStarter")
        context.insert(Habit(name: "Workout", symbol: "figure.run", order: 0))
        context.insert(Habit(name: "Read", symbol: "book", order: 1))
        context.insert(Habit(name: "Sleep by 11", symbol: "moon", order: 2))
        try? context.save()
    }
}

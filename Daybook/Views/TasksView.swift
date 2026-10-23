import SwiftData
import SwiftUI

struct TasksView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.created) private var tasks: [TaskItem]
    @State private var draft = ""
    @State private var when: When = .today
    @State private var pickedDate = Date.now.adding(days: 2)

    enum When: String, CaseIterable { case today = "Today", tomorrow = "Tomorrow", later = "Later" }

    var body: some View {
        let today = Date.now.day
        let carried = tasks.filter(\.isCarried)
        let dueToday = tasks.filter { !$0.isDone && $0.dueDay == today }
        let upcoming = tasks.filter { !$0.isDone && $0.dueDay > today }.sorted { $0.dueDay < $1.dueDay }
        let done = tasks.filter { $0.isDone && ($0.doneAt ?? .distantPast) >= today }
        let oldDone = tasks.filter { $0.isDone && ($0.doneAt ?? .distantPast) < today }

        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                PageTitle(title: "Tasks", kicker: "\(carried.count + dueToday.count) open · \(done.count) done today")

                Block {
                    SectionHeader("New task")
                    ThemedField(placeholder: "What needs doing?", text: $draft, onSubmit: add)
                    HStack(spacing: 8) {
                        ForEach(When.allCases, id: \.self) { w in
                            Button(w.rawValue) { when = w }
                                .buttonStyle(ThemedButtonStyle(filled: when == w))
                        }
                        Spacer(minLength: 0)
                    }
                    if when == .later {
                        DatePicker("Due", selection: $pickedDate, in: Date.now.adding(days: 1)..., displayedComponents: .date)
                            .font(theme.body(15))
                            .foregroundStyle(theme.ink)
                    }
                    Button("Add", action: add)
                        .buttonStyle(ThemedButtonStyle())
                        .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                        .keyboardShortcut(.return, modifiers: .command)
                }

                if !carried.isEmpty {
                    section("Carried over", carried)
                }
                section("Today", dueToday, empty: carried.isEmpty ? "Clear. Enjoy it." : nil)
                if !upcoming.isEmpty {
                    Block {
                        SectionHeader("Upcoming")
                        ForEach(upcoming) { task in
                            HStack(alignment: .firstTextBaseline) {
                                TaskRow(task: task)
                                Text(Fmt.string(task.dueDay, "EEEdMMM").uppercased())
                                    .font(theme.label(10))
                                    .foregroundStyle(theme.muted)
                            }
                        }
                    }
                }
                if !done.isEmpty {
                    section("Done today", done)
                }
                if !oldDone.isEmpty {
                    Button("Clear \(oldDone.count) old finished") {
                        oldDone.forEach { context.delete($0) }
                    }
                    .buttonStyle(ThemedButtonStyle(filled: false))
                }
                Text("Long-press a task to move or delete it. Unfinished tasks roll into tomorrow on their own.")
                    .font(theme.label(11))
                    .foregroundStyle(theme.muted)
            }
            .pagePadding()
            .readableColumn()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [TaskItem], empty: String? = nil) -> some View {
        Block {
            SectionHeader(title) {
                Text("\(items.count)").font(theme.label(11)).foregroundStyle(theme.muted)
            }
            if items.isEmpty, let empty {
                Text(empty).font(theme.body(15)).foregroundStyle(theme.muted)
            }
            VStack(spacing: 0) {
                ForEach(items) { TaskRow(task: $0) }
            }
        }
    }

    private func add() {
        let t = draft.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let due: Date
        switch when {
        case .today: due = Date.now.day
        case .tomorrow: due = Date.now.day.adding(days: 1)
        case .later: due = pickedDate.day
        }
        context.insert(TaskItem(title: t, dueDay: due))
        draft = ""
        WidgetSync.push(context)
    }
}

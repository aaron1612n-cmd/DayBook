import SwiftData
import SwiftUI

struct HabitsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.order) private var habits: [Habit]
    @State private var draft = ""
    @State private var symbol = "star"

    static let symbols = ["star", "figure.run", "book", "moon", "drop", "leaf", "dumbbell", "bicycle",
                          "brain.head.profile", "music.note", "pencil", "fork.knife", "bed.double", "pills", "sun.max", "heart"]

    var body: some View {
        let doneToday = habits.filter { $0.isDone(on: .now) }.count
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                PageTitle(title: "Habits", kicker: "\(doneToday) of \(habits.count) done today")

                VStack(spacing: theme.id == .paper ? 0 : 10) {
                    ForEach(habits) { HabitRow(habit: $0) }
                }

                Block {
                    SectionHeader("New habit")
                    ThemedField(placeholder: "Something to do every day", text: $draft, onSubmit: add)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Self.symbols, id: \.self) { s in
                                Button { symbol = s } label: {
                                    Image(systemName: s)
                                        .font(.system(size: 16))
                                        .frame(width: 40, height: 40)
                                        .foregroundStyle(symbol == s ? theme.onAccent : theme.ink)
                                        .background(symbol == s ? theme.accent : .clear)
                                        .clipShape(RoundedRectangle(cornerRadius: theme.radius))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(s)
                            }
                        }
                    }
                    Button("Add habit", action: add)
                        .buttonStyle(ThemedButtonStyle())
                        .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Text("Tap a day in the week strip to fill it in late. Long-press a habit to delete it.")
                    .font(theme.label(11))
                    .foregroundStyle(theme.muted)
            }
            .pagePadding()
            .readableColumn()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func add() {
        let t = draft.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        context.insert(Habit(name: t, symbol: symbol, order: (habits.map(\.order).max() ?? -1) + 1))
        draft = ""
        WidgetSync.push(context)
    }
}

private struct HabitRow: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var context
    let habit: Habit

    var body: some View {
        let today = Date.now.day
        let week = (0..<7).reversed().map { today.adding(days: -$0) }

        Block {
            HStack(alignment: .center, spacing: 12) {
                if theme.id != .retro {
                    Image(systemName: habit.symbol)
                        .font(.system(size: 18))
                        .foregroundStyle(theme.accent)
                        .frame(width: 26)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name).font(theme.body(18)).foregroundStyle(theme.ink)
                    Text("best \(habit.best) · \(habit.checks.count) total")
                        .font(theme.label(10))
                        .foregroundStyle(theme.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(habit.streak)")
                        .font(theme.display(34))
                        .foregroundStyle(habit.streak > 0 ? theme.ink : theme.muted)
                        .monospacedDigit()
                    Text("day streak").font(theme.label(9)).foregroundStyle(theme.muted)
                }
            }
            HStack(spacing: 6) {
                ForEach(week, id: \.self) { day in
                    let done = habit.isDone(on: day)
                    let isToday = day == today
                    Button {
                        withAnimation(.snappy) { habit.toggle(on: day) }
                        WidgetSync.push(context)
                    } label: {
                        VStack(spacing: 4) {
                            Text(Fmt.string(day, "EEEEE"))
                                .font(theme.label(10))
                                .foregroundStyle(isToday ? theme.accent : theme.muted)
                            ZStack {
                                RoundedRectangle(cornerRadius: theme.radius)
                                    .fill(done ? theme.accent : .clear)
                                RoundedRectangle(cornerRadius: theme.radius)
                                    .strokeBorder(done ? theme.accent : theme.rule, lineWidth: isToday ? 2 : 1)
                                if theme.id == .retro {
                                    Text(done ? "x" : "")
                                        .font(theme.body(16))
                                        .foregroundStyle(theme.onAccent)
                                }
                            }
                            .frame(height: 30)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(Fmt.string(day, "EEEE")), \(done ? "done" : "not done")")
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: habit.checks.count)
        }
        .contextMenu {
            Button("Delete habit", systemImage: "trash", role: .destructive) {
                context.delete(habit)
                WidgetSync.push(context)
            }
        }
    }
}

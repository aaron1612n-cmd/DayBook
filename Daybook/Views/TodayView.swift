import SwiftData
import SwiftUI

struct TodayView: View {
    @Binding var tab: AppTab
    @Environment(\.theme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage(SharedStore.Key.name, store: SharedStore.defaults) private var name = "Aaron"

    var body: some View {
        TimelineView(.everyMinute) { context in
            let now = context.date
            ScrollView {
                if sizeClass == .regular {
                    HStack(alignment: .top, spacing: 36) {
                        VStack(alignment: .leading, spacing: 28) {
                            GreetingHeader(now: now, name: name)
                            WeatherBlock()
                            QuoteBlock(now: now)
                            OnThisDayBlock()
                        }
                        .frame(maxWidth: .infinity)
                        VStack(alignment: .leading, spacing: 28) {
                            TasksPreview(tab: $tab)
                            HabitsStrip(tab: $tab)
                            WaterBlock()
                            MoodBlock()
                            ExtrasRow(now: now)
                            CountdownsPreview()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    .readableColumn(1100)
                } else {
                    VStack(alignment: .leading, spacing: 26) {
                        GreetingHeader(now: now, name: name)
                        WeatherBlock()
                        TasksPreview(tab: $tab)
                        HabitsStrip(tab: $tab)
                        WaterBlock()
                        MoodBlock()
                        QuoteBlock(now: now)
                        ExtrasRow(now: now)
                        CountdownsPreview()
                        OnThisDayBlock()
                    }
                    .pagePadding()
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

// MARK: - Greeting

private struct GreetingHeader: View {
    @Environment(\.theme) private var theme
    let now: Date
    let name: String

    var body: some View {
        let g = GreetingEngine.greeting(for: now, name: name, birthday: SharedStore.birthday)
        let cal = Calendar.current
        let week = cal.component(.weekOfYear, from: now)
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: now) ?? 0

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(Fmt.string(now, "EEEEdMMMM").uppercased())
                Spacer()
                Text("WK \(week) · DAY \(dayOfYear)")
            }
            .font(theme.label(11))
            .tracking(theme.id == .retro ? 0 : 1.2)
            .foregroundStyle(theme.muted)

            InkReveal(delay: 0.15) {
                Text(theme.headline(g.headline))
                    .font(theme.display(theme.id == .bold ? 58 : 52))
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(g.subline)
                .font(theme.id == .paper ? .custom("InstrumentSerif-Italic", size: 22, relativeTo: .title3) : theme.body(16))
                .foregroundStyle(theme.id == .paper ? theme.ink.opacity(0.8) : theme.muted)

            DayProgress(now: now)
                .padding(.top, 6)
        }
        .padding(.top, 12)
    }
}

private struct DayProgress: View {
    @Environment(\.theme) private var theme
    let now: Date

    var body: some View {
        let start = now.day
        let fraction = min(1, max(0, now.timeIntervalSince(start) / 86_400))
        VStack(alignment: .leading, spacing: 6) {
            if theme.id == .retro {
                let filled = Int((fraction * 24).rounded())
                Text(String(repeating: "#", count: filled) + String(repeating: ".", count: 24 - filled))
                    .font(theme.body(18))
                    .foregroundStyle(theme.ink)
            } else {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(theme.id == .paper ? theme.rule : theme.surface)
                        Rectangle().fill(theme.accent).frame(width: geo.size.width * fraction)
                        // Hour ticks make it read like a ruler.
                        HStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { h in
                                Rectangle()
                                    .fill(theme.bg.opacity(h % 6 == 0 ? 0.9 : 0.45))
                                    .frame(width: 1)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
                .frame(height: theme.id == .bold ? 10 : 6)
            }
            Text("\(Int(fraction * 100))% of today gone · \(Int((1 - fraction) * 24))h left")
                .font(theme.label(11))
                .foregroundStyle(theme.muted)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Weather

private struct WeatherBlock: View {
    @Environment(\.theme) private var theme
    @Environment(WeatherModel.self) private var weather

    var body: some View {
        Block {
            SectionHeader("Weather") {
                if let r = weather.report {
                    Text(r.place.uppercased()).font(theme.label(11)).foregroundStyle(theme.muted)
                }
            }
            if let r = weather.report {
                HStack(alignment: .top, spacing: 18) {
                    Text("\(Int(r.temperature.rounded()))°")
                        .font(theme.display(76))
                        .foregroundStyle(theme.ink)
                        .monospacedDigit()
                        .layoutPriority(1)
                    VStack(alignment: .leading, spacing: 6) {
                        Label(r.summary, systemImage: r.symbol)
                            .font(theme.body(17))
                            .foregroundStyle(theme.ink)
                        Text("High \(Int(r.high.rounded()))° · Low \(Int(r.low.rounded()))°")
                        Text("Feels \(Int(r.feelsLike.rounded()))° · Rain \(r.rainChance)%")
                        if let rise = r.sunrise, let set = r.sunset {
                            Text("Sun \(Fmt.time(rise)) – \(Fmt.time(set))")
                        }
                    }
                    .font(theme.body(14))
                    .foregroundStyle(theme.muted)
                    .padding(.top, 10)
                }
                Text(r.advice)
                    .font(theme.label(12))
                    .foregroundStyle(theme.accent)
            } else {
                switch weather.status {
                case .denied:
                    Text("Location is off. Turn it on in Settings to see your weather.")
                        .font(theme.body(15)).foregroundStyle(theme.muted)
                case .failed:
                    Button("Try again") { weather.refresh(force: true) }
                        .buttonStyle(ThemedButtonStyle(filled: false))
                default:
                    Text("Checking the sky…").font(theme.body(15)).foregroundStyle(theme.muted)
                }
            }
        }
        .onTapGesture { weather.refresh(force: true) }
    }
}

// MARK: - Tasks

private struct TasksPreview: View {
    @Binding var tab: AppTab
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.created) private var tasks: [TaskItem]
    @State private var draft = ""

    var body: some View {
        let today = Date.now.day
        let open = tasks.filter { !$0.isDone && $0.dueDay <= today }
        let doneToday = tasks.filter { $0.isDone && ($0.doneAt ?? .distantPast) >= today }

        Block {
            SectionHeader("Today's tasks") {
                Text("\(doneToday.count)/\(open.count + doneToday.count)")
                    .font(theme.label(11))
                    .foregroundStyle(theme.muted)
            }
            VStack(spacing: 0) {
                ForEach(open.prefix(5)) { task in
                    TaskRow(task: task)
                }
                ForEach(doneToday.prefix(2)) { task in
                    TaskRow(task: task)
                }
            }
            if open.isEmpty && doneToday.isEmpty {
                Text("Nothing yet. Add the first thing.")
                    .font(theme.body(15))
                    .foregroundStyle(theme.muted)
            }
            ThemedField(placeholder: "Add a task", text: $draft) {
                let t = draft.trimmingCharacters(in: .whitespaces)
                guard !t.isEmpty else { return }
                context.insert(TaskItem(title: t))
                draft = ""
                WidgetSync.push(context)
            }
            if open.count > 5 {
                Button("All \(open.count) tasks") { tab = .tasks }
                    .font(theme.label(12))
                    .foregroundStyle(theme.accent)
            }
        }
    }
}

struct TaskRow: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var context
    let task: TaskItem

    var body: some View {
        Button {
            withAnimation(.snappy) { task.toggle() }
            WidgetSync.push(context)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                CheckBox(done: task.isDone)
                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 5 }
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(theme.body(16))
                        .strikethrough(task.isDone, color: theme.muted)
                        .foregroundStyle(task.isDone ? theme.muted : theme.ink)
                        .multilineTextAlignment(.leading)
                    if task.isCarried {
                        Text("carried from \(Fmt.string(task.dueDay, "EEEE"))")
                            .font(theme.label(10))
                            .foregroundStyle(theme.accent)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: task.isDone) { _, new in new }
        .contextMenu {
            if !task.isDone {
                Button("Move to tomorrow", systemImage: "arrow.right") {
                    task.dueDay = Date.now.day.adding(days: 1)
                    WidgetSync.push(context)
                }
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                context.delete(task)
                WidgetSync.push(context)
            }
        }
    }
}

// MARK: - Habits

private struct HabitsStrip: View {
    @Binding var tab: AppTab
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.order) private var habits: [Habit]

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 8)]

    var body: some View {
        Block {
            SectionHeader("Habits") {
                Button("Edit") { tab = .habits }
                    .font(theme.label(11))
                    .foregroundStyle(theme.accent)
            }
            if habits.isEmpty {
                Text("Add habits to track streaks.").font(theme.body(15)).foregroundStyle(theme.muted)
            }
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(habits) { habit in
                    HabitChip(habit: habit)
                }
            }
        }
    }
}

private struct HabitChip: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var context
    let habit: Habit

    var body: some View {
        let done = habit.isDone(on: .now)
        Button {
            withAnimation(.snappy) { habit.toggle() }
            WidgetSync.push(context)
        } label: {
            HStack(spacing: 8) {
                if theme.id == .retro {
                    Text(done ? "[x]" : "[ ]")
                } else {
                    Image(systemName: done ? "checkmark" : habit.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 16)
                }
                Text(habit.name)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Text("\(habit.streak)")
                    .monospacedDigit()
                    .opacity(0.8)
            }
            .font(theme.body(14))
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .foregroundStyle(done ? theme.onAccent : theme.ink)
            .background(done ? theme.accent : (theme.id == .bold ? theme.bg : .clear))
            .overlay {
                if !done {
                    RoundedRectangle(cornerRadius: theme.radius)
                        .strokeBorder(theme.id == .paper ? theme.ink.opacity(0.35) : theme.rule, lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.radius))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: done)
        .accessibilityLabel("\(habit.name), \(done ? "done" : "not done"), streak \(habit.streak)")
    }
}

// MARK: - Water

private struct WaterBlock: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var context
    @Query private var logs: [DayLog]
    @AppStorage("waterGoal") private var goal = 8

    init() {
        let d = Date.now.day
        _logs = Query(filter: #Predicate<DayLog> { $0.day == d })
    }

    var body: some View {
        let count = logs.first?.water ?? 0
        Block {
            SectionHeader("Water") {
                Text("\(count) of \(goal) glasses")
                    .font(theme.label(11))
                    .foregroundStyle(count >= goal ? theme.accent : theme.muted)
            }
            HStack(spacing: 6) {
                ForEach(0..<max(goal, count), id: \.self) { i in
                    Button {
                        set(i + 1 == count ? i : i + 1)
                    } label: {
                        glass(filled: i < count)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(i + 1) glasses")
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: count)
            HStack(spacing: 10) {
                Button("+ Glass") { set(count + 1) }
                    .buttonStyle(ThemedButtonStyle())
                Button("Undo") { set(max(0, count - 1)) }
                    .buttonStyle(ThemedButtonStyle(filled: false))
                    .disabled(count == 0)
            }
        }
    }

    private func set(_ n: Int) {
        context.log(for: .now).water = n
    }

    @ViewBuilder
    private func glass(filled: Bool) -> some View {
        switch theme.id {
        case .retro:
            Text(filled ? "█" : "░")
                .font(theme.body(22))
                .foregroundStyle(filled ? theme.accent : theme.rule)
                .frame(maxWidth: .infinity)
        default:
            ZStack(alignment: .bottom) {
                Rectangle()
                    .strokeBorder(filled ? theme.accent : theme.muted.opacity(0.6), lineWidth: 1.2)
                Rectangle()
                    .fill(theme.accent)
                    .frame(height: filled ? nil : 0)
                    .padding(3)
            }
            .frame(maxWidth: 34)
            .frame(height: 38)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: theme.id == .paper ? 6 : 0, bottomTrailingRadius: theme.id == .paper ? 6 : 0))
        }
    }
}

// MARK: - Mood

struct MoodPicker: View {
    @Environment(\.theme) private var theme
    let value: Int
    let onPick: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Mood.allCases, id: \.rawValue) { mood in
                let active = mood.rawValue == value
                Button {
                    onPick(active ? 0 : mood.rawValue)
                } label: {
                    VStack(spacing: 6) {
                        MoodMark(level: mood.rawValue, active: active)
                        Text(mood.word)
                            .font(theme.label(11))
                            .foregroundStyle(active ? theme.accent : theme.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mood.word)
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: value)
    }
}

/// A tiny bar-chart glyph: more bars means a better day. No emoji.
struct MoodMark: View {
    @Environment(\.theme) private var theme
    let level: Int
    var active: Bool = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Rectangle()
                    .fill(i <= level ? (active ? theme.accent : theme.ink.opacity(0.75)) : theme.rule)
                    .frame(width: 4, height: CGFloat(4 + i * 3))
            }
        }
        .frame(height: 20, alignment: .bottom)
    }
}

private struct MoodBlock: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var context
    @Query private var logs: [DayLog]

    init() {
        let d = Date.now.day
        _logs = Query(filter: #Predicate<DayLog> { $0.day == d })
    }

    var body: some View {
        Block {
            SectionHeader("How's today?")
            MoodPicker(value: logs.first?.mood ?? 0) { context.log(for: .now).mood = $0 }
        }
    }
}

// MARK: - Quote, fact, challenge

private struct QuoteBlock: View {
    @Environment(\.theme) private var theme
    let now: Date

    var body: some View {
        let q = DailyContent.quote(for: now)
        Block {
            SectionHeader("Words for today")
            Text(theme.id == .retro ? "\"\(q.text)\"" : "“\(q.text)”")
                .font(theme.id == .paper ? .custom("InstrumentSerif-Italic", size: 28, relativeTo: .title) : theme.display(theme.id == .bold ? 30 : 26))
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("— \(q.author)")
                .font(theme.label(12))
                .foregroundStyle(theme.muted)
        }
    }
}

private struct ExtrasRow: View {
    @Environment(\.theme) private var theme
    let now: Date
    @AppStorage("challengeDoneDay") private var challengeDoneDay = 0.0

    var body: some View {
        let doneToday = challengeDoneDay == now.day.timeIntervalSince1970
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                challenge(done: doneToday).frame(maxWidth: .infinity)
                fact.frame(maxWidth: .infinity)
            }
            .frame(minWidth: 560)
            VStack(spacing: 26) {
                challenge(done: doneToday)
                fact
            }
        }
    }

    private func challenge(done: Bool) -> some View {
        Block {
            SectionHeader("Daily challenge")
            Text(DailyContent.challenge(for: now))
                .font(theme.body(17))
                .foregroundStyle(done ? theme.muted : theme.ink)
                .strikethrough(done, color: theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button(done ? "Done" : "Did it") {
                challengeDoneDay = done ? 0 : now.day.timeIntervalSince1970
            }
            .buttonStyle(ThemedButtonStyle(filled: !done))
            .sensoryFeedback(.success, trigger: done)
        }
    }

    private var fact: some View {
        Block {
            SectionHeader("Fun fact")
            Text(DailyContent.fact(for: now))
                .font(theme.body(17))
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Countdowns & memories

private struct CountdownsPreview: View {
    @Environment(\.theme) private var theme
    @Query(sort: \Countdown.date) private var countdowns: [Countdown]

    var body: some View {
        let upcoming = countdowns.filter { $0.daysLeft >= 0 }.prefix(3)
        if !upcoming.isEmpty {
            Block {
                SectionHeader("Coming up")
                ForEach(Array(upcoming)) { c in
                    HStack(alignment: .firstTextBaseline) {
                        Text(c.title).font(theme.body(16)).foregroundStyle(theme.ink)
                        Spacer()
                        Text(c.daysLeft == 0 ? "today" : "\(c.daysLeft)")
                            .font(theme.display(30))
                            .foregroundStyle(c.daysLeft <= 7 ? theme.accent : theme.ink)
                            .monospacedDigit()
                        if c.daysLeft > 0 {
                            Text(c.daysLeft == 1 ? "day" : "days").font(theme.label(11)).foregroundStyle(theme.muted)
                        }
                    }
                }
            }
        }
    }
}

struct OnThisDayBlock: View {
    @Environment(\.theme) private var theme
    @Query(sort: \DayLog.day, order: .reverse) private var logs: [DayLog]

    var body: some View {
        let cal = Calendar.current
        let today = Date.now.day
        let dom = cal.component(.day, from: today)
        let memories = logs.filter { $0.day < today && cal.component(.day, from: $0.day) == dom && $0.hasWriting }
        if !memories.isEmpty {
            Block {
                SectionHeader("On this day")
                ForEach(memories.prefix(3)) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ago(log.day).uppercased())
                            .font(theme.label(10))
                            .foregroundStyle(theme.accent)
                        Text(log.line.isEmpty ? log.notes : log.line)
                            .font(theme.id == .paper ? .custom("InstrumentSerif-Italic", size: 21, relativeTo: .title3) : theme.body(16))
                            .foregroundStyle(theme.ink)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func ago(_ day: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month], from: day, to: Date.now.day)
        if let y = comps.year, y > 0 { return y == 1 ? "A year ago" : "\(y) years ago" }
        if let m = comps.month, m > 0 { return m == 1 ? "A month ago" : "\(m) months ago" }
        return Fmt.string(day, "MMMd")
    }
}

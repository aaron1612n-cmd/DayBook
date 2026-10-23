import SwiftData
import SwiftUI

struct MoreView: View {
    @Environment(\.theme) private var theme
    @State private var page: Page?

    enum Page: String, CaseIterable, Identifiable {
        case focus, breathe, countdowns, settings
        var id: String { rawValue }

        var title: String {
            switch self {
            case .focus: "Focus timer"
            case .breathe: "Breathe"
            case .countdowns: "Countdowns"
            case .settings: "Settings"
            }
        }

        var blurb: String {
            switch self {
            case .focus: "25 on, 5 off. Get one thing done."
            case .breathe: "Box breathing, four counts each way."
            case .countdowns: "Days until the things you're waiting for."
            case .settings: "Name, look, birthday, morning reminder."
            }
        }

        var symbol: String {
            switch self {
            case .focus: "timer"
            case .breathe: "wind"
            case .countdowns: "calendar"
            case .settings: "slider.horizontal.3"
            }
        }
    }

    var body: some View {
        Group {
            if let page {
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) { self.page = nil }
                        } label: {
                            HStack(spacing: 4) {
                                if theme.id != .retro { Image(systemName: "chevron.left") }
                                Text(theme.id == .retro ? "< BACK" : "More")
                            }
                            .font(theme.label(13))
                            .foregroundStyle(theme.accent)
                        }
                        .keyboardShortcut(.escape, modifiers: [])
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    switch page {
                    case .focus: FocusView()
                    case .breathe: BreatheView()
                    case .countdowns: CountdownsView()
                    case .settings: SettingsView()
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        PageTitle(title: "More", kicker: "Tools")
                        VStack(spacing: theme.id == .paper ? 0 : 10) {
                            ForEach(Page.allCases) { p in
                                Button {
                                    withAnimation(.easeOut(duration: 0.15)) { page = p }
                                } label: {
                                    Block {
                                        HStack(spacing: 16) {
                                            if theme.id != .retro {
                                                Image(systemName: p.symbol)
                                                    .font(.system(size: 22))
                                                    .foregroundStyle(theme.accent)
                                                    .frame(width: 30)
                                            }
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(theme.headline(p.title))
                                                    .font(theme.display(28))
                                                    .foregroundStyle(theme.ink)
                                                Text(p.blurb)
                                                    .font(theme.body(14))
                                                    .foregroundStyle(theme.muted)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            Spacer(minLength: 0)
                                            Image(systemName: "arrow.right")
                                                .foregroundStyle(theme.muted)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        YearProgress()
                    }
                    .pagePadding()
                    .readableColumn()
                }
            }
        }
        .onAppear {
            if let start = UserDefaults.standard.string(forKey: "startPage") {
                page = Page(rawValue: start)
            }
        }
    }
}

private struct YearProgress: View {
    @Environment(\.theme) private var theme

    var body: some View {
        let cal = Calendar.current
        let now = Date.now
        let day = cal.ordinality(of: .day, in: .year, for: now) ?? 1
        let total = cal.range(of: .day, in: .year, for: now)?.count ?? 365
        let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 26)
        Block {
            SectionHeader("The year so far") {
                Text("\(Int(Double(day) / Double(total) * 100))%").font(theme.label(11)).foregroundStyle(theme.accent)
            }
            // One mark per week.
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(0..<52, id: \.self) { w in
                    Rectangle()
                        .fill(w < day / 7 ? theme.ink.opacity(0.8) : (w == day / 7 ? theme.accent : theme.rule))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            Text("\(total - day) days left in \(cal.component(.year, from: now))")
                .font(theme.body(14))
                .foregroundStyle(theme.muted)
        }
    }
}

// MARK: - Focus

struct FocusView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var context
    @AppStorage("focusLength") private var focusLength = 25
    @State private var endDate: Date?
    @State private var remaining: TimeInterval = 25 * 60
    @State private var isBreak = false
    @State private var sessions = 0
    private let tick = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private var total: TimeInterval { TimeInterval((isBreak ? 5 : focusLength) * 60) }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                PageTitle(title: isBreak ? "Break" : "Focus", kicker: "\(sessions) sessions this visit")
                ZStack {
                    Circle().stroke(theme.rule, lineWidth: theme.id == .bold ? 14 : 6)
                    Circle()
                        .trim(from: 0, to: 1 - remaining / total)
                        .stroke(theme.accent, style: StrokeStyle(lineWidth: theme.id == .bold ? 14 : 6, lineCap: theme.id == .paper ? .round : .butt))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 4) {
                        Text(clock(remaining))
                            .font(theme.display(64))
                            .monospacedDigit()
                            .foregroundStyle(theme.ink)
                        Text(endDate == nil ? "ready" : (isBreak ? "breathe out" : "deep work"))
                            .font(theme.label(12))
                            .foregroundStyle(theme.muted)
                    }
                }
                .frame(maxWidth: 300)
                .padding(.horizontal, 30)

                if endDate == nil && !isBreak {
                    HStack(spacing: 8) {
                        ForEach([15, 25, 45, 60], id: \.self) { m in
                            Button("\(m)m") {
                                focusLength = m
                                remaining = TimeInterval(m * 60)
                            }
                            .buttonStyle(ThemedButtonStyle(filled: focusLength == m))
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button(endDate == nil ? "Start" : "Pause") { endDate == nil ? start() : pause() }
                        .buttonStyle(ThemedButtonStyle())
                        .keyboardShortcut(.space, modifiers: [])
                    Button("Reset") { reset() }
                        .buttonStyle(ThemedButtonStyle(filled: false))
                }
            }
            .pagePadding()
            .readableColumn(520)
        }
        .onReceive(tick) { _ in
            guard let endDate else { return }
            remaining = max(0, endDate.timeIntervalSinceNow)
            if remaining == 0 { finish() }
        }
        .sensoryFeedback(.success, trigger: sessions)
    }

    private func clock(_ t: TimeInterval) -> String {
        let s = Int(t.rounded(.up))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private func start() {
        endDate = .now.addingTimeInterval(remaining)
        Task {
            if await Notifications.requestPermission() {
                Notifications.scheduleFocusEnd(after: remaining, isBreak: isBreak)
            }
        }
    }

    private func pause() {
        endDate = nil
        Notifications.cancelFocus()
    }

    private func reset() {
        pause()
        isBreak = false
        remaining = TimeInterval(focusLength * 60)
    }

    private func finish() {
        endDate = nil
        if !isBreak {
            sessions += 1
            context.log(for: .now).focusMinutes += focusLength
        }
        isBreak.toggle()
        remaining = total
    }
}

// MARK: - Breathe

struct BreatheView: View {
    @Environment(\.theme) private var theme
    @State private var started: Date?
    private let phase: Double = 4

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                PageTitle(title: "Breathe", kicker: "Box breathing")
                TimelineView(.animation(paused: started == nil)) { ctx in
                    let t = started.map { ctx.date.timeIntervalSince($0) } ?? 0
                    let cycle = t.truncatingRemainder(dividingBy: phase * 4)
                    let step = Int(cycle / phase)
                    let within = (cycle - Double(step) * phase) / phase
                    let words = ["In", "Hold", "Out", "Hold"]
                    let count = Int(phase - within * phase) + 1

                    ZStack {
                        Rectangle()
                            .strokeBorder(theme.rule, lineWidth: theme.id == .bold ? 6 : 2)
                        Rectangle()
                            .fill(theme.accent.opacity(theme.id == .paper ? 0.85 : 1))
                            .scaleEffect(started == nil ? 0.45 : scale(step: step, within: within))
                        VStack(spacing: 2) {
                            Text(theme.headline(started == nil ? "Ready" : words[step]))
                                .font(theme.display(44))
                            if started != nil {
                                Text("\(min(count, Int(phase)))").font(theme.label(16))
                            }
                        }
                        .foregroundStyle(theme.onAccent)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 300)
                    .clipShape(RoundedRectangle(cornerRadius: theme.id == .paper ? 6 : 0))
                    .sensoryFeedback(.impact(weight: .light), trigger: step)
                    if let started {
                        Text("\(Int(ctx.date.timeIntervalSince(started) / (phase * 4))) rounds")
                            .font(theme.label(12))
                            .foregroundStyle(theme.muted)
                    }
                }
                Button(started == nil ? "Begin" : "Stop") {
                    started = started == nil ? .now : nil
                }
                .buttonStyle(ThemedButtonStyle())
                .keyboardShortcut(.space, modifiers: [])
            }
            .pagePadding()
            .readableColumn(520)
        }
    }

    /// The square grows as you breathe in and shrinks as you breathe out.
    private func scale(step: Int, within: Double) -> Double {
        switch step {
        case 0: 0.45 + 0.55 * within
        case 1: 1
        case 2: 1 - 0.55 * within
        default: 0.45
        }
    }
}

// MARK: - Countdowns

struct CountdownsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \Countdown.date) private var countdowns: [Countdown]
    @State private var title = ""
    @State private var date = Date.now.adding(days: 7)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                PageTitle(title: "Countdowns", kicker: "\(countdowns.filter { $0.daysLeft >= 0 }.count) coming up")
                Block {
                    SectionHeader("New countdown")
                    ThemedField(placeholder: "What are you waiting for?", text: $title, onSubmit: add)
                    DatePicker("Date", selection: $date, in: Date.now..., displayedComponents: .date)
                        .font(theme.body(15))
                        .foregroundStyle(theme.ink)
                    Button("Add", action: add)
                        .buttonStyle(ThemedButtonStyle())
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ForEach(countdowns) { c in
                    Block {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(c.title).font(theme.body(18)).foregroundStyle(theme.ink)
                                Text(Fmt.string(c.date, "EEEEdMMMMyyyy").uppercased())
                                    .font(theme.label(10)).foregroundStyle(theme.muted)
                            }
                            Spacer()
                            Text(c.daysLeft < 0 ? "done" : "\(c.daysLeft)")
                                .font(theme.display(48))
                                .foregroundStyle(c.daysLeft >= 0 && c.daysLeft <= 7 ? theme.accent : theme.ink)
                                .monospacedDigit()
                        }
                    }
                    .opacity(c.daysLeft < 0 ? 0.5 : 1)
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) { context.delete(c) }
                    }
                }
            }
            .pagePadding()
            .readableColumn()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func add() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        context.insert(Countdown(title: t, date: date))
        title = ""
    }
}

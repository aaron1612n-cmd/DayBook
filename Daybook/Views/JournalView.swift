import SwiftData
import SwiftUI

struct JournalView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \DayLog.day, order: .reverse) private var logs: [DayLog]
    @State private var editing: DayLog?

    var body: some View {
        let today = Date.now.day
        let past = logs.filter { $0.day < today && ($0.hasWriting || $0.mood > 0) }

        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                PageTitle(title: "Journal", kicker: Fmt.string(.now, "EEEEdMMMM"))

                if let log = logs.first(where: { $0.day == today }) {
                    EntryEditor(log: log, prompt: DailyContent.prompt(for: .now))
                } else {
                    ProgressView().onAppear { _ = context.log(for: .now) }
                }

                MoodChart(logs: logs)
                OnThisDayBlock()

                if !past.isEmpty {
                    Block {
                        SectionHeader("Earlier") {
                            Text("\(past.count)").font(theme.label(11)).foregroundStyle(theme.muted)
                        }
                        VStack(spacing: 0) {
                            ForEach(past.prefix(60)) { log in
                                Button { editing = log } label: { PastRow(log: log) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .pagePadding()
            .readableColumn()
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(item: $editing) { log in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        PageTitle(title: Fmt.string(log.day, "EEEEdMMMM"))
                        Button("Done") { editing = nil }
                            .buttonStyle(ThemedButtonStyle())
                    }
                    EntryEditor(log: log, prompt: nil)
                }
                .padding(20)
                .readableColumn()
            }
            .background(theme.bg)
            .environment(\.theme, theme)
            .presentationBackground(theme.bg)
        }
    }
}

private struct EntryEditor: View {
    @Environment(\.theme) private var theme
    @Bindable var log: DayLog
    let prompt: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            if let prompt {
                Text(prompt)
                    .font(theme.id == .paper ? .custom("InstrumentSerif-Italic", size: 30, relativeTo: .title) : theme.display(28))
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Block {
                SectionHeader("Mood")
                MoodPicker(value: log.mood) { log.mood = $0 }
            }
            Block {
                SectionHeader("One line")
                ThemedField(placeholder: "Today in a sentence", text: $log.line)
            }
            Block {
                SectionHeader("Notes")
                TextEditor(text: $log.notes)
                    .font(theme.body(16))
                    .foregroundStyle(theme.ink)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .overlay(alignment: .topLeading) {
                        if log.notes.isEmpty {
                            Text("Anything else on your mind…")
                                .font(theme.body(16))
                                .foregroundStyle(theme.muted)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
    }
}

private struct PastRow: View {
    @Environment(\.theme) private var theme
    let log: DayLog

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(Fmt.string(log.day, "d"))
                    .font(theme.display(30))
                    .foregroundStyle(theme.ink)
                Text(Fmt.string(log.day, "MMM").uppercased())
                    .font(theme.label(10))
                    .foregroundStyle(theme.muted)
            }
            .frame(width: 44, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(log.line.isEmpty ? (log.notes.isEmpty ? "No words, just a mood." : log.notes) : log.line)
                    .font(theme.body(16))
                    .foregroundStyle(theme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if log.mood > 0, let m = Mood(rawValue: log.mood) {
                    HStack(spacing: 6) {
                        MoodMark(level: m.rawValue)
                            .scaleEffect(0.7, anchor: .leading)
                        Text(m.word).font(theme.label(10)).foregroundStyle(theme.muted)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Rectangle().fill(theme.rule).frame(height: 1) }
        .contentShape(Rectangle())
    }
}

/// Two weeks of mood as a bar chart; empty days show as a short tick.
private struct MoodChart: View {
    @Environment(\.theme) private var theme
    let logs: [DayLog]

    var body: some View {
        let today = Date.now.day
        let days = (0..<14).reversed().map { today.adding(days: -$0) }
        let byDay = Dictionary(logs.map { ($0.day, $0.mood) }, uniquingKeysWith: { a, _ in a })
        let rated = days.compactMap { byDay[$0] }.filter { $0 > 0 }
        let avg = rated.isEmpty ? 0 : Double(rated.reduce(0, +)) / Double(rated.count)

        Block {
            SectionHeader("Last two weeks") {
                if avg > 0, let m = Mood(rawValue: Int(avg.rounded())) {
                    Text("mostly \(m.word)").font(theme.label(11)).foregroundStyle(theme.accent)
                }
            }
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(days, id: \.self) { day in
                    let mood = byDay[day] ?? 0
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(mood == 0 ? theme.rule : (day == today ? theme.accent : theme.ink.opacity(0.8)))
                            .frame(height: mood == 0 ? 3 : CGFloat(mood) * 14)
                        Text(Fmt.string(day, "EEEEE"))
                            .font(theme.label(9))
                            .foregroundStyle(day == today ? theme.accent : theme.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 92, alignment: .bottom)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(avg > 0 ? "Average mood \(String(format: "%.1f", avg)) out of 5" : "No moods logged yet")
        }
    }
}

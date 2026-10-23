import SwiftUI
import WidgetKit

struct DayEntry: TimelineEntry {
    let date: Date
    let greeting: Greeting
    let snapshot: WidgetSnapshot?
    let theme: Theme
}

struct DayProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry {
        entry(at: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        completion(entry(at: .now))
    }

    /// One entry per hour so the greeting follows the time of day.
    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let cal = Calendar.current
        let now = Date.now
        let topOfHour = cal.date(from: cal.dateComponents([.year, .month, .day, .hour], from: now)) ?? now
        var entries = [entry(at: now)]
        for h in 1...12 {
            if let d = cal.date(byAdding: .hour, value: h, to: topOfHour) {
                entries.append(entry(at: d))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(at date: Date) -> DayEntry {
        DayEntry(
            date: date,
            greeting: GreetingEngine.greeting(for: date, name: SharedStore.name, birthday: SharedStore.birthday),
            snapshot: SharedStore.loadSnapshot(),
            theme: SharedStore.themeID.theme
        )
    }
}

struct DaybookWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DayEntry

    var body: some View {
        let t = entry.theme
        let dateLine = Text(entry.date, format: .dateTime.weekday(.wide).day().month(.abbreviated))

        Group {
            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 6) {
                    dateLine
                        .font(t.label(10))
                        .textCase(.uppercase)
                        .foregroundStyle(t.muted)
                    Spacer(minLength: 0)
                    Text(t.headline(entry.greeting.headline))
                        .font(t.display(26))
                        .foregroundStyle(t.ink)
                        .minimumScaleFactor(0.6)
                    if let s = entry.snapshot {
                        Text("\(s.openCount) to do · \(s.habitsDone)/\(s.habitsTotal) habits")
                            .font(t.label(10))
                            .foregroundStyle(t.accent)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        dateLine
                            .font(t.label(10))
                            .textCase(.uppercase)
                            .foregroundStyle(t.muted)
                        Spacer(minLength: 0)
                        Text(t.headline(entry.greeting.headline))
                            .font(t.display(26))
                            .foregroundStyle(t.ink)
                            .minimumScaleFactor(0.6)
                        Text(entry.greeting.subline)
                            .font(t.body(11))
                            .foregroundStyle(t.muted)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Rectangle().fill(t.rule).frame(width: 1)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("TODAY").font(t.label(10)).foregroundStyle(t.accent)
                        if let s = entry.snapshot, !s.tasks.isEmpty {
                            ForEach(s.tasks.prefix(4), id: \.self) { task in
                                HStack(alignment: .firstTextBaseline, spacing: 5) {
                                    Text(t.id == .retro ? "[ ]" : "○").foregroundStyle(t.muted)
                                    Text(task).lineLimit(1)
                                }
                                .font(t.body(12))
                                .foregroundStyle(t.ink)
                            }
                        } else {
                            Text("All clear.").font(t.body(12)).foregroundStyle(t.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .containerBackground(for: .widget) { t.bg }
    }
}

@main
struct DaybookWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DaybookToday", provider: DayProvider()) { entry in
            DaybookWidgetView(entry: entry)
        }
        .configurationDisplayName("Daybook")
        .description("Your greeting and today's tasks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

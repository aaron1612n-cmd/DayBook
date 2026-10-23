import SwiftData
import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case today, tasks, habits, journal, more

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .tasks: "Tasks"
        case .habits: "Habits"
        case .journal: "Journal"
        case .more: "More"
        }
    }

    var symbol: String {
        switch self {
        case .today: "sun.horizon"
        case .tasks: "checklist"
        case .habits: "square.grid.3x3"
        case .journal: "book.closed"
        case .more: "ellipsis"
        }
    }

    var key: KeyEquivalent { KeyEquivalent(Character("\(rawValue + 1)")) }
}

struct RootView: View {
    @AppStorage(SharedStore.Key.theme, store: SharedStore.defaults) private var themeRaw = ThemeID.paper.rawValue
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: AppTab = AppTab(rawValue: UserDefaults.standard.integer(forKey: "startTab")) ?? .today
    @State private var weather = WeatherModel()

    private var theme: Theme { (ThemeID(rawValue: themeRaw) ?? .paper).theme }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            Group {
                switch tab {
                case .today: TodayView(tab: $tab)
                case .tasks: TasksView()
                case .habits: HabitsView()
                case .journal: JournalView()
                case .more: MoreView()
                }
            }
            .id(tab)
            .transition(.opacity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TabBar(tab: $tab)
        }
        .overlay {
            if theme.id == .retro { Scanlines() }
        }
        .environment(\.theme, theme)
        .environment(weather)
        .preferredColorScheme(theme.scheme)
        .tint(theme.accent)
        .onAppear {
            if UserDefaults.standard.bool(forKey: "demoData") {
                DemoData.seedIfNeeded(context)
            } else {
                DemoData.seedStarter(context)
            }
            weather.refresh()
            WidgetSync.push(context)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                weather.refresh()
                MorningReminder.reschedule()
            } else if phase == .background {
                try? context.save()
                WidgetSync.push(context)
            }
        }
    }
}

struct TabBar: View {
    @Environment(\.theme) private var theme
    @Binding var tab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { item in
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { tab = item }
                } label: {
                    cell(item, active: item == tab)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(item.key, modifiers: .command)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(item == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 2)
        .readableColumn(640)
        .background {
            theme.bg
                .overlay(alignment: .top) {
                    Rectangle().fill(theme.id == .paper ? theme.ink : theme.rule).frame(height: 1)
                }
                .ignoresSafeArea()
        }
        .sensoryFeedback(.selection, trigger: tab)
    }

    @ViewBuilder
    private func cell(_ item: AppTab, active: Bool) -> some View {
        VStack(spacing: 4) {
            if theme.id == .retro {
                Text(active ? "[\(item.title.uppercased())]" : item.title.uppercased())
                    .font(theme.label(13))
                    .foregroundStyle(active ? theme.accent : theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(height: 40)
            } else {
                Image(systemName: item.symbol)
                    .font(.system(size: 18, weight: theme.id == .bold ? .bold : .regular))
                    .frame(height: 22)
                Text(theme.id == .bold ? item.title.uppercased() : item.title)
                    .font(theme.label(10))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(active ? (theme.id == .bold ? theme.onAccent : theme.accent) : theme.muted)
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.id == .retro ? 0 : 6)
        .background {
            if theme.id == .bold && active { theme.accent }
        }
        .overlay(alignment: .top) {
            if theme.id == .paper && active {
                Rectangle().fill(theme.accent).frame(width: 22, height: 2).offset(y: -8)
            }
        }
        .contentShape(Rectangle())
    }
}

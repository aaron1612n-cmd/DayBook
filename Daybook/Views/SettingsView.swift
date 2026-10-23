import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(WeatherModel.self) private var weather
    @AppStorage(SharedStore.Key.name, store: SharedStore.defaults) private var name = "Aaron"
    @AppStorage(SharedStore.Key.theme, store: SharedStore.defaults) private var themeRaw = ThemeID.paper.rawValue
    @AppStorage(SharedStore.Key.birthdayMonth, store: SharedStore.defaults) private var bMonth = 0
    @AppStorage(SharedStore.Key.birthdayDay, store: SharedStore.defaults) private var bDay = 0
    @AppStorage(MorningReminder.enabledKey) private var morningOn = false
    @AppStorage(MorningReminder.timeKey) private var morningTime = 7 * 60 + 30
    @AppStorage("waterGoal") private var waterGoal = 8
    @AppStorage("fahrenheit") private var fahrenheit = Locale.current.measurementSystem == .us

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                PageTitle(title: "Settings")

                Block {
                    SectionHeader("Look")
                    HStack(spacing: 10) {
                        ForEach(ThemeID.allCases) { id in
                            ThemeSwatch(id: id, selected: themeRaw == id.rawValue) {
                                withAnimation(.easeInOut(duration: 0.25)) { themeRaw = id.rawValue }
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                    }
                }

                Block {
                    SectionHeader("What should I call you?")
                    ThemedField(placeholder: "Aaron", text: $name)
                }

                Block {
                    SectionHeader("Birthday")
                    Toggle(isOn: Binding(
                        get: { bMonth > 0 },
                        set: { on in
                            if on {
                                let c = Calendar.current.dateComponents([.month, .day], from: .now)
                                bMonth = c.month ?? 1
                                bDay = c.day ?? 1
                            } else {
                                bMonth = 0
                                bDay = 0
                            }
                        }
                    )) {
                        Text("Special greeting on my birthday").font(theme.body(15)).foregroundStyle(theme.ink)
                    }
                    if bMonth > 0 {
                        DatePicker("Date", selection: birthdayBinding, displayedComponents: .date)
                            .font(theme.body(15))
                            .foregroundStyle(theme.ink)
                    }
                }

                Block {
                    SectionHeader("Morning greeting")
                    Toggle(isOn: $morningOn) {
                        Text("Send me a good-morning notification").font(theme.body(15)).foregroundStyle(theme.ink)
                    }
                    if morningOn {
                        DatePicker("Time", selection: morningBinding, displayedComponents: .hourAndMinute)
                            .font(theme.body(15))
                            .foregroundStyle(theme.ink)
                    }
                }
                .onChange(of: morningOn) { _, on in
                    Task {
                        if on { _ = await Notifications.requestPermission() }
                        MorningReminder.reschedule()
                    }
                }
                .onChange(of: morningTime) { _, _ in MorningReminder.reschedule() }

                Block {
                    SectionHeader("Daily water goal")
                    Stepper(value: $waterGoal, in: 1...16) {
                        Text("\(waterGoal) glasses").font(theme.body(15)).foregroundStyle(theme.ink)
                    }
                }

                Block {
                    SectionHeader("Temperature")
                    HStack(spacing: 8) {
                        Button("°F") { fahrenheit = true; weather.refresh(force: true) }
                            .buttonStyle(ThemedButtonStyle(filled: fahrenheit))
                        Button("°C") { fahrenheit = false; weather.refresh(force: true) }
                            .buttonStyle(ThemedButtonStyle(filled: !fahrenheit))
                    }
                }

                Text("Daybook keeps everything on this phone. Weather by Open-Meteo.")
                    .font(theme.label(11))
                    .foregroundStyle(theme.muted)
            }
            .tint(theme.accent)
            .pagePadding()
            .readableColumn()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var birthdayBinding: Binding<Date> {
        Binding(
            get: { Calendar.current.date(from: DateComponents(year: 2000, month: bMonth, day: bDay)) ?? .now },
            set: {
                let c = Calendar.current.dateComponents([.month, .day], from: $0)
                bMonth = c.month ?? 1
                bDay = c.day ?? 1
            }
        )
    }

    private var morningBinding: Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: morningTime / 60, minute: morningTime % 60, second: 0, of: .now) ?? .now },
            set: {
                let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
                morningTime = (c.hour ?? 7) * 60 + (c.minute ?? 0)
            }
        )
    }
}

/// Each swatch previews the theme in its own colors and typeface.
private struct ThemeSwatch: View {
    let id: ThemeID
    let selected: Bool
    let action: () -> Void

    var body: some View {
        let t = id.theme
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(t.headline("Morning"))
                    .font(t.display(24))
                    .foregroundStyle(t.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Rectangle().fill(t.accent).frame(width: 26, height: 4)
                Text(id.label.uppercased())
                    .font(t.label(10))
                    .foregroundStyle(t.muted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 96)
            .background(t.bg)
            .overlay {
                if id == .retro { Scanlines() }
            }
            .overlay {
                Rectangle().strokeBorder(selected ? t.accent : Color.gray.opacity(0.35), lineWidth: selected ? 3 : 1)
            }
            .clipped()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(id.label) theme")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

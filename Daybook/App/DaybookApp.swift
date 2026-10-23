import SwiftData
import SwiftUI

@main
struct DaybookApp: App {
    let container: ModelContainer

    init() {
        // Launch arguments (`-theme retro`) land in the standard defaults'
        // argument domain; settings live in the app group, so copy them over.
        let args = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        for key in [SharedStore.Key.theme, SharedStore.Key.name] {
            if let value = args[key] as? String {
                SharedStore.defaults.set(value, forKey: key)
            }
        }
        if SharedStore.defaults.string(forKey: SharedStore.Key.name) == nil {
            SharedStore.defaults.set("Aaron", forKey: SharedStore.Key.name)
        }

        let demo = UserDefaults.standard.bool(forKey: "demoData")
        let config = ModelConfiguration(isStoredInMemoryOnly: demo)
        do {
            container = try ModelContainer(for: TaskItem.self, Habit.self, DayLog.self, Countdown.self, configurations: config)
        } catch {
            // A broken store shouldn't brick the app; start fresh in memory.
            container = try! ModelContainer(for: TaskItem.self, Habit.self, DayLog.self, Countdown.self,
                                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

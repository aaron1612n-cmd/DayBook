import Foundation
import UserNotifications

/// Local notifications only: they work without a push entitlement.
enum Notifications {
    static let morningPrefix = "morning-"
    static let focusID = "focus-end"

    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Schedules the next two weeks of morning greetings individually, so
    /// each morning's message is that day's greeting rather than a repeat.
    static func scheduleMornings(enabled: Bool, hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let old = pending.map(\.identifier).filter { $0.hasPrefix(morningPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: old)
            guard enabled else { return }

            let cal = Calendar.current
            for offset in 0..<14 {
                guard let day = cal.date(byAdding: .day, value: offset, to: Date().day),
                      let fire = cal.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                      fire > Date() else { continue }
                let g = GreetingEngine.greeting(for: fire, name: SharedStore.name, birthday: SharedStore.birthday)
                let content = UNMutableNotificationContent()
                content.title = g.headline
                content.body = "\(g.subline) \(DailyContent.challenge(for: fire))"
                content.sound = .default
                let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                center.add(UNNotificationRequest(identifier: "\(morningPrefix)\(offset)", content: content, trigger: trigger))
            }
        }
    }

    static func scheduleFocusEnd(after seconds: TimeInterval, isBreak: Bool) {
        let content = UNMutableNotificationContent()
        content.title = isBreak ? "Break's over" : "Focus session done"
        content.body = isBreak ? "Back to it, \(SharedStore.name)." : "Nice work, \(SharedStore.name). Take five."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: focusID, content: content, trigger: trigger))
    }

    static func cancelFocus() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [focusID])
    }
}

enum MorningReminder {
    static let enabledKey = "morningOn"
    static let timeKey = "morningTime" // minutes after midnight

    static var minutes: Int {
        let v = UserDefaults.standard.object(forKey: timeKey) as? Int
        return v ?? 7 * 60 + 30
    }

    static func reschedule() {
        let on = UserDefaults.standard.bool(forKey: enabledKey)
        Notifications.scheduleMornings(enabled: on, hour: minutes / 60, minute: minutes % 60)
    }
}

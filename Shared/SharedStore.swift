import Foundation

/// Settings and the widget snapshot live in the app group so the widget can
/// read them. If the group isn't available after re-signing, standard
/// defaults keep the app working; the widget just falls back to defaults.
enum SharedStore {
    static let groupID = "group.com.aaron.daybook"

    static let defaults: UserDefaults = UserDefaults(suiteName: groupID) ?? .standard

    enum Key {
        static let name = "name"
        static let theme = "theme"
        static let birthdayMonth = "birthdayMonth"
        static let birthdayDay = "birthdayDay"
        static let snapshot = "widgetSnapshot"
    }

    static var name: String {
        defaults.string(forKey: Key.name) ?? "Aaron"
    }

    static var birthday: DateComponents? {
        let m = defaults.integer(forKey: Key.birthdayMonth)
        let d = defaults.integer(forKey: Key.birthdayDay)
        guard m > 0, d > 0 else { return nil }
        return DateComponents(month: m, day: d)
    }

    static var themeID: ThemeID {
        ThemeID(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .paper
    }

    static func saveSnapshot(_ snapshot: WidgetSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: Key.snapshot)
        }
    }

    static func loadSnapshot() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: Key.snapshot) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}

struct WidgetSnapshot: Codable {
    var tasks: [String]
    var openCount: Int
    var doneCount: Int
    var habitsDone: Int
    var habitsTotal: Int
    var updated: Date
}

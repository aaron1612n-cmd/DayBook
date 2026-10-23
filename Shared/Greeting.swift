import Foundation

struct Greeting: Equatable {
    let headline: String
    let subline: String
}

enum DayPart: Int, CaseIterable {
    case lateNight, dawn, morning, midday, afternoon, evening, night

    init(hour: Int) {
        switch hour {
        case 0..<5: self = .lateNight
        case 5..<8: self = .dawn
        case 8..<12: self = .morning
        case 12..<14: self = .midday
        case 14..<17: self = .afternoon
        case 17..<21: self = .evening
        default: self = .night
        }
    }
}

enum GreetingEngine {
    /// Days since a fixed epoch in the local calendar. Picking lines by
    /// `dayNumber % count` means a given slot never repeats yesterday's line.
    static func dayNumber(_ date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let epoch = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        return calendar.dateComponents([.day], from: epoch, to: start).day ?? 0
    }

    static func greeting(for date: Date, name rawName: String, birthday: DateComponents? = nil, calendar: Calendar = .current) -> Greeting {
        let name = rawName.trimmingCharacters(in: .whitespaces).isEmpty ? "friend" : rawName.trimmingCharacters(in: .whitespaces)
        let hour = calendar.component(.hour, from: date)
        let part = DayPart(hour: hour)
        let day = dayNumber(date, calendar: calendar)

        let lines = headlines[part]!
        let headline = lines[(day + part.rawValue) % lines.count].replacingOccurrences(of: "{n}", with: name)

        if let special = special(for: date, name: name, birthday: birthday, calendar: calendar) {
            return Greeting(headline: special.0 ?? headline, subline: special.1)
        }

        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday
        let pool = weekdayLines[weekday]! + partLines[part]!
        let subline = pool[(day * 7 + part.rawValue) % pool.count]
        return Greeting(headline: headline, subline: subline)
    }

    private static func special(for date: Date, name: String, birthday: DateComponents?, calendar: Calendar) -> (String?, String)? {
        let m = calendar.component(.month, from: date)
        let d = calendar.component(.day, from: date)
        if let b = birthday, b.month == m, b.day == d {
            return ("Happy birthday, \(name).", "Another lap around the sun. Today is yours.")
        }
        switch (m, d) {
        case (1, 1): return ("Happy New Year, \(name).", "Blank page. Write something good on it.")
        case (2, 14): return (nil, "Valentine's Day. Tell someone they matter.")
        case (3, 17): return (nil, "St. Patrick's Day. Wear something green.")
        case (4, 1): return (nil, "April Fools'. Trust nothing today.")
        case (10, 31): return ("Happy Halloween, \(name).", "Spooky season peaks tonight.")
        case (12, 24): return (nil, "Christmas Eve. Slow down tonight.")
        case (12, 25): return ("Merry Christmas, \(name).", "Eat well, rest well.")
        case (12, 31): return (nil, "Last page of the year. Finish it kindly.")
        default: return nil
        }
    }

    static let headlines: [DayPart: [String]] = [
        .lateNight: [
            "Still up, {n}?",
            "Burning the midnight oil, {n}.",
            "The quiet hours, {n}.",
            "Hey night owl.",
            "It's late, {n}. Be gentle.",
            "Small hours, {n}.",
        ],
        .dawn: [
            "Early start, {n}.",
            "First light, {n}.",
            "Up before the sun, {n}?",
            "Morning's barely here, {n}.",
            "Quiet morning, {n}.",
        ],
        .morning: [
            "Good morning, {n}.",
            "Morning, {n}. Fresh page.",
            "Rise and shine, {n}.",
            "Hey {n}, coffee first.",
            "New day, {n}.",
            "Top of the morning, {n}.",
            "Morning, {n}. Let's go.",
            "Hello, sunshine.",
        ],
        .midday: [
            "Afternoon's almost here, {n}.",
            "Lunch break, {n}?",
            "Halfway there, {n}.",
            "Midday check-in, {n}.",
            "Hey {n}, eat something.",
        ],
        .afternoon: [
            "Good afternoon, {n}.",
            "Afternoon, {n}.",
            "Keep it rolling, {n}.",
            "Hey {n}, how's it going?",
            "Second wind, {n}.",
            "Still got this, {n}.",
        ],
        .evening: [
            "Good evening, {n}.",
            "Evening, {n}.",
            "Wind it down, {n}.",
            "You made it, {n}.",
            "Hey {n}, day's nearly done.",
            "Golden hour, {n}.",
        ],
        .night: [
            "Good night soon, {n}.",
            "Night, {n}.",
            "Time to slow down, {n}.",
            "Lights low, {n}.",
            "Rest up, {n}.",
        ],
    ]

    static let weekdayLines: [Int: [String]] = [
        1: ["Sunday. Nothing has to happen today.", "Sunday reset. Plan the week lightly.", "Sunday. Go outside for a bit."],
        2: ["Monday. Pick one thing and win it.", "Monday again. You know how this goes.", "New week, clean slate."],
        3: ["Tuesday. Momentum day.", "Tuesday. Quietly productive.", "Tuesday. Keep the streak alive."],
        4: ["Wednesday. Over the hump.", "Midweek. Check on your habits.", "Wednesday. Halfway home."],
        5: ["Thursday. Almost there.", "Thursday. Finish what you started.", "Thursday. One more push."],
        6: ["Friday. Wrap it up and log off.", "It's Friday. You earned it.", "Friday. Leave a little for Monday."],
        7: ["Saturday. Do something just for fun.", "Saturday. No alarms.", "Saturday. Go make a memory."],
    ]

    static let partLines: [DayPart: [String]] = [
        .lateNight: ["Sleep is a feature, not a bug.", "Tomorrow-you will thank you for bed."],
        .dawn: ["The world's still quiet. Enjoy it.", "Big glass of water first."],
        .morning: ["What's the one thing that matters today?", "Drink some water before the coffee."],
        .midday: ["Step away from the screen for ten.", "Refuel. The afternoon is long."],
        .afternoon: ["Stand up, stretch, keep going.", "Knock out something small."],
        .evening: ["Check off what you did. It counts.", "Write one line about today."],
        .night: ["Screens down soon.", "Set up tomorrow, then rest."],
    ]
}

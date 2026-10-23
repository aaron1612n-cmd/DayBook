import SwiftUI

enum ThemeID: String, CaseIterable, Identifiable, Codable {
    case paper, bold, retro

    var id: String { rawValue }

    var label: String {
        switch self {
        case .paper: "Paper"
        case .bold: "Bold"
        case .retro: "Retro"
        }
    }

    var theme: Theme {
        switch self {
        case .paper: .paper
        case .bold: .bold
        case .retro: .retro
        }
    }
}

/// Each theme is a full identity, not a recolor: its own type pairing,
/// its own section treatment, its own texture.
struct Theme {
    let id: ThemeID
    let bg: Color
    let surface: Color
    let ink: Color
    let muted: Color
    let rule: Color
    let accent: Color
    let onAccent: Color
    let scheme: ColorScheme

    let displayFace: String
    let bodyFace: String?
    let labelFace: String
    /// VT323 runs small, so its sizes are scaled up.
    let scale: CGFloat
    let uppercaseDisplay: Bool
    let radius: CGFloat

    func display(_ size: CGFloat) -> Font {
        .custom(displayFace, size: size * scale, relativeTo: .largeTitle)
    }

    func body(_ size: CGFloat = 17) -> Font {
        if let bodyFace {
            return .custom(bodyFace, size: size * scale, relativeTo: .body)
        }
        return .system(size: size, design: .serif)
    }

    func label(_ size: CGFloat = 12) -> Font {
        .custom(labelFace, size: size * scale, relativeTo: .caption)
    }

    func headline(_ text: String) -> String {
        uppercaseDisplay ? text.uppercased() : text
    }

    static let paper = Theme(
        id: .paper,
        bg: Color(hex: 0xF2EBDD),
        surface: Color(hex: 0xE9DFCB),
        ink: Color(hex: 0x221E18),
        muted: Color(hex: 0x6E6455),
        rule: Color(hex: 0xCDBFA6),
        accent: Color(hex: 0xB8432B),
        onAccent: Color(hex: 0xF7F1E6),
        scheme: .light,
        displayFace: "InstrumentSerif-Regular",
        bodyFace: nil,
        labelFace: "IBMPlexMono-Regular",
        scale: 1,
        uppercaseDisplay: false,
        radius: 2
    )

    static let bold = Theme(
        id: .bold,
        bg: Color(hex: 0x0F0F0E),
        surface: Color(hex: 0x1C1B19),
        ink: Color(hex: 0xF3EFE6),
        muted: Color(hex: 0x8C877C),
        rule: Color(hex: 0x2E2C28),
        accent: Color(hex: 0xFF6A2B),
        onAccent: Color(hex: 0x0F0F0E),
        scheme: .dark,
        displayFace: "Anton-Regular",
        bodyFace: "SpaceMono-Regular",
        labelFace: "SpaceMono-Bold",
        scale: 0.92,
        uppercaseDisplay: true,
        radius: 0
    )

    static let retro = Theme(
        id: .retro,
        bg: Color(hex: 0x150E06),
        surface: Color(hex: 0x21170A),
        ink: Color(hex: 0xFFB547),
        muted: Color(hex: 0xA5722B),
        rule: Color(hex: 0x4A3314),
        accent: Color(hex: 0x8BE07A),
        onAccent: Color(hex: 0x150E06),
        scheme: .dark,
        displayFace: "VT323-Regular",
        bodyFace: "VT323-Regular",
        labelFace: "VT323-Regular",
        scale: 1.3,
        uppercaseDisplay: true,
        radius: 0
    )
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .paper
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

/// Retro's one texture: faint CRT scanlines over everything.
struct Scanlines: View {
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black.opacity(0.22)))
                y += 3
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

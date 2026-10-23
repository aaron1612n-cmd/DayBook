import SwiftUI

/// Small uppercase label that heads every section.
struct SectionHeader<Trailing: View>: View {
    @Environment(\.theme) private var theme
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(theme.id == .retro ? "> \(title.uppercased())" : title.uppercased())
                .font(theme.label(11))
                .tracking(theme.id == .retro ? 0 : 1.4)
                .foregroundStyle(theme.muted)
            Spacer()
            trailing()
        }
        .accessibilityAddTraits(.isHeader)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title) { EmptyView() }
    }
}

/// The section container. Paper gets newspaper rules, Bold gets solid
/// slabs, Retro gets dashed terminal boxes.
struct Block<Content: View>: View {
    @Environment(\.theme) private var theme
    var padded = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        switch theme.id {
        case .paper:
            VStack(alignment: .leading, spacing: 12) { content() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 14)
                .padding(.bottom, 4)
                .overlay(alignment: .top) { Rectangle().fill(theme.ink).frame(height: 1) }
        case .bold:
            VStack(alignment: .leading, spacing: 12) { content() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(padded ? 16 : 0)
                .background(theme.surface)
        case .retro:
            VStack(alignment: .leading, spacing: 10) { content() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(padded ? 14 : 0)
                .overlay {
                    Rectangle().strokeBorder(theme.rule, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
        }
    }
}

/// Large screen title used at the top of each tab.
struct PageTitle: View {
    @Environment(\.theme) private var theme
    let title: String
    var kicker: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let kicker {
                Text(kicker.uppercased())
                    .font(theme.label(11))
                    .tracking(1.2)
                    .foregroundStyle(theme.accent)
            }
            Text(theme.headline(title))
                .font(theme.display(44))
                .foregroundStyle(theme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

struct CheckBox: View {
    @Environment(\.theme) private var theme
    let done: Bool

    var body: some View {
        Group {
            switch theme.id {
            case .paper:
                ZStack {
                    Circle().strokeBorder(done ? theme.accent : theme.ink.opacity(0.55), lineWidth: 1.2)
                    if done {
                        Circle().fill(theme.accent).padding(4)
                    }
                }
                .frame(width: 22, height: 22)
            case .bold:
                ZStack {
                    Rectangle().fill(done ? theme.accent : .clear)
                    Rectangle().strokeBorder(done ? theme.accent : theme.ink.opacity(0.5), lineWidth: 2)
                    if done {
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .black)).foregroundStyle(theme.onAccent)
                    }
                }
                .frame(width: 22, height: 22)
            case .retro:
                Text(done ? "[x]" : "[ ]")
                    .font(theme.body(18))
                    .foregroundStyle(done ? theme.accent : theme.ink)
                    .frame(width: 34, alignment: .leading)
            }
        }
        .animation(.snappy(duration: 0.18), value: done)
    }
}

/// The app's one intentional motion: the greeting is revealed left to
/// right like ink soaking into paper, once per launch.
struct InkReveal<Content: View>: View {
    @State private var progress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var delay: Double = 0
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .mask {
                GeometryReader { geo in
                    let w = geo.size.width * 1.3
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.77),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: w)
                    .offset(x: (progress - 1) * w)
                }
            }
            .onAppear {
                guard progress == 0 else { return }
                if reduceMotion {
                    progress = 1
                } else {
                    withAnimation(.easeOut(duration: 1.1).delay(delay)) { progress = 1 }
                }
            }
    }
}

struct ThemedField: View {
    @Environment(\.theme) private var theme
    let placeholder: String
    @Binding var text: String
    var onSubmit: () -> Void = {}

    var body: some View {
        HStack(spacing: 8) {
            if theme.id == .retro {
                Text("$").font(theme.body(18)).foregroundStyle(theme.accent)
            }
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(theme.muted))
                .font(theme.body(16))
                .foregroundStyle(theme.ink)
                .tint(theme.accent)
                .submitLabel(.done)
                .onSubmit(onSubmit)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, theme.id == .paper ? 0 : 12)
        .background(theme.id == .bold ? theme.bg : .clear)
        .overlay(alignment: .bottom) {
            if theme.id == .paper { Rectangle().fill(theme.rule).frame(height: 1) }
        }
        .overlay {
            if theme.id == .retro { Rectangle().strokeBorder(theme.rule, lineWidth: 1) }
        }
    }
}

/// Primary action button styled per theme.
struct ThemedButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    var filled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.label(13))
            .tracking(theme.id == .retro ? 0 : 0.8)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .foregroundStyle(filled ? theme.onAccent : theme.ink)
            .background(filled ? theme.accent : .clear)
            .overlay {
                if !filled {
                    RoundedRectangle(cornerRadius: theme.radius).strokeBorder(theme.ink.opacity(0.4), lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.radius))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(Rectangle())
    }
}

extension View {
    /// Keeps content readable on iPad by capping the line length.
    func readableColumn(_ maxWidth: CGFloat = 760) -> some View {
        frame(maxWidth: maxWidth).frame(maxWidth: .infinity)
    }

    func pagePadding() -> some View {
        padding(.horizontal, 20).padding(.bottom, 40)
    }
}

enum Fmt {
    static func string(_ date: Date, _ template: String) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate(template)
        return f.string(from: date)
    }

    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}

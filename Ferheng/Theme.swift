import SwiftUI

enum Theme {
    static let brand = Color(red: 0.05, green: 0.55, blue: 0.50)
    static let brandLight = Color(red: 0.13, green: 0.78, blue: 0.66)
    static let sun = Color(red: 0.98, green: 0.72, blue: 0.10)
    static let brandGradient = LinearGradient(colors: [brand, brandLight], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let sunGradient = LinearGradient(colors: [Color(red: 0.98, green: 0.55, blue: 0.15), sun], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let hardGradient = LinearGradient(colors: [Color(red: 0.93, green: 0.27, blue: 0.36), Color(red: 0.98, green: 0.47, blue: 0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let verbGradient = LinearGradient(colors: [Color(red: 0.44, green: 0.30, blue: 0.95), Color(red: 0.70, green: 0.40, blue: 0.98)], startPoint: .topLeading, endPoint: .bottomTrailing)

    static let colorNames = ["teal", "blue", "indigo", "violet", "pink", "red", "orange", "amber", "green", "gray"]

    static func color(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "indigo": return .indigo
        case "violet": return .purple
        case "pink": return .pink
        case "red": return .red
        case "orange": return .orange
        case "amber": return Color(red: 0.95, green: 0.65, blue: 0.05)
        case "green": return .green
        case "gray": return .gray
        default: return brand
        }
    }

    static func color(_ mastery: Mastery) -> Color {
        switch mastery {
        case .new: return Color(.systemGray3)
        case .hard: return Color(red: 0.93, green: 0.27, blue: 0.36)
        case .learning: return .orange
        case .easy: return .blue
        case .mastered: return .green
        }
    }

    static func gradeColor(_ grade: Grade) -> Color {
        switch grade {
        case .again: return Color(red: 0.93, green: 0.27, blue: 0.36)
        case .hard: return .orange
        case .good: return brand
        case .easy: return .blue
        }
    }
}

// MARK: - Bausteine

struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View { modifier(CardBackground(padding: padding)) }
}

struct GradientButtonStyle: ButtonStyle {
    var gradient: LinearGradient = Theme.brandGradient
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    var tint: Color = Theme.brand
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct FolderIcon: View {
    let folder: Folder
    var size: CGFloat = 44
    var body: some View {
        let c = Theme.color(folder.colorName)
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(LinearGradient(colors: [c.opacity(0.25), c.opacity(0.12)], startPoint: .top, endPoint: .bottom))
                .frame(width: size, height: size)
                .overlay(Text(folder.emoji).font(.system(size: size * 0.5)))
            if !folder.linkedIDs.isEmpty {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: size * 0.32))
                    .foregroundStyle(.white, c)
                    .offset(x: 4, y: 4)
            }
        }
    }
}

/// Gestapelter Balken: wie viele Wörter neu / schwer / in Arbeit / leicht / sitzen.
struct MasteryBar: View {
    let counts: [Mastery: Int]
    var height: CGFloat = 8
    var body: some View {
        let total = max(1, counts.values.reduce(0, +))
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach([Mastery.mastered, .easy, .learning, .hard, .new]) { m in
                    let n = counts[m] ?? 0
                    if n > 0 {
                        Capsule()
                            .fill(Theme.color(m))
                            .frame(width: max(height, (geo.size.width - 8) * CGFloat(n) / CGFloat(total)))
                    }
                }
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
    }
}

struct MasteryLegend: View {
    let counts: [Mastery: Int]
    var body: some View {
        HStack(spacing: 12) {
            ForEach([Mastery.mastered, .easy, .learning, .hard, .new]) { m in
                HStack(spacing: 4) {
                    Circle().fill(Theme.color(m)).frame(width: 8, height: 8)
                    Text("\(m.label) \(counts[m] ?? 0)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct Tag: View {
    let text: String
    var color: Color = .secondary
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.13), in: Capsule())
    }
}

/// Leiste mit kurdischen Sonderzeichen, die an Text angehängt werden.
struct KurdishCharBar: View {
    @Binding var text: String
    @State private var upper = false
    private let letters = ["ê", "î", "û", "ç", "ş"]
    var body: some View {
        HStack(spacing: 8) {
            Button {
                upper.toggle()
            } label: {
                Image(systemName: upper ? "shift.fill" : "shift")
                    .frame(width: 38, height: 38)
                    .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            ForEach(letters, id: \.self) { l in
                let char = upper ? l.uppercased() : l
                Button {
                    text += char
                    upper = false
                } label: {
                    Text(char)
                        .font(.title3.weight(.medium))
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var gradient: AngularGradient = AngularGradient(colors: [Theme.brand, Theme.brandLight, Theme.brand], center: .center)
    var body: some View {
        ZStack {
            Circle().stroke(Color(.tertiarySystemFill), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0.001, progress)))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
    }
}

import SwiftUI

enum Theme {
    static let bg = Color(hex: "#eeecef")
    static let panel = Color.white
    static let ink = Color(hex: "#1d1b22")
    static let soft = Color(hex: "#6d6877")
    static let accent = Color(hex: "#a8455f")
    static let chip = Color(hex: "#f4f2f5")
    static let line = Color(hex: "#dcd8e0")
    static let good = Color(hex: "#3f7d63")
    static let gold = Color(hex: "#d4a843")
    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .serif) }
}

/// Legger knapper etter hverandre og bryter til ny linje når det blir fullt.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? 360
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, w: CGFloat = 0
        for v in subviews {
            var s = v.sizeThatFits(.unspecified)
            if s.width > maxW { s = v.sizeThatFits(ProposedViewSize(width: maxW, height: nil)) }
            if x > 0 && x + s.width > maxW { x = 0; y += rowH + spacing; rowH = 0 }
            x += s.width + spacing
            rowH = max(rowH, s.height)
            w = max(w, x - spacing)
        }
        return CGSize(width: min(w, maxW), height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for v in subviews {
            var s = v.sizeThatFits(.unspecified)
            if s.width > bounds.width { s = v.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil)) }
            if x > bounds.minX && x + s.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
    }
}

struct OptionRow<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).font(.system(size: 12, weight: .medium)).kerning(1.4).foregroundStyle(Theme.soft)
            FlowLayout { content }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Swatch: View {
    let color: String
    var on = false
    var locked = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                if color == "none" {
                    Circle().fill(Color.white)
                    Rectangle().fill(Theme.soft).frame(width: 22, height: 1.5).rotationEffect(.degrees(-45))
                } else {
                    Circle().fill(Color(hex: color))
                }
                if locked { Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(.white).shadow(radius: 1) }
            }
            .frame(width: 38, height: 38)
            .opacity(locked ? 0.55 : 1)
            .overlay(Circle().stroke(on ? Theme.ink : Theme.line, lineWidth: on ? 2.5 : 1).padding(on ? -3 : 0))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(color == "none" ? "Ingen" : locked ? "Låst farge" : "Farge")
    }
}

struct Chip: View {
    let label: String
    var on = false
    var locked = false
    var price: Int? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if locked { Image(systemName: "lock.fill").font(.system(size: 10)) }
                Text(label + (locked && price != nil ? " · \(price!) mynter" : ""))
            }
            .font(.system(size: 15))
            .padding(.horizontal, 13).padding(.vertical, 8)
            .foregroundStyle(on ? Color.white : locked ? Theme.soft : Theme.ink)
            .background(RoundedRectangle(cornerRadius: 7).fill(on ? Theme.ink : Theme.chip))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(on ? Theme.ink : Theme.line, style: StrokeStyle(lineWidth: 1, dash: locked ? [4, 3] : [])))
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryButton: View {
    let label: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.system(size: 15, weight: .medium))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .foregroundStyle(.white)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.ink))
        }
        .buttonStyle(.plain)
    }
}

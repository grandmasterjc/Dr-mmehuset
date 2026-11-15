import SwiftUI

/// Tegner SVG-tekst fra spillet med SwiftUI Canvas. Ingen nettleser er involvert.
struct SVGView: View {
    let svg: String
    var viewBox = CGRect(x: 0, y: 0, width: 300, height: 610)
    var alignBottom = true

    var body: some View {
        let root = SVGCache.shared.node(svg)
        Canvas { ctx, size in
            let s = min(size.width / viewBox.width, size.height / viewBox.height)
            let ox = (size.width - viewBox.width * s) / 2 - viewBox.minX * s
            let oy = (alignBottom ? size.height - viewBox.height * s : (size.height - viewBox.height * s) / 2) - viewBox.minY * s
            ctx.translateBy(x: ox, y: oy)
            ctx.scaleBy(x: s, y: s)
            for ch in root.children { SVGDraw.draw(ch, ctx, fill: "#000", scale: s) }
        }
    }
}

final class SVGCache {
    static let shared = SVGCache()
    private var cache: [String: SVGNode] = [:]
    private var order: [String] = []
    func node(_ s: String) -> SVGNode {
        if let n = cache[s] { return n }
        let n = SVG.parse(s)
        cache[s] = n
        order.append(s)
        if order.count > 60 { cache.removeValue(forKey: order.removeFirst()) }
        return n
    }
}

extension Color {
    init(hex: String, alpha: Double = 1) {
        let c = SVG.color(hex) ?? (0, 0, 0, 1)
        self.init(.sRGB, red: c.0, green: c.1, blue: c.2, opacity: c.3 * alpha)
    }
}

enum SVGDraw {
    static func path(_ ops: [PathOp]) -> Path {
        var p = Path()
        for o in ops {
            switch o {
            case let .move(x, y): p.move(to: CGPoint(x: x, y: y))
            case let .line(x, y): p.addLine(to: CGPoint(x: x, y: y))
            case let .quad(cx, cy, x, y): p.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cx, y: cy))
            case let .cubic(a, b, c, d, x, y): p.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: a, y: b), control2: CGPoint(x: c, y: d))
            case .close: p.closeSubpath()
            }
        }
        return p
    }

    static func draw(_ n: SVGNode, _ ctx: GraphicsContext, fill inherited: String, scale: Double) {
        var c = ctx
        var sc = scale
        if n.transform != .id {
            let t = n.transform
            c.concatenate(CGAffineTransform(a: t.a, b: t.b, c: t.c, d: t.d, tx: t.tx, ty: t.ty))
            sc *= sqrt(abs(t.a * t.d - t.b * t.c))
        }
        let fill = n.attrs["fill"] ?? inherited
        let op = n.num("opacity", 1)
        let blur = SVG.blur(n.attrs["filter"])
        if n.name == "g" || n.name == "svg" {
            if n.attrs["clip-path"] != nil { return }
            if op < 1 || blur > 0 {
                if blur > 0 { c.addFilter(.blur(radius: blur * sc)) }
                c.opacity *= op
                c.drawLayer { lc in for ch in n.children { draw(ch, lc, fill: fill, scale: sc) } }
            } else {
                for ch in n.children { draw(ch, c, fill: fill, scale: sc) }
            }
            return
        }
        if n.name == "defs" || n.name == "clipPath" || n.name == "linearGradient" || n.name == "filter" { return }
        if n.name == "text" {
            let size = n.num("font-size", 12)
            let col = SVG.color(n.attrs["fill"] ?? inherited) ?? (0, 0, 0, 1)
            let anchor: UnitPoint = n.attrs["text-anchor"] == "middle" ? .bottom : .bottomLeading
            var t = Text(n.text).font(.system(size: size, weight: (n.attrs["font-weight"] ?? "") >= "600" ? .semibold : .regular))
            t = t.foregroundColor(Color(.sRGB, red: col.0, green: col.1, blue: col.2, opacity: col.3))
            c.opacity *= op
            c.draw(t, at: CGPoint(x: n.num("x"), y: n.num("y") + size * 0.2), anchor: anchor)
            return
        }
        let p: Path
        switch n.name {
        case "path": p = path(n.ops)
        case "circle":
            let r = n.num("r")
            p = Path(ellipseIn: CGRect(x: n.num("cx") - r, y: n.num("cy") - r, width: 2 * r, height: 2 * r))
        case "ellipse":
            let rx = n.num("rx"), ry = n.num("ry")
            p = Path(ellipseIn: CGRect(x: n.num("cx") - rx, y: n.num("cy") - ry, width: 2 * rx, height: 2 * ry))
        case "rect":
            p = Path(roundedRect: CGRect(x: n.num("x"), y: n.num("y"), width: n.num("width"), height: n.num("height")), cornerRadius: n.num("rx"))
        default: return
        }
        if op < 1 { c.opacity *= op }
        if blur > 0 {
            c.addFilter(.blur(radius: blur * sc))
            c.drawLayer { lc in shape(p, n, lc, fill: fill) }
        } else {
            shape(p, n, c, fill: fill)
        }
    }

    static func shape(_ p: Path, _ n: SVGNode, _ c: GraphicsContext, fill: String) {
        if let f = SVG.color(fill) {
            c.fill(p, with: .color(Color(.sRGB, red: f.0, green: f.1, blue: f.2, opacity: f.3)))
        }
        if let s = SVG.color(n.attrs["stroke"]) {
            let so = n.num("stroke-opacity", 1)
            let dash = SVG.numbers(Substring(n.attrs["stroke-dasharray"] ?? "")).map { CGFloat($0) }
            let style = StrokeStyle(lineWidth: n.num("stroke-width", 1),
                                    lineCap: n.attrs["stroke-linecap"] == "round" ? .round : .butt,
                                    lineJoin: n.attrs["stroke-linejoin"] == "round" ? .round : .miter,
                                    dash: dash)
            c.stroke(p, with: .color(Color(.sRGB, red: s.0, green: s.1, blue: s.2, opacity: s.3 * so)), style: style)
        }
    }
}

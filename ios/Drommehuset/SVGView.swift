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
            for ch in root.children { SVGDraw.draw(ch, ctx, fill: "#000", scale: s, ids: root.ids) }
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

    static func draw(_ n: SVGNode, _ ctx: GraphicsContext, fill inherited: String, scale: Double, ids: [String: SVGNode]) {
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
            if let cp = n.attrs["clip-path"], let id = refId(cp), let clip = ids[id] {
                var cpath = Path()
                for ch in clip.children { if let p = shapePath(ch) { cpath.addPath(p, transform: ch.transform == .id ? .identity : CGAffineTransform(a: ch.transform.a, b: ch.transform.b, c: ch.transform.c, d: ch.transform.d, tx: ch.transform.tx, ty: ch.transform.ty)) } }
                c.clip(to: cpath)
            }
            if n.name == "svg", n.attrs["width"] != nil, n.attrs["height"] != nil {
                let x = n.num("x"), y = n.num("y"), w = n.num("width"), h = n.num("height")
                c.clip(to: Path(CGRect(x: x, y: y, width: w, height: h)))
                let vb = SVG.numbers(Substring(n.attrs["viewBox"] ?? ""))
                c.translateBy(x: x, y: y)
                if vb.count == 4, vb[2] > 0, vb[3] > 0 {
                    c.scaleBy(x: w / vb[2], y: h / vb[3]); c.translateBy(x: -vb[0], y: -vb[1])
                    sc *= w / vb[2]
                }
            }
            if op < 1 || blur > 0 {
                if blur > 0 { c.addFilter(.blur(radius: blur * sc)) }
                c.opacity *= op
                c.drawLayer { lc in for ch in n.children { draw(ch, lc, fill: fill, scale: sc, ids: ids) } }
            } else {
                for ch in n.children { draw(ch, c, fill: fill, scale: sc, ids: ids) }
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
        guard let p = shapePath(n) else { return }
        if op < 1 { c.opacity *= op }
        if blur > 0 {
            c.addFilter(.blur(radius: blur * sc))
            c.drawLayer { lc in shape(p, n, lc, fill: fill, ids: ids) }
        } else {
            shape(p, n, c, fill: fill, ids: ids)
        }
    }

    static func refId(_ s: String) -> String? {
        guard let a = s.range(of: "#"), let b = s.range(of: ")") else { return nil }
        return String(s[a.upperBound..<b.lowerBound])
    }

    static func shapePath(_ n: SVGNode) -> Path? {
        switch n.name {
        case "path": return path(n.ops)
        case "circle":
            let r = n.num("r")
            return Path(ellipseIn: CGRect(x: n.num("cx") - r, y: n.num("cy") - r, width: 2 * r, height: 2 * r))
        case "ellipse":
            let rx = n.num("rx"), ry = n.num("ry")
            return Path(ellipseIn: CGRect(x: n.num("cx") - rx, y: n.num("cy") - ry, width: 2 * rx, height: 2 * ry))
        case "rect":
            let r = CGRect(x: n.num("x"), y: n.num("y"), width: n.num("width"), height: n.num("height"))
            let rx = min(n.num("rx"), min(r.width, r.height) / 2)
            return rx > 0 ? Path(roundedRect: r, cornerRadius: rx) : Path(r)
        default: return nil
        }
    }

    /// Fargeovergang (linearGradient) til SwiftUI.
    static func gradient(_ g: SVGNode, _ p: Path) -> GraphicsContext.Shading {
        let stops = g.children.filter { $0.name == "stop" }.map { st -> Gradient.Stop in
            let c = SVG.color(st.attrs["stop-color"]) ?? (0, 0, 0, 1)
            return Gradient.Stop(color: Color(.sRGB, red: c.0, green: c.1, blue: c.2, opacity: c.3 * st.num("stop-opacity", 1)), location: st.num("offset"))
        }
        let x1 = g.num("x1", 0), y1 = g.num("y1", 0), x2 = g.num("x2", 1), y2 = g.num("y2", 0)
        if g.attrs["gradientUnits"] == "userSpaceOnUse" {
            return .linearGradient(Gradient(stops: stops), startPoint: CGPoint(x: x1, y: y1), endPoint: CGPoint(x: x2, y: y2))
        }
        let b = p.boundingRect
        return .linearGradient(Gradient(stops: stops), startPoint: CGPoint(x: b.minX + x1 * b.width, y: b.minY + y1 * b.height), endPoint: CGPoint(x: b.minX + x2 * b.width, y: b.minY + y2 * b.height))
    }

    static func shape(_ p: Path, _ n: SVGNode, _ c: GraphicsContext, fill: String, ids: [String: SVGNode]) {
        if fill.hasPrefix("url("), let id = refId(fill), let g = ids[id] {
            c.fill(p, with: gradient(g, p))
        } else if let f = SVG.color(fill) {
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

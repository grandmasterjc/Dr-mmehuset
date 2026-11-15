import Foundation

// En liten SVG-leser for tegningene i spillet (path, circle, ellipse, rect, g og text).
// Den lager et tre som SVGView tegner med SwiftUI.

struct Aff: Equatable {
    var a = 1.0, b = 0.0, c = 0.0, d = 1.0, tx = 0.0, ty = 0.0
    static let id = Aff()
    /// self etterfulgt av m (m brukes først på punktet)
    func then(_ m: Aff) -> Aff {
        Aff(a: a * m.a + c * m.b, b: b * m.a + d * m.b,
            c: a * m.c + c * m.d, d: b * m.c + d * m.d,
            tx: a * m.tx + c * m.ty + tx, ty: b * m.tx + d * m.ty + ty)
    }
    func apply(_ x: Double, _ y: Double) -> (Double, Double) { (a * x + c * y + tx, b * x + d * y + ty) }
}

enum PathOp: Equatable {
    case move(Double, Double)
    case line(Double, Double)
    case quad(Double, Double, Double, Double)
    case cubic(Double, Double, Double, Double, Double, Double)
    case close
}

final class SVGNode {
    let name: String
    /// alle elementer med id, bare satt på rotnoden
    var ids: [String: SVGNode] = [:]
    var attrs: [String: String]
    var children: [SVGNode] = []
    var text = ""
    // ferdig tolket
    var ops: [PathOp] = []
    var transform = Aff.id
    init(_ name: String, _ attrs: [String: String]) { self.name = name; self.attrs = attrs }
    func num(_ k: String, _ def: Double = 0) -> Double { attrs[k].flatMap { Double($0.trimmingCharacters(in: .whitespaces)) } ?? def }
}

enum SVG {
    static func parse(_ s: String) -> SVGNode {
        let root = SVGNode("g", [:])
        var stack = [root]
        let chars = Array(s.utf8)
        var i = 0
        let n = chars.count
        func str(_ a: Int, _ b: Int) -> String { String(decoding: chars[a..<b], as: UTF8.self) }
        while i < n {
            if chars[i] != UInt8(ascii: "<") {
                let st = i
                while i < n && chars[i] != UInt8(ascii: "<") { i += 1 }
                if let top = stack.last, top.name == "text" { top.text += str(st, i) }
                continue
            }
            i += 1
            if i < n && chars[i] == UInt8(ascii: "/") {
                while i < n && chars[i] != UInt8(ascii: ">") { i += 1 }
                i += 1
                if stack.count > 1 { stack.removeLast() }
                continue
            }
            let ns = i
            while i < n && chars[i] != UInt8(ascii: " ") && chars[i] != UInt8(ascii: ">") && chars[i] != UInt8(ascii: "/") { i += 1 }
            let name = str(ns, i)
            var attrs: [String: String] = [:]
            var selfClose = false
            while i < n {
                let ch = chars[i]
                if ch == UInt8(ascii: ">") { i += 1; break }
                if ch == UInt8(ascii: "/") { selfClose = true; i += 1; continue }
                if ch == UInt8(ascii: " ") || ch == UInt8(ascii: "\n") { i += 1; continue }
                let ks = i
                while i < n && chars[i] != UInt8(ascii: "=") && chars[i] != UInt8(ascii: " ") && chars[i] != UInt8(ascii: ">") { i += 1 }
                let key = str(ks, i)
                if i < n && chars[i] == UInt8(ascii: "=") {
                    i += 1
                    let q = chars[i]
                    i += 1
                    let vs = i
                    while i < n && chars[i] != q { i += 1 }
                    attrs[key] = str(vs, i).replacingOccurrences(of: "&amp;", with: "&").replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&quot;", with: "\"")
                    i += 1
                }
            }
            let node = SVGNode(name, attrs)
            if let t = attrs["transform"] { node.transform = parseTransform(t) }
            if name == "path", let d = attrs["d"] { node.ops = parsePath(d) }
            stack.last!.children.append(node)
            if let id = attrs["id"] { root.ids[id] = node }
            if !selfClose { stack.append(node) }
        }
        return root
    }

    static func numbers(_ s: Substring) -> [Double] {
        var out: [Double] = []
        var cur = ""
        func flush() { if !cur.isEmpty, let v = Double(cur) { out.append(v) }; cur = "" }
        for ch in s {
            if ch == "-" { if !cur.isEmpty && !cur.hasSuffix("e") { flush() }; cur.append(ch) }
            else if ch == "." { if cur.contains(".") && !cur.contains("e") { flush() }; cur.append(ch) }
            else if ch.isNumber || ch == "e" { cur.append(ch) }
            else { flush() }
        }
        flush()
        return out
    }

    static func parseTransform(_ t: String) -> Aff {
        var m = Aff.id
        var rest = Substring(t)
        while let open = rest.firstIndex(of: "("), let close = rest.firstIndex(of: ")") {
            let name = rest[rest.startIndex..<open].trimmingCharacters(in: .whitespaces)
            let v = numbers(rest[rest.index(after: open)..<close])
            var k = Aff.id
            switch name {
            case "translate": k = Aff(tx: v.first ?? 0, ty: v.count > 1 ? v[1] : 0)
            case "scale": let sx = v.first ?? 1; k = Aff(a: sx, d: v.count > 1 ? v[1] : sx)
            case "rotate":
                let r = (v.first ?? 0) * .pi / 180, co = cos(r), si = sin(r)
                let rot = Aff(a: co, b: si, c: -si, d: co)
                if v.count >= 3 { k = Aff(tx: v[1], ty: v[2]).then(rot).then(Aff(tx: -v[1], ty: -v[2])) } else { k = rot }
            default: break
            }
            m = m.then(k)
            rest = rest[rest.index(after: close)...]
        }
        return m
    }

    static func parsePath(_ d: String) -> [PathOp] {
        // del opp i kommandoer og tall
        var toks: [(Character?, Double)] = []
        var cur = ""
        func flush() { if !cur.isEmpty, let v = Double(cur) { toks.append((nil, v)) }; cur = "" }
        for ch in d {
            if ch.isLetter && ch != "e" { flush(); toks.append((ch, 0)) }
            else if ch == "-" { if !cur.isEmpty && !cur.hasSuffix("e") { flush() }; cur.append(ch) }
            else if ch == "." { if cur.contains(".") { flush() }; cur.append(ch) }
            else if ch.isNumber || ch == "e" { cur.append(ch) }
            else { flush() }
        }
        flush()
        var ops: [PathOp] = []
        var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0
        var cmd: Character = "M"
        var i = 0
        func next() -> Double? {
            guard i < toks.count, toks[i].0 == nil else { return nil }
            defer { i += 1 }
            return toks[i].1
        }
        while i < toks.count {
            if let c = toks[i].0 { cmd = c; i += 1 }
            let rel = cmd.isLowercase
            let ox = rel ? x : 0, oy = rel ? y : 0
            switch cmd {
            case "M", "m":
                guard let a = next(), let b = next() else { i += 1; continue }
                x = a + ox; y = b + oy; sx = x; sy = y; ops.append(.move(x, y))
                cmd = rel ? "l" : "L"
            case "L", "l":
                guard let a = next(), let b = next() else { i += 1; continue }
                x = a + ox; y = b + oy; ops.append(.line(x, y))
            case "H", "h":
                guard let a = next() else { i += 1; continue }
                x = a + ox; ops.append(.line(x, y))
            case "V", "v":
                guard let a = next() else { i += 1; continue }
                y = a + oy; ops.append(.line(x, y))
            case "Q", "q":
                guard let a = next(), let b = next(), let c = next(), let e = next() else { i += 1; continue }
                let cx = a + ox, cy = b + oy
                x = c + ox; y = e + oy; ops.append(.quad(cx, cy, x, y))
            case "C", "c":
                guard let a = next(), let b = next(), let c = next(), let e = next(), let f = next(), let g = next() else { i += 1; continue }
                let c1x = a + ox, c1y = b + oy, c2x = c + ox, c2y = e + oy
                x = f + ox; y = g + oy; ops.append(.cubic(c1x, c1y, c2x, c2y, x, y))
            case "Z", "z":
                ops.append(.close); x = sx; y = sy
                if i < toks.count && toks[i].0 == nil { i += 1 }
            default:
                i += 1
            }
        }
        return ops
    }

    /// Fargekode til (r, g, b, a) mellom 0 og 1. nil betyr "none".
    static func color(_ s: String?) -> (Double, Double, Double, Double)? {
        guard var s = s?.trimmingCharacters(in: .whitespaces), s != "none", !s.isEmpty else { return nil }
        if s.hasPrefix("url(") { return nil }
        if s == "white" { s = "#fff" }
        if s == "black" { s = "#000" }
        guard s.hasPrefix("#") else { return (0, 0, 0, 1) }
        var h = String(s.dropFirst())
        if h.count == 3 || h.count == 4 { h = h.map { "\($0)\($0)" }.joined() }
        guard let v = UInt64(h, radix: 16) else { return (0, 0, 0, 1) }
        if h.count == 8 { return (Double((v >> 24) & 255) / 255, Double((v >> 16) & 255) / 255, Double((v >> 8) & 255) / 255, Double(v & 255) / 255) }
        return (Double((v >> 16) & 255) / 255, Double((v >> 8) & 255) / 255, Double(v & 255) / 255, 1)
    }

    /// Uskarphet for filtrene b1 og b2 i tegningene.
    static func blur(_ f: String?) -> Double {
        guard let f = f else { return 0 }
        if f.contains("b1") { return 0.8 }
        if f.contains("b2") { return 2.2 }
        if f.contains("gl") { return 7 }
        return 0
    }
}

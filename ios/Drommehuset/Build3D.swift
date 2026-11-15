import SceneKit
import UIKit

/// Resultat av husbyggingen: hindringer og ting som slås av og på under spillet.
struct Built3D {
    var obs: [[Double]] = []   // [x, z, radius, etasje]
    var foam: SCNNode? = nil
    var water: SCNNode? = nil
    var sky: UIImage? = nil
    var eve = false
    var hemi = 0.8, sun = 0.75
}

enum Build3D {
    static let FR: [Room] = [
        ("#e9cfd0", "parkett", "#8c8f96", "#f4f1ea", "landskap", true, false), ("#e7ddd0", "mork", "#c9a227", "#9b3b47", "abstrakt", true, true),
        ("#cfd9e3", "parkett", "#f4f1ea", "#34507a", "landskap", false, true), ("#8a9a84", "teppe", "#d8c3a5", "none", "abstrakt", true, false),
        ("#f4f1ea", "mork", "#34507a", "#c9a227", "landskap", true, true), ("#e7ddd0", "parkett", "#9b3b47", "#d8c3a5", "abstrakt", false, true),
    ].map { a in Room(wall: a.0, floor: a.1, main: a.2, rug: a.3, art: a.4, items: ["plante": true, "lampe": true, "bord": true, "tv": a.5, "bokhylle": a.6, "gardiner": true]) }

    /// Huset til en venn eller nabo (samme oppskrift som i nettversjonen).
    static func friendHouse(_ i: Int, _ b: House) -> House {
        var r = Rng(Double(i * 97 + 13))
        func pk(_ a: [String]) -> String { a[Int(floor(r.next() * Double(a.count)))] }
        let F: Room
        if i < FR.count { F = FR[i] } else {
            let w = pk(Pal.wallIn), fl = pk(["parkett", "mork", "teppe"]), mn = pk(Pal.furn), rg = pk(Pal.furn), ar = pk(["abstrakt", "landskap"])
            let tv = r.next() < 0.6, bh = r.next() < 0.5
            F = Room(wall: w, floor: fl, main: mn, rug: rg, art: ar, items: ["plante": true, "lampe": true, "bord": true, "tv": tv, "bokhylle": bh, "gardiner": true])
        }
        let Q: [[String]] = [["#e9cfd0", "#c97b84", "#f4f1ea", "#8b2f2a"], ["#e7ddd0", "#c9a227", "#2e3338", "#34507a"], ["#cfd9e3", "#34507a", "#f4f1ea", "#1f1f24"], ["#d7dfd6", "#5d7a5e", "#b9b2a6", "#5d7a5e"], ["#e7ddd0", "#34507a", "#d9c36a", "#1f1f24"], ["#e9cfd0", "#9b3b47", "#56707f", "#f4f1ea"]]
        let q = i < Q.count ? Q[i] : [pk(Pal.wallIn), pk(Pal.furn), pk(Pal.wall), pk(Pal.door)]
        var h = House()
        h.time = b.time; h.wall = q[2]; h.door = q[3]; h.roofColor = "#2b2d31"
        var I = Inne()
        I.stue = F
        I.gang = Room(wall: q[0], floor: F.floor, main: q[1], rug: "#8c8f96", art: "landskap", items: ["knagger": true, "skohylle": true, "speil": true, "kommode": true, "plante": true])
        I.kjokken = Room(wall: "#f4f1ea", floor: "fliser", main: q[1], rug: "none", art: "none", items: ["kjoleskap": true, "spisebord": true, "plante": true, "gardiner": true])
        I.soverom = Room(wall: q[0], floor: F.floor, main: q[1], rug: F.rug, art: F.art, items: ["plante": true, "nattbord": true, "skrivebord": true, "speil": true, "lyslenke": i % 2 == 0, "gardiner": true])
        I.bad = Room(wall: "#cfd9e3", floor: "fliser", main: q[1], rug: "#f4f1ea", art: "none", items: ["speil": true, "handkle": true, "badekar": true, "plante": true])
        h.inne = I
        return h
    }

    /// Bygger hele huset inn i g. away = hos en venn (ingen egne dyr/barn-møbler).
    static func build(_ g: SCNNode, H: House, away: Bool, me: Look, tv: Bool, rain: Bool, act: String?) -> Built3D {
        P3.clear(g)
        var out = Built3D()
        let I = H.inne, eve = H.time == "kveld"
        out.eve = eve
        let wood = "#8a6a4a", wd = "#6b4f36", wh = "#fbfaf7", st = "#c9ced3", dk = "#2b2d31", pw = "#efece6", gold = "#c9a36a"
        func lamp(_ x: Double, _ y: Double, _ z: Double, _ c: String = "#ffd9a0", _ i: Double = 0.9) {
            guard eve else { return }
            let l = SCNLight()
            l.type = .omni
            l.color = uiColor(c)
            l.intensity = CGFloat(i * 1400)
            l.attenuationStartDistance = 0
            l.attenuationEndDistance = 9
            l.attenuationFalloffExponent = 1.6
            let n = SCNNode(); n.light = l; n.position = v3(x, y, z); g.addChildNode(n)
        }
        func win(_ x: Double, _ Y: Double, _ cur: Bool) {
            B(g, x - 0.72, x + 0.72, Y + 1.05, Y + 2.2, -0.02, 0.05, "#f6f4ef"); B(g, x - 0.64, x + 0.64, Y + 1.13, Y + 2.12, 0, 0.07, eve ? "#39446e" : "#a9d3f0", "b")
            B(g, x - 0.03, x + 0.03, Y + 1.13, Y + 2.12, 0.02, 0.09, "#f6f4ef"); B(g, x - 0.64, x + 0.64, Y + 1.6, Y + 1.65, 0.02, 0.09, "#f6f4ef"); B(g, x - 0.8, x + 0.8, Y + 1.0, Y + 1.05, -0.02, 0.16, "#f6f4ef")
            if cur { B(g, x - 1, x - 0.66, Y + 0.9, Y + 2.32, 0.06, 0.14, "#ece5d8"); B(g, x + 0.66, x + 1, Y + 0.9, Y + 2.32, 0.06, 0.14, "#ece5d8"); B(g, x - 1.08, x + 1.08, Y + 2.32, Y + 2.36, 0.08, 0.12, dk) }
        }
        func art(_ x: Double, _ Y: Double, _ k: String) {
            if k == "none" { return }
            B(g, x - 0.5, x + 0.5, Y + 1.5, Y + 2.2, 0, 0.04, dk); B(g, x - 0.45, x + 0.45, Y + 1.55, Y + 2.15, 0.02, 0.06, k == "abstrakt" ? "#f3efe6" : "#cfe0ea")
            if k.hasPrefix("g") {
                var rn = Rng(Double(Int(k.dropFirst()) ?? 7)); if rn.s == 0 { rn = Rng(7) }
                _ = rn.next()
                for i in 0..<4 {
                    let cx = x - 0.3 + rn.next() * 0.6, cy = Y + 1.68 + rn.next() * 0.34, w = 0.06 + rn.next() * 0.1, c = hsl(rn.next() * 360, 55, 52); _ = rn.next()
                    let di = Double(i)
                    B(g, cx - w, cx + w, cy - w * 0.7, cy + w * 0.7, 0.04 + di * 0.004, 0.072 + di * 0.004, c)
                }
                return
            }
            if k == "abstrakt" { B(g, x - 0.3, x - 0.02, Y + 1.7, Y + 2, 0.04, 0.075, "#c9736b"); B(g, x + 0.02, x + 0.3, Y + 1.65, Y + 1.95, 0.04, 0.075, "#34507a"); B(g, x - 0.3, x + 0.3, Y + 1.6, Y + 1.63, 0.04, 0.075, "#c9a227") }
            else { B(g, x - 0.45, x + 0.45, Y + 1.55, Y + 1.8, 0.04, 0.075, "#5d7a5e"); B(g, x - 0.2, x + 0.1, Y + 1.8, Y + 1.95, 0.04, 0.07, "#3f6b52"); B(g, x + 0.2, x + 0.3, Y + 1.95, Y + 2.05, 0.04, 0.07, "#f2d48a") }
        }
        func plant(_ x: Double, _ Y: Double, _ z: Double, _ k: Double = 1) {
            Cy(g, x, Y, Y + 0.3 * k, z, 0.12 * k, "#b9b2a6", 0.16 * k); Cy(g, x, Y + 0.26 * k, Y + 0.3 * k, z, 0.15 * k, "#4a3626")
            for i in 0..<7 {
                let p = RNode(); p.pos(x, Y + 0.3 * k, z); p.rot(0, Double(i) * 0.9, i > 0 ? 0.5 : 0)
                let m = Sp(p, 0, 0.34 * k, 0, 1, i % 2 == 1 ? "#3d6e45" : "#4f8a4a"); m.scale = v3(0.075 * k, 0.34 * k, 0.03 * k)
                g.addChildNode(p)
            }
        }
        func legs(_ x0: Double, _ x1: Double, _ y: [Double], _ z0: Double, _ z1: Double, _ c: String) {
            for q in [[x0, z0], [x1 - 0.05, z0], [x0, z1 - 0.05], [x1 - 0.05, z1 - 0.05]] { B(g, q[0], q[0] + 0.05, y[0], y[1], q[1], q[1] + 0.05, c) }
        }
        func pend(_ x: Double, _ Y: Double, _ z: Double) { Cy(g, x, Y + 2.38, Y + 2.86, z, 0.008, dk); Cy(g, x, Y + 2.14, Y + 2.38, z, 0.22, "#f3efe6", 0.07, eve ? "b" : "") }
        func tree(_ x: Double, _ z: Double, _ k: Double) {
            Cy(g, x, -0.2, 2.4 * k, z, 0.2 * k, "#6b4a35", 0.14 * k); Sp(g, x, 3.3 * k, z, 1.5 * k, "#4f8f52"); Sp(g, x + 0.9 * k, 2.8 * k, z + 0.3, 1 * k, "#458248"); Sp(g, x - 0.8 * k, 2.9 * k, z - 0.2, 1.1 * k, "#5a9a58")
        }
        B(g, -60, 76, -0.4, -0.15, -40, 50, "#6f9f5c"); B(g, -4, 0, -0.16, -0.13, 2.4, 3.8, "#cfcac1"); B(g, -4.6, -3.2, -0.16, -0.13, 3.8, 30, "#cfcac1")
        tree(-5, 0.5, 1); tree(-9, 5, 1.2); tree(20, 1, 1.1); tree(23, 6, 0.9); B(g, -14, -1.2, -0.15, 1, -1.6, -0.8, "#3d6e45"); B(g, 17.2, 30, -0.15, 1, -1.6, -0.8, "#3d6e45")
        let segs: [(String, Double, Double, Double)] = [("gang", 0, 5, 0), ("stue", 5, 11, 0), ("kjokken", 11, 16, 0), ("gang", 0, 5, 3), ("soverom", 5, 11, 3), ("bad", 11, 16, 3)]
        for q in segs {
            let r = I[q.0], Y = q.3, fc = Mat3.floor(r.floor)
            if Y > 0 && q.0 == "gang" { B(g, 0, 0.9, Y - 0.14, Y, 0, 1.5, mat: fc); B(g, 4.4, 5, Y - 0.14, Y, 0, 1.5, mat: fc); B(g, 0, 5, Y - 0.14, Y, 1.5, 5, mat: fc) }
            else { B(g, q.1, q.2, Y - 0.14, Y, 0, 5, mat: fc) }
            B(g, q.1, q.2, Y - 0.14, Y + 2.86, -0.14, 0, r.wall); B(g, q.1 + 0.06, q.2 - 0.06, Y, Y + 0.1, 0, 0.025, wh)
            if !(q.0 == "gang" && Y == 0) { pend((q.1 + q.2) / 2, Y, 3) }
            if r.rug != "none" && q.0 != "gang" { B(g, (q.1 + q.2) / 2 - 1.5, (q.1 + q.2) / 2 + 1.5, Y, Y + 0.02, 2.1, 4.3, mat: Mat3.rug(r.rug)) }
        }
        for Y in [0.0, 3.0] {
            for x in [5.0, 11.0] {
                B(g, x - 0.06, x + 0.06, Y, Y + 2.86, 0, 2.6, pw); B(g, x - 0.06, x + 0.06, Y, Y + 2.86, 4, 5, pw); B(g, x - 0.06, x + 0.06, Y + 2.1, Y + 2.86, 2.6, 4, pw)
                B(g, x - 0.085, x + 0.085, Y, Y + 2.1, 2.56, 2.62, wh); B(g, x - 0.085, x + 0.085, Y, Y + 2.1, 3.98, 4.04, wh); B(g, x - 0.085, x + 0.085, Y + 2.08, Y + 2.15, 2.56, 4.04, wh)
            }
            B(g, -0.14, 0, Y - 0.14, Y + 2.86, -0.14, 5, H.wall); B(g, 16, 16.14, Y - 0.14, Y + 2.86, -0.14, 5, H.wall)
        }
        // tak
        let th = atan2(1.7, 2.9), rl = (1.7 * 1.7 + 2.9 * 2.9).squareRoot()
        let rf = B(g, -0.5, 16.5, -0.07, 0.07, -rl / 2, rl / 2, H.roofColor), rb = B(g, -0.5, 16.5, -0.07, 0.07, -rl / 2, rl / 2, H.roofColor)
        rf.pos(8, 6.85, 3.95); rf.rx = th; rb.pos(8, 6.85, 1.05); rb.rx = -th
        B(g, 12, 12.7, 7, 8.4, 1.4, 2.1, "#8a8480"); B(g, 11.95, 12.75, 8.4, 8.5, 1.35, 2.15, "#55514d")
        for x in [-0.07, 16.07] { g.addChildNode(P3.triangle([v3(x, 5.86, -0.14), v3(x, 5.86, 5), v3(x, 7.5, 2.5)], H.wall)) }
        B(g, 0, 0.05, 0, 2.05, 2.5, 3.7, H.door); B(g, 0.05, 0.07, 0.25, 0.95, 2.65, 3.55, shade(H.door, -0.15)); B(g, 0.05, 0.07, 1.15, 1.85, 2.65, 3.55, shade(H.door, -0.15)); B(g, 0.05, 0.1, 1, 1.1, 3.5, 3.56, "#d9c9a0", "s")
        B(g, 0, 0.09, 0, 2.12, 2.42, 2.5, wh); B(g, 0, 0.09, 0, 2.12, 3.7, 3.78, wh); B(g, 0, 0.09, 2.05, 2.12, 2.42, 3.78, wh)

        // gang og trapp
        let G = I.gang, gc = G.main
        if G.rug != "none" { B(g, 0.2, 1.5, 0, 0.02, 2.5, 3.7, mat: Mat3.rug(G.rug)) }
        for i in 0..<14 {
            let di = Double(i), x1 = 4.4 - di * 0.25
            B(g, x1 - 0.25, x1, 0, (di + 1) * 3 / 14, 0.2, 1.4, i % 2 == 1 ? "#b08a62" : "#a67f58"); B(g, x1 - 0.27, x1, (di + 1) * 3 / 14, (di + 1) * 3 / 14 + 0.025, 0.2, 1.42, "#c9a271")
            if i % 2 == 0 { B(g, x1 - 0.14, x1 - 0.1, (di + 1) * 3 / 14, (di + 1) * 3 / 14 + 0.92, 1.4, 1.44, wd) }
        }
        let ra = B(g, -2.36, 2.36, -0.03, 0.03, -0.03, 0.03, wd); ra.pos(2.6, 2.47, 1.42); ra.rz = -atan2(3, 3.5)
        B(g, 0.9, 4.4, 3.86, 3.93, 1.46, 1.54, wd); B(g, 4.36, 4.44, 3.86, 3.93, 0, 1.5, wd)
        for x in stride(from: 0.9, to: 4.45, by: 0.25) { B(g, x - 0.02, x + 0.02, 3, 3.86, 1.48, 1.52, wd) }
        for z in stride(from: 0.25, to: 1.4, by: 0.25) { B(g, 4.38, 4.42, 3, 3.86, z - 0.02, z + 0.02, wd) }
        if G.has("speil") { B(g, 0, 0.04, 0.5, 2, 1.7, 2.3, gold); B(g, 0.03, 0.06, 0.56, 1.94, 1.76, 2.24, "#cfdde6", "s") }
        if G.has("knagger") { B(g, 0, 0.06, 1.62, 1.68, 3.95, 4.9, wood); B(g, 0.04, 0.16, 0.95, 1.6, 4.05, 4.35, gc); B(g, 0.04, 0.16, 0.85, 1.6, 4.5, 4.8, "#34507a"); for z in [4.2, 4.65] { B(g, 0.04, 0.12, 1.6, 1.66, z - 0.02, z + 0.02, dk) } }
        if G.has("skohylle") { B(g, 0.03, 0.4, 0, 0.4, 3.95, 4.9, wood); B(g, 0.03, 0.4, 0.4, 0.46, 3.95, 4.9, gc); B(g, 0.42, 0.56, 0, 0.08, 4.1, 4.36, wh); B(g, 0.42, 0.56, 0, 0.08, 4.45, 4.71, "#1f1f24") }
        if G.has("kommode") {
            B(g, 4.48, 4.92, 0, 0.8, 4.05, 4.95, wood)
            for y in [0.2, 0.45, 0.68] { B(g, 4.47, 4.48, y - 0.09, y + 0.09, 4.1, 4.9, wd); Sp(g, 4.465, y, 4.5, 0.018, "#d9c9a0") }
            Cy(g, 4.7, 0.8, 0.95, 4.5, 0.03, dk); Cy(g, 4.7, 0.95, 1.15, 4.5, 0.13, "#efe7d6", 0.09, eve ? "b" : ""); lamp(4.5, 1.3, 4.4); out.obs.append([4.7, 4.5, 0.6, 0])
        }
        if G.has("plante") { plant(4.6, 3, 4.5); out.obs.append([4.6, 4.5, 0.45, 1]) }
        art(2.6, 3, G.art)

        // stue
        let S = I.stue, sc = S.main, sd = shade(sc, -0.13), pc = shade(sc, isLightHex(sc) ? -0.3 : 0.4)
        B(g, 5.9, 8.3, 0.1, 0.3, 0.3, 1.2, sd); B(g, 5.94, 7.08, 0.3, 0.48, 0.5, 1.22, sc); B(g, 7.12, 8.26, 0.3, 0.48, 0.5, 1.22, sc); B(g, 5.9, 8.3, 0.3, 0.98, 0.2, 0.5, sd); B(g, 5.94, 7.08, 0.48, 0.92, 0.42, 0.56, sc); B(g, 7.12, 8.26, 0.48, 0.92, 0.42, 0.56, sc)
        B(g, 5.84, 6.08, 0.1, 0.68, 0.2, 1.22, sd); B(g, 8.12, 8.36, 0.1, 0.68, 0.2, 1.22, sd); legs(5.9, 8.3, [0, 0.1], 0.3, 1.18, dk)
        for (i, x) in [6.3, 7.9].enumerated() { let m = B(g, x - 0.2, x + 0.2, 0.5, 0.84, 0.56, 0.68, pc); m.rot(-0.25, 0, i > 0 ? -0.12 : 0.12) }
        if S.has("bord") { B(g, 6.55, 7.65, 0.38, 0.43, 1.34, 1.74, wood); legs(6.6, 7.6, [0, 0.38], 1.38, 1.7, wd); B(g, 6.9, 7.2, 0.43, 0.46, 1.44, 1.64, "#e7ddd0"); B(g, 6.93, 7.17, 0.46, 0.485, 1.46, 1.62, "#9b3b47"); Cy(g, 7.42, 0.43, 0.5, 1.54, 0.06, wh, 0.08) }
        if S.has("lampe") { Cy(g, 5.45, 0, 0.03, 0.6, 0.16, dk); Cy(g, 5.45, 0, 1.5, 0.6, 0.018, dk); Cy(g, 5.45, 1.5, 1.82, 0.6, 0.2, "#efe7d6", 0.13, eve ? "b" : ""); lamp(5.6, 1.9, 1) }
        if S.has("plante") { plant(8.8, 0, 0.6) }
        if !away && me.pet.type != "none" {
            let bc = me.pet.collar != "none" ? me.pet.collar : "#9b3b47"
            let m = P3.torus(0.36, 0.11, Mat3.m(bc)); m.rx = Double.pi / 2; m.pos(10.1, 0.11, 4.15); g.addChildNode(m)
            Cy(g, 10.1, 0, 0.07, 4.15, 0.34, shade(bc, 0.35)); Cy(g, 10.1, 0.07, 0.1, 4.15, 0.3, "#f2ece2"); out.obs.append([10.1, 4.15, 0.5, 0])
        }
        if S.has("tv") {
            let on = !away && tv
            B(g, 9.2, 10.5, 0.08, 0.45, 0.2, 0.65, wood); legs(9.25, 10.45, [0, 0.08], 0.24, 0.6, dk); B(g, 9.84, 9.86, 0.1, 0.43, 0.65, 0.66, wd); B(g, 9.75, 9.95, 0.45, 0.6, 0.3, 0.4, dk); B(g, 9.3, 10.4, 0.6, 1.3, 0.3, 0.35, dk); B(g, 9.33, 10.37, 0.63, 1.27, 0.35, 0.365, on ? "#86aede" : "#20242b", "b")
            if on { let l = SCNLight(); l.type = .omni; l.color = uiColor("#8fb6e6"); l.intensity = 900; l.attenuationEndDistance = 5; let n = SCNNode(); n.light = l; n.position = v3(9.85, 1, 1.2); g.addChildNode(n) }
        }
        if S.has("bokhylle") {
            B(g, 10.62, 10.94, 0, 1.95, 0.3, 2.3, wood)
            let bcs = ["#c9736b", "#34507a", "#e7ddd0", "#5d7a5e", "#c9a227", "#8c8f96"]
            for k in 0..<4 {
                let dk2 = Double(k)
                B(g, 10.6, 10.63, 0.1 + dk2 * 0.46, 0.12 + dk2 * 0.46, 0.32, 2.28, wd)
                for b in 0..<12 { let db = Double(b); B(g, 10.54, 10.63, 0.12 + dk2 * 0.46, 0.12 + dk2 * 0.46 + 0.24 + Double((b * 7) % 4) * 0.03, 0.38 + db * 0.155, 0.38 + db * 0.155 + 0.11, bcs[(b * 5 + k) % 6]) }
            }
        }
        art(7.1, 0, S.art); win(9.85, 0, S.has("gardiner"))

        // kjøkken
        let K = I.kjokken, kc = K.main, kd = shade(kc, -0.16), hd = isLightHex(kc) ? "#55595f" : "#e4e0d8"
        B(g, 11.3, 14.6, 0.1, 0.86, 0.1, 0.7, kc); B(g, 11.3, 14.6, 0, 0.1, 0.1, 0.64, dk)
        for (i, x) in [11.32, 12.84, 13.42, 14.02].enumerated() { let w = i > 0 ? 0.56 : 0.86; B(g, x, x + w, 0.14, 0.82, 0.7, 0.715, kd); B(g, x + w - 0.08, x + w - 0.06, 0.55, 0.72, 0.715, 0.74, hd) }
        B(g, 11.25, 14.65, 0.86, 0.92, 0.05, 0.76, "#ece9e3", "s")
        B(g, 11.3, 14.6, 0.92, 1.5, 0, 0.02, mat: Mat3.tile)
        B(g, 12.2, 12.8, 0, 0.87, 0.1, 0.72, dk); B(g, 12.26, 12.74, 0.2, 0.62, 0.72, 0.735, "#111214", "s"); B(g, 12.26, 12.74, 0.7, 0.73, 0.735, 0.76, st, "s"); B(g, 12.2, 12.8, 0.92, 0.935, 0.1, 0.72, "#17181b", "s")
        Cy(g, 12.5, 0.935, 1.08, 0.4, 0.13, "#8c8f96", nil, "s"); Cy(g, 12.5, 1.08, 1.1, 0.4, 0.14, "#6d747b"); B(g, 12.32, 12.68, 1.02, 1.04, 0.39, 0.41, "#55595f"); Cy(g, 12.36, 0.935, 0.945, 0.58, 0.07, "#33363b"); Cy(g, 12.66, 0.935, 0.945, 0.58, 0.07, "#33363b")
        B(g, 13.35, 14, 0.9, 0.925, 0.2, 0.6, "#9aa0a8", "s"); Cy(g, 13.67, 0.92, 1.2, 0.16, 0.016, "#9aa0a8", nil, "s"); B(g, 13.655, 13.685, 1.18, 1.21, 0.16, 0.32, "#9aa0a8", "s")
        B(g, 11.3, 12.05, 1.5, 2.25, 0.02, 0.4, kc); B(g, 11.32, 11.66, 1.53, 2.22, 0.4, 0.415, kd); B(g, 11.69, 12.03, 1.53, 2.22, 0.4, 0.415, kd); B(g, 12.2, 12.8, 1.75, 1.95, 0.05, 0.55, st, "s"); B(g, 12.4, 12.6, 1.95, 2.86, 0.1, 0.3, st, "s")
        if K.has("kjoleskap") { B(g, 14.8, 15.6, 0, 1.9, 0.1, 0.8, st, "s"); B(g, 14.8, 15.6, 1.18, 1.2, 0.8, 0.805, "#8c8f96"); B(g, 14.86, 14.89, 1.3, 1.75, 0.8, 0.84, "#7d848c", "s"); B(g, 14.86, 14.89, 0.4, 1.05, 0.8, 0.84, "#7d848c", "s") }
        if K.has("plante") { plant(11.6, 0.92, 0.4, 0.42) }
        if K.has("spisebord") {
            B(g, 13.4, 15, 0.7, 0.76, 3.95, 4.75, wood); legs(13.45, 14.95, [0, 0.7], 4, 4.7, wd)
            for x in [13.05, 15.0] { B(g, x, x + 0.4, 0.42, 0.46, 4.15, 4.55, dk); B(g, x < 14 ? x : x + 0.36, x < 14 ? x + 0.04 : x + 0.4, 0.46, 0.95, 4.15, 4.55, dk); legs(x, x + 0.4, [0, 0.42], 4.15, 4.55, dk) }
            Cy(g, 14.2, 0.76, 0.8, 4.35, 0.16, wh, 0.2); Sp(g, 14.14, 0.85, 4.36, 0.055, "#c4313f"); Sp(g, 14.26, 0.85, 4.32, 0.055, "#c9a227"); Sp(g, 14.2, 0.85, 4.43, 0.055, "#5d9a52"); out.obs.append([14.2, 4.35, 1.05, 0])
        }
        win(13.7, 0, K.has("gardiner"))

        // soverom
        let So = I.soverom, bc = So.main
        B(g, 6.9, 9, 3.12, 3.3, 0.2, 1.55, wd); legs(6.9, 9, [3, 3.12], 0.22, 1.53, dk); B(g, 6.95, 8.95, 3.3, 3.48, 0.25, 1.5, wh); B(g, 7.62, 8.97, 3.46, 3.56, 0.22, 1.54, bc); B(g, 7.5, 7.66, 3.47, 3.58, 0.22, 1.54, shade(bc, isLightHex(bc) ? -0.1 : 0.3))
        for z in [0.3, 0.92] { let m = B(g, 7.0, 7.44, 3.48, 3.6, z, z + 0.54, wh); m.rz = 0.08 }
        B(g, 6.8, 6.92, 3, 4, 0.2, 1.55, wood)
        if So.has("nattbord") { B(g, 9.2, 9.7, 3.06, 3.5, 0.2, 0.65, wood); legs(9.2, 9.7, [3, 3.06], 0.22, 0.63, dk); B(g, 9.24, 9.66, 3.3, 3.46, 0.65, 0.66, wd); Sp(g, 9.45, 3.38, 0.67, 0.018, "#d9c9a0"); Cy(g, 9.45, 3.5, 3.66, 0.42, 0.02, dk); Cy(g, 9.45, 3.66, 3.86, 0.42, 0.13, "#efe7d6", 0.09, eve ? "b" : ""); lamp(9.45, 4, 0.8) }
        B(g, 5.2, 6.3, 3, 5.1, 0.05, 0.62, wood); B(g, 5.22, 5.74, 3.04, 5.06, 0.62, 0.635, wd); B(g, 5.76, 6.28, 3.04, 5.06, 0.62, 0.635, wd); B(g, 5.7, 5.72, 3.9, 4.2, 0.635, 0.66, "#d9c9a0", "s"); B(g, 5.78, 5.8, 3.9, 4.2, 0.635, 0.66, "#d9c9a0", "s")
        if So.has("skrivebord") { B(g, 9.78, 10.84, 3.7, 3.75, 0.15, 0.75, wood); legs(9.82, 10.8, [3, 3.7], 0.2, 0.7, wd); B(g, 10.1, 10.5, 3.75, 3.77, 0.3, 0.58, "#8c8f96", "s"); B(g, 10.1, 10.5, 3.77, 4.02, 0.28, 0.3, "#8c8f96"); B(g, 10.12, 10.48, 3.79, 4, 0.3, 0.305, "#cfd9e3", "b"); Cy(g, 10.68, 3.75, 3.87, 0.35, 0.04, "#c9736b"); B(g, 10.1, 10.5, 3.42, 3.46, 0.85, 1.2, dk); legs(10.1, 10.5, [3, 3.42], 0.85, 1.2, dk) }
        if So.has("speil") { B(g, 10.9, 10.94, 3.2, 4.9, 0.4, 1.1, gold); B(g, 10.87, 10.9, 3.26, 4.84, 0.46, 1.04, "#cfdde6", "s") }
        if So.has("lyslenke") { for x in stride(from: 5.3, to: 10.75, by: 0.3) { Sp(g, x, 5.55 - 0.18 * sin((x - 5.3) / 5.4 * Double.pi), 0.06, 0.035, eve ? "#fff3c4" : "#ffe9a8", "b") } }
        if So.has("plante") { plant(6.62, 3, 0.5, 0.9) }
        if !away && me.kid.age > 0 {
            B(g, 7.15, 9.05, 3, 3.28, 3.85, 4.6, wood); legs(7.15, 9.05, [3, 3.1], 3.87, 4.58, wd); B(g, 7.2, 9.0, 3.28, 3.42, 3.9, 4.55, wh); B(g, 7.75, 9.02, 3.4, 3.5, 3.88, 4.57, "#5d9a52"); B(g, 7.62, 7.78, 3.41, 3.51, 3.88, 4.57, "#4a8243"); B(g, 7.25, 7.6, 3.42, 3.52, 3.98, 4.47, wh); B(g, 7.05, 7.15, 3, 3.85, 3.85, 4.6, wood); B(g, 9.05, 9.15, 3, 3.6, 3.85, 4.6, wood)
            out.obs.append([7.65, 4.25, 0.5, 1]); out.obs.append([8.55, 4.25, 0.5, 1])
        }
        if !away && me.kid.age == 0 {
            let kdd = me.kid
            B(g, 9.85, 10.65, 3.3, 3.38, 1.95, 2.65, wh); legs(9.85, 10.65, [3, 3.3], 1.95, 2.65, wood); B(g, 9.85, 10.65, 3.36, 3.4, 1.95, 2.65, "#f6f4ef")
            for x in stride(from: 9.85, to: 10.66, by: 0.1) { B(g, x - 0.012, x + 0.012, 3.38, 3.72, 1.95, 1.975, wood); B(g, x - 0.012, x + 0.012, 3.38, 3.72, 2.625, 2.65, wood) }
            for z in [1.95, 2.63] { B(g, 9.84, 10.66, 3.72, 3.75, z, z + 0.025, wood) }
            for x in [9.84, 10.64] { B(g, x, x + 0.02, 3.38, 3.75, 1.95, 2.65, wood) }
            let top = !kdd.look.topColor.isEmpty ? kdd.look.topColor : (kdd.girl ? "#e9cfd0" : "#cfd9e3")
            let bb = Sp(g, 10.25, 3.46, 2.24, 1, top); bb.scale = v3(0.1, 0.07, 0.17)
            Sp(g, 10.25, 3.5, 2.46, 0.068, me.skin); let hh = Sp(g, 10.25, 3.53, 2.44, 1, me.hairColor); hh.scale = v3(0.066, 0.045, 0.06); out.obs.append([10.25, 2.3, 0.62, 1])
        }
        art(8, 3, So.art); win(9.95, 3, So.has("gardiner"))

        // bad
        let Ba = I.bad, ac = Ba.main
        B(g, 11.06, 16, 3, 4.3, 0, 0.02, mat: Mat3.tile); B(g, 11.15, 12.35, 3, 3.06, 0.1, 1.3, wh); B(g, 11.15, 12.35, 3.06, 5, 1.28, 1.3, "#bfe0ec", "g"); B(g, 12.33, 12.35, 3.06, 5, 0.1, 1.3, "#bfe0ec", "g"); B(g, 12.31, 12.37, 3.06, 5, 1.27, 1.31, st, "s")
        Cy(g, 11.3, 3.06, 5.1, 0.2, 0.02, "#9aa0a8", nil, "s"); B(g, 11.3, 11.6, 5.08, 5.12, 0.18, 0.22, "#9aa0a8", "s"); Cy(g, 11.6, 5, 5.08, 0.2, 0.09, "#9aa0a8", nil, "s")
        B(g, 12.8, 13.3, 3.42, 3.9, 0.06, 0.28, wh, "s"); Cy(g, 13.05, 3, 3.42, 0.55, 0.2, wh, 0.22, "s"); Cy(g, 13.05, 3.42, 3.45, 0.55, 0.23, wh, nil, "s")
        B(g, 13.7, 14.7, 3.1, 3.8, 0.08, 0.6, ac); B(g, 13.72, 14.19, 3.14, 3.76, 0.6, 0.615, shade(ac, -0.14)); B(g, 14.21, 14.68, 3.14, 3.76, 0.6, 0.615, shade(ac, -0.14)); B(g, 13.65, 14.75, 3.8, 3.86, 0.05, 0.65, wh, "s"); Cy(g, 14.2, 3.8, 3.865, 0.35, 0.2, "#dfe6ea", 0.24, "s"); Cy(g, 14.2, 3.86, 4.05, 0.14, 0.015, "#9aa0a8", nil, "s")
        if Ba.has("speil") { B(g, 13.8, 14.6, 4.2, 5, 0, 0.04, gold); B(g, 13.85, 14.55, 4.25, 4.95, 0.02, 0.06, "#cfdde6", "s") }
        if Ba.has("handkle") { B(g, 15, 15.8, 4.4, 4.43, 0.04, 0.08, "#9aa0a8", "s"); B(g, 15.05, 15.35, 3.85, 4.42, 0.05, 0.1, ac); B(g, 15.45, 15.75, 3.98, 4.42, 0.05, 0.1, shade(ac, 0.4)) }
        if Ba.has("badekar") {
            B(g, 14.95, 15.85, 3.06, 3.55, 0.15, 1.6, wh, "s"); legs(14.98, 15.82, [3, 3.06], 0.18, 1.57, gold); B(g, 15.03, 15.77, 3.5, 3.56, 0.23, 1.52, "#cfe3ec", "s")
            let foam = SCNNode()
            for i in 0..<14 { Sp(foam, 15.1 + Double((i * 37) % 60) / 100, 3.57, 0.3 + Double((i * 53) % 115) / 100, 0.05 + Double(i % 3) * 0.02, "#ffffff") }
            foam.isHidden = act != "bath"; g.addChildNode(foam); out.foam = foam
        }
        if Ba.has("plante") { plant(12.58, 3, 0.45, 0.7) }
        let water = SCNNode()
        for i in 0..<28 { Cy(water, 11.42 + Double((i * 37) % 62) / 100, 0, 0.14, 0.38 + Double((i * 53) % 62) / 100, 0.005, "#bfe6f7", nil, "b") }
        water.isHidden = act != "shower"; g.addChildNode(water); out.water = water
        if eve { lamp(8, 2.3, 3.4, "#ffe2b8", 0.45); lamp(8, 5.3, 3.4, "#ffe2b8", 0.45) }
        let sk = rain ? ["#7d8794", "#bcc3ca"] : eve ? ["#161c3c", "#c98672"] : ["#7fb8e8", "#dcecf7"]
        out.sky = Mat3.sky(sk[0], sk[1])
        out.hemi = eve ? 0.32 : 0.8
        out.sun = eve ? 0.06 : rain ? 0.35 : 0.75
        return out
    }
}

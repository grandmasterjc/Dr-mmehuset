import SceneKit
import UIKit

/// Leddene til en 3D-figur, som rig i nettversjonen.
final class Rig {
    var bd = RNode(), tr = RNode()
    var hip: [RNode] = [], knee: [RNode] = [], foot: [RNode] = [], arm: [RNode] = [], elbow: [RNode] = []
    var ty = 1.0
}

final class PetRig {
    var legs: [RNode] = []
    var tail: RNode? = nil
    var type = ""
    var hd = RNode()
}

enum Figure3D {
    /// Bygger en person. towel = badetøy (dusj/bad).
    @MainActor
    static func build(_ g: SCNNode, s s0: Look, f: Feat, child: Bool, towel: Bool = false) -> Rig {
        P3.clear(g)
        g.scale = v3(1, 1, 1)
        let boy = f.bx >= 1.1
        var s = s0
        if towel {
            s.dress = "none"; s.top = boy ? "ingen" : "singlet"; s.topColor = "#2f7fb8"; s.bottom = boy ? "shorts" : "badebunn"; s.bottomColor = "#2f7fb8"
            s.outer = "none"; s.shoes = "barfot"; s.acc.veske = false; s.acc.solbriller = false
        }
        let sk = s.skin, bw = f.bx
        let rig = Rig()
        let bd = P3.grp(g, 0, 0), tr = P3.grp(bd, 0, 1.0), ti = P3.grp(tr, 0, -1.0)
        rig.bd = bd; rig.tr = tr
        let dress = s.dress != "none", pants = !dress && (s.bottom == "jeans" || s.bottom == "vide"), shorts = !dress && s.bottom == "shorts", wide = pants && s.bottom == "vide"
        let jacket = s.outer != "none", long = jacket || (!dress && (s.top.contains("genser") || s.top.contains("skjorte")))
        let bare = !jacket && (dress ? s.dress != "enkel" : s.top == "singlet" || s.top == "ingen"), big = !dress && s.top.contains("genser")
        let ic = dress ? s.dressColor : s.topColor, tc = jacket ? s.outerColor : ic, lc = pants ? s.bottomColor : sk, sc = s.shoeColor
        for d in [-1.0, 1.0] {
            let hp = P3.grp(bd, d * 0.088, 0.88)
            Cy(hp, 0, -0.42, 0, 0, wide ? 0.092 : 0.064, lc, wide ? 0.098 : 0.09)
            if shorts { Cy(hp, 0, -0.17, 0.02, 0, 0.096, s.bottomColor, 0.1) }
            let kn = P3.grp(hp, 0, -0.42)
            Sp(kn, 0, 0, 0, wide ? 0.092 : 0.064, lc); Cy(kn, 0, -0.4, 0, 0, wide ? 0.1 : 0.042, lc, wide ? 0.092 : 0.062)
            if !wide { let cf = Sp(kn, 0, -0.15, -0.012, 1, lc); cf.scale = v3(0.06, 0.13, 0.064) }
            if s.shoes == "boots" { Cy(kn, 0, -0.4, -0.13, 0, 0.058, sc, 0.07) }
            let ft = P3.grp(kn, 0, -0.4)
            if s.shoes == "barfot" { let m = Sp(ft, 0, -0.03, 0.045, 1, sk); m.scale = v3(0.045, 0.03, 0.1) }
            else if s.shoes == "haeler" { let m = Sp(ft, 0, -0.025, 0.055, 1, sc); m.scale = v3(0.045, 0.03, 0.11); m.rx = 0.3; Cy(ft, 0, -0.06, -0.005, -0.04, 0.011, sc) }
            else if s.shoes == "ballerina" { let m = Sp(ft, 0, -0.035, 0.05, 1, sc); m.scale = v3(0.05, 0.03, 0.118); Sp(ft, 0, 0, 0, 0.042, sk) }
            else {
                let m = Sp(ft, 0, -0.018, 0.045, 1, sc); m.scale = v3(0.058, 0.052, 0.125); B(ft, -0.056, 0.056, -0.06, -0.036, -0.075, 0.168, s.shoes == "boots" ? shade(sc, -0.35) : "#f2f0ec")
                if s.shoes == "sneakers" {
                    for z in [0.02, 0.05, 0.08] { B(ft, -0.03, 0.03, 0.012 - z * 0.25, 0.02 - z * 0.25, z, z + 0.012, "#fbfaf7") }
                    let tcap = Sp(ft, 0, -0.02, 0.135, 1, "#f2f0ec"); tcap.scale = v3(0.05, 0.03, 0.04)
                }
            }
            rig.hip.append(hp); rig.knee.append(kn); rig.foot.append(ft)
        }
        if dress {
            let q: [Double] = ["enkel": [0.5, 0.25], "sommer": [0.62, 0.4], "galla": [0.98, 0.42], "handkle": [0.36, 0.22]][s.dress] ?? [0.5, 0.25]
            P3.lathe(bd, [(q[1], 1.03 - q[0]), (q[1] * 0.62, 1.03 - q[0] * 0.55), (0.2, 0.9), (0.172, 0.97), (0.15, 1.03)], s.dressColor, bw, 0.8)
        } else if s.bottom == "badebunn" {
            P3.lathe(bd, [(0.12, 0.84), (0.165, 0.9), (0.17, 0.97), (0.15, 1.035)], s.bottomColor, bw, 0.66)
        } else if pants || shorts {
            P3.lathe(bd, [(0.1, 0.76), (0.176, 0.83), (0.186, 0.92), (0.166, 1.0), (0.15, 1.035)], s.bottomColor, bw, 0.66)
            if s.bottom == "jeans" || shorts {
                let b = Cy(bd, 0, 1.0, 1.03, 0, 0.156 * bw, "#3a2a20"); b.scale = v3(1, 1, 0.7)
                B(bd, -0.018, 0.018, 1.002, 1.028, 0.1, 0.112, "#d4a843", "s")
                for d in [-1.0, 1.0] { B(bd, d * 0.1 - 0.035, d * 0.1 + 0.035, 0.9, 0.97, -0.118, -0.108, shade(s.bottomColor, -0.15)) }
            }
        } else {
            let hh = s.bottom == "midi" ? 0.72 : 0.36, R = s.bottom == "midi" ? 0.37 : 0.3
            P3.lathe(bd, [(R, 1.03 - hh), (R * 0.75, 1.03 - hh * 0.5), (0.172, 0.97), (0.15, 1.03)], s.bottomColor, bw, 0.8)
        }
        P3.lathe(ti, [(0.142, 1.0), (0.128, 1.12), (0.165, 1.3), (0.176, 1.4), (0.06, 1.47)], sk, bw, 0.6)
        let k = big ? 1.07 : 1
        let gp: [(Double, Double)] = bare ? [(0.16, 0.97), (0.143, 1.12), (0.18, 1.3), (0.178, 1.375)] : [(0.16 * k, big ? 0.93 : 0.97), (0.143 * k, 1.12), (0.18 * k, 1.3), (0.19 * k, 1.41), (0.066, 1.478)]
        if s.top != "ingen" { P3.lathe(ti, gp, ic, bw, 0.62) }
        if bare && s.top != "ingen" && s.dress != "galla" && s.dress != "handkle" { for d in [-1.0, 1.0] { B(ti, d * 0.09 * bw - 0.012, d * 0.09 * bw + 0.012, 1.36, 1.468, -0.09, 0.09, ic) } }
        if jacket {
            P3.lathe(ti, [(0.172, s.outer == "blazer" ? 0.9 : 0.99), (0.156, 1.12), (0.193, 1.3), (0.203, 1.41), (0.075, 1.482)], tc, bw, 0.63)
            B(ti, -0.05, 0.05, 1.0, 1.45, 0.09, 0.134, ic)
            for d in [-1.0, 1.0] { let m = B(ti, d * 0.07 - 0.028, d * 0.07 + 0.028, 1.2, 1.45, 0.118, 0.134, shade(tc, -0.18)); m.rz = d * 0.16 }
            if s.outer == "dongeri" { for y in [1.08, 1.2, 1.32] { Sp(ti, 0.058, y, 0.132, 0.009, "#c9a36a", "s") } }
        } else if !dress && s.top == "skjorte" {
            B(ti, -0.012, 0.012, 1.0, 1.45, 0.1, 0.121, shade(ic, -0.06))
            for y in [1.05, 1.13, 1.21, 1.29, 1.37] { Sp(ti, 0, y, 0.122, 0.008, shade(ic, -0.35)) }
            for d in [-1.0, 1.0] { let m = B(ti, d * 0.04 - 0.03, d * 0.04 + 0.03, 1.44, 1.5, 0.03, 0.075, ic); m.rz = d * -0.5 }
        } else if !dress && s.top == "hettegenser" {
            let m = Sp(ti, 0, 1.47, -0.09, 1, ic); m.scale = v3(0.12, 0.09, 0.075); B(ti, -0.1, 0.1, 1.02, 1.13, 0.1, 0.128, shade(ic, -0.08))
            for d in [-1.0, 1.0] { Cy(ti, d * 0.03, 1.3, 1.44, 0.125, 0.004, "#f2f0ec") }
        }
        if s.acc.halskjede || s.acc.smykker {
            let m = P3.torus(0.062, 0.004, Mat3.m(s.acc.smykker ? "#d4a843" : "#c9ccd1", "s")); m.rx = 1.2; m.pos(0, 1.455, 0.03); ti.addChildNode(m)
        }
        Cy(ti, 0, 1.455, 1.56, 0, 0.05, sk, 0.044)
        for (i, d) in [-1.0, 1.0].enumerated() {
            let ar = P3.grp(ti, d * (0.19 * bw + 0.014), 1.415)
            Sp(ar, 0, 0, 0, big ? 0.066 : 0.054, bare ? sk : tc); Cy(ar, 0, -0.27, 0, 0, big ? 0.05 : 0.04, long ? tc : sk, big ? 0.062 : 0.052)
            if !long && !bare { Cy(ar, 0, -0.13, 0.012, 0, 0.057, tc, 0.063) }
            let el = P3.grp(ar, 0, -0.27)
            Sp(el, 0, 0, 0, big ? 0.05 : 0.04, long ? tc : sk); Cy(el, 0, -0.25, 0, 0, big ? 0.042 : 0.03, long ? tc : sk, big ? 0.05 : 0.04)
            if long { Cy(el, 0, -0.25, -0.215, 0, big ? 0.044 : 0.034, shade(tc, -0.12)) }
            let hn = Sp(el, 0, -0.3, 0, 1, sk); hn.scale = v3(0.028, 0.052, 0.02); Sp(el, -d * 0.02, -0.275, 0.014, 0.012, sk)
            if i == 1 && s.acc.veske {
                B(el, -0.035, 0.035, -0.6, -0.37, -0.14, 0.14, "#7a4b33"); B(el, -0.036, 0.036, -0.47, -0.44, -0.142, 0.142, "#4a2f22")
                B(el, -0.004, 0.004, -0.37, -0.3, -0.1, -0.09, "#4a2f22"); B(el, -0.004, 0.004, -0.37, -0.3, 0.09, 0.1, "#4a2f22")
            }
            rig.arm.append(ar); rig.elbow.append(el)
        }
        let n0 = ti.childNodes.count
        let hd = P3.grp(ti, 0, 1.64)
        Sp(hd, 0, 0, 0, 0.13, sk); let jw = Sp(hd, 0, -0.045, 0.01, 1, sk); jw.scale = v3(0.108, 0.1, 0.112)
        let fmat = SCNMaterial()
        fmat.lightingModel = .physicallyBased
        fmat.roughness.contents = 0.8
        fmat.diffuse.contents = FaceTex.image(Figure(s: s, f: f, child: child).face(), skin: sk) ?? uiColor(sk)
        let fm = P3.spherePart(0.1315, 24, 18, Double.pi / 2 - 0.79, 1.58, 1.168, 1.462, fmat)
        hd.addChildNode(fm)
        let ns = Sp(hd, 0, -0.02, 0.128, 1, sk); ns.scale = v3(0.012, 0.02, 0.014)
        for d in [-1.0, 1.0] {
            let e = Sp(hd, d * 0.128, -0.005, 0, 1, sk); e.scale = v3(0.02, 0.035, 0.022)
            if s.acc.oredobber { Sp(hd, d * 0.132, -0.035, 0.004, 0.01, "#f6f2ea", "s") }
            if s.acc.smykker { let m = P3.torus(0.022, 0.003, Mat3.m("#d4a843", "s")); m.pos(d * 0.134, -0.05, 0.004); m.ry = Double.pi / 2; hd.addChildNode(m) }
        }
        hd.scale = v3(1, 1.18, 1)
        let hc = s.hairColor, h = s.hair, hl = shade(hc, 0.12)
        let cap = Sp(ti, 0, 1.7, -0.05, h == "kroller" ? 0.19 : 0.15, hc); cap.scale = v3(1.02, 1.08, 1)
        func cur(_ bot: Double, _ w: Double = 0.046) { for d in [-1.0, 1.0] { let m = Sp(ti, d * 0.118, (1.775 + bot) / 2, 0.028, 1, hc); m.scale = v3(w, (1.775 - bot) / 2, 0.082); m.rz = d * 0.05 } }
        func back(_ bot: Double, _ r: Double) { let b = Cy(ti, 0, bot, 1.72, -0.11, r, hc, 0.146); b.scale = v3(1, 1, 0.5) }
        if h == "langt" || h == "pannelugg" { back(1.12, 0.14); cur(1.16) }
        if h == "bolgete" {
            back(1.1, 0.175); cur(1.2, 0.056)
            for d in [-1.0, 1.0] { for (i, q) in [[0.152, 1.54], [0.136, 1.42], [0.158, 1.3], [0.142, 1.18]].enumerated() { Sp(ti, d * q[0], q[1], -0.005, 0.064, i % 2 == 1 ? hl : hc) } }
        }
        if h == "lob" { back(1.4, 0.156); cur(1.42, 0.052) }
        if h == "pannelugg" { let m = B(ti, -0.105, 0.105, 1.71, 1.775, 0.06, 0.135, hc); m.rx = 0.22 }
        if h == "hestehale" { let m = Cy(ti, 0, 1.3, 1.74, -0.22, 0.028, hc, 0.055); m.rx = -0.28; Sp(ti, 0, 1.78, -0.16, 0.048, hc); Cy(ti, 0, 1.75, 1.78, -0.17, 0.052, "#a8455f") }
        if h == "knute" { Sp(ti, 0, 1.88, -0.05, 0.078, hc); Sp(ti, 0, 1.82, -0.05, 0.05, hl) }
        if h == "fletter" { cur(1.52); for d in [-1.0, 1.0] { for i in 0..<7 { Sp(ti, d * 0.13, 1.56 - Double(i) * 0.062, 0.035, 0.036, i % 2 == 1 ? hl : hc) } } }
        if h == "kroller" { for d in [-1.0, 1.0] { Sp(ti, d * 0.14, 1.5, -0.04, 0.12, hc); Sp(ti, d * 0.1, 1.84, -0.03, 0.1, hc); Sp(ti, d * 0.17, 1.68, 0, 0.08, hl) } }
        if h == "kort" { let m = B(ti, -0.12, 0.12, 1.735, 1.79, 0.03, 0.12, hc); m.rx = 0.3 }
        if s.acc.lue { let m = Sp(ti, 0, 1.74, -0.02, 1, "#9b3b47"); m.scale = v3(0.156, 0.12, 0.16); Cy(ti, 0, 1.7, 1.745, -0.02, 0.158, "#7d2e39"); Sp(ti, 0, 1.87, -0.02, 0.04, "#c97b84") }
        if s.acc.solbriller { B(ti, -0.1, 0.1, 1.635, 1.675, 0.122, 0.14, "#161418", "s"); for d in [-1.0, 1.0] { B(ti, d * 0.1 - 0.004, d * 0.1 + 0.004, 1.65, 1.66, 0, 0.13, "#161418") } }
        rig.ty = 1
        if child {
            // barn: større hode, kortere ben
            let pv = RNode(); pv.pos(0, 1.6, 0)
            let moved = Array(ti.childNodes[n0...])
            ti.addChildNode(pv)
            for c in moved {
                let t = pv.convertTransform(c.transform, from: ti)
                c.removeFromParentNode(); c.transform = t; pv.addChildNode(c)
            }
            pv.scale = v3(1.3, 1.3, 1.3)
            let d = 0.82 * (1 - 0.75)
            for c in bd.childNodes { c.position.y -= Float(d) }
            for hp in rig.hip { hp.scale = v3(1, 0.75, 1) }
            rig.ty = 1 - d
        }
        g.scale = v3(f.h, f.h, f.h)
        return rig
    }

    static func buildPet(_ g: SCNNode, _ pt: Pet) -> PetRig? {
        P3.clear(g)
        if pt.type == "none" { return nil }
        let c = pt.color, d = shade(c, -0.22), l = shade(c, 0.3), t = pt.type, kan = t == "kanin", hund = t == "hund"
        let b = Sp(g, 0, 0.2, 0, 1, c); b.scale = v3(0.1, kan ? 0.11 : 0.095, kan ? 0.15 : 0.2)
        let ch = Sp(g, 0, 0.19, 0.1, 1, l); ch.scale = v3(0.07, 0.07, 0.08)
        let hd = P3.grp(g, 0, kan ? 0.3 : 0.31, kan ? 0.13 : 0.2)
        Sp(hd, 0, 0, 0, 0.082, c)
        for q in [-1.0, 1.0] { Sp(hd, q * 0.035, 0.018, 0.068, 0.013, "#1d1020"); Sp(hd, q * 0.037, 0.022, 0.078, 0.004, "#ffffff", "b") }
        if hund {
            let sn = Sp(hd, 0, -0.022, 0.075, 1, l); sn.scale = v3(0.045, 0.035, 0.055); Sp(hd, 0, -0.008, 0.128, 0.014, "#1d1020")
            for q in [-1.0, 1.0] { let e = Sp(hd, q * 0.082, -0.015, 0, 1, d); e.scale = v3(0.02, 0.06, 0.038) }
        } else if kan {
            Sp(hd, 0, -0.01, 0.082, 0.01, "#d98a8f")
            for q in [-1.0, 1.0] {
                let e = Sp(hd, q * 0.032, 0.13, -0.012, 1, c); e.scale = v3(0.018, 0.085, 0.012); e.rz = q * -0.12
                let i = Sp(hd, q * 0.032, 0.13, -0.002, 1, "#e9b8bd"); i.scale = v3(0.009, 0.065, 0.006); i.rz = q * -0.12
            }
            Sp(g, 0, 0.2, -0.15, 0.038, "#fbfaf7")
        } else {
            Sp(hd, 0, -0.012, 0.082, 0.01, "#d98a8f")
            for q in [-1.0, 1.0] { let e = Cy(hd, q * 0.048, 0.055, 0.125, 0, 0.03, c, 0); e.rz = q * -0.2 }
        }
        let rig = PetRig()
        for q in [[-1.0, 1.0], [1, 1], [-1, -1], [1, -1]] {
            let L = P3.grp(g, q[0] * 0.055, 0.13, q[1] * 0.11)
            Cy(L, 0, -0.12, 0, 0, 0.02, c, 0.026); Sp(L, 0, -0.12, 0.008, 0.024, l)
            rig.legs.append(L)
        }
        if !kan {
            let tail = P3.grp(g, 0, 0.24, -0.18)
            Cy(tail, 0, 0, hund ? 0.16 : 0.24, 0, hund ? 0.02 : 0.014, c, hund ? 0.012 : 0.016)
            tail.rx = hund ? -0.5 : -0.9
            rig.tail = tail
        }
        if pt.collar != "none" || pt.leash {
            let m = P3.torus(kan ? 0.062 : 0.07, 0.012, Mat3.m(pt.collar != "none" ? pt.collar : "#9b3b47")); m.rx = 1.15; m.pos(0, kan ? 0.25 : 0.27, kan ? 0.09 : 0.13); g.addChildNode(m)
            Sp(g, 0, kan ? 0.2 : 0.215, kan ? 0.13 : 0.18, 0.014, "#d4a843", "s")
        }
        rig.type = t; rig.hd = hd
        let sc = hund ? 1.3 : kan ? 0.8 : 0.95
        g.scale = v3(sc, sc, sc)
        return rig
    }

    /// Gange: samme bevegelser som poseRig i nettversjonen.
    static func pose(_ R: Rig, _ a: Double, _ p: Double, _ climb: Bool, _ now: Double) {
        let cl = climb ? 1.4 : 1, idle = sin(now / 700)
        for i in 0..<2 {
            let q = p + Double(i) * Double.pi, sn = sin(q), cs = cos(q), sd = i == 1 ? 1.0 : -1.0
            R.hip[i].rx = -0.52 * a * sn - (climb ? 0.3 * a * max(0, cs) : 0)
            R.knee[i].rx = a * (0.1 + 0.9 * cl * max(0, cs))
            R.foot[i].rx = a * (0.28 * max(0, sn) - 0.3 * max(0, -sn) * max(0, cs))
            R.arm[i].rot(0.48 * a * sn, 0, sd * (0.07 + 0.012 * idle))
            R.elbow[i].rx = -(0.1 + a * (0.28 + 0.3 * max(0, -sn)))
        }
        R.bd.py = a * (0.02 * cos(2 * p) - 0.018); R.bd.px = a * 0.014 * sin(p); R.bd.rz = a * 0.025 * sin(p)
        R.tr.rot(0.05 * a, -0.13 * a * sin(p), 0); R.tr.py = R.ty + 0.004 * idle
    }

    /// Alle ledd på en gang (sitte, ligge osv.).
    static func all(_ R: Rig, _ hp: Double, _ kn: Double, _ ft: Double, _ ar: Double, _ el: Double) {
        for i in 0..<2 {
            R.hip[i].rx = hp; R.knee[i].rx = kn; R.foot[i].rx = ft
            R.arm[i].rot(ar, 0, (i == 1 ? 1 : -1) * 0.07); R.elbow[i].rx = el
        }
    }
}

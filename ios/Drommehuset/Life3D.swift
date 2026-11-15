import SceneKit
import UIKit

/// En som kan gå rundt: deg, vennen eller barnet.
final class Body {
    var x: Double, y: Double, z: Double
    init(_ x: Double, _ y: Double, _ z: Double) { self.x = x; self.y = y; self.z = z }
}

struct Seat { var x: Double, y: Double, z: Double, r: Double }

final class Host {
    var f = 0
    let b: Body
    var ry = -Double.pi / 2, amp = 0.0, ph = 0.0
    var path: [(Double, Double)]? = nil
    var after: (() -> Void)? = nil
    var act: String? = nil
    var mode = "follow"
    var idle = -4.0, rp = 0.0, stuck = 0.0, sayT = 0.0, st = 0.0, t = 0.0
    var sayTxt = ""
    var lastP = (0.0, 0.0)
    var waitT = false
    var seat: Seat? = nil
    var climb = false
    init(f: Int) { self.f = f; b = Body(8, 0, 3.4) }
}

final class PetAct {
    var k: String, ph = 0, t = 0.0
    var fx: Double, fz: Double, bx: Double, bz: Double, y: Double
    var sx = 0.0, sz = 0.0
    init(k: String, fx: Double, fz: Double, bx: Double, bz: Double, y: Double) { self.k = k; self.fx = fx; self.fz = fz; self.bx = bx; self.bz = bz; self.y = y }
}

final class KidMover {
    let b: Body
    var a = 0.0, ph = 0.0
    var push: (Double, Double)? = nil
    init(_ x: Double, _ y: Double, _ z: Double) { b = Body(x, y, z) }
}

final class KidSeat {
    var t: Double
    var done: () -> Void
    var plate: SCNNode? = nil
    var food: SCNNode? = nil
    init(t: Double, done: @escaping () -> Void) { self.t = t; self.done = done }
}

/// 3D-huset: bygger scenen, styrer figurene og kameraet. Samme logikk som three.js-versjonen.
@MainActor
final class Life3D: NSObject {
    weak var m: GameModel?
    let scene = SCNScene()
    let camNode = SCNNode(), house = SCNNode(), me = RNode(), pet = RNode(), fr = RNode(), kid = RNode()
    let amb = SCNNode(), sun = SCNNode()
    weak var view: SCNView?
    var bubble: UILabel?
    var link: CADisplayLink?
    var running = false
    var lastT = 0.0
    var look = SIMD3<Double>(8, 1, 2)

    // tilstand
    let h = Body(8, 0, 3.1)
    var dir = (0.0, 0.0)
    var path: [(Double, Double)]? = nil
    var after: (() -> Void)? = nil
    var act: String? = nil
    var seat: Seat? = nil
    var actT = 0.0
    var actDone: (() -> Void)? = nil
    var towel = false, kbed = false, petBed = false, ward = false
    var petJump = 0.0, kjump = 0.0
    var kseat: KidSeat? = nil
    var kp: KidMover? = nil
    var pp: Body? = nil
    var pph = 0.0
    var trail: [(Double, Double, Double)] = []
    var vx = 0.0, vz = 0.0, amp = 0.0, ph = 0.0, td = 0.0
    var climb = false, up = false, far = false, snap = false
    var bump: String? = nil
    var bumpT = 0.0, stuck = 0.0
    var lastStep = 0
    var hb: Host? = nil
    var pa: PetAct? = nil
    var rig: Rig? = nil, krig: Rig? = nil, frig: Rig? = nil, petRig: PetRig? = nil
    var built = Built3D()
    var key = "", ckey = "", fkey = ""
    var props: SCNNode? = nil, bowl = SCNNode(), food: SCNNode? = nil, ball: SCNNode? = nil, hearts: [SCNNode] = []
    var leash: SCNNode? = nil
    var roomKey = ""
    var saveT = 0.0
    var cooking: () -> Bool = { false }

    override init() {
        super.init()
        let cam = SCNCamera()
        cam.fieldOfView = 42
        cam.zNear = 0.1
        cam.zFar = 160
        cam.wantsHDR = false
        camNode.camera = cam
        camNode.position = v3(8, 3, 8)
        let a = SCNLight(); a.type = .ambient; a.color = UIColor(red: 0.92, green: 0.9, blue: 0.86, alpha: 1); amb.light = a
        let s = SCNLight(); s.type = .directional; s.color = uiColor("#fff4e0"); s.castsShadow = true
        s.shadowMapSize = CGSize(width: 2048, height: 2048); s.shadowMode = .deferred; s.shadowSampleCount = 8; s.shadowRadius = 2.5
        s.orthographicScale = 13; s.zNear = 1; s.zFar = 50; s.shadowBias = 0.6; s.shadowColor = UIColor(white: 0, alpha: 0.45)
        sun.light = s
        sun.position = v3(5, 10, 24)
        sun.look(at: v3(8, 2.5, 2.5))
        for n in [camNode, amb, sun, house, me, pet, fr, kid] { scene.rootNode.addChildNode(n) }
    }

    var st: GameState { m?.s ?? GameState() }
    var away: Bool { st.life.place == "venn" }

    // MARK: bygg og oppdater

    /// Bygger på nytt det som har endret seg (som sync3).
    func sync() {
        guard let m = m else { return }
        let s = m.s, l = s.life, H = s.house
        let k = "\(away ? String(l.friend) : String(describing: H.inne))|\(s.kid.age)|\(s.pet.type)|\(s.pet.collar)|\(H.time)|\(H.wall)|\(H.door)|\(H.roofColor)|\(l.tv)|\(s.rain)"
        if k != key {
            key = k
            let hs = away ? Build3D.friendHouse(l.friend, H) : H
            built = Build3D.build(house, H: hs, away: away, me: s.me, tv: l.tv, rain: s.rain, act: act)
            scene.background.contents = built.sky
            amb.light?.intensity = CGFloat(built.hemi * 1000)
            sun.light?.intensity = CGFloat(built.sun * 1500)
            if act == "shower" { built.water?.isHidden = false }
        }
        var me0 = s.me; me0.oops = nil; me0.pet.glad = 0; me0.kid.glad = 0; me0.kid.mett = 0; me0.kid.xp = 0
        let ck = "\(s.cur)\(String(describing: me0))"
        let p = away ? l.f3 : l.h3
        if ck != ckey {
            ckey = ck
            buildMe(); petRig = Figure3D.buildPet(pet, s.pet); buildKid(); pp = nil; kp = nil
        }
        if !running || yAt(h.x, h.z, h.y) == nil {
            h.x = p.x; h.y = p.y; h.z = p.z
            if yAt(h.x, h.z, h.y) == nil { h.x = 8; h.z = 3.1; h.y = 0 }
        }
        if pp == nil || !running {
            pp = Body(min(15.4, h.x + 0.6), h.y > 1.5 ? 3 : h.y < 0.1 ? 0 : h.y, h.z)
            trail = []; vx = 0; vz = 0; kp = nil
        }
        fr.isHidden = !away
        if away {
            let (fl, ff) = Life3D.hostLook(s, l.friend)
            let fk = "\(l.friend)\(String(describing: fl))"
            if fk != fkey { fkey = fk; frig = Figure3D.build(fr, s: fl, f: ff, child: false) }
            if hb == nil || hb!.f != l.friend { if act != nil { endAct(quiet: true) }; hostInit() }
        } else { hb = nil }
        roomKey = room3().0 + (room3().2 ? "1" : "0")
        if !running { start() }
    }

    static var hostLookFn: ((GameState, Int) -> (Look, Feat))? = nil
    static func hostLook(_ s: GameState, _ i: Int) -> (Look, Feat) {
        if let f = hostLookFn { return f(s, i) }
        let j = min(max(0, i), s.people.count - 1)
        return (s.people[j], Feats.people[min(j, Feats.people.count - 1)])
    }

    func buildMe() {
        guard let s = m?.s else { return }
        rig = Figure3D.build(me, s: s.me, f: s.feat, child: false, towel: towel)
    }

    func buildKid() {
        guard let s = m?.s else { return }
        P3.clear(kid); krig = nil; kid.isHidden = true
        if s.kid.age < 1 { return }
        let (L, F) = Kids.look(s)
        krig = Figure3D.build(kid, s: L, f: F, child: true)
        kid.isHidden = false
    }

    func setTowel(_ on: Bool) { towel = on; buildMe() }

    func start() {
        guard !running else { return }
        running = true; snap = true
        lastT = CACurrentMediaTime()
        let l = CADisplayLink(target: self, selector: #selector(frame(_:)))
        l.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        l.add(to: .main, forMode: .common)
        link = l
    }

    func stop() {
        link?.invalidate(); link = nil
        if running { savePos() }
        running = false
        bubble?.isHidden = true
        Sound.shared.loop("water", false)
    }

    func savePos() {
        guard let m = m else { return }
        let p = Pos(x: h.x, z: h.z, y: h.y)
        if away { if m.s.life.f3 != p { m.s.life.f3 = p } } else if m.s.life.h3 != p { m.s.life.h3 = p }
    }

    // MARK: gåing

    func yAt(_ x: Double, _ z: Double, _ cy: Double) -> Double? {
        if x >= 0.9 && x <= 4.4 && z >= 0.3 && z <= 1.3 { let y = (4.4 - x) / 3.5 * 3; return abs(y - cy) < 0.6 ? y : nil }
        if x > 4.4 && x <= 4.9 && z >= 0.3 && z < 1.7 && cy < 0.6 { return 0 }
        if x >= 0.4 && x < 0.9 && z >= 0.3 && z < 1.7 && cy > 2.4 { return 3 }
        if x >= 0.4 && x <= 15.6 && z >= 1.7 && z <= 4.6 { return cy < 0.6 ? 0 : cy > 2.4 ? 3 : nil }
        return nil
    }

    func bodyAt(_ selfId: String, _ nx: Double, _ nz: Double, _ ox: Double, _ oz: Double, _ y: Double) -> String? {
        let upf = y > 1.5
        var L: [(String, Double, Double, Double)] = []
        if selfId != "me" && act == nil { L.append(("me", h.x, h.z, h.y)) }
        if selfId != "hb", !fr.isHidden, let hb = hb, hb.act != "sit" && hb.act != "chair" { L.append(("hb", hb.b.x, hb.b.z, hb.b.y)) }
        if selfId != "kid", !kid.isHidden, let kp = kp { L.append(("kid", kp.b.x, kp.b.z, kp.b.y)) }
        if nz < 1.8 { return nil }
        for b in L {
            if (b.3 > 1.5) != upf || b.2 < 1.8 { continue }
            let dn = hypot(nx - b.1, nz - b.2)
            if dn < 0.5 && dn < hypot(ox - b.1, oz - b.2) { return b.0 }
        }
        return nil
    }

    func tryMove(_ o: Body, _ dx: Double, _ dz: Double) -> Bool {
        let nx = o.x + dx, nz = o.z + dz
        guard let y = yAt(nx, nz, o.y) else { return false }
        let isMe = o === h
        if let who = bodyAt(isMe ? "me" : o === hb?.b ? "hb" : "x", nx, nz, o.x, o.z, y) { if isMe { bump = who }; return false }
        if (abs(nx - 5) < 0.22 || abs(nx - 11) < 0.22) && (nz < 2.75 || nz > 3.85) { return false }
        let fl = y > 1.5 ? 1.0 : 0.0
        for ob in built.obs where ob[3] == fl && hypot(nx - ob[0], nz - ob[1]) < ob[2] { return false }
        o.x = nx; o.z = nz; o.y = y
        return true
    }

    func plan(_ o: Body, _ x: Double, _ z: Double, _ Y: Double) -> [(Double, Double)] {
        let upf = o.y > 1.5, goUp = Y > 1.5
        var p: [(Double, Double)] = []
        if o.z >= 1.7 {
            p.append((o.x, 3.1))
            if upf != goUp {
                if goUp { p += [(4.62, 3.1), (4.62, 0.8), (0.65, 0.8), (0.65, 2.2), (0.65, 3.1)] }
                else { p += [(0.65, 3.1), (0.65, 0.8), (4.62, 0.8), (4.62, 2.2), (4.62, 3.1)] }
            }
        } else {
            if goUp { p += [(0.65, 0.8), (0.65, 3.1)] } else { p += [(4.62, 0.8), (4.62, 3.1)] }
        }
        p += [(x, 3.1), (x, z)]
        return p
    }

    func walkTo(_ x: Double, _ z: Double, _ Y: Double, _ f: (() -> Void)? = nil) {
        path = plan(h, x, z, Y); after = f; stuck = 0
    }

    /// Rommet du står i: (nøkkel, navn, oppe?)
    func room3() -> (String, String, Bool) {
        let upf = h.y > 1.5
        let k = h.x < 5 ? "gang" : h.x < 11 ? (upf ? "soverom" : "stue") : (upf ? "bad" : "kjokken")
        let names = ["gang": "Gang", "stue": "Stue", "kjokken": "Kjøkken", "soverom": "Soverom", "bad": "Bad"]
        return (k, k == "gang" ? (upf ? "Gang oppe" : "Gang") : names[k]!, upf)
    }

    func stepAside(_ who: String, _ vx: Double, _ vz: Double) {
        let o: Body? = who == "hb" ? hb?.b : kp?.b
        guard let o = o else { return }
        let n = max(1e-9, hypot(vx, vz)), px = -vz / n, pz = vx / n, fl = o.y > 1.5 ? 1.0 : 0.0
        func ok(_ x: Double, _ z: Double) -> Bool {
            yAt(x, z, o.y) != nil && z >= 1.75 && !built.obs.contains { $0[3] == fl && hypot(x - $0[0], z - $0[1]) < $0[2] } && !((abs(x - 5) < 0.25 || abs(x - 11) < 0.25) && (z < 2.75 || z > 3.85))
        }
        let c = [(o.x + px, o.z + pz), (o.x - px, o.z - pz), (o.x + vx / n * 1.3, o.z + vz / n * 1.3), (o.x + px * 0.6 + vx / n, o.z + pz * 0.6 + vz / n)].first { ok($0.0, $0.1) }
        guard let c = c else { return }
        if who == "hb", let hb = hb {
            hb.act = nil; hb.path = [c]; hb.after = nil; hb.stuck = 0; hb.idle = -6; hb.rp = 1.5
            hostSay(LifeData.pick(["Unnskyld!", "Oi, beklager!", "Jeg flytter meg."]), 2.5)
        } else { kp?.push = c }
    }

    /// Trykk på gulvet: gå dit.
    func tap(_ p: CGPoint) {
        guard running, !cooking(), let v = view else { return }
        let Y = h.y > 1.5 ? 3.0 : 0.0
        let a = v.unprojectPoint(SCNVector3(Float(p.x), Float(p.y), 0)), b = v.unprojectPoint(SCNVector3(Float(p.x), Float(p.y), 1))
        let dy = Double(b.y - a.y)
        if abs(dy) < 1e-6 { return }
        let t = (Y - Double(a.y)) / dy
        if t < 0 { return }
        let px = Double(a.x) + Double(b.x - a.x) * t, pz = Double(a.z) + Double(b.z - a.z) * t
        let x = max(0.5, min(15.5, px)), z = max(1.75, min(4.55, pz))
        func side(_ v: Double) -> Int { v < 5 ? 0 : v < 11 ? 1 : 2 }
        if h.z >= 1.7 && side(x) == side(h.x) { path = [(x, z)]; after = nil; stuck = 0 } else { walkTo(x, z, Y) }
    }

    // MARK: handlinger

    func endAct(quiet: Bool = false) {
        guard act != nil else { return }
        if towel { setTowel(false) }
        Sound.shared.loop("water", false)
        let keep = act == "petcare" || act == "bend" || act == "wash" ? me.ry : 0
        built.foam?.isHidden = true
        act = nil; pa = nil; props?.isHidden = true
        me.rot(0, keep, 0)
        built.water?.isHidden = true
        Mat3.m("#bfe0ec", "g").transparency = 0.3
        rig?.bd.pos(0, 0, 0)
        if !quiet { m?.objectWillChange.send() }
    }

    func props3() {
        if props != nil { return }
        let g = SCNNode(); scene.rootNode.addChildNode(g); props = g
        bowl = SCNNode()
        Cy(bowl, 0, 0, 0.05, 0, 0.085, "#c9ced3", 0.11, "s")
        food = Cy(bowl, 0, 0.035, 0.055, 0, 0.085, "#7a4a2a")
        g.addChildNode(bowl)
        ball = Sp(g, 0, 0, 0, 0.055, "#e2552d")
        let sh = UIBezierPath()
        sh.move(to: CGPoint(x: 0, y: -0.04))
        sh.addCurve(to: CGPoint(x: 0, y: 0.024), controlPoint1: CGPoint(x: -0.075, y: 0.012), controlPoint2: CGPoint(x: -0.035, y: 0.062))
        sh.addCurve(to: CGPoint(x: 0, y: -0.04), controlPoint1: CGPoint(x: 0.035, y: 0.062), controlPoint2: CGPoint(x: 0.075, y: 0.012))
        sh.flatness = 0.002
        let geo = SCNShape(path: sh, extrusionDepth: 0.004)
        geo.materials = [Mat3.m("#e8456b", "b")]
        hearts = (0..<4).map { _ in let n = SCNNode(geometry: geo); n.castsShadow = false; g.addChildNode(n); return n }
    }

    func startPet(_ k: String) {
        let ry = me.ry
        let lo = h.x < 5 ? 0.5 : h.x < 11 ? 5.35 : 11.35, hi = h.x < 5 ? 4.65 : h.x < 11 ? 10.65 : 15.5
        func cl(_ v: Double, _ a: Double, _ b: Double) -> Double { max(a, min(b, v)) }
        endAct(quiet: true); petBed = false; props3(); path = nil; after = nil
        let pt = st.pet.type
        DispatchQueue.main.asyncAfter(deadline: .now() + (k == "petplay" ? 1.5 : 0.9)) { Sound.shared.sfx(pt == "hund" ? "bark" : pt == "katt" ? "meow" : "squeak") }
        let fx = cl(h.x + sin(ry) * 0.6, lo, hi), fz = cl(h.z + cos(ry) * 0.6, 1.8, 4.5), d = (h.x - lo > hi - h.x) ? -1.0 : 1.0
        pa = PetAct(k: k, fx: fx, fz: fz, bx: cl(h.x + d * 2.4, lo, hi), bz: cl(h.z + 0.5, 1.9, 4.4), y: h.y)
        act = "petcare"
        props?.isHidden = false; bowl.isHidden = true; ball?.isHidden = true; hearts.forEach { $0.isHidden = true }
        food?.scale = v3(1, 1, 1)
    }

    var onPetDone: ((String) -> Void)? = nil
    var onShowerDone: (() -> Void)? = nil
    var onStairs: (() -> Void)? = nil
    var onLeave: (() -> Void)? = nil
    var onRoom: (() -> Void)? = nil

    func donePet() {
        guard let a = pa else { return }
        pa = nil
        endAct(quiet: true)
        onPetDone?(a.k)
    }

    // MARK: vennen (verten)

    func hostInit() {
        let hb = Host(f: st.life.friend)
        hb.lastP = (h.x, h.z)
        self.hb = hb
        hb.path = plan(hb.b, min(15, h.x + 1), 3.1, h.y)
        hostSay(LifeData.pick(["Hei! Så hyggelig at du kom!", "Hei! Kom inn, kom inn!", "Endelig! Jeg har ventet på deg."]))
    }

    func hostSay(_ t: String, _ d: Double = 4.5) {
        guard let hb = hb else { return }
        hb.sayTxt = t; hb.sayT = d
        if m?.s.life.said != t { m?.s.life.said = t }
    }

    func segOf(_ x: Double) -> Int { x < 5 ? 0 : x < 11 ? 1 : 2 }
    func hRoom(_ o: Body) -> String { let upf = o.y > 1.5, s = segOf(o.x); return s == 0 ? (upf ? "oppe" : "gang") : s == 1 ? (upf ? "soverom" : "stue") : (upf ? "bad" : "kjokken") }

    func hostGo(_ x: Double, _ z: Double, _ Y: Double, _ f: (() -> Void)? = nil) {
        guard let hb = hb else { return }
        hb.act = nil; hb.path = plan(hb.b, x, z, Y); hb.after = f; hb.stuck = 0
    }

    static let HACT: [String: [(Double, Double, Double, String)]] = [
        "stue": [(9.85, 1.8, Double.pi, "Se så fin utsikt det er herfra."), (10.3, 1.9, Double.pi / 2, "Har du lest denne boka? Den er kjempespennende."), (8.8, 1.75, Double.pi, "Jeg må huske å vanne planten min.")],
        "kjokken": [(15.2, 1.75, Double.pi, "Vil du ha noe å drikke? Jeg har saft."), (13.7, 1.8, Double.pi, "Jeg elsker kjøkkenet mitt.")],
        "gang": [(0.8, 2.0, -Double.pi / 2, "Ser håret mitt fint ut i dag?"), (2.6, 4.3, 0, "Velkommen hjem til meg!")],
        "soverom": [(5.75, 1.8, Double.pi, "Jeg har altfor mange klær."), (9.95, 1.8, Double.pi, "Her sover jeg som en stein.")],
        "bad": [(14.2, 1.8, Double.pi, "Jeg sjekker bare sminken.")], "oppe": [(2.6, 4.3, 0, "Her oppe er det rolig og fint.")],
    ]

    func turn(_ cur: Double, _ target: Double, _ k: Double) -> Double {
        var q = target - cur; q = atan2(sin(q), cos(q)); return cur + q * min(1, k)
    }

    func hostStep(_ dt: Double, _ now: Double) {
        guard let hb = hb, let R = frig else { return }
        let g = fr, hh = Double(g.scale.y)
        var moved = 0.0
        hb.sayT -= dt
        let pm = hypot(h.x - hb.lastP.0, h.z - hb.lastP.1); hb.lastP = (h.x, h.z)
        if pm > 0.002 { hb.st = 0 } else { hb.st += dt }
        let o = hb.b
        if var p = hb.path, let t = p.first {
            let ex = t.0 - o.x, ez = t.1 - o.z, d = hypot(ex, ez)
            if d < 0.08 {
                p.removeFirst(); hb.path = p
                if p.isEmpty { hb.path = nil; let f = hb.after; hb.after = nil; f?() }
            } else {
                let sp = min(d, 2.1 * dt), ox = o.x, oz = o.z, oy = o.y
                if tryMove(o, ex / d * sp, ez / d * sp) || tryMove(o, ex / d * sp, 0) || tryMove(o, 0, ez / d * sp) {
                    moved = hypot(o.x - ox, o.z - oz); hb.climb = abs(o.y - oy) > 0.0005; hb.stuck = 0; hb.ry = atan2(o.x - ox, o.z - oz)
                } else { hb.stuck += dt; if hb.stuck > 0.6 { hb.path = nil; hb.after = nil } }
            }
        } else if hb.act == nil && hb.mode == "follow" {
            let d = hypot(h.x - o.x, h.z - o.z), fl = (h.y > 1.5) != (o.y > 1.5), onStairs = h.z < 1.7
            if hRoom(h) == "bad" {
                let wx = 10.2, wz = 2.3
                if hypot(o.x - wx, o.z - wz) > 0.3 || o.y < 2.5 {
                    if !hb.waitT { hb.waitT = true; hostSay(LifeData.pick(["Jeg venter her ute.", "Jeg venter på soverommet så lenge.", "Ta den tiden du trenger!"])) }
                    hb.rp -= dt; if hb.rp <= 0 { hb.rp = 1; hostGo(wx, wz, 3) }
                } else { hb.ry = turn(hb.ry, atan2(11.5 - o.x, 3.3 - o.z), dt * 4) }
            } else if act == "sit" && seat == nil && hRoom(o) == "stue" && o.y < 1 {
                hb.waitT = false
                hostGo(6.35, 1.75, 0) { [weak self] in hb.act = "sit"; hb.seat = Seat(x: 6.35, y: 0.57, z: 0.84, r: 0); self?.hostSay(LifeData.pick(["Så deilig å slappe av sammen.", "Jeg setter meg ved siden av deg."])) }
            } else if !onStairs && (fl || d > 2.1 || (segOf(h.x) != segOf(o.x) && d > 1.3)) {
                hb.rp -= dt
                if hb.rp <= 0 {
                    hb.rp = 0.8
                    var vx = o.x - h.x, vz = o.z - h.z, n = hypot(vx, vz); if n == 0 { n = 1 }
                    if fl { vx = h.x < 8 ? 1 : -1; vz = 0; n = 1 }
                    hostGo(max(0.6, min(15.4, h.x + vx / n * 0.95)), max(1.85, min(4.45, h.z + vz / n * 0.95)), h.y > 1.5 ? 3 : 0)
                }
                hb.idle = min(hb.idle, -3)
            } else {
                hb.ry = turn(hb.ry, atan2(h.x - o.x, h.z - o.z), dt * 4)
                if hb.st > 1.5 && !cooking() { hb.idle += dt }
                if hb.idle > 6 && act == nil {
                    let L = Life3D.HACT[hRoom(h)] ?? []
                    hb.idle = -(5 + Double.random(in: 0..<6))
                    if let a = L.randomElement() {
                        hostGo(a.0, a.1, h.y > 1.5 ? 3 : 0) { [weak self] in hb.ry = a.2; hb.act = "do"; hb.t = 2.6; self?.hostSay(a.3) }
                    }
                }
            }
        }
        if hb.act == "sit" && act != "sit" { hb.act = nil; o.x = 6.35; o.z = 1.8; o.y = 0 }
        if hb.act == "chair" && hb.mode != "eat" && !(act == "sit" && seat != nil) { hb.act = nil; o.x = 15.55; o.z = 4.35; o.y = 0; hb.mode = "follow" }
        if hb.act == "do" { hb.t -= dt; if hb.t <= 0 { hb.act = nil } }
        if (hb.act == "sit" || hb.act == "chair"), let S = hb.seat {
            g.pos(S.x, S.y - 0.88 * hh, S.z); g.rot(0, S.r, 0)
            Figure3D.all(R, -1.5, 1.5, 0, -0.42, -0.75)
            R.tr.rot(-0.1, 0, 0); R.bd.pos(0, sin(now / 800) * 0.006, 0); R.bd.rz = 0
            if hb.mode == "eat" { R.arm[1].rx = -0.9 + sin(now / 260) * 0.25; R.elbow[1].rx = -1.6 }
        } else {
            hb.amp += (min(1, moved / dt / 2.1) - hb.amp) * min(1, dt * 9); hb.ph += moved * 4.3
            Figure3D.pose(R, hb.amp, hb.ph, hb.climb, now)
            if hb.act == "do" || (hb.mode == "cook" && hb.path == nil) {
                let w = sin(now / (hb.mode == "cook" ? 240 : 330))
                R.arm[1].rx = -1.1 + w * 0.25; R.elbow[1].rx = -0.9
                if hb.mode == "cook" { R.arm[0].rx = -0.8 - w * 0.2 }
            }
            g.pos(o.x, o.y, o.z)
            g.rot(0, turn(g.ry, hb.ry, dt * 10), 0)
        }
        // snakkeboble
        if let lab = bubble, let v = view {
            if hb.sayT > 0 {
                let p = v.projectPoint(v3(g.px, g.py + (hb.act == "sit" || hb.act == "chair" ? 1.45 : 2.02) * hh, g.pz))
                let w = v.bounds.width, hgt = v.bounds.height
                if p.z < 1 && p.z > 0 && p.x > -0.05 * Float(w) && p.x < 1.05 * Float(w) && p.y > -0.05 * Float(hgt) && p.y < 1.05 * Float(hgt) {
                    if lab.text != hb.sayTxt { lab.text = hb.sayTxt; lab.sizeToFit(); lab.bounds.size.width = min(lab.bounds.width + 20, w - 20); lab.bounds.size.height += 12 }
                    let bw = lab.bounds.width / 2 + 6
                    lab.center = CGPoint(x: max(bw, min(w - bw, CGFloat(p.x))), y: CGFloat(p.y) - lab.bounds.height / 2)
                    lab.isHidden = false
                } else { lab.isHidden = true }
            } else { lab.isHidden = true }
        }
    }

    // MARK: barnet og dyret

    func kidStep(_ dt: Double, _ now: Double) {
        guard let R = krig, !kid.isHidden else { return }
        if kp == nil { kp = KidMover(max(0.5, h.x - 0.5), h.y > 1.5 ? 3 : 0, max(1.8, h.z)) }
        let kp = kp!
        if kbed && st.life.place == "hjem" {
            Figure3D.all(R, 0, 0.1, 0.4, -0.2, -0.3); R.arm[0].rz = -0.1; R.arm[1].rz = 0.1
            R.tr.rot(0, 0, 0); R.bd.pos(0, sin(now / 900) * 0.01, 0)
            kid.rot(0, 0, Double.pi / 2); kid.pos(8.95, 3.6, 4.2); kid.isHidden = false
            return
        }
        if kid.rz != 0 { kid.rz = 0; kp.b.x = 8.1; kp.b.z = 3.3; kp.b.y = 3 }
        if let ks = kseat {
            let hs = Double(kid.scale.y)
            if ks.plate == nil {
                let pl = SCNNode()
                Cy(pl, 13.72, 0.76, 0.78, 4.35, 0.13, "#fbfaf7", 0.15)
                let f = Sp(pl, 13.72, 0.8, 4.35, 1, "#d9a55a"); f.scale = v3(0.09, 0.035, 0.09); ks.food = f
                Cy(pl, 13.62, 0.76, 0.9, 4.18, 0.03, "#cfe3ec", 0.035)
                scene.rootNode.addChildNode(pl); ks.plate = pl
            }
            ks.t -= dt
            let u = max(0.05, ks.t / 4.5)
            ks.food?.scale = v3(0.09 * u, 0.035, 0.09 * u)
            Figure3D.all(R, -1.5, 1.5, 0, -0.5, -0.7)
            R.arm[1].rx = -0.95 + sin(now / 230) * 0.3; R.elbow[1].rx = -1.5; R.tr.rot(-0.05, 0, 0); R.bd.pos(0, 0, 0); R.tr.py = R.ty
            kid.pos(13.22, 0.47 - 0.675 * hs, 4.35); kid.ry = Double.pi / 2
            if ks.t <= 0 {
                ks.plate?.removeFromParentNode(); kseat = nil
                kp.b.x = 12.75; kp.b.z = 4.35; kp.b.y = 0; kjump = 0.8
                ks.done()
            }
            return
        }
        var t: (Double, Double, Double)? = trail.count > 13 ? trail[trail.count - 13] : nil
        var mv = 0.0
        if let p = kp.push {
            t = (p.0, kp.b.y, p.1)
            if hypot(p.0 - kp.b.x, p.1 - kp.b.z) < 0.08 { kp.push = nil }
        } else if let tt = t, (h.y > 1.5) == (kp.b.y > 1.5) {
            let dn = hypot(tt.0 - h.x, tt.2 - h.z)
            if dn < 0.55 && hypot(kp.b.x - h.x, kp.b.z - h.z) < 0.9 { t = nil }
        }
        if let tt = t {
            let ex = tt.0 - kp.b.x, ez = tt.2 - kp.b.z, d = hypot(ex, ez)
            if d > 0 {
                let st0 = min(d, min(2.4, d * 4) * dt), nx = kp.b.x + ex / d * st0, nz = kp.b.z + ez / d * st0, dm = hypot(nx - h.x, nz - h.z)
                let blk = kp.push == nil && act == nil && (h.y > 1.5) == (kp.b.y > 1.5) && dm < 0.5 && dm < hypot(kp.b.x - h.x, kp.b.z - h.z)
                if d > 0.06 && !blk {
                    kp.b.x += ex / d * st0; kp.b.z += ez / d * st0; kp.b.y += (tt.1 - kp.b.y) * min(1, st0 / d); mv = st0
                    kid.ry = turn(kid.ry, atan2(ex, ez), dt * 10)
                }
            }
        }
        kp.a += (min(1, mv / dt / 1.6) - kp.a) * min(1, dt * 9); kp.ph += mv * 7.5
        Figure3D.pose(R, kp.a, kp.ph, false, now)
        var hop = 0.0
        if kjump > 0 { kjump -= dt; hop = abs(sin(kjump * 8)) * 0.16 }
        kid.pos(kp.b.x, kp.b.y + hop, kp.b.z)
    }

    func petStep(_ dt: Double, _ now: Double) {
        guard let R = petRig, let pp = pp else { return }
        let sc = Double(pet.scale.y)
        var mv = 0.0, eat = false, wag = 1.0, lie = false
        func go(_ tx: Double, _ tz: Double, _ ty: Double, _ sp: Double) -> Double {
            let ex = tx - pp.x, ez = tz - pp.z, d = hypot(ex, ez)
            if d > 0.05 {
                let s = min(d, sp * dt); pp.x += ex / d * s; pp.z += ez / d * s; pp.y += (ty - pp.y) * min(1, s / d); mv = s
                pet.ry = turn(pet.ry, atan2(ex, ez), dt * 10)
            }
            return d
        }
        func face(_ tx: Double, _ tz: Double) { pet.ry = turn(pet.ry, atan2(tx - pp.x, tz - pp.z), dt * 8) }
        if let a = pa {
            let mp = me.position
            let mx = Double(mp.x), mz = Double(mp.z)
            a.t += dt
            if a.k == "pet" {
                if a.ph == 0 { if go(a.fx, a.fz, a.y, 2.6) < 0.1 { a.ph = 1; a.t = 0 } }
                else {
                    face(mx, mz); wag = 3
                    for (i, m) in hearts.enumerated() {
                        let u = (a.t * 0.55 + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
                        m.isHidden = false
                        m.position = v3(pp.x + sin(Double(i) * 2.3 + a.t * 2) * 0.14, pp.y + 0.42 * sc + u * 0.55, pp.z + 0.05)
                        let s = 1.2 - u * 0.8; m.scale = v3(s, s, s)
                        m.eulerAngles.y = Float(atan2(Double(camNode.position.x) - pp.x, Double(camNode.position.z) - pp.z))
                    }
                    if a.t > 2.8 { return donePet() }
                }
            } else if a.k == "petfeed" {
                bowl.position = v3(a.fx, a.y, a.fz)
                if a.ph == 0 { bowl.isHidden = a.t <= 0.55; face(a.fx, a.fz); if a.t > 1.1 { a.ph = 1; a.t = 0 } }
                else if a.ph == 1 {
                    let ex = a.fx - pp.x, ez = a.fz - pp.z, d = max(1e-9, hypot(ex, ez)), k = 0.2 * sc
                    if go(a.fx - ex / d * k, a.fz - ez / d * k, a.y, 2.4) < 0.08 || d < k + 0.05 { a.ph = 2; a.t = 0 }
                } else {
                    face(a.fx, a.fz); eat = true; wag = 2
                    let u = max(0.02, 1 - a.t / 2.8); food?.scale = v3(u, 1, u)
                    if a.t > 2.8 { return donePet() }
                }
            } else if let b = ball {
                let hx = mx + cos(me.ry) * 0.22, hz = mz - sin(me.ry) * 0.22
                b.isHidden = false
                if a.ph == 0 { b.position = v3(hx, a.y + 0.85, hz); face(mx, mz); wag = 3; if a.t > 0.6 { a.ph = 1; a.t = 0; a.sx = hx; a.sz = hz } }
                else if a.ph == 1 {
                    let u = min(1, a.t / 0.85)
                    b.position = v3(a.sx + (a.bx - a.sx) * u, a.y + 0.06 + (1 - u) * 0.9 + sin(u * Double.pi) * 0.7, a.sz + (a.bz - a.sz) * u)
                    _ = go(a.bx, a.bz, a.y, 3.6); if u >= 1 { a.ph = 2; a.t = 0 }
                } else if a.ph == 2 {
                    b.position = v3(a.bx, a.y + 0.055 + abs(sin(a.t * 9)) * 0.12 * max(0, 1 - a.t), a.bz)
                    if go(a.bx, a.bz, a.y, 3.6) < 0.12 { a.ph = 3; a.t = 0 }
                } else if a.ph == 3 {
                    let d = go(a.fx, a.fz, a.y, 3.2)
                    b.position = v3(pp.x + sin(pet.ry) * 0.26 * sc, pp.y + 0.27 * sc, pp.z + cos(pet.ry) * 0.26 * sc)
                    if d < 0.1 { a.ph = 4; a.t = 0 }
                } else {
                    face(mx, mz); wag = 3
                    b.position = v3(pp.x + sin(pet.ry) * 0.26 * sc, pp.y + 0.27 * sc + a.t * 0.25, pp.z + cos(pet.ry) * 0.26 * sc)
                    if a.t > 1.3 { return donePet() }
                }
            }
        } else if petBed && st.life.place == "hjem" {
            if go(10.1, 4.15, 0, 2.4) < 0.1 { lie = true; wag = 0.4; pet.ry += (-0.6 - pet.ry) * min(1, dt * 3) }
        } else {
            let lag = st.pet.leash ? 5 : 8
            if trail.count > lag {
                let t = trail[trail.count - lag], d = hypot(t.0 - pp.x, t.2 - pp.z)
                if d > 0.06 { _ = go(t.0, t.2, t.1, min(3.2, d * 5)) }
            }
        }
        pph += mv * 16
        let am = min(1, mv / dt / 1.4), sn = sin(pph)
        for (i, L) in R.legs.enumerated() { L.rx = lie ? (i < 2 ? -1.35 : 1.35) : ((i == 0 || i == 3) ? 1 : -1) * 0.65 * am * sn }
        R.tail?.rz = sin(now / (150 / wag)) * 0.4
        R.hd.rx = eat ? 0.75 + sin(now / 110) * 0.14 : 0
        var hop = R.type == "kanin" ? am * 0.07 * abs(sn) : am * 0.012 * abs(sn)
        if petJump > 0 { petJump -= dt; hop += abs(sin(petJump * 8)) * 0.2 }
        pet.pos(pp.x, pp.y + hop + (lie ? 0.04 - 0.09 * sc : 0), pp.z)
        if lie { R.hd.rx = 0.35 }
        // bånd
        let on = st.pet.leash && act == nil
        leash?.removeFromParentNode(); leash = nil
        if on {
            let ry = me.ry, f = st.feat.h
            let hx = Double(me.position.x) + cos(ry) * 0.25 * f, hy = Double(me.position.y) + 0.84 * f, hz = Double(me.position.z) - sin(ry) * 0.25 * f, py = pp.y + hop + 0.27 * sc
            var pts: [SCNVector3] = []
            for i in 0..<9 { let u = Double(i) / 8; pts.append(v3(hx + (pp.x - hx) * u, hy + (py - hy) * u - sin(u * Double.pi) * 0.16, hz + (pp.z - hz) * u)) }
            var idx: [Int32] = []
            for i in 0..<8 { idx += [Int32(i), Int32(i + 1)] }
            let geo = SCNGeometry(sources: [SCNGeometrySource(vertices: pts)], elements: [SCNGeometryElement(indices: idx, primitiveType: .line)])
            geo.materials = [Mat3.m("#3a2a20", "b")]
            let n = SCNNode(geometry: geo); n.castsShadow = false
            scene.rootNode.addChildNode(n); leash = n
        }
    }

    // MARK: poser

    func actPose(_ dt: Double, _ now: Double) {
        guard let R = rig, let a = act else { return }
        let f = st.feat.h, br = sin(now / 800) * 0.008
        R.bd.rz = 0; R.tr.py = R.ty
        if a == "lie" {
            let m = simd_float3x3(columns: (SIMD3<Float>(0, 0, -1), SIMD3<Float>(-1, 0, 0), SIMD3<Float>(0, 1, 0)))
            me.pos(7.2 + 1.68 * f, 3.66, 0.88); me.simdOrientation = simd_quatf(m)
            Figure3D.all(R, -0.02, 0.05, 0.5, 0, -0.08); R.tr.rot(0, 0, 0); R.bd.pos(0, 0, br)
        } else if a == "sit" {
            let S = seat ?? Seat(x: 7.1, y: 0.57, z: 0.84, r: 0)
            me.pos(S.x, S.y - 0.88 * f, S.z); me.rot(0, S.r, 0)
            Figure3D.all(R, -1.5, 1.5, 0, -0.42, -0.75); R.tr.rot(-0.1, 0, 0); R.bd.pos(0, br, 0)
        } else if a == "petcare" {
            me.pos(h.x, h.y, h.z)
            guard let q = pa else { return }
            var b = 0.0, arm = 0.0, el = -0.2
            if q.k == "pet" && q.ph == 1 { b = 0.75; arm = -0.55 + sin(now / 130) * 0.28; el = -0.5 }
            if q.k == "petfeed" && q.ph == 0 { b = sin(min(1, q.t / 1.1) * Double.pi) * 0.85; arm = -0.6; el = -0.3 }
            if q.k == "petplay" {
                if q.ph == 0 { arm = 1.1 * min(1, q.t / 0.5) }
                else if q.ph == 1 { arm = 1.1 - min(1, q.t / 0.25) * 2.9; el = -0.1 }
                else if q.ph == 4 { b = sin(min(1, q.t / 1.3) * Double.pi) * 0.8; arm = -0.6; el = -0.4 }
            }
            Figure3D.all(R, -b * 0.55, b * 1.05, 0, 0, -0.12)
            R.arm[1].rx = arm; R.elbow[1].rx = el; R.arm[0].rx = -b * 0.3; R.tr.rot(b * 0.85, 0, 0); R.bd.pos(0, -b * 0.13, br * 0.3)
        } else if a == "toilet" || a == "bath" {
            actT -= dt
            let S = seat ?? Seat(x: h.x, y: h.y, z: h.z, r: 0)
            me.pos(S.x, S.y - 0.88 * f, S.z); me.rot(0, S.r, 0)
            Figure3D.all(R, -1.5, 1.5, 0, a == "bath" ? -0.2 : -0.42, a == "bath" ? -0.3 : -0.75)
            R.tr.rot(a == "bath" ? -0.25 : -0.05, 0, 0); R.bd.pos(0, br, 0)
            if actT <= 0 { let d = actDone; actDone = nil; endAct(quiet: true); d?() }
        } else if a == "wash" {
            actT -= dt
            let w = sin(now / 120)
            me.pos(h.x, h.y, h.z)
            Figure3D.all(R, 0, 0, 0, -1.05, -0.55)
            R.arm[0].rot(-1.05 + w * 0.12, 0, -0.25); R.arm[1].rot(-1.05 - w * 0.12, 0, 0.25)
            R.tr.rot(0.18, 0, 0); R.bd.pos(0, 0, 0)
            if actT <= 0 { let d = actDone; actDone = nil; endAct(quiet: true); d?() }
        } else if a == "bend" {
            actT -= dt
            let b = sin(max(0, min(1, 1 - actT / 1.6)) * Double.pi) * 0.75
            me.pos(h.x, h.y, h.z)
            Figure3D.all(R, -b * 0.55, b * 1.05, 0, -b * 1.1, -0.5); R.tr.rot(b * 0.85, 0, 0); R.bd.pos(0, -b * 0.13, 0)
            if actT <= 0 { endAct() }
        } else if a == "shower" {
            actT -= dt
            me.pos(11.75, 3.06, 0.7); me.rot(0, now / 800, 0)
            Figure3D.all(R, 0, 0, 0, -2.5, -1.3)
            for i in 0..<2 { R.arm[i].rx = -2.5 + sin(now / 180 + Double(i) * 2) * 0.25 }
            R.tr.rot(0, 0, 0); R.bd.pos(0, 0, 0)
            if let w = built.water {
                for (i, c) in w.childNodes.enumerated() { c.position.y = Float(5 - ((now / 420) + Double(i) * 0.37).truncatingRemainder(dividingBy: 1) * 1.9) }
            }
            if actT <= 0 { endAct(quiet: true); onShowerDone?() }
        }
    }

    // MARK: hovedløkka

    @objc func frame(_ l: CADisplayLink) {
        let t = CACurrentMediaTime()
        let dt = max(0.001, min(0.05, t - lastT)); lastT = t
        step(dt, t * 1000)
    }

    func step(_ dt: Double, _ now: Double) {
        guard running, let m = m else { return }
        let SPD = m.s.game.needs.energi < 20 ? 1.5 : 2.25
        var dx = dir.0, dz = dir.1, auto = false, rem = 9.0, moved = 0.0
        bump = nil
        if act != nil && act != "shower" && (dx != 0 || dz != 0 || path != nil) { endAct() }
        if act != nil { path = nil; dx = 0; dz = 0 }
        if dx != 0 || dz != 0 { path = nil; after = nil }
        else if var p = path, let tg = p.first {
            let ex = tg.0 - h.x, ez = tg.1 - h.z, d = hypot(ex, ez)
            if d < 0.07 {
                p.removeFirst(); path = p
                if p.isEmpty { path = nil; let f = after; after = nil; savePos(); f?(); if !running { return } }
            } else { dx = ex / d; dz = ez / d; auto = true; rem = d }
        }
        let n = hypot(dx, dz), kk = min(1, dt * (auto ? 16 : 9))
        vx += ((n > 0 ? dx / n * SPD : 0) - vx) * kk; vz += ((n > 0 ? dz / n * SPD : 0) - vz) * kk
        var sx = vx * dt, sz = vz * dt, sl = hypot(sx, sz)
        if auto && sl > rem { sx *= rem / sl; sz *= rem / sl; sl = rem }
        if sl > 0.0004 {
            let ox = h.x, oz = h.z, oy = h.y
            if tryMove(h, sx, sz) || tryMove(h, sx, 0) || tryMove(h, 0, sz) {
                moved = hypot(h.x - ox, h.z - oz); climb = abs(h.y - oy) > 0.0005; stuck = 0
                me.ry = turn(me.ry, atan2(h.x - ox, h.z - oz), dt * 11)
                td += moved
                if td > 0.12 { td = 0; trail.append((h.x, h.y, h.z)); if trail.count > 60 { trail.removeFirst() } }
            } else {
                vx = 0; vz = 0
                if path != nil && bump == nil { stuck += dt; if stuck > 0.5 { path = nil; after = nil } }
            }
        }
        if let b = bump { bumpT += dt; if bumpT > 0.35 { bumpT = 0; stepAside(b, dx != 0 ? dx : vx, dz != 0 ? dz : vz) } } else { bumpT = 0 }
        if h.y < 0.5 && h.x <= 0.46 && abs(h.z - 3.1) < 0.6 && dx < 0 { onLeave?(); return }
        if h.y > 2.95 && !up { up = true; onStairs?() } else if h.y < 0.05 { up = false }
        amp += (min(1, moved / dt / SPD) - amp) * min(1, dt * 9); ph += moved * 4.3
        let sp = Int(floor(ph / Double.pi)); if sp != lastStep { lastStep = sp; if amp > 0.3 { Sound.shared.sfx("step") } }
        if let R = rig { Figure3D.pose(R, amp, ph, climb, now) }
        if act != nil { actPose(dt, now); if !running { return } } else { me.pos(h.x, h.y, h.z) }
        petStep(dt, now); kidStep(dt, now)
        if !fr.isHidden && frig != nil && hb != nil { hostStep(dt, now) } else { bubble?.isHidden = true }
        // kamera
        let sz0 = view?.bounds.size ?? CGSize(width: 1, height: 1)
        let asp = Double(sz0.width / max(1, sz0.height))
        let k = snap ? 1 : min(1, dt * 4.5); snap = false
        var g = SIMD3<Double>(0, 0, 0), L = SIMD3<Double>(0, 0, 0)
        if far {
            let x = max(2.5, min(13.5, h.x)); g = SIMD3(x, h.y + 2.5, 11.5 + (asp < 1.1 ? (1.1 - asp) * 9 : 0)); L = SIMD3(x, g.y - 1.25, 1.2)
        } else if let hb = hb, !fr.isHidden, hb.mode == "eat" || (hb.mode == "sat" && act == "sit") {
            let x = (h.x + hb.b.x) / 2; g = SIMD3(x, h.y + 2.3, h.z + 4.6 + (asp < 1 ? (1 - asp) * 8 : 0)); L = SIMD3(x, h.y + 0.9, h.z)
        } else {
            g = SIMD3(h.x, h.y + 2.15, h.z + 4.3 + (asp < 1 ? (1 - asp) * 6.5 : 0)); L = SIMD3(h.x, h.y + 1.05, h.z)
        }
        let c = camNode.position
        let cp = SIMD3<Double>(Double(c.x), Double(c.y), Double(c.z))
        let nc = cp + (g - cp) * k
        look += (L - look) * k
        camNode.position = v3(nc.x, nc.y, nc.z)
        camNode.look(at: v3(look.x, look.y, look.z), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        let r = room3(), rk = r.0 + (r.2 ? "1" : "0")
        if rk != roomKey { roomKey = rk; onRoom?() }
        saveT += dt
        if saveT > 2 { saveT = 0; savePos() }
    }
}

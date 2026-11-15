import SwiftUI
import UIKit

/// Tegnede scener i Liv (ute, bil, flyplass, reise, dyrebutikk, flyet) og gåing/kjøring i dem.
@MainActor
final class Loop2D: NSObject, ObservableObject {
    @Published var t = 0.0
    weak var m: GameModel?
    var link: CADisplayLink?
    var last = CACurrentMediaTime()

    func start() {
        guard link == nil else { return }
        last = CACurrentMediaTime()
        let l = CADisplayLink(target: self, selector: #selector(tick(_:)))
        l.preferredFrameRateRange = CAFrameRateRange(minimum: 20, maximum: 30, preferred: 30)
        l.add(to: .main, forMode: .common)
        link = l
    }

    func stop() { link?.invalidate(); link = nil }

    @objc func tick(_ l: CADisplayLink) {
        let t = CACurrentMediaTime(), dt = min(0.05, t - last)
        last = t
        m?.step2D(dt, t)
    }
}

extension GameModel {
    /// Ett steg i 2D-scenen: figuren går mot målet, bilen kjører.
    func step2D(_ dt: Double, _ now: Double) {
        guard tab == "liv", !use3 else { return }
        let l = s.life
        var changed = false
        if l.place == "bil" && flying == nil {
            var ix = driveDir
            if ix != 0 && !belted {
                ix = 0
                if now - drive.wt > 2.6 { drive.wt = now; say("Spenn fast setebeltet først!"); Sound.shared.sfx("bad") }
            }
            drive.v += (ix * 440 - drive.v) * min(1, dt * (ix != 0 ? 1.8 : 3))
            let ox = cx
            cx = max(150, min(3050, cx + drive.v * dt))
            if cx == ox { drive.v = 0 }
            changed = cx != ox || ix != 0
            if abs(drive.v) > 4 { drive.dirn = drive.v > 0 ? 1 : -1 }
            wheelAng += (cx - ox) * drive.dirn / 16 * 57.3
            let near = Scenes2D.stops.first { abs($0.x - cx) < 120 }?.key ?? ""
            if near != driveNear { driveNear = near; s.life.cx = cx }
        } else if let t = tx {
            changed = true
            let d = t - wx, sp = 210 * dt
            if abs(d) <= sp { wx = t; tx = nil } else { wx += (d > 0 ? 1 : -1) * sp }
            let mx = l.place == "reise" && l.dest == "preikestolen" ? 400.0 : 616.0
            if wx < 24 { wx = 24; tx = nil } else if wx > mx { wx = mx; tx = nil }
            if tx == nil {
                s.life.x = wx
                if let f = pending { pending = nil; f() }
            }
        }
        if changed { loop2D.t = now }
    }

    /// Kopi av spillet der posisjonene er de levende verdiene fra løkka.
    var live2D: GameState {
        var st = s
        st.life.x = wx
        st.life.cx = cx
        return st
    }
}

struct Scene2DView: View {
    @EnvironmentObject var m: GameModel
    var body: some View { Scene2DInner(lp: m.loop2D) }
}

struct Scene2DInner: View {
    @EnvironmentObject var m: GameModel
    @ObservedObject var lp: Loop2D
    var body: some View {
        let st = m.live2D
        var op = SceneOpts()
        op.flying = m.flying; op.flyView = m.flyView; op.t = lp.t
        op.driveIn = m.drive.view == "in"; op.dirn = m.drive.dirn; op.beltMe = m.drive.meBelt; op.beltKid = m.drive.kidBelt
        op.ang = m.wheelAng; op.steer = m.driveDir; op.v = m.drive.v
        let sc = Scenes2D.lifeScene(st, op)
        return GeometryReader { g in
            SVGView(svg: sc.0, viewBox: CGRect(x: 0, y: 0, width: 640, height: 400))
                .background(Color(hex: sc.1))
                .contentShape(Rectangle())
                .onTapGesture { p in
                    guard m.flying == nil, m.cook == nil, st.life.place != "bil" else { return }
                    let w = g.size.width, h = g.size.height, k = min(w / 640, h / 400)
                    let x = (p.x - (w - 640 * k) / 2) / k
                    m.pending = nil
                    m.tx = max(26, min(614, x))
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { m.wx = m.s.life.x; m.cx = m.s.life.cx; m.loop2D.m = m; m.loop2D.start() }
        .onDisappear { m.loop2D.stop(); m.s.life.x = m.wx; m.s.life.cx = m.cx }
    }
}

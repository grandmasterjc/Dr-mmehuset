import SceneKit
import SwiftUI
import UIKit

/// SceneKit-visningen for 3D-huset, med snakkeboble og trykk for å gå.
struct Scene3DView: UIViewRepresentable {
    let e: Life3D

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView(frame: .zero)
        v.scene = e.scene
        v.pointOfView = e.camNode
        v.antialiasingMode = .multisampling4X
        v.isPlaying = true
        v.rendersContinuously = true
        v.backgroundColor = UIColor(red: 0.5, green: 0.72, blue: 0.91, alpha: 1)
        let lab = PaddedLabel()
        lab.font = .systemFont(ofSize: 14, weight: .medium)
        lab.textColor = UIColor(red: 0.11, green: 0.1, blue: 0.13, alpha: 1)
        lab.backgroundColor = .white
        lab.layer.cornerRadius = 12
        lab.layer.masksToBounds = true
        lab.numberOfLines = 0
        lab.textAlignment = .center
        lab.isHidden = true
        v.addSubview(lab)
        e.bubble = lab
        e.view = v
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coord.tap(_:)))
        v.addGestureRecognizer(tap)
        return v
    }

    func updateUIView(_ v: SCNView, context: Context) { e.view = v }

    static func dismantleUIView(_ v: SCNView, coordinator: Coord) { coordinator.e.stop() }

    func makeCoordinator() -> Coord { Coord(e) }

    final class Coord: NSObject {
        let e: Life3D
        init(_ e: Life3D) { self.e = e }
        @MainActor @objc func tap(_ g: UITapGestureRecognizer) { e.tap(g.location(in: g.view)) }
    }
}

final class PaddedLabel: UILabel {
    override func drawText(in rect: CGRect) { super.drawText(in: rect.insetBy(dx: 10, dy: 6)) }
}

/// Pilene i bildet: hold inne for å gå.
struct Pad: View {
    var onDir: (Double, Double) -> Void
    var body: some View {
        VStack(spacing: 4) {
            PadKey(s: "chevron.up", label: "Gå innover") { onDir($0 ? 0 : 0, $0 ? -1 : 0) }
            HStack(spacing: 4) {
                PadKey(s: "chevron.left", label: "Gå til venstre") { onDir($0 ? -1 : 0, 0) }
                PadKey(s: "chevron.down", label: "Gå utover") { onDir(0, $0 ? 1 : 0) }
                PadKey(s: "chevron.right", label: "Gå til høyre") { onDir($0 ? 1 : 0, 0) }
            }
        }
    }
}

struct PadKey: View {
    let s: String, label: String
    var on: (Bool) -> Void
    @State private var down = false
    var body: some View {
        Image(systemName: s).font(.system(size: 18, weight: .bold))
            .frame(width: 46, height: 42)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(down ? 0.95 : 0.78)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line))
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in if !down { down = true; on(true) } }
                .onEnded { _ in down = false; on(false) })
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
    }
}

/// Scenen i Liv-fanen: 3D-huset, eller en tegnet scene ute, i bilen, på flyplassen osv.
struct LivStage: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        let l = m.s.life
        ZStack(alignment: .bottomTrailing) {
            if m.use3 {
                Scene3DView(e: m.life3)
                    .onAppear { m.life3.sync() }
                    .onChange(of: m.s) { _, _ in m.life3.sync() }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                Pad { x, z in m.life3.dir = (x, z) }.padding(10)
                VStack {
                    HStack {
                        Spacer()
                        Button(m.life3.far ? "Følg figuren" : "Oversikt") { m.life3.far.toggle(); m.objectWillChange.send() }
                            .font(.system(size: 14, weight: .semibold)).padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Capsule().fill(Color.white.opacity(0.85))).foregroundStyle(Theme.ink)
                    }
                    Spacer()
                }.padding(10)
            } else {
                Scene2DView()
                if l.place == "bil" && m.flying == nil {
                    HStack(spacing: 4) {
                        PadKey(s: "chevron.left", label: "Kjør til venstre") { m.driveDir = $0 ? -1 : 0 }
                        PadKey(s: "chevron.right", label: "Kjør til høyre") { m.driveDir = $0 ? 1 : 0 }
                    }.padding(10)
                }
            }
        }
    }
}

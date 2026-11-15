import SceneKit
import SwiftUI
import UIKit

/// Byggeklosser for 3D-scenen (SceneKit). Samme mål og koordinater som three.js-versjonen.
func v3(_ x: Double, _ y: Double, _ z: Double) -> SCNVector3 { SCNVector3(Float(x), Float(y), Float(z)) }

func uiColor(_ hex: String) -> UIColor {
    let c = SVG.color(hex) ?? (0, 0, 0, 1)
    return UIColor(red: CGFloat(c.0), green: CGFloat(c.1), blue: CGFloat(c.2), alpha: CGFloat(c.3))
}

/// Rotasjon i samme rekkefølge som three.js (XYZ).
func setRot(_ n: SCNNode, _ x: Double, _ y: Double, _ z: Double) {
    let qx = simd_quatf(angle: Float(x), axis: SIMD3<Float>(1, 0, 0))
    let qy = simd_quatf(angle: Float(y), axis: SIMD3<Float>(0, 1, 0))
    let qz = simd_quatf(angle: Float(z), axis: SIMD3<Float>(0, 0, 1))
    n.simdOrientation = qx * qy * qz
}

/// Vinkler lagres separat slik at de kan leses og endres som i three.js (rotation.x osv.).
final class RNode: SCNNode {
    var rx = 0.0 { didSet { apply() } }
    var ry = 0.0 { didSet { apply() } }
    var rz = 0.0 { didSet { apply() } }
    func rot(_ x: Double, _ y: Double, _ z: Double) { rx = x; ry = y; rz = z }
    private func apply() { setRot(self, rx, ry, rz) }
    var px: Double { get { Double(position.x) } set { position.x = Float(newValue) } }
    var py: Double { get { Double(position.y) } set { position.y = Float(newValue) } }
    var pz: Double { get { Double(position.z) } set { position.z = Float(newValue) } }
    func pos(_ x: Double, _ y: Double, _ z: Double) { position = v3(x, y, z) }
}

enum Mat3 {
    static var cache: [String: SCNMaterial] = [:]

    static func m(_ c: String, _ o: String = "") -> SCNMaterial {
        let k = c + o
        if let m = cache[k] { return m }
        let m = SCNMaterial()
        m.diffuse.contents = uiColor(c)
        switch o {
        case "b": m.lightingModel = .constant
        case "g": m.lightingModel = .physicallyBased; m.transparency = 0.3; m.roughness.contents = 0.1; m.writesToDepthBuffer = false
        case "s": m.lightingModel = .physicallyBased; m.roughness.contents = 0.35; m.metalness.contents = 0.15
        case "d": m.lightingModel = .physicallyBased; m.roughness.contents = 0.85; m.isDoubleSided = true
        default: m.lightingModel = .physicallyBased; m.roughness.contents = 0.85
        }
        cache[k] = m
        return m
    }

    static func image(_ w: Int = 256, _ h: Int = 256, _ draw: (CGContext) -> Void) -> UIImage {
        let f = UIGraphicsImageRendererFormat()
        f.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: f).image { draw($0.cgContext) }
    }

    static func tex(_ key: String, _ rx: Double, _ ry: Double, _ draw: (CGContext) -> Void) -> SCNMaterial {
        if let m = cache[key] { return m }
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.roughness.contents = 0.75
        m.diffuse.contents = image(256, 256, draw)
        m.diffuse.wrapS = .repeat
        m.diffuse.wrapT = .repeat
        m.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(rx), Float(ry), 1)
        m.diffuse.mipFilter = .linear
        m.diffuse.maxAnisotropy = 4
        cache[key] = m
        return m
    }

    static func fill(_ x: CGContext, _ c: String, _ r: CGRect) { x.setFillColor(uiColor(c).cgColor); x.fill(r) }
    static func fillA(_ x: CGContext, _ w: CGFloat, _ a: CGFloat, _ r: CGRect) { x.setFillColor(UIColor(white: w, alpha: a).cgColor); x.fill(r) }

    static func floor(_ kind: String) -> SCNMaterial {
        let base = ["parkett": "#c9a271", "mork": "#6b4a35", "fliser": "#d9d6d0", "teppe": "#b9ad9d"][kind] ?? "#c9a271"
        return tex("f" + kind, 2.5, 2.5) { x in
            fill(x, base, CGRect(x: 0, y: 0, width: 256, height: 256))
            if kind == "fliser" {
                for i in 0..<4 { for k in 0..<4 { fill(x, shade(base, Double((i * 3 + k * 5) % 4) * 0.025 - 1.5 * 0.025), CGRect(x: i * 64, y: k * 64, width: 64, height: 64)) } }
                x.setStrokeColor(UIColor(white: 0, alpha: 0.22).cgColor); x.setLineWidth(2)
                for i in 0...4 { x.move(to: CGPoint(x: i * 64, y: 0)); x.addLine(to: CGPoint(x: i * 64, y: 256)); x.move(to: CGPoint(x: 0, y: i * 64)); x.addLine(to: CGPoint(x: 256, y: i * 64)) }
                x.strokePath()
            } else if kind == "teppe" {
                for i in 0..<2600 { fillA(x, i % 2 == 1 ? 1 : 0, 0.07, CGRect(x: (i * 73) % 256, y: (i * 151) % 256, width: 2, height: 2)) }
            } else {
                for r in 0..<8 {
                    let off = (r * 89) % 128
                    for i in -1..<3 { fill(x, shade(base, Double((r * 7 + i * 13 + 20) % 5 - 2) * 0.04), CGRect(x: off + i * 128, y: r * 32, width: 127, height: 31)) }
                    fillA(x, 0, 0.28, CGRect(x: 0, y: r * 32 + 31, width: 256, height: 1))
                    for i in -1..<3 { fillA(x, 0, 0.28, CGRect(x: off + i * 128 + 127, y: r * 32, width: 1, height: 32)) }
                    for q in 0..<5 { fillA(x, 0, 0.05, CGRect(x: (r * 53 + q * 61) % 256, y: r * 32 + 5 + q * 5, width: 70, height: 1)) }
                }
            }
        }
    }

    static var tile: SCNMaterial {
        tex("wt", 6, 1.5) { x in
            fill(x, "#f3f5f6", CGRect(x: 0, y: 0, width: 256, height: 256))
            x.setStrokeColor(UIColor(white: 0, alpha: 0.14).cgColor); x.setLineWidth(3)
            for i in 0...4 { x.move(to: CGPoint(x: i * 64, y: 0)); x.addLine(to: CGPoint(x: i * 64, y: 256)); x.move(to: CGPoint(x: 0, y: i * 64)); x.addLine(to: CGPoint(x: 256, y: i * 64)) }
            x.strokePath()
        }
    }

    static func rug(_ c: String) -> SCNMaterial {
        tex("rug" + c, 1, 1) { x in
            let l = shade(c, isLightHex(c) ? -0.22 : 0.35)
            fill(x, c, CGRect(x: 0, y: 0, width: 256, height: 256))
            x.setStrokeColor(uiColor(l).cgColor)
            x.setLineWidth(8); x.stroke(CGRect(x: 14, y: 14, width: 228, height: 228))
            x.setLineWidth(3); x.stroke(CGRect(x: 30, y: 30, width: 196, height: 196))
            for i in stride(from: 0, to: 256, by: 4) { fillA(x, 0, 0.05, CGRect(x: 0, y: i, width: 256, height: 1)) }
        }
    }

    static func sky(_ a: String, _ b: String) -> UIImage {
        image(4, 256) { x in
            let cs = CGColorSpaceCreateDeviceRGB()
            if let g = CGGradient(colorsSpace: cs, colors: [uiColor(a).cgColor, uiColor(b).cgColor] as CFArray, locations: [0, 1]) {
                x.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: 256), options: [])
            }
        }
    }
}

/// Lys farge? (samme test som i JS: rød-kanal over 150)
func isLightHex(_ c: String) -> Bool {
    let s = Array(c)
    guard s.count >= 3, let v = Int(String(s[1...2]), radix: 16) else { return false }
    return v > 150
}

/// Primitivene B (boks), Cy (sylinder/kjegle), Sp (kule), lathe og torus.
enum P3 {
    static func fin(_ g: SCNNode, _ n: RNode, _ o: String) -> RNode {
        n.castsShadow = !(o == "b" || o == "g")
        g.addChildNode(n)
        return n
    }

    @discardableResult
    static func B(_ g: SCNNode, _ x0: Double, _ x1: Double, _ y0: Double, _ y1: Double, _ z0: Double, _ z1: Double, _ c: String, _ o: String = "") -> RNode {
        B(g, x0, x1, y0, y1, z0, z1, mat: Mat3.m(c, o), o)
    }

    @discardableResult
    static func B(_ g: SCNNode, _ x0: Double, _ x1: Double, _ y0: Double, _ y1: Double, _ z0: Double, _ z1: Double, mat: SCNMaterial, _ o: String = "") -> RNode {
        let b = SCNBox(width: CGFloat(x1 - x0), height: CGFloat(y1 - y0), length: CGFloat(z1 - z0), chamferRadius: 0)
        b.materials = [mat]
        let n = RNode()
        n.geometry = b
        n.pos((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
        return fin(g, n, o)
    }

    @discardableResult
    static func Cy(_ g: SCNNode, _ x: Double, _ y0: Double, _ y1: Double, _ z: Double, _ r: Double, _ c: String, _ rt: Double? = nil, _ o: String = "") -> RNode {
        let top = rt ?? r
        let h = CGFloat(y1 - y0)
        let geo: SCNGeometry
        if abs(top - r) < 1e-9 {
            let s = SCNCylinder(radius: CGFloat(r), height: h); s.radialSegmentCount = 20; geo = s
        } else {
            let s = SCNCone(topRadius: CGFloat(top), bottomRadius: CGFloat(r), height: h); s.radialSegmentCount = 20; geo = s
        }
        geo.materials = [Mat3.m(c, o)]
        let n = RNode()
        n.geometry = geo
        n.pos(x, (y0 + y1) / 2, z)
        return fin(g, n, o)
    }

    @discardableResult
    static func Sp(_ g: SCNNode, _ x: Double, _ y: Double, _ z: Double, _ r: Double, _ c: String, _ o: String = "") -> RNode {
        let s = SCNSphere(radius: CGFloat(r))
        s.segmentCount = 22
        s.materials = [Mat3.m(c, o)]
        let n = RNode()
        n.geometry = s
        n.pos(x, y, z)
        return fin(g, n, o)
    }

    /// Torus som i three.js (liggende i XY-planet).
    static func torus(_ ring: Double, _ pipe: Double, _ m: SCNMaterial) -> RNode {
        let t = SCNTorus(ringRadius: CGFloat(ring), pipeRadius: CGFloat(pipe))
        t.materials = [m]
        let inner = SCNNode(geometry: t)
        inner.eulerAngles.x = Float.pi / 2
        let n = RNode()
        n.addChildNode(inner)
        return n
    }

    static func grp(_ par: SCNNode, _ x: Double, _ y: Double, _ z: Double = 0) -> RNode {
        let q = RNode()
        q.pos(x, y, z)
        par.addChildNode(q)
        return q
    }

    /// LatheGeometry: profil rundt Y-aksen, 26 segmenter.
    @discardableResult
    static func lathe(_ g: SCNNode, _ pts: [(Double, Double)], _ c: String, _ sx: Double = 1, _ sz: Double = 0.62) -> RNode {
        let seg = 26
        var vs: [SCNVector3] = [], ns: [SCNVector3] = [], idx: [Int32] = []
        let np = pts.count
        for i in 0...seg {
            let phi = Double(i) / Double(seg) * 2 * Double.pi
            let s = sin(phi), co = cos(phi)
            for j in 0..<np {
                let p = pts[j]
                vs.append(v3(p.0 * s, p.1, p.0 * co))
                // normal fra profilens helning
                let a = pts[max(0, j - 1)], b = pts[min(np - 1, j + 1)]
                let dx = b.0 - a.0, dy = b.1 - a.1
                var nx = dy, ny = -dx
                let l = max(1e-6, (nx * nx + ny * ny).squareRoot()); nx /= l; ny /= l
                ns.append(v3(nx * s, ny, nx * co))
            }
        }
        for i in 0..<seg {
            for j in 0..<(np - 1) {
                let a = Int32(i * np + j), b = Int32((i + 1) * np + j), c2 = Int32((i + 1) * np + j + 1), d = Int32(i * np + j + 1)
                idx += [a, b, d, b, c2, d]
            }
        }
        let geo = SCNGeometry(sources: [SCNGeometrySource(vertices: vs), SCNGeometrySource(normals: ns)], elements: [SCNGeometryElement(indices: idx, primitiveType: .triangles)])
        geo.materials = [Mat3.m(c, "d")]
        let n = RNode()
        n.geometry = geo
        n.scale = v3(sx, 1, sz)
        return fin(g, n, "")
    }

    /// Del av en kule (for ansiktet), med samme UV-kart som three.js SphereGeometry.
    static func spherePart(_ r: Double, _ ws: Int, _ hs: Int, _ phiStart: Double, _ phiLen: Double, _ thStart: Double, _ thLen: Double, _ m: SCNMaterial) -> RNode {
        var vs: [SCNVector3] = [], ns: [SCNVector3] = [], uv: [CGPoint] = [], idx: [Int32] = []
        for iy in 0...hs {
            let v = Double(iy) / Double(hs)
            for ix in 0...ws {
                let u = Double(ix) / Double(ws)
                let x = -cos(phiStart + u * phiLen) * sin(thStart + v * thLen)
                let y = cos(thStart + v * thLen)
                let z = sin(phiStart + u * phiLen) * sin(thStart + v * thLen)
                vs.append(v3(x * r, y * r, z * r)); ns.append(v3(x, y, z))
                uv.append(CGPoint(x: u, y: v))
            }
        }
        for iy in 0..<hs {
            for ix in 0..<ws {
                let a = Int32(iy * (ws + 1) + ix + 1), b = Int32(iy * (ws + 1) + ix), c = Int32((iy + 1) * (ws + 1) + ix), d = Int32((iy + 1) * (ws + 1) + ix + 1)
                idx += [a, b, d, b, c, d]
            }
        }
        let geo = SCNGeometry(sources: [SCNGeometrySource(vertices: vs), SCNGeometrySource(normals: ns), SCNGeometrySource(textureCoordinates: uv)], elements: [SCNGeometryElement(indices: idx, primitiveType: .triangles)])
        geo.materials = [m]
        let n = RNode()
        n.geometry = geo
        return n
    }

    static func triangle(_ pts: [SCNVector3], _ c: String) -> SCNNode {
        let a = pts[0], b = pts[1], cc = pts[2]
        let u = SIMD3<Float>(b.x - a.x, b.y - a.y, b.z - a.z), w = SIMD3<Float>(cc.x - a.x, cc.y - a.y, cc.z - a.z)
        let nn = simd_normalize(simd_cross(u, w))
        let nv = SCNVector3(nn.x, nn.y, nn.z)
        let geo = SCNGeometry(sources: [SCNGeometrySource(vertices: pts), SCNGeometrySource(normals: [nv, nv, nv])], elements: [SCNGeometryElement(indices: [Int32(0), 1, 2], primitiveType: .triangles)])
        geo.materials = [Mat3.m(c, "d")]
        return SCNNode(geometry: geo)
    }

    static func clear(_ g: SCNNode) { for c in g.childNodes { c.removeFromParentNode() } }
}

/// Ansiktet som tekstur: samme SVG som i 2D, tegnet til et bilde.
@MainActor
enum FaceTex {
    static var cache: [String: UIImage] = [:]
    static func image(_ faceSVG: String, skin: String) -> UIImage? {
        let key = skin + faceSVG
        if let i = cache[key] { return i }
        let root = SVG.parse(GDEFS + faceSVG)
        let v = Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: skin)))
            ctx.scaleBy(x: 256 / 44, y: 256 / 50)
            ctx.translateBy(x: -128, y: -54)
            for ch in root.children { SVGDraw.draw(ch, ctx, fill: "#000", scale: 5.5, ids: root.ids) }
        }.frame(width: 256, height: 256)
        let r = ImageRenderer(content: v)
        r.scale = 1
        let img = r.uiImage
        if cache.count > 30 { cache.removeAll() }
        if let img = img { cache[key] = img }
        return img
    }
}

// Korte navn som i JS-koden.
@discardableResult func B(_ g: SCNNode, _ x0: Double, _ x1: Double, _ y0: Double, _ y1: Double, _ z0: Double, _ z1: Double, _ c: String, _ o: String = "") -> RNode { P3.B(g, x0, x1, y0, y1, z0, z1, c, o) }
@discardableResult func B(_ g: SCNNode, _ x0: Double, _ x1: Double, _ y0: Double, _ y1: Double, _ z0: Double, _ z1: Double, mat: SCNMaterial) -> RNode { P3.B(g, x0, x1, y0, y1, z0, z1, mat: mat) }
@discardableResult func Cy(_ g: SCNNode, _ x: Double, _ y0: Double, _ y1: Double, _ z: Double, _ r: Double, _ c: String, _ rt: Double? = nil, _ o: String = "") -> RNode { P3.Cy(g, x, y0, y1, z, r, c, rt, o) }
@discardableResult func Sp(_ g: SCNNode, _ x: Double, _ y: Double, _ z: Double, _ r: Double, _ c: String, _ o: String = "") -> RNode { P3.Sp(g, x, y, z, r, c, o) }

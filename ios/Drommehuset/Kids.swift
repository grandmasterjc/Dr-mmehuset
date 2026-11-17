import Foundation

struct KidForm: Equatable { var name = ""; var girl = true; var c = 0 }

/// Barn: utseende, kandidater og tegninger, overført fra nettversjonen.
enum Kids {
    static func candidates(_ st: GameState, girl: Bool) -> [KidLook] {
        let q = st.people[st.cur]
        let si = Pal.skin.firstIndex(of: q.skin) ?? -1, hi = Pal.hair.firstIndex(of: q.hairColor) ?? -1
        func sk(_ d: Int) -> String { Pal.skin[max(0, min(5, (si < 0 ? 1 : si) + d))] }
        func hc(_ d: Int) -> String { Pal.hair[((hi < 0 ? 2 : hi) + d + 8) % 6] }
        func ey(_ d: Int) -> String { Pal.eyes[(max(0, Pal.eyes.firstIndex(of: q.eyes) ?? -1) + d) % Pal.eyes.count] }
        let base: [(String, String, String, String, Bool)] = [
            (sk(0), ey(1), hc(2), girl ? "hestehale" : "kort", true), (sk(1), ey(2), hc(1), girl ? "fletter" : "kroller", false),
            (sk(-1), ey(3), hc(4), girl ? "lob" : "kort", false), (sk(2), ey(4), hc(-1), girl ? "kroller" : "kort", false),
        ]
        let tops = girl ? ["#c97b84", "#c9a227", "#7fa3c7", "#5d7a5e"] : ["#7fa3c7", "#5d7a5e", "#c9a227", "#9b3b47"]
        return base.enumerated().map { i, b in
            var k = KidLook()
            k.skin = b.0; k.eyes = b.1; k.hairColor = b.2; k.hair = b.3; k.freckles = b.4
            k.top = "tskjorte"; k.topColor = tops[i]; k.bottom = girl ? "skjort" : "shorts"; k.bottomColor = girl ? "#9b3b47" : "#34507a"
            k.shoes = "sneakers"; k.shoeColor = "#f5f3ee"
            return k
        }
    }

    static func look(_ st: GameState, override: KidLook? = nil) -> (Look, Feat) {
        let q = st.people[st.cur], k = q.kid, L = override ?? k.look, g = k.girl
        let hi = max(0, Pal.hair.firstIndex(of: q.hairColor) ?? -1)
        var o = Look()
        o.skin = L.skin.isEmpty ? q.skin : L.skin
        o.eyes = L.eyes.isEmpty ? Pal.eyes[(max(0, Pal.eyes.firstIndex(of: q.eyes) ?? -1) + 1) % Pal.eyes.count] : L.eyes
        o.freckles = L.freckles
        o.hair = L.hair.isEmpty ? (g ? "hestehale" : "kort") : L.hair
        o.hairColor = L.hairColor.isEmpty ? Pal.hair[(hi + 2) % 6] : L.hairColor
        o.top = L.top.isEmpty ? "tskjorte" : L.top
        o.topColor = L.topColor.isEmpty ? (g ? "#c97b84" : "#7fa3c7") : L.topColor
        o.bottom = L.bottom.isEmpty ? (g ? "skjort" : "shorts") : L.bottom
        o.bottomColor = L.bottomColor.isEmpty ? (g ? "#9b3b47" : "#34507a") : L.bottomColor
        o.dress = L.dress.isEmpty ? "none" : L.dress
        o.dressColor = L.dressColor.isEmpty ? "#7fa3c7" : L.dressColor
        o.shoes = L.shoes.isEmpty ? "sneakers" : L.shoes
        o.shoeColor = L.shoeColor.isEmpty ? "#f5f3ee" : L.shoeColor
        return (o, Feat(face: "rund", er: 0, es: 1.18, lip: 0.9, bx: 0.94, h: k.age > 1 ? 0.7 : 0.52))
    }

    static func figure(_ st: GameState, override: KidLook? = nil) -> String {
        let (l, f) = look(st, override: override)
        return Figure(s: l, f: f, child: true).svg()
    }

    static func face(_ st: GameState, _ c: KidLook) -> String {
        "<svg viewBox=\"108 20 84 96\" aria-hidden=\"true\">\(GDEFS)\(figure(st, override: c))</svg>"
    }

    static func baby(_ topColor: String, _ sk: String, _ hc: String, _ x: Double, _ y: Double, _ k: Double) -> String {
        "<g transform=\"translate(\(js(x)) \(js(y))) scale(\(js(k)))\"><ellipse cx=\"0\" cy=\"40\" rx=\"62\" ry=\"10\" fill=\"#000\" opacity=\".12\"/><path d=\"M-58 30Q-60 -10 -20 -22L40 -22Q62 -10 60 30Z\" fill=\"\(topColor.isEmpty ? "#e9cfd0" : topColor)\"/><path d=\"M-20 -22Q10 0 40 -22\" stroke=\"#0002\" fill=\"none\"/>"
            + "<circle cx=\"-30\" cy=\"-40\" r=\"30\" fill=\"\(sk)\"/><path d=\"M-56 -50Q-50 -76 -26 -72Q-8 -70 -4 -54Q-20 -66 -40 -60Z\" fill=\"\(hc)\"/><circle cx=\"-40\" cy=\"-40\" r=\"2.6\" fill=\"#1d1020\"/><circle cx=\"-22\" cy=\"-40\" r=\"2.6\" fill=\"#1d1020\"/><path d=\"M-36 -28Q-31 -24 -26 -28\" stroke=\"#b5616a\" stroke-width=\"2\" fill=\"none\" stroke-linecap=\"round\"/><circle cx=\"-46\" cy=\"-32\" r=\"5\" fill=\"#ff9bb0\" opacity=\".45\"/><circle cx=\"-16\" cy=\"-32\" r=\"5\" fill=\"#ff9bb0\" opacity=\".45\"/></g>"
    }

    /// Forelder og barn ved siden av hverandre (Barn-fanen).
    static func stage(_ st: GameState, form: KidForm?) -> String {
        let q = st.people[st.cur], k = q.kid
        let par = Figure(s: q, f: Feats.people[min(st.cur, Feats.people.count - 1)]).svg()
        var o = "<svg viewBox=\"0 0 560 610\" preserveAspectRatio=\"xMidYMax meet\" role=\"img\" aria-label=\"Barnet ditt\">\(GDEFS)<g transform=\"translate(-20 0)\">\(par)</g>"
        if let f = form {
            let c = candidates(st, girl: f.girl)[f.c]
            o += baby(c.topColor, c.skin, c.hairColor, 400, 520, 1.4)
        } else if k.age == 0 {
            let L = look(st).0
            o += baby(k.look.topColor, L.skin, L.hairColor, 400, 520, 1.4)
        } else if k.age > 0 {
            let g = figure(st), s = k.age > 1 ? 0.68 : 0.55
            o += "<g transform=\"translate(\(fx(420 - 150 * s, 0)) \(fx(598 - 598 * s, 0))) scale(\(js(s)))\">\(g)</g>"
        }
        return o + "</svg>"
    }
}

extension GameState {
    mutating func welcomeKid(_ f: KidForm) -> String {
        let cd = Kids.candidates(self, girl: f.girl)[f.c]
        let nm = f.name.trimmingCharacters(in: .whitespaces)
        let k = Kid(age: 0, name: nm.isEmpty ? (f.girl ? "Lillemor" : "Lillebror") : nm, xp: 0, glad: 85, mett: 70, girl: f.girl, look: cd)
        if people[cur].kids.count >= Look.maxKids { return "" }
        people[cur].kids.append(k)
        people[cur].kidSel = people[cur].kids.count - 1
        need("humor", 30)
        return k.name
    }
}

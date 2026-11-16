import SwiftUI

/// Jobb: en vakt i bakeriet eller i dyreparken. Hver vakt har fem runder og gir mynter.
struct Job: Equatable {
    var kind = "baker"          // "baker" eller "zoo"
    var round = 1
    let total = 5
    var order: [String: Int] = [:]
    var picked: [String: Int] = [:]
    var customer = 0
    var animal = ""
    var fed = ""
    var answered = false
    var ok = false
    var right = 0
    var earned = 0
    var finished = false
}

enum Jobs {
    static let pay = 6, bonus = 10

    // MARK: bakeriet
    static let bakeOrder = ["bolle", "kanelsnurr", "skolebolle", "brod", "croissant", "muffins"]
    static let bake: [String: (one: String, many: String)] = [
        "bolle": ("bolle", "boller"), "kanelsnurr": ("kanelsnurr", "kanelsnurrer"), "skolebolle": ("skolebolle", "skoleboller"),
        "brod": ("brød", "brød"), "croissant": ("croissant", "croissanter"), "muffins": ("muffins", "muffins"),
    ]
    static func bakeLabel(_ k: String) -> String { (bake[k]?.one ?? k).prefix(1).uppercased() + (bake[k]?.one ?? k).dropFirst() }

    static func newOrder() -> [String: Int] {
        let n = Int.random(in: 1...3)
        var o: [String: Int] = [:]
        for k in bakeOrder.shuffled().prefix(n) { o[k] = Int.random(in: 1...(n == 1 ? 3 : 2)) }
        return o
    }

    static func orderText(_ o: [String: Int]) -> String {
        let parts = bakeOrder.compactMap { k -> String? in
            guard let c = o[k], c > 0, let b = bake[k] else { return nil }
            return "\(c) \(c == 1 ? b.one : b.many)"
        }
        return listText(parts)
    }

    // MARK: dyreparken
    static let animalOrder = ["love", "giraff", "pingvin", "apekatt", "elefant"]
    static let animals: [String: (name: String, food: String, sound: String)] = [
        "love": ("Løven", "Kjøtt", "Løven brøler. Den er sulten!"), "giraff": ("Giraffen", "Blader", "Giraffen strekker halsen etter mat."),
        "pingvin": ("Pingvinen", "Fisk", "Pingvinen vagger bort til deg og venter."), "apekatt": ("Apekatten", "Bananer", "Apekatten hopper og hyler. Den vil ha mat!"),
        "elefant": ("Elefanten", "Høy", "Elefanten løfter snabelen. Den er sulten."),
    ]
    static let foods = ["Kjøtt", "Blader", "Fisk", "Bananer", "Høy"]

    // MARK: tegninger
    static func item(_ k: String, _ x: Double, _ y: Double, _ s: Double = 1) -> String {
        let g: String
        switch k {
        case "bolle": g = ##"<ellipse cx="0" cy="0" rx="14" ry="9" fill="#c98f3e"/><ellipse cx="-3" cy="-3" rx="7" ry="3" fill="#e2b56a"/>"##
        case "kanelsnurr": g = ##"<circle cx="0" cy="0" r="12" fill="#c98f3e"/><path d="M0 0m-2 0a2 2 0 1 1 4 0a5 5 0 1 1 -9 1a8 8 0 1 1 15 -1" stroke="#7a4a22" stroke-width="2" fill="none"/>"##
        case "skolebolle": g = ##"<ellipse cx="0" cy="0" rx="14" ry="10" fill="#d9a55a"/><ellipse cx="0" cy="-2" rx="9" ry="6" fill="#fbfaf7"/><circle cx="0" cy="-2" r="4.5" fill="#f2c94c"/>"##
        case "brod": g = ##"<path d="M-20 6Q-22 -10 0 -11Q22 -10 20 6Z" fill="#b97a35"/><path d="M-10 -6l4 8M-1 -8l4 8M8 -6l4 8" stroke="#e9c27a" stroke-width="2"/>"##
        case "croissant": g = ##"<path d="M-18 4Q-14 -12 0 -12Q14 -12 18 4Q10 -2 0 -2Q-10 -2 -18 4Z" fill="#e0a548"/><path d="M-8 -10l3 8M0 -12v10M8 -10l-3 8" stroke="#b97a35" stroke-width="1.6"/>"##
        default: g = ##"<path d="M-10 10L-12 -2L12 -2L10 10Z" fill="#c97b84"/><ellipse cx="0" cy="-4" rx="13" ry="8" fill="#6b3f22"/><circle cx="-4" cy="-7" r="1.6" fill="#f2d48a"/><circle cx="4" cy="-5" r="1.6" fill="#f2d48a"/>"##
        }
        return "<g transform=\"translate(\(js(x)) \(js(y))) scale(\(js(s)))\">\(g)</g>"
    }

    static func bubble(_ t: String, _ cx: Double, _ y: Double) -> String {
        let w = Double(t.count) * 6.6 + 26, bx = max(8, min(632 - w, cx - w / 2))
        return "<rect x=\"\(js(bx))\" y=\"\(js(y))\" width=\"\(js(w))\" height=\"30\" rx=\"10\" fill=\"#fff\" stroke=\"#0003\"/><path d=\"M\(js(cx - 4)) \(js(y + 29))l4 12l10-12z\" fill=\"#fff\"/><text x=\"\(js(bx + 13))\" y=\"\(js(y + 20))\" font-family=\"Jost,sans-serif\" font-size=\"13\" fill=\"#1d1b22\">\(esc(t))</text>"
    }

    static func bakeryScene(_ st: GameState, _ j: Job?, walker: String) -> (String, String) {
        var o = Scenes2D.sc0(["#f3e6d6", "#f3e6d6"], "Bakeriet") + Scenes2D.gr("#b98a5a", 300)
        o += ##"<rect x="-640" y="292" width="1920" height="8" fill="#f6f4ef"/><rect x="200" y="40" width="240" height="40" rx="6" fill="#9b3b47"/><text x="320" y="66" text-anchor="middle" font-family="Jost,sans-serif" font-size="17" font-weight="600" letter-spacing="3" fill="#fbfaf7">BAKERIET</text>"##
        // hyller med brød bak disken
        o += ##"<rect x="330" y="96" width="290" height="150" fill="#8a6a4a"/>"##
        for r in 0..<3 {
            o += "<rect x=\"336\" y=\"\(102 + r * 48)\" width=\"278\" height=\"42\" fill=\"#6b4f36\"/>"
            for i in 0..<6 { o += item(bakeOrder[(i + r * 2) % 6], 360 + Double(i) * 45, Double(130 + r * 48), 0.9) }
        }
        // kunde
        if let j = j, !j.finished {
            let fig = Scenes2D.crowdSVG[j.customer % Scenes2D.crowdSVG.count]
            o += "<g transform=\"\(Scenes2D.wt(150, 0.34, 378, 0))\">\(fig)</g>"
            let t = j.answered ? (j.ok ? "Tusen takk! Ha en fin dag." : "Hmm, det var ikke det jeg ba om.") : "Jeg vil gjerne ha " + orderText(j.order) + "."
            o += bubble(t, 150, 92)
        }
        o += walker
        // disken med glassmonter
        o += ##"<rect x="300" y="262" width="320" height="110" fill="#e7ddd0"/><rect x="300" y="256" width="320" height="10" fill="#fbfaf7"/><rect x="312" y="276" width="296" height="60" rx="4" fill="#cfe3ec" opacity=".75"/>"##
        for (i, k) in bakeOrder.enumerated() { o += item(k, 336 + Double(i) * 50, 312) }
        // det du har lagt på brettet
        if let j = j, !j.finished {
            o += ##"<rect x="228" y="282" width="68" height="8" rx="3" fill="#8c8f96"/>"##
            var n = 0
            for k in bakeOrder { for _ in 0..<(j.picked[k] ?? 0) { o += item(k, 240 + Double(n % 4) * 15, 276 - Double(n / 4) * 12, 0.6); n += 1 } }
        }
        return (o + "</svg>", "#f3e6d6")
    }

    static func animalSVG(_ a: String, _ x: Double, _ y: Double) -> String {
        let g: String
        switch a {
        case "love":
            g = ##"<path d="M60 -30Q90 -40 86 -10" stroke="#c98f3e" stroke-width="6" fill="none" stroke-linecap="round"/><circle cx="86" cy="-10" r="7" fill="#7a4a22"/><ellipse cx="10" cy="-30" rx="62" ry="30" fill="#d9a04a"/><rect x="-40" y="-14" width="13" height="40" rx="6" fill="#c98f3e"/><rect x="-14" y="-14" width="13" height="40" rx="6" fill="#d9a04a"/><rect x="30" y="-14" width="13" height="40" rx="6" fill="#c98f3e"/><rect x="52" y="-14" width="13" height="40" rx="6" fill="#d9a04a"/><circle cx="-52" cy="-56" r="38" fill="#a8652a"/><circle cx="-56" cy="-54" r="25" fill="#e2b25e"/><circle cx="-66" cy="-60" r="3" fill="#1d1020"/><circle cx="-48" cy="-60" r="3" fill="#1d1020"/><path d="M-61 -48L-53 -48L-57 -43Z" fill="#6b3f22"/>"##
        case "giraff":
            g = ##"<rect x="-30" y="-40" width="10" height="66" fill="#e0b25a"/><rect x="34" y="-40" width="10" height="66" fill="#e0b25a"/><ellipse cx="6" cy="-50" rx="50" ry="26" fill="#e8c06a"/><path d="M-30 -60L-60 -170L-42 -174L-14 -64Z" fill="#e8c06a"/><ellipse cx="-58" cy="-180" rx="22" ry="13" fill="#e8c06a"/><circle cx="-60" cy="-184" r="2.6" fill="#1d1020"/><path d="M-50 -192l2 -12M-62 -192l-2 -12" stroke="#a8652a" stroke-width="3" stroke-linecap="round"/><circle cx="-6" cy="-56" r="7" fill="#a8652a"/><circle cx="18" cy="-46" r="8" fill="#a8652a"/><circle cx="34" cy="-60" r="6" fill="#a8652a"/><circle cx="-40" cy="-110" r="5" fill="#a8652a"/><circle cx="-50" cy="-140" r="5" fill="#a8652a"/>"##
        case "pingvin":
            g = ##"<ellipse cx="0" cy="-40" rx="30" ry="44" fill="#1f1f24"/><ellipse cx="0" cy="-32" rx="20" ry="34" fill="#fbfaf7"/><circle cx="0" cy="-86" r="20" fill="#1f1f24"/><circle cx="-7" cy="-90" r="3" fill="#fff"/><circle cx="7" cy="-90" r="3" fill="#fff"/><path d="M-6 -82L6 -82L0 -74Z" fill="#e9813c"/><ellipse cx="-12" cy="4" rx="10" ry="4" fill="#e9813c"/><ellipse cx="12" cy="4" rx="10" ry="4" fill="#e9813c"/>"##
        case "apekatt":
            g = ##"<path d="M24 -20Q70 -10 60 -60Q54 -80 40 -70" stroke="#7a4a22" stroke-width="7" fill="none" stroke-linecap="round"/><ellipse cx="0" cy="-30" rx="26" ry="32" fill="#7a4a22"/><rect x="-20" y="-6" width="11" height="30" rx="5" fill="#7a4a22"/><rect x="9" y="-6" width="11" height="30" rx="5" fill="#7a4a22"/><circle cx="-28" cy="-82" r="9" fill="#d9a77a"/><circle cx="28" cy="-82" r="9" fill="#d9a77a"/><circle cx="0" cy="-78" r="24" fill="#7a4a22"/><ellipse cx="0" cy="-72" rx="16" ry="14" fill="#d9a77a"/><circle cx="-6" cy="-78" r="2.6" fill="#1d1020"/><circle cx="6" cy="-78" r="2.6" fill="#1d1020"/><path d="M-5 -66Q0 -62 5 -66" stroke="#6b3f22" stroke-width="1.6" fill="none"/>"##
        default:
            g = ##"<rect x="-46" y="-30" width="20" height="56" rx="6" fill="#8c8f96"/><rect x="-14" y="-30" width="20" height="56" rx="6" fill="#9aa0a8"/><rect x="22" y="-30" width="20" height="56" rx="6" fill="#8c8f96"/><rect x="48" y="-30" width="20" height="56" rx="6" fill="#9aa0a8"/><ellipse cx="10" cy="-56" rx="70" ry="44" fill="#9aa0a8"/><circle cx="-62" cy="-74" r="34" fill="#9aa0a8"/><ellipse cx="-44" cy="-74" rx="22" ry="30" fill="#8c8f96"/><path d="M-86 -64Q-100 -30 -86 -4" stroke="#9aa0a8" stroke-width="13" fill="none" stroke-linecap="round"/><circle cx="-74" cy="-84" r="3" fill="#1d1020"/><path d="M-80 -60l-10 8" stroke="#f6f4ef" stroke-width="4" stroke-linecap="round"/>"##
        }
        return "<g transform=\"translate(\(js(x)) \(js(y)))\">\(g)</g>"
    }

    static func foodSVG(_ f: String, _ x: Double, _ y: Double) -> String {
        let g: String
        switch f {
        case "Kjøtt": g = ##"<ellipse cx="0" cy="0" rx="16" ry="10" fill="#b5404a"/><circle cx="14" cy="4" r="5" fill="#f6f4ef"/>"##
        case "Blader": g = ##"<ellipse cx="-8" cy="0" rx="12" ry="6" fill="#4f8a4a" transform="rotate(-20 -8 0)"/><ellipse cx="8" cy="-2" rx="12" ry="6" fill="#5d9a52" transform="rotate(20 8 -2)"/>"##
        case "Fisk": g = ##"<ellipse cx="0" cy="0" rx="16" ry="7" fill="#7fa3c7"/><path d="M14 0l10 -7v14z" fill="#7fa3c7"/><circle cx="-9" cy="-2" r="1.6" fill="#1d1020"/>"##
        case "Bananer": g = ##"<path d="M-14 -6Q0 12 16 -6Q0 4 -14 -6Z" fill="#f2d94c"/><path d="M-12 -12Q2 6 16 -12Q2 -2 -12 -12Z" fill="#e9c93c"/>"##
        default: g = ##"<path d="M-18 6Q-10 -14 0 -10Q10 -16 18 6Z" fill="#d9c36a"/><path d="M-10 4l-3 -10M0 4v-12M10 4l3 -10" stroke="#b9a34a" stroke-width="1.4"/>"##
        }
        return "<g transform=\"translate(\(js(x)) \(js(y)))\">\(g)</g>"
    }

    static func zooScene(_ st: GameState, _ j: Job?, walker: String) -> (String, String) {
        var o = Scenes2D.sc0(["#8fc1ea", "#e6f1f8"], "Dyreparken")
        o += ##"<path d="M-640 260Q-300 200 0 240T640 220T1280 260L1280 400L-640 400Z" fill="#7fae63"/>"## + Scenes2D.gr("#8cbb6c", 300)
        o += ##"<rect x="210" y="34" width="220" height="40" rx="6" fill="#3f6b52"/><text x="320" y="60" text-anchor="middle" font-family="Jost,sans-serif" font-size="17" font-weight="600" letter-spacing="3" fill="#fbfaf7">DYREPARKEN</text>"##
        o += ##"<circle cx="560" cy="170" r="54" fill="#4f8f52"/><rect x="552" y="200" width="16" height="100" fill="#6b4a35"/><circle cx="600" cy="200" r="40" fill="#5a9a58"/>"##
        // innhegning
        o += ##"<rect x="30" y="300" width="360" height="40" fill="#c9b27a" opacity=".6"/>"##
        if let j = j, !j.finished {
            o += animalSVG(j.animal, 200, 330)
            if !j.fed.isEmpty { o += foodSVG(j.fed, j.animal == "giraff" ? 140 : 120, 334) }
            let a = animals[j.animal]
            let t = j.answered ? (j.ok ? "Mmm! " + (a?.name ?? "") + " er mett og glad." : (a?.name ?? "") + " vil ikke ha " + j.fed.lowercased() + ".") : (a?.sound ?? "")
            o += bubble(t, 200, 84)
        }
        for x in stride(from: 30.0, through: 390, by: 24) { o += "<rect x=\"\(js(x))\" y=\"262\" width=\"6\" height=\"84\" fill=\"#8a6a4a\"/>" }
        o += ##"<rect x="26" y="276" width="370" height="6" fill="#6b4f36"/><rect x="26" y="316" width="370" height="6" fill="#6b4f36"/>"##
        o += walker
        // matbøtte
        o += ##"<path d="M520 340L524 378L556 378L560 340Z" fill="#c4313f"/><rect x="516" y="334" width="48" height="8" rx="3" fill="#9b2732"/>"##
        return (o + "</svg>", "#8fc1ea")
    }

    static func scene(_ st: GameState, _ j: Job?) -> (String, String) {
        if st.life.place == "bakeri" { return bakeryScene(st, j, walker: Scenes2D.walkerG(st, st.life.x, 0.34, 378)) }
        return zooScene(st, j, walker: Scenes2D.walkerG(st, st.life.x, 0.34, 378))
    }
}

extension GameModel {
    func nextRound(_ j: inout Job) {
        j.answered = false; j.ok = false; j.picked = [:]; j.fed = ""
        if j.kind == "baker" {
            j.order = Jobs.newOrder()
            var c = Int.random(in: 0..<max(1, Scenes2D.crowdSVG.count))
            if c == j.customer { c = (c + 1) % max(1, Scenes2D.crowdSVG.count) }
            j.customer = c
        } else {
            var a = Jobs.animalOrder.randomElement()!
            if a == j.animal { a = Jobs.animalOrder[(Jobs.animalOrder.firstIndex(of: a)! + 1) % Jobs.animalOrder.count] }
            j.animal = a
        }
    }

    func jobAct(_ k: String, _ v: String) {
        switch k {
        case "job":
            if s.game.needs.energi < 15 { msg = nm + " er for trøtt til å jobbe. Legg deg og sov først."; return }
            var j = Job(); j.kind = v
            nextRound(&j)
            job = j
            s.life.place = v == "baker" ? "bakeri" : "dyrepark"
            s.life.x = v == "baker" ? 450 : 470
            Sound.shared.sfx("door")
        case "jobadd":
            guard var j = job, !j.answered else { return }
            j.picked[v] = min(5, (j.picked[v] ?? 0) + 1); job = j; Sound.shared.sfx("pop")
        case "jobclear":
            job?.picked = [:]
        case "jobserve":
            guard var j = job, !j.answered else { return }
            let got = j.picked.filter { $0.value > 0 }
            if got.isEmpty { msg = "Legg noe på brettet først."; return }
            j.answered = true; j.ok = got == j.order.filter { $0.value > 0 }
            finishRound(&j)
        case "jobfeed":
            guard var j = job, !j.answered else { return }
            j.fed = v; j.answered = true; j.ok = Jobs.animals[j.animal]?.food == v
            if j.ok {
                let pt = j.animal == "love" ? "bark" : j.animal == "pingvin" ? "squeak" : "giggle"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { Sound.shared.sfx(pt) }
            }
            finishRound(&j)
        case "jobnext":
            guard var j = job else { return }
            if j.round >= j.total {
                j.finished = true
                if j.right == j.total { j.earned += Jobs.bonus; s.game.coins += Jobs.bonus }
                need("energi", -15); need("sult", -10); need("humor", 10)
                job = j
                Sound.shared.sfx("level")
                fire(j.kind)
                return
            }
            j.round += 1; nextRound(&j); job = j
        case "jobend":
            job = nil
            s.life.place = "ute"; s.life.x = doorX
        default: break
        }
    }

    private func finishRound(_ j: inout Job) {
        if j.ok {
            j.right += 1; j.earned += Jobs.pay; s.game.coins += Jobs.pay
            Sound.shared.sfx("coin"); Haptics.success()
        } else {
            Sound.shared.sfx("bad"); Haptics.warn()
        }
        job = j
    }
}

struct JobView: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        let baker = m.s.life.place == "bakeri"
        VStack(alignment: .leading, spacing: 14) {
            if let j = m.job {
                if j.finished {
                    Head(eye: baker ? "Bakeriet" : "Dyreparken", title: "Vakten er ferdig!",
                         text: "Du fikk \(j.right) av \(j.total) riktige og tjente \(j.earned) mynter." + (j.right == j.total ? " Alt riktig, så du fikk \(Jobs.bonus) mynter ekstra!" : ""))
                    Acts { AB(a: "job:" + j.kind, t: "Ta en vakt til"); AB(a: "jobend", t: "Gå hjem", ghost: true) }
                } else if baker {
                    Head(eye: "Bakeriet · kunde \(j.round) av \(j.total)", title: j.answered ? (j.ok ? "Riktig!" : "Feil bestilling") : "Hva vil kunden ha?",
                         text: "Kunden vil ha " + Jobs.orderText(j.order) + ".")
                    if !j.answered {
                        OptionRow(title: "Legg på brettet") {
                            ForEach(Jobs.bakeOrder, id: \.self) { k in
                                let n = j.picked[k] ?? 0
                                Chip(label: Jobs.bakeLabel(k) + (n > 0 ? " · \(n)" : ""), on: n > 0) { m.act("jobadd:" + k) }
                            }
                        }
                        Acts { AB(a: "jobserve", t: "Gi til kunden"); AB(a: "jobclear", t: "Tøm brettet", ghost: true) }
                    } else {
                        Hint(t: j.ok ? "Kunden betalte. +\(Jobs.pay) mynter." : "Kunden fikk feil og betalte ikke denne gangen.")
                        Acts { AB(a: "jobnext", t: j.round >= j.total ? "Avslutt vakten" : "Neste kunde") }
                    }
                } else {
                    let a = Jobs.animals[j.animal]
                    Head(eye: "Dyreparken · dyr \(j.round) av \(j.total)", title: j.answered ? (j.ok ? "Riktig mat!" : "Feil mat") : "Hva spiser " + (a?.name.lowercased() ?? "dyret") + "?",
                         text: j.answered ? (j.ok ? "" : (a?.name ?? "") + " spiser " + (a?.food.lowercased() ?? "") + ".") : "Velg riktig mat fra bøtta.")
                    if !j.answered {
                        OptionRow(title: "Mat") { ForEach(Jobs.foods, id: \.self) { f in Chip(label: f) { m.act("jobfeed:" + f) } } }
                    } else {
                        Hint(t: j.ok ? "Dyrepasseren roser deg. +\(Jobs.pay) mynter." : "Ingen mynter denne gangen.")
                        Acts { AB(a: "jobnext", t: j.round >= j.total ? "Avslutt vakten" : "Neste dyr") }
                    }
                }
                Acts { AB(a: "jobend", t: "Slutt for i dag", ghost: true) }
            } else {
                Head(eye: baker ? "Bakeriet" : "Dyreparken", title: "Klar for en vakt?")
                Acts { AB(a: "job:" + (baker ? "baker" : "zoo"), t: "Start vakten"); AB(a: "jobend", t: "Gå hjem", ghost: true) }
            }
            if !m.msg.isEmpty { Hint(t: m.msg) }
        }
    }
}

import SwiftUI

/// Jobb-fanen: søk på hvilken som helst jobb og ta en vakt med fem oppgaver.
struct WorkTask: Equatable { var q: String; var o: [String]; var r: Int }

struct Work: Equatable {
    var id = "", name = "", e = "💼"
    var bg = ["#e7e3dc", "#f7f5f1"]
    var tasks: [WorkTask] = []
    var i = 0, ans = -1, right = 0, earned = 0
    var done = false
}

enum WorkLogic {
    static func norm(_ t: String) -> String { t.lowercased().trimmingCharacters(in: .whitespaces) }

    static func find(_ q0: String) -> [WorkData.Job] {
        let q = norm(q0)
        if q.isEmpty { return [] }
        var sc: [(Int, Int, WorkData.Job)] = []
        for (idx, j) in WorkData.jobs.enumerated() {
            var s = 0
            for n in [j.id, norm(j.name)] + j.w {
                if n == q { s = max(s, 4) } else if n.hasPrefix(q) { s = max(s, 3) } else if n.contains(q) || (n.count > 3 && q.contains(n)) { s = max(s, 2) }
            }
            if s > 0 { sc.append((s, idx, j)) }
        }
        return sc.sorted { $0.0 != $1.0 ? $0.0 > $1.0 : $0.1 < $1.1 }.prefix(8).map { $0.2 }
    }

    static func make(_ j: WorkData.Job) -> Work {
        let low = j.name.lowercased()
        func f(_ x: String) -> String { x.replacingOccurrences(of: "{j}", with: low) }
        let spec = Array(j.t.shuffled().prefix(3))
        let gen = Array(WorkData.generic.shuffled().prefix(5 - spec.count))
        let tasks = (spec.shuffled() + gen).map { t -> WorkTask in
            let o = [t[1], t[2], t[3]].shuffled().map(f)
            return WorkTask(q: f(t[0]), o: o, r: o.firstIndex(of: f(t[1])) ?? 0)
        }
        return Work(id: j.id, name: j.name, e: j.e, bg: j.bg, tasks: tasks)
    }

    /// Hvilken som helst jobb: finnes den i lista brukes den, ellers lages en ny.
    static func any(_ q0: String) -> WorkData.Job? {
        let q = String(q0.trimmingCharacters(in: .whitespaces).prefix(28))
        if q.isEmpty { return nil }
        let n = norm(q)
        if let f = find(q).first, norm(f.name) == n || f.id == n || f.w.contains(n) { return f }
        let e = WorkData.emoji.first { n.contains($0.0) }?.1 ?? "💼"
        return WorkData.Job(id: "", name: q.prefix(1).uppercased() + q.dropFirst(), e: e, w: [], bg: ["#e7e3dc", "#f7f5f1"], t: [])
    }

    static func scene(_ st: GameState, _ w: Work?) -> (String, String) {
        let bg = w?.bg ?? ["#e7e3dc", "#f7f5f1"]
        let dark = (Int(String(Array(bg[0])[1...2]), radix: 16) ?? 255) < 90
        var o = Scenes2D.sc0(bg, w?.name ?? "Jobb") + Scenes2D.gr(dark ? "#3a3448" : "#c9b89a", 300)
        o += "<rect x=\"-640\" y=\"292\" width=\"1920\" height=\"8\" fill=\"\(dark ? "#4a4458" : "#f6f4ef")\"/>"
        let walker = Scenes2D.walkerG(st, 450, 0.34, 378)
        guard let w = w else {
            o += ##"<rect x="190" y="70" width="260" height="44" rx="8" fill="#34507a"/><text x="320" y="99" text-anchor="middle" font-family="Jost,sans-serif" font-size="18" font-weight="600" letter-spacing="3" fill="#fbfaf7">JOBBSENTERET</text><rect x="140" y="160" width="160" height="110" rx="6" fill="#fbfaf7" stroke="#b9b2a6"/><text x="220" y="236" text-anchor="middle" font-size="60">💼</text>"##
            return (o + walker + "</svg>", bg[0])
        }
        let nm = String(w.name.uppercased().prefix(22)), sw = max(200.0, Double(nm.count) * 13 + 60)
        o += "<rect x=\"\(js((320 - sw / 2).rounded()))\" y=\"40\" width=\"\(js(sw.rounded()))\" height=\"44\" rx=\"8\" fill=\"#a8455f\"/><text x=\"320\" y=\"69\" text-anchor=\"middle\" font-family=\"Jost,sans-serif\" font-size=\"18\" font-weight=\"600\" letter-spacing=\"3\" fill=\"#fbfaf7\">\(esc(nm))</text>"
        o += "<ellipse cx=\"200\" cy=\"300\" rx=\"90\" ry=\"14\" fill=\"#000\" opacity=\".12\"/><text x=\"200\" y=\"285\" text-anchor=\"middle\" font-size=\"150\">\(w.e)</text>"
        o += walker
        if w.ans >= 0 && !w.done {
            let ok = w.ans == w.tasks[w.i].r, t = ok ? "Bra jobbet!" : "Oi, det ble feil.", bw = Double(t.count) * 7 + 30
            o += "<rect x=\"\(js((450 - bw / 2).rounded()))\" y=\"120\" width=\"\(js(bw))\" height=\"30\" rx=\"10\" fill=\"#fff\" stroke=\"#0003\"/><path d=\"M446 149l4 12l10-12z\" fill=\"#fff\"/><text x=\"\(js((450 - bw / 2 + 15).rounded()))\" y=\"140\" font-family=\"Jost,sans-serif\" font-size=\"13\" fill=\"\(ok ? "#3f7d63" : "#a8455f")\">\(t)</text>"
        }
        if w.done { o += "<text x=\"450\" y=\"130\" text-anchor=\"middle\" font-size=\"40\">⭐</text>" }
        return (o + "</svg>", bg[0])
    }
}

extension GameModel {
    func startWork(_ j: WorkData.Job) {
        if s.game.needs.energi < 15 { workMsg = nm + " er for trøtt til å jobbe. Legg deg og sov under Liv først."; return }
        work = WorkLogic.make(j); workMsg = ""
        Sound.shared.sfx("door")
    }

    func answerWork(_ i: Int) {
        guard var w = work, w.ans < 0 else { return }
        w.ans = i
        if i == w.tasks[w.i].r { w.right += 1; w.earned += 6; s.game.coins += 6; Sound.shared.sfx("coin"); Haptics.success() }
        else { Sound.shared.sfx("bad"); Haptics.warn() }
        work = w
    }

    func nextWork() {
        guard var w = work else { return }
        if w.i >= w.tasks.count - 1 {
            w.done = true
            if w.right == w.tasks.count { w.earned += 10; s.game.coins += 10 }
            need("energi", -15); need("sult", -10); need("humor", 10)
            work = w
            Sound.shared.sfx("level")
            fire("job")
            return
        }
        w.i += 1; w.ans = -1; work = w
    }
}

struct JobbPanel: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let w = m.work {
                Button { m.work = nil; Haptics.tap() } label: { Label("Tilbake", systemImage: "chevron.left").font(.system(size: 15, weight: .medium)) }
                    .buttonStyle(.bordered).tint(Theme.ink)
                if w.done {
                    Head(eye: w.e + " " + w.name, title: "Vakten er ferdig!", text: "Du fikk \(w.right) av \(w.tasks.count) riktige og tjente \(w.earned) mynter." + (w.right == w.tasks.count ? " Alt riktig, så du fikk 10 mynter ekstra!" : ""))
                    HStack {
                        PrimaryButton(label: "Jobb en vakt til") { m.startWork(WorkData.jobs.first { $0.id == w.id && !w.id.isEmpty } ?? WorkData.Job(id: "", name: w.name, e: w.e, w: [], bg: w.bg, t: [])) }
                        Chip(label: "Finn en annen jobb") { m.work = nil }
                    }
                } else {
                    let t = w.tasks[w.i]
                    Head(eye: "\(w.e) \(w.name) · oppgave \(w.i + 1) av \(w.tasks.count)", title: t.q,
                         text: w.ans < 0 ? "Velg det riktige svaret." : (w.ans == t.r ? "Riktig! +6 mynter." : "Ikke helt. Riktig svar er: \(t.o[t.r])."))
                    FlowLayout {
                        ForEach(t.o.indices, id: \.self) { i in Chip(label: t.o[i], on: w.ans >= 0 && i == t.r) { m.answerWork(i) } }
                    }
                    if w.ans >= 0 { PrimaryButton(label: w.i < w.tasks.count - 1 ? "Neste oppgave" : "Avslutt vakten") { m.nextWork() } }
                }
            } else {
                Head(eye: "Jobb", title: "Hva vil du jobbe som?", text: "Søk på en hvilken som helst jobb. Hver vakt har fem oppgaver, og riktige svar gir mynter.")
                OptionRow(title: "Søk etter jobb") {
                    TextField("For eksempel lege, frisør eller astronaut", text: Binding(get: { m.workQuery }, set: { m.workQuery = String($0.prefix(28)) }))
                        .textFieldStyle(.roundedBorder).frame(minWidth: 260).submitLabel(.go)
                        .onSubmit { if let j = WorkLogic.any(m.workQuery) { m.startWork(j) } }
                }
                let q = m.workQuery.trimmingCharacters(in: .whitespaces), found = WorkLogic.find(q)
                if !q.isEmpty {
                    PrimaryButton(label: "Jobb som «\(q)»") { if let j = WorkLogic.any(q) { m.startWork(j) } }
                    FlowLayout { ForEach(found, id: \.name) { j in Chip(label: j.e + " " + j.name) { m.startWork(j) } } }
                    if found.isEmpty { Hint(t: "Den jobben står ikke i lista, men du kan prøve den likevel.") }
                } else {
                    OptionRow(title: "Populære jobber") { ForEach(WorkData.jobs.prefix(14), id: \.name) { j in Chip(label: j.e + " " + j.name) { m.startWork(j) } } }
                }
            }
            if !m.workMsg.isEmpty { Hint(t: m.workMsg) }
        }
    }
}

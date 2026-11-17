import SwiftUI

/// Knapp som i nettversjonen: fylt (hovedvalg) eller lys (ghost).
struct AB: View {
    @EnvironmentObject var m: GameModel
    let a: String, t: String
    var ghost = false
    var body: some View {
        if ghost { Chip(label: t) { m.act(a); Haptics.tap() } } else { PrimaryButton(label: t) { m.act(a); Haptics.tap() } }
    }
}

struct Head: View {
    let eye: String, title: String
    var text = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eye.uppercased()).font(.system(size: 12, weight: .semibold)).kerning(1.6).foregroundStyle(Theme.soft)
            Text(title).font(Theme.title(24))
            if !text.isEmpty { Text(text).font(.system(size: 15)) }
        }
    }
}

struct Hint: View {
    let t: String
    var body: some View { Text(t).font(.system(size: 14)).foregroundStyle(Theme.soft) }
}

struct Acts<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { FlowLayout(spacing: 8) { content } }
}

struct NeedBar: View {
    let t: String, v: Double
    var body: some View {
        HStack(spacing: 8) {
            Text(t).font(.system(size: 13)).frame(width: 110, alignment: .leading).lineLimit(1)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.chip)
                    Capsule().fill(v < 25 ? Theme.accent : Theme.good).frame(width: g.size.width * max(0, min(1, v / 100)))
                }
            }.frame(height: 8)
        }
    }
}

struct Hud: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        let g = m.s.game, n = g.needs, p = m.s.me
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Text("\(g.coins) mynter").font(.system(size: 14, weight: .semibold))
                Text("Nivå \(m.s.level)").font(.system(size: 14))
                GeometryReader { gg in
                    ZStack(alignment: .leading) { Capsule().fill(Theme.chip); Capsule().fill(Theme.gold).frame(width: gg.size.width * Double(g.xp % 100) / 100) }
                }.frame(height: 6).accessibilityLabel("Poeng til neste nivå")
            }
            NeedBar(t: "Mett", v: n.sult); NeedBar(t: "Energi", v: n.energi); NeedBar(t: "Ren", v: n.hygiene); NeedBar(t: "Humør", v: n.humor)
            if p.pet.type != "none" { NeedBar(t: p.pet.name.isEmpty ? "Dyret" : p.pet.name, v: p.pet.glad) }
            if p.kid.age >= 0 {
                let kn = p.kid.name.isEmpty ? "Barnet" : p.kid.name
                NeedBar(t: kn + " glad", v: p.kid.glad); NeedBar(t: kn + " mett", v: p.kid.mett)
            }
            let low = m.s.lowHint
            if !low.isEmpty { Hint(t: low) }
        }
        .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Theme.chip.opacity(0.6)))
    }
}

struct TasksView: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OPPDRAG").font(.system(size: 12, weight: .medium)).kerning(1.4).foregroundStyle(Theme.soft)
            VStack(alignment: .leading, spacing: 6) {
                ForEach([m.s.game.tasks.a, m.s.game.tasks.b, m.s.game.tasks.c], id: \.self) { t in
                    HStack { Text(GameState.taskText(t)).font(.system(size: 15)); Spacer(); Text("+\(GameState.taskPay(t))").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.good) }
                }
                Hint(t: "Oppdrag gir mynter og poeng. Er alle behov over halvfulle, får du halvannen gang så mange mynter.")
            }
        }
    }
}

struct LivPanel: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        let l = m.s.life
        VStack(alignment: .leading, spacing: 14) {
            if l.place == "ute" && (m.writing != nil || l.letter != nil) { LivBody() }
            else {
                Hud()
                LivBody()
                if m.cook == nil && m.flying == nil { TasksView() }
            }
        }
    }
}

struct LivBody: View {
    @EnvironmentObject var m: GameModel
    var friends: some View {
        ForEach(m.s.people.indices, id: \.self) { i in
            if i != m.s.cur { AB(a: "friend:\(i)", t: m.s.people[i].name.isEmpty ? "Venn" : m.s.people[i].name, ghost: true) }
        }
    }
    var msgV: some View { Group { if !m.msg.isEmpty { Hint(t: m.msg) } } }
    var foodV: some View { Group { if let f = m.s.life.food { Hint(t: "Du har med deg: \(f.name.lowercased()).") } } }

    var body: some View {
        let l = m.s.life, p = m.s.me
        VStack(alignment: .leading, spacing: 14) {
            if let fl = m.flying {
                let cr = Scenes2D.crewList(m.s).map { $0.name }
                Head(eye: "I lufta", title: fl == "home" ? "På vei hjem" : "På vei til " + (LifeData.dest[fl]?.0 ?? ""),
                     text: cr.isEmpty ? "Du reiser alene denne gangen." : "Du sitter sammen med " + listText(cr) + ".")
                Acts { AB(a: "land", t: "Land"); AB(a: "window", t: m.flyView == "out" ? "Se inn i kabinen" : "Se flyet utenfra", ghost: true); if !m.snack { AB(a: "snack", t: "Be om servering", ghost: true) } }
                msgV
            } else if let c = m.cook {
                CookView(c: c)
            } else if l.place == "ute", let w = m.writing {
                WriteView(w: w)
                msgV
            } else if l.place == "ute", let L = l.letter {
                LetterView(L: L)
            } else if l.place == "ute" {
                Head(eye: "Ute", title: "Utenfor huset")
                OptionRow(title: "Hjem") { AB(a: "in", t: "Gå inn") }
                OptionRow(title: "Besøk en venn") { FlowLayout { friends } }
                OptionRow(title: "Naboer") { FlowLayout { ForEach(Scenes2D.neighbours.map { $0.0.name }.indices, id: \.self) { i in AB(a: "friend:\(m.s.people.count + i)", t: "Hils på " + Scenes2D.neighbours.map { $0.0.name }[i], ghost: true) } } }
                OptionRow(title: "Postkasse") {
                    FlowLayout {
                        if m.s.game.mail > 0 { AB(a: "mail", t: "Hent posten (\(m.s.game.mail))") }
                        AB(a: "write", t: "Skriv et brev", ghost: true)
                        if m.s.game.mail == 0 { Hint(t: "Ingen ny post akkurat nå.") }
                    }
                }
                OptionRow(title: "Jobb") { AB(a: "job:baker", t: "Jobb i bakeriet", ghost: true); AB(a: "job:zoo", t: "Jobb i dyreparken", ghost: true) }
                OptionRow(title: "Bil") { AB(a: "drive", t: "Kjør bil", ghost: true) }
                OptionRow(title: "Reise") { AB(a: "airport", t: "Dra til flyplassen", ghost: true) }
                OptionRow(title: "Dyr") { AB(a: "petshop", t: "Gå til dyrebutikken", ghost: true) }
                foodV; msgV
            } else if l.place == "bakeri" || l.place == "dyrepark" {
                JobView()
            } else if l.place == "bil" {
                DriveView()
                msgV
            } else if l.place == "dyr" {
                PetShopView()
                msgV
            } else if l.place == "venn" {
                VisitView()
                msgV
            } else if l.place == "flyplass" {
                AirportView()
            } else if l.place == "reise", let d = LifeData.dest[l.dest] {
                Head(eye: d.1, title: d.0, text: d.2)
                Acts { AB(a: "airport", t: "Fly videre"); AB(a: "fly:home", t: "Fly hjem", ghost: true) }
                Hint(t: "Stempler i passet: \(l.stamps.values.filter { $0 }.count) av 11.")
            } else if m.ward {
                Head(eye: "Klesskapet", title: "Bytt klær", text: "Det du velger, får hun på seg med en gang.")
                Acts { AB(a: "wardone", t: "Ferdig") }
                KlaerPanel()
            } else {
                let r = m.life3.room3(), rk = r.0
                Head(eye: "Hjemme", title: r.1, text: "Styr med pilene i bildet, eller trykk på gulvet.")
                OptionRow(title: "Gå til") {
                    FlowLayout {
                        AB(a: "goto:gang", t: "Gang", ghost: true); AB(a: "goto:stue", t: "Stue", ghost: true); AB(a: "goto:kjokken", t: "Kjøkken", ghost: true)
                        AB(a: "goto:oppe", t: r.2 ? "Gang oppe" : "Opp trappa", ghost: true); AB(a: "goto:soverom", t: "Soverom", ghost: true); AB(a: "goto:bad", t: "Bad", ghost: true)
                        AB(a: "out", t: "Gå ut", ghost: true)
                    }
                }
                if rk != "gang" {
                    OptionRow(title: "Gjør noe") {
                        FlowLayout {
                            if rk == "bad" { BadActs(items: m.s.house.inne.bad.items) }
                            if rk == "stue" { AB(a: "sit", t: "Sett deg i sofaen", ghost: true); AB(a: "tv", t: l.tv ? "Slå av TV-en" : "Se på TV", ghost: true) }
                            if rk == "kjokken" { AB(a: "cook", t: "Lag mat"); if let f = l.food { AB(a: "eat", t: "Spis " + f.name.lowercased(), ghost: true) } }
                            if rk == "soverom" {
                                if m.life3.act == "lie" { AB(a: "wake", t: "Stå opp") } else { AB(a: "sleep", t: "Legg deg", ghost: true) }
                                AB(a: "wardrobe", t: "Åpne klesskapet", ghost: true)
                                if p.kid.age > 0 { AB(a: "kidbed", t: m.life3.kbed ? "Vekk " + p.kid.name : "Legg " + p.kid.name + " i senga", ghost: true) }
                            }
                        }
                    }
                }
                PetRow(); KidRow(); foodV; msgV
            }
        }
    }
}

func listText(_ a: [String]) -> String {
    if a.count < 2 { return a.joined() }
    return a.dropLast().joined(separator: ", ") + " og " + a.last!
}

struct BadActs: View {
    let items: [String: Bool]
    @EnvironmentObject var m: GameModel
    var body: some View {
        AB(a: "shower", t: "Ta en dusj", ghost: true)
        if items["badekar"] ?? false { AB(a: "bath", t: "Ta et bad", ghost: true) }
        AB(a: "toilet", t: "Gå på do", ghost: true)
        AB(a: "wash", t: m.s.life.wash ? "Vask hendene (husk!)" : "Vask hendene", ghost: true)
    }
}

struct PetRow: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        let pt = m.s.pet
        if pt.type != "none" {
            OptionRow(title: pt.name.isEmpty ? "Kjæledyr" : pt.name) {
                FlowLayout {
                    AB(a: "pet", t: "Klapp", ghost: true); AB(a: "petplay", t: "Lek", ghost: true); AB(a: "petfeed", t: "Gi mat", ghost: true)
                    if m.use3 && m.s.life.place == "hjem" { AB(a: "petbed", t: m.life3.petBed ? "Kall på " + pt.name : "Send til " + (pt.type == "hund" ? "hundesenga" : "senga"), ghost: true) }
                }
            }
        }
    }
}

struct KidRow: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        let kd = m.s.kid, all = m.s.me.kids
        if all.count > 1 {
            OptionRow(title: "Barnet som er med deg") {
                Menu {
                    ForEach(all.indices, id: \.self) { i in Button(all[i].name) { m.pickKid(i) } }
                } label: { Chip(label: kd.name + " · bytt (\(all.count) barn)") {} }
            }
        }
        if kd.age < 0 {
            OptionRow(title: "Familie") { Chip(label: "Få et barn (fanen Barn)") { m.tab = "barn" } }
        } else if kd.age == 0 {
            OptionRow(title: kd.name + ", baby") {
                FlowLayout {
                    if m.use3 && m.s.life.place == "hjem" {
                        if m.life3.carry { AB(a: "kid:down", t: "Legg babyen i senga", ghost: true) } else { AB(a: "kid:carry", t: "Bær babyen") }
                    }
                    AB(a: "kid:bottle", t: "Gi flaske", ghost: true); AB(a: "kid:cuddle", t: "Kos", ghost: true); AB(a: "kid:song", t: "Syng en sang", ghost: true)
                }
            }
        } else {
            OptionRow(title: kd.name + (kd.age > 1 ? ", barn" : ", smårolling")) {
                FlowLayout { AB(a: "kid:play", t: "Lek", ghost: true); AB(a: "kid:read", t: "Les en bok", ghost: true); AB(a: "kid:food", t: m.s.life.food != nil ? "Gi barnet " + m.s.life.food!.name.lowercased() : "Gi mat", ghost: true) }
            }
        }
    }
}

struct CookView: View {
    @EnvironmentObject var m: GameModel
    let c: Cook
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if c.step == 1 {
                Head(eye: "Kjøkken", title: "Hva vil du lage?")
                FlowLayout {
                    ForEach(LifeData.recipeOrder, id: \.self) { k in
                        let r = LifeData.recipes[k]!
                        if r.2 <= m.s.level { AB(a: "dish:" + k, t: r.0, ghost: true) }
                        else { Chip(label: "\(r.0) · nivå \(r.2)", locked: true) {} }
                    }
                }
                Acts { AB(a: "cookend", t: "Avbryt") }
            } else if c.step == 2 {
                Head(eye: "Steg 1 av 2", title: LifeData.recipes[c.dish]?.0 ?? "", text: "Velg de fire ingrediensene som hører hjemme i oppskriften.")
                FlowLayout { ForEach(c.opts, id: \.self) { n in Chip(label: n, on: c.pick[n] ?? false) { m.act("ing:" + n) } } }
                Acts { AB(a: "heat", t: "Sett på varmen"); AB(a: "cookend", t: "Avbryt", ghost: true) }
            } else if c.step == 3 {
                Head(eye: "Steg 2 av 2", title: "Ta av varmen i det grønne feltet")
                HeatBar(t0: c.t0)
                Acts { AB(a: "off", t: "Ta av varmen") }
            } else {
                let T = ["perfekt": "Perfekt stekt", "raa": "For rått", "brent": "Brent"][c.q] ?? ""
                HStack(alignment: .center, spacing: 14) {
                    SVGView(svg: Scenes2D.dishSVG(c.dish, c.q), viewBox: CGRect(x: 0, y: 0, width: 120, height: 80), alignBottom: false).frame(width: 130, height: 90)
                    VStack(alignment: .leading, spacing: 6) {
                        Text((LifeData.recipes[c.dish]?.0 ?? "").uppercased()).font(.system(size: 12, weight: .semibold)).kerning(1.6).foregroundStyle(m.s.life.food?.ok == true ? Theme.good : Theme.accent)
                        Text(T).font(Theme.title(24))
                        Text((c.wrong > 0 ? "Noen ingredienser var feil, så det smakte litt rart." : "Alle ingrediensene var riktige.") + " Du kan spise maten eller ta den med til en venn.").font(.system(size: 15))
                        AB(a: "cookend", t: "Ferdig")
                    }
                }
            }
        }
    }
}

/// Stekelinja: markøren går fra venstre mot høyre på 3,6 sekunder. Grønt felt = perfekt.
struct HeatBar: View {
    let t0: Double
    var body: some View {
        TimelineView(.animation) { tl in
            let p = min(1, (CACurrentMediaTime() - t0) / 3.6)
            GeometryReader { g in
                let w = g.size.width
                ZStack(alignment: .leading) {
                    LinearGradient(colors: [Color(hex: "#f2d48a"), Color(hex: "#e9a64c"), Color(hex: "#c4313f")], startPoint: .leading, endPoint: .trailing)
                    Rectangle().fill(Color(hex: "#3f9d55")).frame(width: w * 0.23).offset(x: w * 0.55)
                    Rectangle().fill(Theme.ink).frame(width: 4).offset(x: w * p - 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(height: 26)
            .id(tl.date)
        }
    }
}

struct WriteView: View {
    @EnvironmentObject var m: GameModel
    let w: Writing
    var body: some View {
        let to = m.s.people.enumerated().filter { $0.offset != m.s.cur }.map { $0.element.name.isEmpty ? "Venn" : $0.element.name } + ["Bestemor", "Bestefar", "Mamma", "Pappa"]
        VStack(alignment: .leading, spacing: 14) {
            Head(eye: "Postkassa", title: "Skriv et brev", text: "Velg hvem det er til, og skriv selv eller trykk på setningene.")
            OptionRow(title: "Til") { FlowLayout { ForEach(to, id: \.self) { n in Chip(label: n, on: w.to == n) { m.act("wto:" + n) } } } }
            OptionRow(title: "Brevet") {
                TextField("Kjære " + (w.to.isEmpty ? "…" : w.to), text: Binding(get: { m.writing?.text ?? "" }, set: { m.writing?.text = String($0.prefix(400)) }), axis: .vertical)
                    .lineLimit(3...8).padding(10).background(RoundedRectangle(cornerRadius: 10).stroke(Theme.line))
            }
            OptionRow(title: "Ferdige setninger") { FlowLayout { ForEach(LifeData.phrases.indices, id: \.self) { i in AB(a: "wadd:\(i)", t: LifeData.phrases[i], ghost: true) } } }
            Acts { AB(a: "wsend", t: "Send brevet"); AB(a: "wcancel", t: "Avbryt", ghost: true) }
        }
    }
}

struct LetterView: View {
    @EnvironmentObject var m: GameModel
    let L: Letter
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                Text(L.t.uppercased()).font(.system(size: 12, weight: .semibold)).kerning(1.6).foregroundStyle(Theme.soft)
                Text("Kjære \(m.s.me.name.isEmpty ? "deg" : m.s.me.name),").font(.custom("Georgia", size: 17))
                ForEach(L.body.indices, id: \.self) { i in Text(L.body[i]).font(.custom("Georgia", size: 17)) }
                Text(L.sign).font(.custom("Georgia-Italic", size: 17)).frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "#fbf7ee")).shadow(color: .black.opacity(0.12), radius: 6, y: 2))
            if !L.note.isEmpty { Hint(t: L.note) }
            Acts { AB(a: "letterdone", t: "Legg bort brevet") }
        }
    }
}

struct DriveView: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        let l = m.s.life, p = m.s.me
        let nr = Scenes2D.stops.first { abs($0.x - m.cx) < 120 }
        VStack(alignment: .leading, spacing: 14) {
            Head(eye: "På veien", title: nr?.2 ?? "Kjør bil", text: "Hold inne pilene i bildet.")
            if let nr = nr {
                if nr.0 == "friends" { OptionRow(title: "Besøk en venn") { FlowLayout { ForEach(m.s.people.indices, id: \.self) { i in if i != m.s.cur { AB(a: "friend:\(i)", t: m.s.people[i].name.isEmpty ? "Venn" : m.s.people[i].name, ghost: true) } } } } }
                else { Acts { AB(a: nr.0, t: nr.0 == "home" ? "Parker hjemme" : "Parker og gå inn") } }
            }
            OptionRow(title: "Setebelte") {
                FlowLayout {
                    if m.drive.meBelt { Chip(label: "Du har belte på", on: true) {} } else { AB(a: "belt:me", t: "Spenn fast deg selv") }
                    if p.kid.age >= 0 { if m.drive.kidBelt { Chip(label: p.kid.name + " har belte på", on: true) {} } else { AB(a: "belt:kid", t: "Spenn fast " + p.kid.name) } }
                }
            }
            if !m.belted { Hint(t: "Alle må ha setebeltet på før bilen kan kjøre.") }
            Acts { AB(a: "carview", t: m.drive.view == "in" ? "Se bilen utenfra" : "Se inn i bilen", ghost: true) }
            let w = (p.kid.age >= 0 ? [p.kid.name] : []) + (p.pet.type != "none" ? [p.pet.name] : [])
            if !w.isEmpty { Hint(t: "Med i bilen: " + w.joined(separator: " og ") + ".") }
            OptionRow(title: "Bilfarge") { FlowLayout { ForEach(LifeData.carColors, id: \.self) { c in Swatch(color: c, on: l.car == c) { m.act("carcol:" + c) } } } }
        }
    }
}

struct PetShopView: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        let sh = m.s.life.shop, pt = m.s.pet, info = LifeData.pets[sh.type] ?? ("Katt", 50, "Pusen")
        VStack(alignment: .leading, spacing: 14) {
            Head(eye: "Dyrebutikken", title: pt.type == "none" ? "Velg et kjæledyr" : "Bytt kjæledyr", text: pt.type == "none" ? "Dyret følger deg rundt i huset." : "Du har \(pt.name) fra før. Et nytt dyr tar plassen.")
            OptionRow(title: "Dyr") { FlowLayout { ForEach(LifeData.petOrder, id: \.self) { k in Chip(label: "\(LifeData.pets[k]!.0) · \(LifeData.pets[k]!.1)", on: sh.type == k) { m.act("ptype:" + k) } } } }
            OptionRow(title: "Farge") { FlowLayout { ForEach(LifeData.petColors, id: \.self) { c in Swatch(color: c, on: sh.color == c) { m.act("pcol:" + c) } } } }
            OptionRow(title: "Navn") {
                TextField(info.2, text: Binding(get: { m.s.life.shop.name }, set: { m.s.life.shop.name = String($0.prefix(12)) }))
                    .padding(10).background(RoundedRectangle(cornerRadius: 10).stroke(Theme.line))
            }
            Acts { AB(a: "adopt", t: "Ta med hjem for \(info.1) mynter"); AB(a: "home", t: "Gå hjem", ghost: true) }
        }
    }
}

struct VisitView: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        let l = m.s.life
        let fn = Life3D.hostLook(m.s, l.friend).0.name
        let r = m.life3.room3()
        VStack(alignment: .leading, spacing: 14) {
            Head(eye: "På besøk hos " + (fn.isEmpty ? "Venn" : fn), title: r.1, text: "Gå rundt i huset med pilene i bildet, eller trykk på gulvet.")
            VStack(alignment: .leading, spacing: 4) {
                if !m.s.life.meSaid.isEmpty { Text(LocalizedStringKey("**Du:** " + m.s.life.meSaid)) }
                Text(LocalizedStringKey("**" + (fn.isEmpty ? "Venn" : fn) + ":** " + (l.said.isEmpty ? LifeData.lines[l.line % LifeData.lines.count] : l.said)))
            }
            .font(.system(size: 15)).padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.chip))
            OptionRow(title: "Gå til") {
                FlowLayout {
                    AB(a: "goto:gang", t: "Gang", ghost: true); AB(a: "goto:stue", t: "Stue", ghost: true); AB(a: "goto:kjokken", t: "Kjøkken", ghost: true)
                    AB(a: "goto:oppe", t: r.2 ? "Gang oppe" : "Opp trappa", ghost: true); AB(a: "goto:soverom", t: "Soverom", ghost: true); AB(a: "goto:bad", t: "Bad", ghost: true)
                }
            }
            OptionRow(title: "Gjør noe") {
                FlowLayout {
                    if r.0 == "stue" { AB(a: "sit", t: "Sett deg i sofaen", ghost: true) }
                    if r.0 == "kjokken" { AB(a: "cooktog", t: "Lag mat sammen", ghost: true) }
                    if l.food != nil && r.0 == "kjokken" { AB(a: "eattog", t: "Spis sammen ved bordet", ghost: true) }
                    if r.0 == "bad" { BadActs(items: Build3D.friendHouse(l.friend, m.s.house).inne.bad.items) }
                    if r.0 != "stue" && r.0 != "kjokken" && r.0 != "bad" { Hint(t: "Gå til stua eller kjøkkenet for å finne på noe sammen.") }
                }
            }
            OptionRow(title: "Si noe selv") {
                HStack {
                    TextField("Skriv hva du vil si", text: $m.sayText).padding(10).background(RoundedRectangle(cornerRadius: 10).stroke(Theme.line)).onSubmit { m.act("say") }
                    AB(a: "say", t: "Si det")
                }
            }
            OptionRow(title: "Forslag") { FlowLayout { ForEach(LifeData.sayQ.indices, id: \.self) { i in AB(a: "sayq:\(i)", t: LifeData.sayQ[i], ghost: true) } } }
            Acts {
                AB(a: "talk", t: "La vennen prate", ghost: true)
                if let f = l.food { AB(a: "give", t: "Gi bort " + f.name.lowercased(), ghost: true) }
                AB(a: "home", t: "Dra hjem", ghost: true)
            }
        }
    }
}

struct AirportView: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        let l = m.s.life, p = m.s.me
        VStack(alignment: .leading, spacing: 14) {
            Head(eye: "Flyplassen", title: "Hvor vil du fly?", text: "Billetter i Norge koster 20 mynter per person. Utlandet koster 45 per person.")
            OptionRow(title: "Hvem blir med?") {
                FlowLayout {
                    ForEach(m.s.people.indices, id: \.self) { i in if i != m.s.cur { Chip(label: m.s.people[i].name.isEmpty ? "Venn" : m.s.people[i].name, on: l.crew["f\(i)"] ?? false) { m.act("crew:f\(i)") } } }
                    ForEach(["mamma", "pappa", "bestemor", "bestefar"], id: \.self) { q in Chip(label: q.prefix(1).uppercased() + q.dropFirst(), on: l.crew[q] ?? false) { m.act("crew:" + q) } }
                    if p.kid.age >= 0 { Chip(label: p.kid.name + " (halv pris)", on: l.crew["kid"] ?? false) { m.act("crew:kid") } }
                    if p.pet.type != "none" { Chip(label: p.pet.name + " (10 mynter)", on: l.crew["pet"] ?? false) { m.act("crew:pet") } }
                }
            }
            OptionRow(title: "Norge") { FlowLayout { ForEach(LifeData.destOrder.filter { LifeData.dest[$0]!.3 }, id: \.self) { k in AB(a: "fly:" + k, t: LifeData.dest[k]!.0 + " · 20", ghost: true) } } }
            OptionRow(title: "Utlandet") { FlowLayout { ForEach(LifeData.destOrder.filter { !LifeData.dest[$0]!.3 }, id: \.self) { k in AB(a: "fly:" + k, t: LifeData.dest[k]!.0 + " · 45", ghost: true) } } }
            Acts { AB(a: "home", t: "Dra hjem") }
            Hint(t: "Stempler i passet: \(l.stamps.values.filter { $0 }.count) av 11.")
            if !m.msg.isEmpty { Hint(t: m.msg) }
        }
    }
}

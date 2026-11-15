import SwiftUI

struct Opt: Identifiable { let id: String; let label: String }
func opts(_ a: [(String, String)]) -> [Opt] { a.map { Opt(id: $0.0, label: $0.1) } }

struct SminkePanel: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        let s = m.me
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("NAVN").font(.system(size: 12, weight: .medium)).kerning(1.4).foregroundStyle(Theme.soft)
                TextField("Navn", text: Binding(get: { m.me.name }, set: { m.set(\.name, String($0.prefix(14))) }))
                    .textFieldStyle(.roundedBorder).frame(maxWidth: 240)
            }
            OptionRow(title: "Hud") { ForEach(Pal.skin, id: \.self) { c in Swatch(color: c, on: s.skin == c) { m.set(\.skin, c) } } }
            OptionRow(title: "Øyenfarge") { ForEach(Pal.eyes, id: \.self) { c in Swatch(color: c, on: s.eyes == c) { m.set(\.eyes, c) } } }
            OptionRow(title: "Leppestift") { ForEach(["none"] + Pal.lips, id: \.self) { c in Swatch(color: c, on: s.lips == c) { m.set(\.lips, c) } } }
            OptionRow(title: "Øyenskygge") { ForEach(["none"] + Pal.shadow, id: \.self) { c in Swatch(color: c, on: s.shadow == c) { m.set(\.shadow, c) } } }
            OptionRow(title: "Rouge") { ForEach(["none"] + Pal.blush, id: \.self) { c in Swatch(color: c, on: s.blush == c) { m.set(\.blush, c) } } }
            OptionRow(title: "Detaljer") {
                Chip(label: "Maskara", on: s.mascara) { m.set(\.mascara, !s.mascara) }
                Chip(label: "Eyeliner", on: s.liner) { m.set(\.liner, !s.liner) }
                Chip(label: "Lipgloss", on: s.gloss) { m.set(\.gloss, !s.gloss) }
                Chip(label: "Fregner", on: s.freckles) { m.set(\.freckles, !s.freckles) }
            }
        }
    }
}

struct HaarPanel: View {
    @EnvironmentObject var m: GameModel
    let styles = opts([("kort", "Kort"), ("langt", "Langt"), ("bolgete", "Bølgete"), ("lob", "Halvlangt"), ("pannelugg", "Pannelugg"), ("hestehale", "Hestehale"), ("knute", "Knute"), ("fletter", "Fletter"), ("kroller", "Krøller")])
    var body: some View {
        let s = m.me
        VStack(alignment: .leading, spacing: 16) {
            OptionRow(title: "Frisyre") { ForEach(styles) { st in Chip(label: st.label, on: s.hair == st.id) { m.set(\.hair, st.id) } } }
            OptionRow(title: "Hårfarge") {
                ForEach(m.s.hairColors, id: \.self) { c in Swatch(color: c, on: s.hairColor == c) { m.set(\.hairColor, c) } }
                Swatch(color: Pal.rosa, on: s.hairColor == Pal.rosa, locked: !m.s.unlocked.rosa) { if m.s.unlocked.rosa { m.set(\.hairColor, Pal.rosa) } else { m.ask = "rosa" } }
                Swatch(color: Pal.blaa, on: s.hairColor == Pal.blaa, locked: !m.s.unlocked.blaa) { if m.s.unlocked.blaa { m.set(\.hairColor, Pal.blaa) } else { m.ask = "blaa" } }
            }
            if !m.s.unlocked.rosa || !m.s.unlocked.blaa {
                Text("Rosa og blå koster \(Shop.item("rosa")!.price) mynter hver.").font(.footnote).foregroundStyle(Theme.soft)
            }
        }
    }
}

struct KlaerPanel: View {
    @EnvironmentObject var m: GameModel
    func lockChip(_ label: String, _ id: String, on: Bool, _ act: @escaping () -> Void) -> some View {
        let lk = !m.s.unlocked[id]
        return Chip(label: label, on: on, locked: lk, price: Shop.item(id)?.price) { if lk { m.ask = id } else { act() } }
    }
    var body: some View {
        let s = m.me, cl = m.s.clothColors, d = s.dress != "none"
        VStack(alignment: .leading, spacing: 16) {
            OptionRow(title: "Kjole") {
                Chip(label: "Ingen", on: s.dress == "none") { m.set(\.dress, "none") }
                Chip(label: "T-skjortekjole", on: s.dress == "enkel") { m.set(\.dress, "enkel") }
                Chip(label: "Sommerkjole", on: s.dress == "sommer") { m.set(\.dress, "sommer") }
                lockChip("Gallakjole", "gallakjole", on: s.dress == "galla") { m.set(\.dress, "galla") }
            }
            if d { OptionRow(title: "Farge på kjolen") { ForEach(cl, id: \.self) { c in Swatch(color: c, on: s.dressColor == c) { m.set(\.dressColor, c) } } } }
            OptionRow(title: "Overdel") {
                ForEach(opts([("tskjorte", "T-skjorte"), ("singlet", "Topp"), ("skjorte", "Skjorte"), ("genser", "Genser"), ("hettegenser", "Hettegenser")])) { t in
                    Chip(label: t.label, on: !d && s.top == t.id) { m.set(\.top, t.id); m.set(\.dress, "none") }
                }
            }
            if !d { OptionRow(title: "Farge på overdelen") { ForEach(cl, id: \.self) { c in Swatch(color: c, on: s.topColor == c) { m.set(\.topColor, c) } } } }
            OptionRow(title: "Underdel") {
                ForEach(opts([("jeans", "Jeans"), ("vide", "Vide bukser"), ("shorts", "Shorts"), ("skjort", "Skjørt"), ("midi", "Langt skjørt")])) { t in
                    Chip(label: t.label, on: !d && s.bottom == t.id) { m.set(\.bottom, t.id); m.set(\.dress, "none") }
                }
            }
            if !d { OptionRow(title: "Farge på underdelen") { ForEach(cl, id: \.self) { c in Swatch(color: c, on: s.bottomColor == c) { m.set(\.bottomColor, c) } } } }
            OptionRow(title: "Jakke") {
                Chip(label: "Ingen", on: s.outer == "none") { m.set(\.outer, "none") }
                Chip(label: "Dongerijakke", on: s.outer == "dongeri") { m.set(\.outer, "dongeri") }
                Chip(label: "Blazer", on: s.outer == "blazer") { m.set(\.outer, "blazer") }
                lockChip("Skinnjakke", "skinnjakke", on: s.outer == "skinn") { m.set(\.outer, "skinn") }
            }
            if s.outer != "none" { OptionRow(title: "Farge på jakken") { ForEach(cl, id: \.self) { c in Swatch(color: c, on: s.outerColor == c) { m.set(\.outerColor, c) } } } }
            OptionRow(title: "Sko") {
                ForEach(opts([("sneakers", "Sneakers"), ("ballerina", "Ballerina"), ("haeler", "Hæler"), ("boots", "Boots")])) { t in
                    Chip(label: t.label, on: s.shoes == t.id) { m.set(\.shoes, t.id) }
                }
            }
            OptionRow(title: "Farge på skoene") { ForEach(cl, id: \.self) { c in Swatch(color: c, on: s.shoeColor == c) { m.set(\.shoeColor, c) } } }
            OptionRow(title: "Tilbehør") {
                Chip(label: "Halskjede", on: s.acc.halskjede) { m.set(\.acc.halskjede, !s.acc.halskjede) }
                Chip(label: "Perleøredobber", on: s.acc.oredobber) { m.set(\.acc.oredobber, !s.acc.oredobber) }
                lockChip("Solbriller", "solbriller", on: s.acc.solbriller) { m.set(\.acc.solbriller, !s.acc.solbriller) }
                lockChip("Veske", "veske", on: s.acc.veske) { m.set(\.acc.veske, !s.acc.veske) }
                lockChip("Gullsmykker", "smykker", on: s.acc.smykker) { m.set(\.acc.smykker, !s.acc.smykker) }
                lockChip("Lue", "lue", on: s.acc.lue) { m.set(\.acc.lue, !s.acc.lue) }
            }
        }
    }
}

struct PakkePanel: View {
    @EnvironmentObject var m: GameModel
    var info: String {
        let g = m.s.game, n = m.s.opened
        var t = "Du har åpnet \(n) " + (n == 1 ? "pakke" : "pakker") + " og funnet \(m.s.unlocked.count) av 10 faste kupp. "
        if g.free > 0 { t += "Du har \(g.free) " + (g.free > 1 ? "gratispakker." : "gratispakke.") } else { t += "En pakke koster \(m.s.giftPrice) mynter." }
        return t + " Pakkene tar aldri slutt."
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                Button { m.openGift() } label: { GiftBox(open: m.gift != nil, shaking: m.shaking) }
                    .buttonStyle(.plain).accessibilityLabel("Åpne pakken")
                VStack(alignment: .leading, spacing: 6) {
                    if let r = m.gift {
                        Text(r.good ? "KUPP" : "UFLAKS").font(.system(size: 12, weight: .semibold)).kerning(1.6).foregroundStyle(r.good ? Theme.good : Theme.accent)
                        Text(r.title).font(Theme.title(24))
                        if let sw = r.swatch { Circle().fill(Color(hex: sw)).frame(width: 30, height: 30) }
                        Text(r.text).font(.system(size: 15))
                        PrimaryButton(label: "Åpne en ny") { m.openGift() }
                    } else {
                        Text("PAKKE NR. \(m.s.opened + 1)").font(.system(size: 12, weight: .semibold)).kerning(1.6).foregroundStyle(Theme.soft)
                        Text("Åpne pakken").font(Theme.title(24))
                        Text("Noen ganger er det et kupp. Noen ganger er det uflaks.").font(.system(size: 15))
                    }
                }
            }
            Text(info).font(.footnote).foregroundStyle(Theme.soft)
            let shop = Shop.items.filter { !m.s.unlocked[$0.id] }
            if !shop.isEmpty {
                OptionRow(title: "Kan også kjøpes med mynter") {
                    ForEach(shop, id: \.id) { it in Chip(label: it.name, locked: true, price: it.price) { m.ask = it.id } }
                }
            }
        }
    }
}

struct GiftBox: View {
    var open: Bool
    var shaking: Bool
    @State private var wiggle = false
    var body: some View {
        ZStack(alignment: .top) {
            Ellipse().fill(Color.black.opacity(0.12)).frame(width: 124, height: 10).offset(y: 124)
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#c79a63")).frame(width: 112, height: 72).offset(y: 56)
            Rectangle().fill(Color(hex: "#e3c796")).frame(width: 16, height: 72).offset(y: 56)
            RoundedRectangle(cornerRadius: 1).fill(Color(hex: "#fbfaf7")).frame(width: 30, height: 22).offset(x: -26, y: 94)
            ZStack { Rectangle().fill(Color(hex: "#b5864f")).frame(width: 124, height: 16); Rectangle().fill(Color(hex: "#e3c796")).frame(width: 16, height: 16) }
                .offset(y: 42)
                .rotationEffect(.degrees(open ? -14 : 0), anchor: .bottomLeading)
                .offset(x: open ? -6 : 0, y: open ? -20 : 0)
        }
        .frame(width: 150, height: 140)
        .rotationEffect(.degrees(wiggle ? 5 : 0))
        .animation(.easeInOut(duration: 0.3), value: open)
        .onChange(of: shaking) { _, v in
            if v { withAnimation(.easeInOut(duration: 0.12).repeatCount(5, autoreverses: true)) { wiggle = true } } else { wiggle = false }
        }
    }
}

struct SnartPanel: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.title(24))
            Text("Denne delen er ennå ikke flyttet over til appen. Den kommer i neste runde.").font(.system(size: 15)).foregroundStyle(Theme.soft)
        }
    }
}

struct HusPanel: View {
    @EnvironmentObject var m: GameModel
    static let rooms = opts([("gang", "Gang"), ("stue", "Stue"), ("kjokken", "Kjøkken"), ("soverom", "Soverom"), ("bad", "Bad")])
    static let items: [String: [Opt]] = [
        "stue": opts([("lampe", "Gulvlampe"), ("bord", "Salongbord"), ("tv", "TV"), ("bokhylle", "Bokhylle"), ("plante", "Plante"), ("gardiner", "Gardiner")]),
        "soverom": opts([("nattbord", "Nattbord"), ("skrivebord", "Skrivebord"), ("speil", "Speil"), ("lyslenke", "Lyslenke"), ("plante", "Plante"), ("gardiner", "Gardiner")]),
        "kjokken": opts([("kjoleskap", "Kjøleskap"), ("spisebord", "Spisebord"), ("plante", "Urter"), ("gardiner", "Gardiner")]),
        "bad": opts([("speil", "Speil"), ("handkle", "Håndklær"), ("badekar", "Badekar"), ("plante", "Plante")]),
        "gang": opts([("knagger", "Knagger"), ("skohylle", "Skohylle"), ("speil", "Speil"), ("kommode", "Kommode"), ("plante", "Plante")]),
    ]
    var body: some View {
        let h = m.s.house
        VStack(alignment: .leading, spacing: 16) {
            OptionRow(title: "Vis") {
                Chip(label: "Utenfor", on: h.view != "inne") { m.s.house.view = "ute" }
                Chip(label: "Innendørs", on: h.view == "inne") { m.s.house.view = "inne" }
            }
            if h.view == "inne" { inside } else { outside }
            OptionRow(title: "Tid på døgnet") {
                Chip(label: "Dag", on: h.time == "dag") { m.s.house.time = "dag" }
                Chip(label: "Kveld", on: h.time == "kveld") { m.s.house.time = "kveld" }
            }
        }
    }

    var outside: some View {
        let h = m.s.house
        return VStack(alignment: .leading, spacing: 16) {
            OptionRow(title: "Hustype") {
                ForEach(opts([("klassisk", "Klassisk"), ("moderne", "Moderne"), ("villa", "Villa"), ("hytte", "Hytte"), ("byhus", "Byhus"), ("slott", "Slott")])) { t in
                    Chip(label: t.label, on: h.type == t.id) { m.s.house.type = t.id }
                }
            }
            OptionRow(title: "Vegg") { ForEach(Pal.wall + m.s.extra.wall, id: \.self) { c in Swatch(color: c, on: h.wall == c) { m.s.house.wall = c } } }
            OptionRow(title: "Tak") { ForEach(Pal.roof, id: \.self) { c in Swatch(color: c, on: h.roofColor == c) { m.s.house.roofColor = c } } }
            OptionRow(title: "Vinduskarmer") {
                Chip(label: "Hvite", on: h.trim == "hvit") { m.s.house.trim = "hvit" }
                Chip(label: "Svarte", on: h.trim == "svart") { m.s.house.trim = "svart" }
            }
            OptionRow(title: "Dør") { ForEach(Pal.door, id: \.self) { c in Swatch(color: c, on: h.door == c) { m.s.house.door = c } } }
            OptionRow(title: "Hage") {
                Chip(label: "Tre", on: h.garden.tre) { m.s.house.garden.tre.toggle() }
                Chip(label: "Hekk", on: h.garden.hekk) { m.s.house.garden.hekk.toggle() }
                Chip(label: "Blomsterbed", on: h.garden.bed) { m.s.house.garden.bed.toggle() }
                Chip(label: "Utelys", on: h.garden.lys) { m.s.house.garden.lys.toggle() }
                Chip(label: "Terrasse", on: h.garden.terrasse) { m.s.house.garden.terrasse.toggle() }
                Chip(label: "Bil", on: h.garden.bil) { m.s.house.garden.bil.toggle() }
                let lk = !m.s.unlocked.basseng
                Chip(label: "Basseng", on: h.garden.basseng, locked: lk, price: Shop.item("basseng")?.price) {
                    if lk { m.ask = "basseng" } else { m.s.house.garden.basseng.toggle() }
                }
            }
        }
    }

    var inside: some View {
        let rm = m.s.house.inne.rom, r = m.s.house.inne[rm]
        let mainLabel = ["stue": "Sofa", "soverom": "Sengetøy", "kjokken": "Skap", "bad": "Skap og håndklær", "gang": "Tekstiler"][rm] ?? "Møbler"
        let rugLabel = rm == "bad" ? "Badematte" : rm == "gang" ? "Dørmatte" : "Gulvteppe"
        let arts = opts([("none", "Ingen"), ("abstrakt", "Abstrakt"), ("landskap", "Landskap")]) + m.s.extra.art.enumerated().map { Opt(id: $0.element, label: "Kunst \($0.offset + 1)") }
        return VStack(alignment: .leading, spacing: 16) {
            OptionRow(title: "Rom") { ForEach(Self.rooms) { o in Chip(label: o.label, on: rm == o.id) { m.s.house.inne.rom = o.id } } }
            OptionRow(title: "Vegg") { ForEach(Pal.wallIn + m.s.extra.wall, id: \.self) { c in Swatch(color: c, on: r.wall == c) { m.s.house.inne[rm].wall = c } } }
            OptionRow(title: "Gulv") {
                ForEach(opts([("parkett", "Lys parkett"), ("mork", "Mørk parkett"), ("fliser", "Fliser"), ("teppe", "Teppe")])) { f in
                    Chip(label: f.label, on: r.floor == f.id) { m.s.house.inne[rm].floor = f.id }
                }
            }
            OptionRow(title: mainLabel) { ForEach(Pal.furn + m.s.extra.furn, id: \.self) { c in Swatch(color: c, on: r.main == c) { m.s.house.inne[rm].main = c } } }
            OptionRow(title: rugLabel) { ForEach(["none"] + Pal.furn + m.s.extra.furn, id: \.self) { c in Swatch(color: c, on: r.rug == c) { m.s.house.inne[rm].rug = c } } }
            if rm != "kjokken" && rm != "bad" {
                OptionRow(title: "Bilde på veggen") { ForEach(arts) { a in Chip(label: a.label, on: r.art == a.id) { m.s.house.inne[rm].art = a.id } } }
            }
            OptionRow(title: "Møbler og pynt") {
                ForEach(Self.items[rm] ?? []) { it in
                    Chip(label: it.label, on: r.has(it.id)) { m.s.house.inne[rm].items[it.id] = !r.has(it.id) }
                }
            }
        }
    }
}

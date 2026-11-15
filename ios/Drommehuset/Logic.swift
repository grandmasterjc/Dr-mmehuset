import Foundation

// Spillregler som ikke har med skjermen å gjøre: butikk, pakker og tilfeldig stil.

struct ShopItem { let id: String; let name: String; let price: Int }

enum Shop {
    static let items: [ShopItem] = [
        ShopItem(id: "rosa", name: "Rosa hårfarge", price: 40), ShopItem(id: "blaa", name: "Blå hårfarge", price: 40),
        ShopItem(id: "lue", name: "Strikkelue", price: 50), ShopItem(id: "solbriller", name: "Solbriller", price: 60),
        ShopItem(id: "gull", name: "Gullfarge til klærne", price: 70), ShopItem(id: "smykker", name: "Gullsmykker", price: 80),
        ShopItem(id: "veske", name: "Skinnveske", price: 90), ShopItem(id: "skinnjakke", name: "Skinnjakke", price: 120),
        ShopItem(id: "gallakjole", name: "Gallakjole", price: 150), ShopItem(id: "basseng", name: "Svømmebasseng", price: 250),
    ]
    static func item(_ id: String) -> ShopItem? { items.first { $0.id == id } }
}

struct GiftResult: Equatable {
    var good: Bool
    var title: String
    var text: String
    var swatch: String? = nil
    var face = false
}

func colName(_ h: Double, _ l: Double) -> String {
    (l < 42 ? "mørk" : l > 62 ? "lys" : "") + (h < 15 ? "rød" : h < 45 ? "oransje" : h < 70 ? "gul" : h < 160 ? "grønn" : h < 200 ? "turkis" : h < 255 ? "blå" : h < 290 ? "lilla" : h < 345 ? "rosa" : "rød")
}

extension GameState {
    var me: Look {
        get { people[cur] }
        set { people[cur] = newValue }
    }
    var feat: Feat { Feats.people[min(cur, Feats.people.count - 1)] }

    var clothColors: [String] { (unlocked.gull ? Pal.cloth + [Pal.gold] : Pal.cloth) + extra.cloth }
    var hairColors: [String] { Pal.hair + extra.hair }

    /// Låser opp og tar i bruk en ting. Brukes både når man kjøper og når man vinner.
    mutating func grant(_ id: String) {
        unlocked[id] = true
        switch id {
        case "solbriller": me.acc.solbriller = true
        case "smykker": me.acc.smykker = true
        case "veske": me.acc.veske = true
        case "lue": me.acc.lue = true
        case "skinnjakke": me.outer = "skinn"; me.outerColor = Pal.cloth[1]
        case "gallakjole": me.dress = "galla"
        case "rosa": me.hairColor = Pal.rosa
        case "blaa": me.hairColor = Pal.blaa
        case "gull": me.shoeColor = Pal.gold
        default: break
        }
    }

    /// Kjøp med mynter. Gir false hvis man ikke har råd.
    mutating func buy(_ id: String) -> Bool {
        guard let it = Shop.item(id), !unlocked[id], game.coins >= it.price else { return false }
        game.coins -= it.price
        grant(id)
        return true
    }

    mutating func need(_ k: String, _ d: Double) {
        func c(_ v: Double) -> Double { max(0, min(100, v + d)) }
        switch k {
        case "sult": game.needs.sult = c(game.needs.sult)
        case "energi": game.needs.energi = c(game.needs.energi)
        case "hygiene": game.needs.hygiene = c(game.needs.hygiene)
        default: game.needs.humor = c(game.needs.humor)
        }
    }

    // MARK: pakker
    static let good: [(String, String, String, Bool)] = [
        ("solbriller", "Designersolbriller", "Du har dem på nå. De ligger under Klær.", true),
        ("smykker", "Gullsmykker", "Øreringer og kjeder. De ligger under Klær.", true),
        ("veske", "En skinnveske", "Den ligger under Klær.", false),
        ("skinnjakke", "En skinnjakke", "Du har den på nå. Den ligger under Klær.", false),
        ("gallakjole", "En gallakjole", "Du har den på nå. Den ligger under Klær.", false),
        ("rosa", "Rosa hårfarge", "Du har den i håret nå. Den ligger under Hår.", true),
        ("blaa", "Blå hårfarge", "Du har den i håret nå. Den ligger under Hår.", true),
        ("lue", "En strikkelue", "Du har den på nå. Den ligger under Klær.", true),
        ("gull", "Gullfarge til klærne", "Skoene dine er gull nå. Fargen ligger under Klær.", false),
        ("basseng", "Et svømmebasseng", "Det blir satt opp i hagen når huset kommer i appen.", false),
    ]
    static let treats: [(String, String, Double, String)] = [
        ("En sjokoladeplate", "sult", 20, "Du ble litt mettere."), ("En energibar", "energi", 25, "Du fikk mer energi."),
        ("Et spa-sett", "hygiene", 35, "Du føler deg ren og fin."), ("En god bok", "humor", 25, "Humøret steg."),
        ("Kinobilletter", "humor", 35, "For en fin kveld."), ("En fruktkurv", "sult", 30, "Du ble mett."),
        ("En kopp kakao", "energi", 15, "Varmt og godt."), ("En spilleliste", "humor", 20, "Favorittmusikken din."),
    ]
    static let woes: [(String, String, Double, String)] = [
        ("Sur melk", "sult", -15, "Du mistet matlysten."), ("Bråkete nabo", "energi", -15, "Du sov dårlig."),
        ("Søle på skoene", "hygiene", -20, "Du må vaske deg."), ("Kjedelig reklame", "humor", -10, "Det var bare reklame i pakken."),
    ]

    var giftPrice: Int { 15 }

    /// Åpner en pakke. Gir nil hvis man ikke har råd.
    mutating func openGift<R: RandomNumberGenerator>(using r: inout R) -> GiftResult? {
        if game.free > 0 { game.free -= 1 } else if game.coins >= giftPrice { game.coins -= giftPrice } else { return nil }
        opened += 1
        if Double.random(in: 0..<1, using: &r) < 0.64 { return genGood(using: &r) }
        return genBad(using: &r)
    }

    mutating func genGood<R: RandomNumberGenerator>(using rg: inout R) -> GiftResult {
        let left = Self.good.filter { !unlocked[$0.0] }
        let r = Double.random(in: 0..<1, using: &rg)
        if !left.isEmpty && r < 0.2 {
            let q = left.randomElement(using: &rg)!
            grant(q.0)
            return GiftResult(good: true, title: q.1, text: q.2, face: q.3)
        }
        if r < 0.5 {
            var ks = ["cloth", "hair"].filter { (($0 == "cloth" ? extra.cloth : extra.hair).count) < 14 }
            if ks.isEmpty { ks = [] }
            if let k = ks.randomElement(using: &rg) {
                let h = Double.random(in: 0..<360, using: &rg), l = 32 + Double.random(in: 0..<40, using: &rg)
                let c = hsl(h, 40 + Double.random(in: 0..<35, using: &rg), l)
                if k == "cloth" {
                    extra.cloth.append(c)
                    if me.dress != "none" { me.dressColor = c } else { me.topColor = c }
                    return GiftResult(good: true, title: "Ny farge: " + colName(h, l), text: "En ny farge til klærne. Du har den på nå, og den ligger under Klær.", swatch: c)
                }
                extra.hair.append(c); me.hairColor = c
                return GiftResult(good: true, title: "Ny farge: " + colName(h, l), text: "En ny hårfarge. Du har den i håret nå.", swatch: c, face: true)
            }
        }
        if r < 0.8 {
            let c = 10 + 5 * Int.random(in: 0..<13, using: &rg)
            game.coins += c
            return GiftResult(good: true, title: "\(c) mynter", text: "Pengene er lagt i lommeboka.")
        }
        if r < 0.88 {
            let n = Double.random(in: 0..<1, using: &rg) < 0.3 ? 2 : 1
            game.free += n
            return GiftResult(good: true, title: n > 1 ? "To gratispakker" : "En gratispakke", text: n > 1 ? "De to neste pakkene koster ingenting." : "Den neste pakken koster ingenting.")
        }
        let t = Self.treats.randomElement(using: &rg)!
        need(t.1, t.2)
        return GiftResult(good: true, title: t.0, text: t.3)
    }

    mutating func genBad<R: RandomNumberGenerator>(using rg: inout R) -> GiftResult {
        let r = Double.random(in: 0..<1, using: &rg)
        if r < 0.42 {
            let b = [("flekk", "Kaffeflekk", "Du sølte kaffe på antrekket.", false), ("maskara", "Maskaraen rant", "Det ble svarte striper under øynene.", true),
                     ("frizz", "Dårlig hårdag", "Håret ble helt elektrisk.", true), ("", "Feil størrelse", "Plagget passet ikke. Det sendes i retur.", false)].randomElement(using: &rg)!
            if !b.0.isEmpty { me.oops = b.0 }
            return GiftResult(good: false, title: b.1, text: b.2, face: b.3)
        }
        if r < 0.6 && game.coins > 0 {
            let c = min(game.coins, 6 + Int.random(in: 0..<14, using: &rg))
            game.coins -= c
            return GiftResult(good: false, title: "En regning", text: "Du måtte betale \(c) mynter.")
        }
        if r < 0.86 {
            let t = Self.woes.randomElement(using: &rg)!
            need(t.1, t.2)
            return GiftResult(good: false, title: t.0, text: t.3)
        }
        return GiftResult(good: false, title: "Tom eske", text: "Det var ingenting i den.")
    }

    /// Tilfeldig stil for personen som er valgt.
    mutating func randomize<R: RandomNumberGenerator>(using r: inout R) {
        func pick<T>(_ a: [T]) -> T { a.randomElement(using: &r)! }
        var s = me
        s.lips = pick(Pal.lips + ["none"]); s.shadow = pick(Pal.shadow + ["none", "none"]); s.blush = pick(Pal.blush + ["none"])
        s.mascara = Double.random(in: 0..<1, using: &r) < 0.6; s.liner = Double.random(in: 0..<1, using: &r) < 0.3; s.gloss = Double.random(in: 0..<1, using: &r) < 0.4
        s.dress = pick(["none", "none", "none", "enkel", "sommer"]); s.dressColor = pick(Pal.cloth)
        s.top = pick(["tskjorte", "singlet", "skjorte", "genser", "hettegenser"]); s.topColor = pick(Pal.cloth)
        s.bottom = pick(["jeans", "vide", "shorts", "skjort", "midi"]); s.bottomColor = pick(Pal.cloth)
        s.outer = pick(["none", "none", "dongeri", "blazer"]); s.outerColor = pick(Pal.cloth)
        s.shoes = pick(["sneakers", "ballerina", "haeler", "boots"]); s.shoeColor = pick(Pal.cloth)
        s.hair = pick(["kort", "langt", "bolgete", "lob", "pannelugg", "hestehale", "knute", "fletter", "kroller"]); s.hairColor = pick(Pal.hair)
        s.acc.halskjede = Double.random(in: 0..<1, using: &r) < 0.4; s.acc.oredobber = Double.random(in: 0..<1, using: &r) < 0.4
        me = s
    }
}

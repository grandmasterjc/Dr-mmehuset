import Foundation

/// Tegninger (SVG) for Liv-modusens 2D-scener: ute, flyplass, reisemål, flyet, bilen, dyrebutikken.
/// Direkte overført fra nettversjonen, slik at bildene blir helt like.

/// Valg som styrer hva lifeScene viser (det som i nettversjonen lå i globale variabler).
struct SceneOpts {
    var flying: String? = nil
    var flyView = "cabin"
    /// tid i sekunder (brukes for at folk på gata skal gå i takt)
    var t = 0.0
    var driveIn = false
    var dirn = 1.0
    var beltMe = false
    var beltKid = false
    /// bilens hjul-rotasjon i grader (DR.ang i nettversjonen)
    var ang = 0.0
    /// styring: -1, 0 eller 1 (ix i driveStep)
    var steer = 0.0
    /// fart (DR.v)
    var v = 0.0
    /// true når bilen har kjørt: da tegnes det driveStep ellers ville satt inn i bildet
    var moving: Bool { ang != 0 || steer != 0 || v != 0 }
}

/// En person, et barn eller et dyr som er med på tur.
struct CrewMember {
    var name: String
    var i: Int? = nil
    var look: Look? = nil
    var feat: Feat? = nil
    var kid: Int? = nil
    var pet: Pet? = nil
}

/// Nøyaktig som JavaScripts toFixed (runder ut fra den eksakte verdien, halve bort fra null).
func tf(_ x: Double, _ d: Int) -> String {
    let neg = x < 0
    let a = abs(x)
    let full = String(format: "%.60f", a)
    let parts = full.split(separator: ".", omittingEmptySubsequences: false)
    var digits = Array(parts[0] + (d > 0 ? parts[1].prefix(d) : ""))
    let next = parts[1].dropFirst(d).first ?? "0"
    if next >= "5" {
        var i = digits.count - 1
        while i >= 0 {
            if digits[i] == "9" { digits[i] = "0"; i -= 1 } else { digits[i] = Character(String(digits[i].wholeNumberValue! + 1)); break }
        }
        if i < 0 { digits.insert("1", at: 0) }
    }
    let intLen = digits.count - d
    var o = String(digits[0..<intLen])
    if d > 0 { o += "." + String(digits[intLen...]) }
    return (neg ? "-" : "") + o
}

func esc(_ t: String) -> String {
    var o = ""
    for c in t {
        switch c {
        case "&": o += "&amp;"
        case "<": o += "&lt;"
        case ">": o += "&gt;"
        case "\"": o += "&quot;"
        default: o.append(c)
        }
    }
    return o
}

enum Scenes2D {
    // MARK: data
    static let lines = ["Så gøy at du kom!", "Liker du stilen min i dag?", "Skal vi lage mat hos deg neste gang?", "Jeg drømmer om å reise til Tokyo.", "Har du pusset opp hjemme?"]

    /// id → (navn, land, fakta, i Norge)
    static let destOrder = ["oslo", "bergen", "tromso", "lofoten", "preikestolen", "paris", "london", "roma", "newyork", "tokyo", "egypt"]
    static let dest: [String: (name: String, land: String, fact: String, norge: Bool)] = [
        "oslo": ("Oslo", "Norge", "Operahuset i Oslo. Du kan gå helt opp på taket.", true),
        "bergen": ("Bergen", "Norge", "Bryggen i Bergen står på UNESCOs verdensarvliste.", true),
        "tromso": ("Tromsø", "Norge", "Ishavskatedralen. Her kan du se nordlys om vinteren.", true),
        "lofoten": ("Lofoten", "Norge", "Lofoten er kjent for spisse fjell og røde rorbuer.", true),
        "preikestolen": ("Preikestolen", "Norge", "Preikestolen rager 604 meter over Lysefjorden.", true),
        "paris": ("Paris", "Frankrike", "Eiffeltårnet er rundt 330 meter høyt.", false),
        "london": ("London", "England", "Klokketårnet heter Elizabeth Tower. Selve klokken heter Big Ben.", false),
        "roma": ("Roma", "Italia", "Colosseum er nesten 2000 år gammelt.", false),
        "newyork": ("New York", "USA", "Frihetsgudinnen var en gave fra Frankrike.", false),
        "tokyo": ("Tokyo", "Japan", "Fuji er Japans høyeste fjell, 3776 meter.", false),
        "egypt": ("Giza", "Egypt", "Pyramidene i Giza er rundt 4500 år gamle.", false),
    ]

    struct Recipe { let key: String; let name: String; let ings: [String]; let lvl: Int }
    static let recipes: [Recipe] = [
        Recipe(key: "pannekaker", name: "Pannekaker", ings: ["Mel", "Egg", "Melk", "Smør"], lvl: 1),
        Recipe(key: "pizza", name: "Pizza", ings: ["Pizzadeig", "Tomatsaus", "Ost", "Skinke"], lvl: 1),
        Recipe(key: "taco", name: "Taco", ings: ["Tacoskjell", "Kjøttdeig", "Ost", "Salat"], lvl: 1),
        Recipe(key: "pasta", name: "Pasta med tomatsaus", ings: ["Pasta", "Tomatsaus", "Løk", "Ost"], lvl: 1),
        Recipe(key: "vafler", name: "Vafler", ings: ["Mel", "Egg", "Melk", "Sukker"], lvl: 2),
        Recipe(key: "omelett", name: "Omelett", ings: ["Egg", "Melk", "Ost", "Skinke"], lvl: 2),
        Recipe(key: "burger", name: "Burger", ings: ["Burgerbrød", "Kjøttdeig", "Ost", "Salat"], lvl: 3),
        Recipe(key: "suppe", name: "Tomatsuppe", ings: ["Tomater", "Løk", "Fløte", "Buljong"], lvl: 3),
        Recipe(key: "kjottkaker", name: "Kjøttkaker", ings: ["Kjøttdeig", "Løk", "Poteter", "Brun saus"], lvl: 4),
        Recipe(key: "frukt", name: "Fruktsalat", ings: ["Banan", "Eple", "Jordbær", "Druer"], lvl: 4),
        Recipe(key: "laks", name: "Laks med poteter", ings: ["Laks", "Poteter", "Smør", "Sitron"], lvl: 5),
        Recipe(key: "wok", name: "Wok", ings: ["Nudler", "Kylling", "Paprika", "Soyasaus"], lvl: 5),
        Recipe(key: "kake", name: "Sjokoladekake", ings: ["Mel", "Egg", "Sukker", "Sjokolade"], lvl: 6),
    ]
    static func recipe(_ k: String) -> Recipe? { recipes.first { $0.key == k } }
    static let allIngredients: [String] = recipes.reduce(into: ["Fiskepinner"]) { a, r in for n in r.ings where !a.contains(n) { a.append(n) } }

    static let dishX: [String: String] = [
        "vafler": ##"<ellipse cx="60" cy="45" rx="34" ry="12" fill="#dba54e"/><path d="M30 45h60M60 33v24M40 38l40 14M80 38l-40 14" stroke="#b9822f" stroke-width="2"/><circle cx="60" cy="43" r="5" fill="#c4313f"/>"##,
        "omelett": ##"<path d="M26 48Q60 20 94 48Q60 58 26 48Z" fill="#f2cf5b" stroke="#d9a93a"/><circle cx="50" cy="44" r="3" fill="#d9808a"/><circle cx="66" cy="42" r="3" fill="#d9808a"/><circle cx="58" cy="48" r="2" fill="#5d9a52"/>"##,
        "burger": ##"<ellipse cx="60" cy="52" rx="28" ry="7" fill="#d9a55a"/><ellipse cx="60" cy="47" rx="30" ry="6" fill="#5d9a52"/><ellipse cx="60" cy="43" rx="28" ry="6" fill="#6b3f22"/><rect x="33" y="37" width="54" height="4" fill="#f2c94c"/><path d="M32 38Q60 10 88 38Z" fill="#dba54e"/>"##,
        "suppe": ##"<ellipse cx="60" cy="44" rx="34" ry="12" fill="#fbfaf7" stroke="#b9b2a6"/><ellipse cx="60" cy="44" rx="28" ry="9" fill="#d9482f"/><path d="M50 43Q58 38 68 44" stroke="#fbfaf7" stroke-width="2.5" fill="none"/>"##,
        "kjottkaker": ##"<ellipse cx="60" cy="48" rx="34" ry="10" fill="#6b4423" opacity=".5"/><circle cx="46" cy="42" r="9" fill="#6b3f22"/><circle cx="62" cy="46" r="9" fill="#7a4a2a"/><circle cx="78" cy="42" r="7" fill="#e9d9a0"/><circle cx="72" cy="52" r="6" fill="#e9d9a0"/>"##,
        "frukt": [(44, 44, "#c4313f"), (54, 40, "#f2d94c"), (64, 45, "#7a4a9a"), (74, 41, "#5d9a52"), (50, 50, "#f2d94c"), (60, 52, "#c4313f"), (70, 50, "#7a4a9a"), (58, 45, "#e9813c")].map { ##"<circle cx="\##($0.0)" cy="\##($0.1)" r="6" fill="\##($0.2)"/>"## }.joined(),
        "laks": ##"<path d="M30 44Q52 30 78 40Q70 54 34 52Z" fill="#f08a6c"/><path d="M40 42l28 2M38 47l26 2" stroke="#fbd0c0"/><circle cx="84" cy="50" r="6" fill="#e9d9a0"/><circle cx="74" cy="54" r="5" fill="#e9d9a0"/><circle cx="44" cy="34" r="6" fill="#f2d94c"/>"##,
        "wok": ##"<g fill="none" stroke="#e3c27a" stroke-width="3" stroke-linecap="round"><path d="M32 48Q46 32 60 46T88 44"/><path d="M34 54Q50 42 62 52T86 52"/></g><circle cx="46" cy="42" r="4" fill="#c4313f"/><circle cx="62" cy="40" r="4" fill="#5d9a52"/><circle cx="74" cy="46" r="4" fill="#e9813c"/><circle cx="54" cy="50" r="4" fill="#d9b58a"/>"##,
        "kake": ##"<path d="M36 52L36 34L84 34L84 52Z" fill="#5a3320"/><rect x="36" y="41" width="48" height="3" fill="#f3e3c3"/><path d="M36 34Q60 26 84 34Z" fill="#3d2214"/><circle cx="60" cy="29" r="4" fill="#c4313f"/>"##,
    ]

    /// Stuene hos vennene (når 3D ikke er i bruk).
    static let friendRooms: [Room] = [
        ("#e9cfd0", "parkett", "#8c8f96", "#f4f1ea", "landskap", true, false), ("#e7ddd0", "mork", "#c9a227", "#9b3b47", "abstrakt", true, true),
        ("#cfd9e3", "parkett", "#f4f1ea", "#34507a", "landskap", false, true), ("#8a9a84", "teppe", "#d8c3a5", "none", "abstrakt", true, false),
        ("#f4f1ea", "mork", "#34507a", "#c9a227", "landskap", true, true), ("#e7ddd0", "parkett", "#9b3b47", "#d8c3a5", "abstrakt", false, true),
    ].map { Room(wall: $0.0, floor: $0.1, main: $0.2, rug: $0.3, art: $0.4, items: ["plante": true, "lampe": true, "bord": true, "tv": $0.5, "bokhylle": $0.6, "gardiner": true]) }

    static let stops: [(key: String, x: Double, name: String)] = [("home", 300, "Hjem"), ("friends", 1100, "Vennene"), ("petshop", 1900, "Dyrebutikken"), ("airport", 2800, "Flyplassen")]

    // MARK: familie og naboer
    private static func mk(_ f: (inout Look) -> Void) -> Look { var l = Look(); f(&l); return l }
    static let famOrder = ["mamma", "pappa", "bestemor", "bestefar"]
    static let fam: [String: (Look, Feat)] = {
        let S = Pal.skin, E = Pal.eyes, H = Pal.hair, C = Pal.cloth, L = Pal.lips
        return [
            "mamma": (mk { $0.name = "Mamma"; $0.skin = S[1]; $0.eyes = E[3]; $0.hair = "lob"; $0.hairColor = H[2]; $0.lips = L[0]; $0.mascara = true; $0.top = "skjorte"; $0.topColor = C[0]; $0.outer = "blazer"; $0.outerColor = C[4]; $0.bottom = "vide"; $0.bottomColor = C[1]; $0.shoes = "haeler"; $0.shoeColor = C[1] },
                      Feat(face: "oval", er: 0, es: 0.95, lip: 1, bx: 1.04, h: 1)),
            "pappa": (mk { $0.name = "Pappa"; $0.skin = S[1]; $0.eyes = E[0]; $0.hair = "kort"; $0.hairColor = H[1]; $0.top = "skjorte"; $0.topColor = C[5]; $0.bottom = "jeans"; $0.bottomColor = C[4]; $0.shoes = "boots"; $0.shoeColor = C[1] },
                      Feat(face: "kantet", er: 2, es: 0.85, lip: 0.75, bx: 1.14, h: 1.05)),
            "bestemor": (mk { $0.name = "Bestemor"; $0.skin = S[0]; $0.eyes = E[4]; $0.hair = "knute"; $0.hairColor = "#c9c6c0"; $0.lips = L[1]; $0.top = "genser"; $0.topColor = C[7]; $0.bottom = "midi"; $0.bottomColor = C[2]; $0.shoes = "ballerina"; $0.shoeColor = C[1]; $0.acc.oredobber = true; $0.acc.halskjede = true },
                         Feat(face: "rund", er: -2, es: 0.9, lip: 0.9, bx: 1.08, h: 0.93)),
            "bestefar": (mk { $0.name = "Bestefar"; $0.skin = S[1]; $0.eyes = E[4]; $0.hair = "kort"; $0.hairColor = "#b9b6b0"; $0.top = "genser"; $0.topColor = C[8]; $0.bottom = "vide"; $0.bottomColor = C[2]; $0.shoes = "boots"; $0.shoeColor = C[1] },
                         Feat(face: "kantet", er: 1, es: 0.85, lip: 0.75, bx: 1.12, h: 0.98)),
        ]
    }()

    /// Naboene (vises etter vennene, som venn nummer NP, NP+1 ...).
    static let neighbours: [(Look, Feat)] = {
        let S = Pal.skin, E = Pal.eyes, H = Pal.hair, C = Pal.cloth, L = Pal.lips
        return [
            (mk { $0.name = "Ingrid"; $0.skin = S[0]; $0.eyes = E[2]; $0.hair = "pannelugg"; $0.hairColor = H[6]; $0.lips = L[2]; $0.top = "genser"; $0.topColor = C[8]; $0.bottom = "jeans"; $0.bottomColor = C[5]; $0.shoes = "boots"; $0.shoeColor = C[3] },
             Feat(face: "oval", er: -3, es: 1, lip: 1.1, bx: 1, h: 0.97)),
            (mk { $0.name = "Henrik"; $0.skin = S[3]; $0.eyes = E[0]; $0.hair = "kort"; $0.hairColor = H[0]; $0.top = "hettegenser"; $0.topColor = C[2]; $0.bottom = "jeans"; $0.bottomColor = C[1]; $0.shoes = "sneakers"; $0.shoeColor = C[0] },
             Feat(face: "kantet", er: 2, es: 0.86, lip: 0.78, bx: 1.14, h: 1.05)),
            (mk { $0.name = "Kari"; $0.skin = S[0]; $0.eyes = E[4]; $0.hair = "knute"; $0.hairColor = "#c9c6c0"; $0.lips = L[1]; $0.top = "genser"; $0.topColor = C[7]; $0.bottom = "midi"; $0.bottomColor = C[2]; $0.shoes = "ballerina"; $0.shoeColor = C[1]; $0.acc.oredobber = true; $0.acc.halskjede = true },
             Feat(face: "rund", er: -1, es: 0.9, lip: 0.9, bx: 1.08, h: 0.93)),
            (mk { $0.name = "Ahmed"; $0.skin = S[3]; $0.eyes = E[0]; $0.hair = "kort"; $0.hairColor = H[0]; $0.top = "skjorte"; $0.topColor = C[5]; $0.outer = "blazer"; $0.outerColor = C[1]; $0.bottom = "vide"; $0.bottomColor = C[1]; $0.shoes = "boots"; $0.shoeColor = C[1] },
             Feat(face: "kantet", er: 1, es: 0.86, lip: 0.8, bx: 1.15, h: 1.06)),
            (mk { $0.name = "Sara"; $0.skin = S[2]; $0.eyes = E[2]; $0.hair = "kroller"; $0.hairColor = H[1]; $0.lips = L[0]; $0.top = "tskjorte"; $0.topColor = C[9]; $0.bottom = "skjort"; $0.bottomColor = C[8]; $0.shoes = "sneakers"; $0.shoeColor = C[0] },
             Feat(face: "oval", er: -3, es: 1.04, lip: 1.2, bx: 0.98, h: 0.96)),
        ]
    }()

    static func feat(_ i: Int) -> Feat { Feats.people[min(max(0, i), Feats.people.count - 1)] }
    static func hostLook(_ st: GameState, _ i: Int) -> (Look, Feat) {
        i < st.people.count ? (st.people[i], feat(i)) : neighbours[min(i - st.people.count, neighbours.count - 1)]
    }
    static func me(_ st: GameState) -> Look { st.people[st.cur] }
    static func girl(_ st: GameState) -> String { fig(me(st), feat(st.cur)) }
    /// Voksen figur slik girl() tegner den i nettversjonen (uten skyggen under føttene, som Figure.svg() legger til).
    static func fig(_ l: Look, _ f: Feat) -> String {
        let sh = "<ellipse cx=\"150\" cy=\"598\" rx=\"74\" ry=\"6\" fill=\"#000\" opacity=\".12\"/>"
        let o = Figure(s: l, f: f).svg()
        return o.hasPrefix(sh) ? String(o.dropFirst(sh.count)) : o
    }

    // MARK: små hjelpere
    static func wt(_ x: Double, _ sc: Double, _ fy: Double, _ bob: Double) -> String {
        "translate(\(tf(x - 150 * sc, 1)) \(tf(fy - 598 * sc + bob, 1))) scale(\(js(sc)))"
    }
    static func walkerG(_ st: GameState, _ x: Double, _ sc0: Double, _ fy: Double) -> String {
        let sc = sc0 * feat(st.cur).h
        return ##"<g id="walker" data-sc="\##(js(sc))" data-fy="\##(js(fy))" transform="\##(wt(x, sc, fy, 0))">\##(girl(st))</g>"##
    }
    static func sc0(_ sky: [String], _ label: String) -> String {
        ##"<svg viewBox="0 0 640 400" preserveAspectRatio="xMidYMax meet" role="img" aria-label="\##(label)"><defs><linearGradient id="sky" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="300"><stop offset="0" stop-color="\##(sky[0])"/><stop offset="1" stop-color="\##(sky[1])"/></linearGradient></defs>\##(GDEFS)<rect x="-640" y="-600" width="1920" height="1000" fill="url(#sky)"/>"##
    }
    static func gr(_ c: String, _ y: Double) -> String { ##"<rect x="-640" y="\##(js(y))" width="1920" height="400" fill="\##(c)"/>"## }
    static func plane(_ x: Double, _ y: Double, _ k: Double) -> String {
        var o = ##"<g transform="translate(\##(js(x)) \##(js(y))) scale(\##(js(k)))"><path d="M-10 4L-44 42L-20 42L26 6Z" fill="#c9ced3"/><ellipse cx="2" cy="24" rx="13" ry="6" fill="#8c8f96"/><path d="M-88 -10L-106 -46L-84 -46L-60 -14Z" fill="#a8455f"/><path d="M-92 0Q-92 -14 -60 -14L60 -14Q96 -12 106 0Q96 11 60 12L-60 12Q-92 12 -92 0Z" fill="#fbfaf7" stroke="#9aa0a8"/>"##
        o += [-52, -40, -28, -16, -4, 8, 20, 32, 44, 56].map { ##"<circle cx="\##($0)" cy="-4" r="2.6" fill="#5f87ad"/>"## }.joined()
        o += ##"<path d="M76 -9L94 -3L78 -2Z" fill="#5f87ad"/><path d="M-92 2L-112 -6L-112 6Z" fill="#c9ced3"/></g>"##
        return o
    }
    static func tower(_ c: String) -> String {
        ##"<path d="M262 300Q306 220 314 70L326 70Q334 220 378 300L352 300Q340 262 320 258Q300 262 288 300Z" fill="\##(c)"/><rect x="286" y="222" width="68" height="8" fill="\##(c)"/><rect x="300" y="158" width="40" height="6" fill="\##(c)"/><rect x="318.5" y="38" width="3" height="34" fill="\##(c)"/><path d="M296 230L344 290M344 230L296 290M306 164L334 222M334 164L306 222" stroke="#fff" opacity=".25"/>"##
    }

    // MARK: dyr
    static func petSVG(_ t: String, _ c: String, _ x: Double, _ y: Double, _ k: Double) -> String {
        let d = shade(c, -0.25), l = shade(c, 0.3)
        let eye = ##"<circle cx="-9" cy="-50" r="3.6" fill="#1d1020"/><circle cx="9" cy="-50" r="3.6" fill="#1d1020"/><circle cx="-8" cy="-51" r="1.1" fill="#fff"/><circle cx="10" cy="-51" r="1.1" fill="#fff"/>"##
        var o = ##"<g transform="translate(\##(js(x)) \##(js(y))) scale(\##(js(k)))">"##
        if t == "katt" {
            o += ##"<path d="M34 16Q72 8 60 -36" stroke="\##(c)" stroke-width="11" fill="none" stroke-linecap="round"/><ellipse cx="0" cy="2" rx="38" ry="34" fill="\##(c)"/><path d="M-22 -60L-20 -88L-3 -70ZM22 -60L20 -88L3 -70Z" fill="\##(c)"/><circle cx="0" cy="-48" r="27" fill="\##(c)"/>\##(eye)<path d="M-3.5 -42L3.5 -42L0 -37Z" fill="#d98a8f"/><path d="M-12 -39L-32 -43M-12 -36L-32 -34M12 -39L32 -43M12 -36L32 -34" stroke="#0005"/><ellipse cx="-14" cy="32" rx="11" ry="6" fill="\##(l)"/><ellipse cx="14" cy="32" rx="11" ry="6" fill="\##(l)"/>"##
        } else if t == "hund" {
            let e2 = eye.replacingOccurrences(of: "-50", with: "-57").replacingOccurrences(of: "-51", with: "-58")
            o += ##"<path d="M34 6Q58 -6 54 -34" stroke="\##(c)" stroke-width="10" fill="none" stroke-linecap="round"/><ellipse cx="0" cy="0" rx="42" ry="37" fill="\##(c)"/><circle cx="0" cy="-52" r="29" fill="\##(c)"/><ellipse cx="-28" cy="-48" rx="10" ry="22" fill="\##(d)" transform="rotate(14 -28 -48)"/><ellipse cx="28" cy="-48" rx="10" ry="22" fill="\##(d)" transform="rotate(-14 28 -48)"/><ellipse cx="0" cy="-42" rx="15" ry="11" fill="\##(l)"/>\##(e2)<ellipse cx="0" cy="-47" rx="5" ry="3.6" fill="#1d1020"/><path d="M-4 -38Q0 -28 4 -38Z" fill="#d9606a"/><ellipse cx="-16" cy="34" rx="12" ry="6.5" fill="\##(l)"/><ellipse cx="16" cy="34" rx="12" ry="6.5" fill="\##(l)"/>"##
        } else {
            o += ##"<circle cx="36" cy="14" r="10" fill="#fbfaf7"/><ellipse cx="0" cy="4" rx="36" ry="32" fill="\##(c)"/><ellipse cx="-11" cy="-88" rx="7.5" ry="27" fill="\##(c)"/><ellipse cx="11" cy="-88" rx="7.5" ry="27" fill="\##(c)"/><ellipse cx="-11" cy="-88" rx="3.5" ry="20" fill="#e9b8bd"/><ellipse cx="11" cy="-88" rx="3.5" ry="20" fill="#e9b8bd"/><circle cx="0" cy="-46" r="25" fill="\##(c)"/>\##(eye)<path d="M-3 -41L3 -41L0 -37Z" fill="#d98a8f"/><path d="M0 -37L0 -33M-10 -38L-28 -40M10 -38L28 -40" stroke="#0005"/><ellipse cx="-13" cy="32" rx="10" ry="6" fill="\##(l)"/><ellipse cx="13" cy="32" rx="10" ry="6" fill="\##(l)"/>"##
        }
        return o + "</g>"
    }

    static func petShopSVG(_ st: GameState, _ extra: String = "") -> (String, String) {
        let sh = st.life.shop
        let cols = ["#c9736b", "#5d7a5e", "#c9a227", "#34507a"]
        var o = sc0(["#e7ddd0", "#e7ddd0"], "Dyrebutikken") + gr("#c9a271", 300)
        o += ##"<rect x="-640" y="292" width="1920" height="8" fill="#f6f4ef"/><rect x="220" y="44" width="200" height="40" rx="6" fill="#34507a"/><text x="320" y="70" text-anchor="middle" font-family="Jost,sans-serif" font-size="17" font-weight="600" letter-spacing="3" fill="#fbfaf7">DYREBUTIKK</text>"##
        o += ##"<rect x="456" y="120" width="150" height="172" fill="#8a6a4a"/>"##
        o += (0..<3).map { r in ##"<rect x="462" y="\##(126 + r * 56)" width="138" height="50" fill="#6b4f36"/>"## + (0..<4).map { i in ##"<rect x="\##(468 + i * 33)" y="\##(140 + r * 56)" width="26" height="36" rx="3" fill="\##(cols[(i + r) % 4])"/>"## }.joined() }.joined()
        o += ##"<rect x="40" y="150" width="120" height="90" rx="6" fill="#cfe3ec" stroke="#8c8f96" stroke-width="3"/><path d="M40 210Q70 196 100 210T160 208L160 240L40 240Z" fill="#7fb8d6"/><path d="M84 190l14 8l-14 8z M100 198h8" fill="#e9813c" stroke="#e9813c"/><rect x="52" y="240" width="96" height="52" fill="#8a6a4a"/>"##
        o += ##"<ellipse cx="320" cy="300" rx="92" ry="16" fill="#9b3b47"/><ellipse cx="320" cy="296" rx="82" ry="12" fill="#b5536c"/>"## + petSVG(sh.type, sh.color, 320, 262, 1.05)
        return (o + extra + "</svg>", "#e7ddd0")
    }

    // MARK: reisemål
    static func destSVG(_ id: String, _ extra: String = "") -> (String, String) {
        let day = ["#8fc1ea", "#e6f1f8"]
        var sky = day, b = ""
        if id == "oslo" {
            b = ##"<path d="M-640 300Q-200 250 100 290T1280 280L1280 300Z" fill="#4f7a57"/>"## + gr("#5f8fb3", 300) + ##"<rect x="426" y="168" width="126" height="46" fill="#e6e6e2"/><path d="M60 322L560 196L560 322Z" fill="#f4f4f1"/><path d="M330 322L330 262L544 208L544 322Z" fill="#9db9cc"/><path d="M370 252L370 322M410 242L410 322M450 232L450 322M490 222L490 322M530 212L530 322" stroke="#f4f4f1" stroke-width="2"/>"## + gr("#cfcac1", 340)
        } else if id == "bergen" {
            b = ##"<path d="M-640 300Q100 110 320 200Q500 120 1280 300Z" fill="#4f7a57"/>"##
            for (i, c) in ["#a8362e", "#d9a441", "#f1ece0", "#a8362e", "#c9772e", "#7a4a33", "#d9a441"].enumerated() {
                let x = 68 + i * 72, hh = 112 + (i % 2) * 12, y = 300 - hh
                b += ##"<rect x="\##(x)" y="\##(y)" width="66" height="\##(hh)" fill="\##(c)"/><path d="M\##(x - 2) \##(y)L\##(x + 33) \##(y - 34)L\##(x + 68) \##(y)Z" fill="\##(shade(c, -0.2))"/>"##
                for r in 0..<3 { for k in 0..<3 { b += ##"<rect x="\##(x + 9 + k * 18)" y="\##(y + 12 + r * 26)" width="11" height="15" fill="#fbfaf7" stroke="#0004"/>"## } }
                b += ##"<rect x="\##(x + 25)" y="\##(300 - 24)" width="16" height="24" fill="\##(shade(c, -0.45))"/>"##
            }
            b += gr("#8f8b85", 300)
        } else if id == "tromso" {
            sky = ["#0c1a3a", "#1f4a5c"]
            b = ##"<g fill="none" stroke="#6ff0b0" stroke-linecap="round" filter="url(#b2)"><path d="M-80 130Q160 20 320 110T760 80" stroke-width="26" opacity=".3"/><path d="M-60 80Q200 0 380 70T760 30" stroke-width="16" opacity=".22"/></g>"##
            b += [(60, 40), (150, 90), (240, 30), (420, 50), (520, 24), (600, 100), (330, 20)].map { ##"<circle cx="\##($0.0)" cy="\##($0.1)" r="1.1" fill="#fff"/>"## }.joined()
            b += ##"<path d="M-640 300L-200 220L40 180L150 240L300 170L460 250L560 190L800 260L1280 300Z" fill="#aebfd0"/>"##
            b += ##"<path d="M196 300L320 84L444 300Z" fill="#f4f6f8"/><path d="M222 300L320 128M248 300L320 172M418 300L320 128M392 300L320 172" stroke="#c5cfd8" stroke-width="2"/><path d="M300 300L320 112L340 300Z" fill="#f2d48a"/>"## + gr("#e8eef3", 300)
        } else if id == "lofoten" {
            b = ##"<path d="M-640 300L-100 300L40 150L90 210L170 90L240 200L300 130L380 230L450 110L540 220L600 160L760 300Z" fill="#55657a"/><path d="M170 90L150 122L170 114L186 126ZM450 110L432 140L450 132L466 144ZM40 150L26 172L42 166L54 176Z" fill="#f4f6f8"/>"## + gr("#3f6f8c", 300)
            for x in [110, 250, 410] {
                b += ##"<path d="M\##(x + 6) 300L\##(x + 6) 322M\##(x + 34) 300L\##(x + 34) 322M\##(x + 62) 300L\##(x + 62) 322" stroke="#4e4238" stroke-width="3"/><rect x="\##(x)" y="262" width="70" height="38" fill="#b03a30"/><path d="M\##(x - 4) 264L\##(x + 35) 240L\##(x + 74) 264Z" fill="#33363b"/><rect x="\##(x + 10)" y="272" width="14" height="14" fill="#fbfaf7" stroke="#0004"/><rect x="\##(x + 44)" y="272" width="14" height="14" fill="#fbfaf7" stroke="#0004"/>"##
            }
            b += gr("#7d7a72", 332)
        } else if id == "preikestolen" {
            b = ##"<path d="M-640 262L80 262L220 180L330 230L470 160L640 240L1280 200L1280 300L-640 300Z" fill="#7f95a6"/>"## + gr("#4c7c9c", 262) + ##"<path d="M300 262L420 252L560 262Z" fill="#fff" opacity=".2"/><path d="M-640 400L-640 330L436 330L452 352L440 400Z" fill="#8f8a80"/><path d="M-640 330L436 330L442 338L-640 338Z" fill="#b5b0a6"/><path d="M120 338L112 400M300 338L318 400" stroke="#000" opacity=".15"/>"##
        } else if id == "paris" {
            func bl(_ x: Int) -> String {
                let a = ##"<rect x="\##(x)" y="222" width="150" height="78" fill="#e2d6c2"/><rect x="\##(x)" y="208" width="150" height="16" fill="#6d747b"/>"##
                let c: String = (0..<6).map { k in ##"<rect x="\##(x + 12 + k * 23)" y="236" width="10" height="18" fill="#7d8a94"/><rect x="\##(x + 12 + k * 23)" y="266" width="10" height="18" fill="#7d8a94"/>"## }.joined()
                return a + c
            }
            b = bl(-60) + bl(96) + bl(410) + bl(566) + tower("#6b5a4a") + gr("#cfc8b8", 300) + ##"<circle cx="60" cy="286" r="20" fill="#4f8a4a"/><circle cx="580" cy="286" r="20" fill="#4f8a4a"/>"##
        } else if id == "london" {
            sky = ["#9fb7cc", "#e6ecf0"]
            b = ##"<rect x="330" y="206" width="252" height="94" fill="#c9b48a"/>"## + [340, 372, 404, 436, 468, 500, 532, 564].map { x in ##"<rect x="\##(x)" y="188" width="7" height="18" fill="#b39f78"/><rect x="\##(x - 2)" y="220" width="11" height="64" fill="#8f7d5c"/>"## }.joined()
            b += ##"<rect x="270" y="96" width="44" height="204" fill="#c9b48a"/><path d="M280 150L280 300M292 150L292 300M304 150L304 300" stroke="#8f7d5c" opacity=".6"/><rect x="266" y="90" width="52" height="8" fill="#5c5a55"/><path d="M270 90L292 38L314 90Z" fill="#5c5a55"/><circle cx="292" cy="124" r="15" fill="#fbfaf7" stroke="#33363b" stroke-width="2"/><path d="M292 124L292 114M292 124L299 127" stroke="#33363b" stroke-width="2" stroke-linecap="round"/>"##
            b += gr("#6f8799", 300) + gr("#b9b2a6", 338) + ##"<rect x="64" y="290" width="116" height="48" rx="6" fill="#c4313f"/><path d="M72 298h100v12h-100zM72 316h76v10h-76z" fill="#dfe8ee"/><circle cx="90" cy="340" r="8" fill="#1d1f23"/><circle cx="156" cy="340" r="8" fill="#1d1f23"/>"##
        } else if id == "roma" {
            sky = ["#8fc1ea", "#f6ead2"]
            b = ##"<path d="M170 300L170 128L400 128L400 176L482 176L482 300Z" fill="#cdb48c"/>"##
            for r in [(146, 392), (196, 470), (246, 470)] {
                var x = 182
                while x + 22 < r.1 { b += ##"<rect x="\##(x)" y="\##(r.0)" width="22" height="38" rx="11" fill="#7a644a"/>"##; x += 34 }
            }
            b += ##"<path d="M170 138L400 138M170 188L482 188M170 238L482 238" stroke="#b39b72" stroke-width="3"/>"## + gr("#d9c9a5", 300)
            b += [70, 570].map { x in ##"<rect x="\##(x - 3)" y="210" width="6" height="92" fill="#6b4a35"/><ellipse cx="\##(x)" cy="206" rx="40" ry="16" fill="#3f6b52"/>"## }.joined()
        } else if id == "newyork" {
            b = gr("#5b86a8", 300)
            for q in [(210, 120, "#7d8a94"), (252, 176, "#56707f"), (298, 140, "#8c8f96"), (340, 236, "#6d747b"), (388, 160, "#56707f"), (432, 196, "#7d8a94"), (480, 130, "#8c8f96"), (524, 156, "#6d747b"), (568, 110, "#56707f")] {
                b += ##"<rect x="\##(q.0)" y="\##(300 - q.1)" width="40" height="\##(q.1)" fill="\##(q.2)"/>"##
                var x = q.0 + 8
                while x < q.0 + 38 { b += ##"<path d="M\##(x) \##(306 - q.1)L\##(x) 296" stroke="#f2e6b0" stroke-width="3" stroke-dasharray="3 6" opacity=".55"/>"##; x += 12 }
            }
            b += ##"<rect x="356" y="38" width="8" height="28" fill="#6d747b"/><ellipse cx="110" cy="302" rx="56" ry="7" fill="#7d7a72"/><rect x="84" y="284" width="52" height="16" fill="#b9b2a6"/><rect x="94" y="232" width="32" height="54" fill="#c9c2b6"/>"##
            b += ##"<path d="M99 232L103 176Q110 164 117 176L121 232Z" fill="#6fae9c"/><circle cx="110" cy="162" r="7.5" fill="#6fae9c"/><path d="M102 158L100 148L106 155L110 145L114 155L120 148L118 158Z" fill="#6fae9c"/><path d="M115 176L128 134" stroke="#6fae9c" stroke-width="6" stroke-linecap="round"/><rect x="125" y="124" width="6" height="12" fill="#6fae9c"/><circle cx="128" cy="120" r="5" fill="#f2c94c"/>"## + gr("#b9b5ae", 340)
        } else if id == "tokyo" {
            sky = ["#bcd3ee", "#fbe3e6"]
            b = ##"<path d="M110 300L300 110Q320 100 340 110L530 300Z" fill="#6f86b3"/><path d="M258 152L300 110Q320 100 340 110L382 152L360 140L342 158L320 138L298 158L280 142Z" fill="#fbfaf7"/>"##
            b += ##"<g transform="translate(390 148) scale(.5)">\##(tower("#d9482f"))<rect x="298" y="150" width="44" height="14" fill="#fbfaf7"/></g>"## + gr("#b7c9a8", 300)
            b += ##"<path d="M84 300Q88 250 76 220M84 262Q100 240 118 232" stroke="#5a3a32" stroke-width="7" fill="none" stroke-linecap="round"/>"##
            b += [(70, 206, 30), (104, 196, 26), (126, 222, 22), (48, 228, 22), (88, 176, 22)].enumerated().map { i, q in ##"<circle cx="\##(q.0)" cy="\##(q.1)" r="\##(q.2)" fill="\##(i % 2 == 1 ? "#f9d0dc" : "#f4b6c8")"/>"## }.joined()
        } else {
            sky = ["#f2c98a", "#fbe8c4"]
            b = ##"<circle cx="520" cy="80" r="26" fill="#fff3c4"/><path d="M330 300L450 180L570 300Z" fill="#d9b574"/><path d="M450 180L570 300L494 300Z" fill="#b8934f"/><path d="M110 300L250 146L390 300Z" fill="#dfbc7c"/><path d="M250 146L390 300L304 300Z" fill="#bd9854"/><path d="M20 300L84 236L148 300Z" fill="#d9b574"/><path d="M84 236L148 300L108 300Z" fill="#b8934f"/>"##
            b += gr("#e2c48d", 300) + ##"<path d="M600 302Q596 250 606 214" stroke="#6b4a35" stroke-width="6" fill="none"/><path d="M606 214Q580 196 560 210M606 214Q590 186 572 184M606 214Q612 186 632 186M606 214Q628 200 644 214" stroke="#3f6b52" stroke-width="6" fill="none" stroke-linecap="round"/>"##
        }
        return (sc0(sky, dest[id]?.name ?? id) + b + extra + "</svg>", sky[0])
    }

    // MARK: flyplass og fly
    static func airportSVG(_ extra: String = "") -> (String, String) {
        var o = sc0(["#e9eaec", "#e9eaec"], "Flyplassen") + ##"<rect x="40" y="86" width="364" height="190" fill="#bfe0f5"/><rect x="40" y="236" width="364" height="40" fill="#9aa0a8"/>"## + plane(210, 214, 0.9)
        o += ##"<path d="M40 86h364v190h-364zM161 86v190M283 86v190" fill="none" stroke="#f6f4ef" stroke-width="6"/><rect x="430" y="66" width="184" height="160" rx="6" fill="#17181b"/><text x="444" y="90" font-family="Jost,sans-serif" font-size="12" font-weight="600" letter-spacing="2" fill="#f2c94c">AVGANGER</text>"##
        for (i, d) in [("Bergen", "09:15"), ("Tromsø", "10:40"), ("Paris", "11:05"), ("London", "12:30"), ("Tokyo", "13:55"), ("New York", "15:10")].enumerated() {
            o += ##"<text x="444" y="\##(112 + i * 19)" font-family="Jost,sans-serif" font-size="12" fill="#f4f1ea">\##(d.1)   \##(d.0)</text>"##
        }
        o += gr("#cdd0d5", 306) + ##"<path d="M-640 320L1280 320" stroke="#fff" opacity=".4" stroke-width="3"/><rect x="448" y="258" width="150" height="50" fill="#34507a"/><rect x="442" y="252" width="162" height="8" rx="2" fill="#e4e0d8"/><rect x="478" y="272" width="90" height="16" rx="3" fill="#fbfaf7"/><text x="523" y="284" text-anchor="middle" font-family="Jost,sans-serif" font-size="10" fill="#34507a">INNSJEKK</text>"##
        return (o + extra + "</svg>", "#e9eaec")
    }

    static func flightSVG() -> (String, String) {
        func cl(_ x: Double, _ y: Double, _ k: Double) -> String {
            ##"<g transform="translate(\##(js(x)) \##(js(y))) scale(\##(js(k)))" fill="#fff" opacity=".9"><ellipse cx="0" cy="0" rx="70" ry="16"/><ellipse cx="-20" cy="-12" rx="34" ry="16"/><ellipse cx="24" cy="-16" rx="40" ry="20"/></g>"##
        }
        return (sc0(["#4f97dc", "#cfe6f7"], "I lufta") + ##"<g class="cl">\##(cl(120, 90, 1) + cl(520, 150, 0.8) + cl(760, 60, 1.1) + cl(960, 260, 1.2) + cl(300, 300, 1.3))</g>"## + plane(320, 200, 1.5) + "</svg>", "#4f97dc")
    }

    // MARK: mat
    static func dishSVG(_ k: String, _ q: String) -> String {
        var d = ""
        if k == "pannekaker" {
            d = ##"<ellipse cx="60" cy="50" rx="34" ry="11" fill="#c98f3e"/><ellipse cx="60" cy="45" rx="34" ry="11" fill="#dba54e"/><ellipse cx="60" cy="40" rx="34" ry="11" fill="#e9bb66"/><rect x="54" y="33" width="12" height="8" rx="2" fill="#fff3c4"/>"##
        } else if k == "pizza" {
            d = ##"<ellipse cx="60" cy="45" rx="38" ry="15" fill="#d9a55a"/><ellipse cx="60" cy="45" rx="33" ry="12" fill="#c4313f"/><ellipse cx="60" cy="45" rx="30" ry="10.5" fill="#f2d48a"/>"##
            d += [(46, 42), (62, 39), (74, 46), (56, 50), (68, 51)].map { ##"<ellipse cx="\##($0.0)" cy="\##($0.1)" rx="4.5" ry="2.4" fill="#d9808a"/>"## }.joined()
        } else if k == "taco" {
            d = ##"<path d="M26 52Q60 6 94 52Z" fill="#e9bb66" stroke="#c98f3e"/><path d="M30 52Q60 30 90 52Z" fill="#7a4a33"/>"##
            d += [(40, 48, "#5d9a52"), (52, 44, "#f2d48a"), (64, 43, "#c4313f"), (76, 47, "#5d9a52"), (58, 49, "#c4313f"), (70, 50, "#f2d48a")].map { ##"<circle cx="\##($0.0)" cy="\##($0.1)" r="4" fill="\##($0.2)"/>"## }.joined()
        } else if let x = dishX[k] {
            d = x
        } else {
            d = ##"<g fill="none" stroke="#e9c46a" stroke-width="3.5" stroke-linecap="round"><path d="M32 48Q46 30 60 46T88 44"/><path d="M34 54Q50 40 62 52T86 52"/><path d="M38 42Q54 34 66 42T82 38"/></g><ellipse cx="60" cy="42" rx="15" ry="6" fill="#c4313f"/><circle cx="56" cy="40" r="2" fill="#5d9a52"/>"##
        }
        let ov = q == "brent" ? ##"<ellipse cx="60" cy="45" rx="38" ry="18" fill="#22140c" opacity=".62"/>"## : q == "raa" ? ##"<ellipse cx="60" cy="45" rx="38" ry="18" fill="#fff" opacity=".45"/>"## : ""
        return ##"<svg class="plate" viewBox="0 0 120 80" aria-hidden="true"><ellipse cx="60" cy="54" rx="54" ry="20" fill="#f4f1ea" stroke="#b9b2a6"/><ellipse cx="60" cy="53" rx="42" ry="14" fill="#fbfaf7" stroke="#dcd8d0"/>\##(d)\##(ov)</svg>"##
    }

    // MARK: folk på gata
    static let crowdLooks: [(Look, Feat)] = {
        var r = Rng(4242)
        func pk<T>(_ a: [T]) -> T { a[Int((r.next() * Double(a.count)).rounded(.down))] }
        func rnd(_ x: Double) -> Double { (x + 0.5).rounded(.down) }
        var o: [(Look, Feat)] = []
        for i in 0..<12 {
            let m = i % 3 == 1, old = i % 5 == 4
            var L = Look()
            L.skin = pk(Pal.skin); L.eyes = pk(Pal.eyes)
            L.hair = m ? "kort" : pk(["langt", "bolgete", "lob", "hestehale", "knute", "kroller", "fletter"])
            L.hairColor = old ? "#c9c6c0" : pk(Array(Pal.hair[0..<6]))
            L.lips = m ? "none" : pk(Pal.lips + ["none"])
            L.top = pk(["tskjorte", "genser", "skjorte", "hettegenser"]); L.topColor = pk(Pal.cloth)
            L.bottom = m ? pk(["jeans", "vide"]) : pk(["jeans", "vide", "skjort", "midi", "shorts"]); L.bottomColor = pk(Pal.cloth)
            L.outer = r.next() < 0.3 ? pk(["dongeri", "blazer", "skinn"]) : "none"; L.outerColor = pk(Pal.cloth)
            L.shoes = m ? pk(["sneakers", "boots"]) : pk(["sneakers", "boots", "ballerina"]); L.shoeColor = pk(Pal.cloth)
            L.acc.veske = !m && r.next() < 0.3
            L.acc.solbriller = r.next() < 0.15
            let face: String = pk(["oval", "rund", "kantet"])
            let er = rnd(r.next() * 6 - 3)
            let es = m ? 0.86 : 0.95 + r.next() * 0.1
            let lip = m ? 0.78 : 1 + r.next() * 0.2
            let bx = m ? 1.14 : 0.96 + r.next() * 0.1
            let h = m ? 1.04 : 0.92 + r.next() * 0.08
            o.append((L, Feat(face: face, er: er == 0 ? 0 : er, es: es, lip: lip, bx: bx, h: h)))
        }
        return o
    }()
    static let crowdSVG: [String] = crowdLooks.map { fig($0.0, $0.1) }

    static func crowd(_ n: Int, _ fy: Double, _ k: Double, _ seed: Int, _ x0: Double, _ x1: Double, t: Double) -> String {
        var r = Rng(Double(seed * 31 + 7))
        var o = ""
        for i in 0..<n {
            let j = (seed * 5 + i * 7) % crowdLooks.count
            let kk = k * crowdLooks[j].1.h * (0.94 + r.next() * 0.1)
            let durS = tf(16 + r.next() * 14, 1), dur = Double(durS)!
            let ph = tf((t + r.next() * 99).truncatingRemainder(dividingBy: dur), 2)
            let a = tf(x0 + r.next() * 20, 0), b = tf(x1 - r.next() * 20, 0)
            let f = r.next() < 0.5
            let yS = tf(fy + (r.next() - 0.5) * 6, 0), y = Double(yS)!
            o += ##"<g><animateTransform attributeName="transform" type="translate" values="\##(f ? a : b) 0;\##(f ? b : a) 0;\##(f ? a : b) 0" dur="\##(js(dur * 2))s" begin="-\##(ph)s" repeatCount="indefinite"/><g transform="translate(\##(tf(-150 * kk, 1)) \##(tf(y - 598 * kk, 1))) scale(\##(tf(kk, 3)))"><animateTransform attributeName="transform" type="translate" additive="sum" values="0 0;0 -6;0 0" dur=".55s" repeatCount="indefinite"/>\##(crowdSVG[j])</g></g>"##
        }
        return o
    }

    // MARK: med på tur
    static func crewList(_ st: GameState) -> [CrewMember] {
        let c = st.life.crew
        var o: [CrewMember] = []
        for (i, q) in st.people.enumerated() where i != st.cur && (c["f\(i)"] ?? false) {
            o.append(CrewMember(name: q.name.isEmpty ? "Venn" : q.name, i: i))
        }
        for k in famOrder where c[k] ?? false {
            let f = fam[k]!
            o.append(CrewMember(name: f.0.name, look: f.0, feat: f.1))
        }
        var r = Array(o.prefix(4))
        let q = st.people[st.cur]
        if (c["kid"] ?? false) && q.kid.age >= 0 { r.append(CrewMember(name: q.kid.name.isEmpty ? "Barnet" : q.kid.name, kid: q.kid.age)) }
        if (c["pet"] ?? false) && q.pet.type != "none" { r.append(CrewMember(name: q.pet.name.isEmpty ? "Dyret" : q.pet.name, pet: q.pet)) }
        return r
    }

    /// Tegning av en person i følget, og høydefaktoren.
    static func figOf(_ st: GameState, _ e: CrewMember?, seat: Bool = false) -> (String, Double) {
        if let e = e, let pt = e.pet {
            return (seat ? petSVG(pt.type, pt.color, 150, 240, 1.85) : petSVG(pt.type, pt.color, 150, 520, 2.3), 1)
        }
        if let e = e, e.kid == 0 {
            let L = Kids.look(st).0
            if seat { return (Kids.baby(st.people[st.cur].kid.look.topColor, L.skin, L.hairColor, 170, 250, 2.1), 1) }
            let s1 = ##"<g><rect x="70" y="420" width="170" height="110" rx="40" fill="#34507a"/><path d="M80 470Q90 380 190 395L196 470Z" fill="#2c4467"/><path d="M240 430L268 380" stroke="#33363b" stroke-width="10" stroke-linecap="round"/><circle cx="105" cy="560" r="34" fill="#1d1f23"/><circle cx="215" cy="560" r="34" fill="#1d1f23"/><circle cx="105" cy="560" r="12" fill="#9ba1a8"/><circle cx="215" cy="560" r="12" fill="#9ba1a8"/>"##
            let s2 = ##"<circle cx="205" cy="440" r="26" fill="\##(L.skin)"/><path d="M182 432Q186 410 206 412Q226 414 229 432Q214 424 196 428Z" fill="\##(L.hairColor)"/><circle cx="198" cy="442" r="2.6" fill="#1d1020"/><circle cx="213" cy="442" r="2.6" fill="#1d1020"/></g>"##
            return (s1 + s2, 1)
        }
        guard let e = e else { return (girl(st), feat(st.cur).h) }
        if e.kid != nil { return (Kids.figure(st), 1) }
        if let l = e.look, let f = e.feat { return (fig(l, f), f.h) }
        if let i = e.i { return (fig(st.people[i], feat(i)), feat(i).h) }
        return (girl(st), feat(st.cur).h)
    }

    /// Venn nummer i som skal tegnes (venner først, så naboer).
    static func hostEntry(_ st: GameState, _ i: Int) -> CrewMember {
        if i < st.people.count { return CrewMember(name: st.people[i].name, i: i) }
        let n = neighbours[min(i - st.people.count, neighbours.count - 1)]
        return CrewMember(name: n.0.name, look: n.0, feat: n.1)
    }

    static func crewFigs(_ st: GameState, _ xs: [Double], _ sc: Double, _ fy: Double) -> String {
        crewList(st).enumerated().map { j, e in
            let f = figOf(st, e)
            return ##"<g transform="\##(wt(xs[j], sc * f.1, fy, 0))">\##(f.0)</g>"##
        }.joined()
    }

    static func cabinSVG(_ st: GameState) -> (String, String) {
        let crew = crewList(st), half = (crew.count + 1) / 2
        let all: [CrewMember?] = Array(crew.prefix(half)) + [nil] + Array(crew.dropFirst(half))
        let m = all.count, eve = st.house.time == "kveld"
        var o = ##"<svg viewBox="0 0 640 400" preserveAspectRatio="xMidYMax meet" role="img" aria-label="Inne i flyet">"## + GDEFS
        o += ##"<rect x="-640" y="-600" width="1920" height="1000" fill="#e9ecef"/><path d="M-640 -600h1920v664Q320 30 -640 64Z" fill="#dfe3e8"/>"##
        for i in -2..<10 { o += ##"<rect x="\##(i * 92 - 10)" y="60" width="86" height="34" rx="9" fill="#f6f7f8" stroke="#c9ced3"/><rect x="\##(i * 92 + 26)" y="84" width="14" height="4" rx="2" fill="#9aa0a8"/>"## }
        for i in -2..<9 {
            let x = i * 104 + 38
            o += ##"<svg x="\##(x)" y="112" width="52" height="68" viewBox="0 0 52 68"><rect width="52" height="68" fill="\##(eve ? "#39446e" : "#8fc1ea")"/><g class="cl2" style="animation-delay:-\##(js(Double(i + 3) * 0.9))s"><ellipse cx="20" cy="30" rx="18" ry="6" fill="#fff" opacity=".9"/><ellipse cx="26" cy="24" rx="10" ry="6" fill="#fff" opacity=".9"/><ellipse cx="-50" cy="48" rx="16" ry="5" fill="#fff" opacity=".8"/></g></svg><rect x="\##(x - 3)" y="109" width="58" height="74" rx="20" fill="none" stroke="#f6f7f8" stroke-width="8"/><rect x="\##(x - 7)" y="105" width="66" height="82" rx="24" fill="none" stroke="#c9ced3" stroke-width="2"/>"##
        }
        for i in -3..<10 { o += ##"<rect x="\##(i * 100 - 20)" y="196" width="84" height="150" rx="14" fill="#2c4467"/><rect x="\##(i * 100 - 4)" y="188" width="52" height="34" rx="10" fill="#34507a"/>"## }
        o += ##"<rect x="-640" y="262" width="1920" height="200" fill="#0002"/>"##
        let xs: [Double] = (0..<m).map { (i: Int) -> Double in 320 + (Double(i) - Double(m - 1) / 2) * 104 }
        for x in xs { o += ##"<rect x="\##(js(x - 44))" y="176" width="88" height="170" rx="15" fill="#34507a"/><rect x="\##(js(x - 27))" y="166" width="54" height="40" rx="11" fill="#40609a"/><rect x="\##(js(x - 22))" y="170" width="44" height="14" rx="5" fill="#f6f7f8" opacity=".85"/>"## }
        o += ##"<svg x="0" y="0" width="640" height="326" viewBox="0 0 640 326">"## + all.enumerated().map { i, e in
            let f = figOf(st, e, seat: true), k = 0.6 * f.1
            return ##"<g transform="translate(\##(tf(xs[i] - 150 * k, 1)) \##(tf(232 - 70 * k, 1))) scale(\##(js(k)))">\##(f.0)</g>"##
        }.joined() + "</svg>"
        for (i, x) in xs.enumerated() {
            let nm = all[i]?.name ?? (st.people[st.cur].name.isEmpty ? "Du" : st.people[st.cur].name)
            o += ##"<rect x="\##(js(x - 46))" y="318" width="92" height="50" rx="8" fill="#2c4467"/><path d="M\##(js(x - 40)) 322Q\##(js(x)) 334 \##(js(x + 40)) 322" stroke="#8c8f96" stroke-width="5" fill="none"/><rect x="\##(js(x - 7))" y="324" width="14" height="9" rx="2" fill="#c9ced3"/>"##
            o += ##"<text x="\##(js(x))" y="358" text-anchor="middle" font-family="Jost,sans-serif" font-size="12" fill="#f6f7f8">\##(esc(nm))</text>"##
        }
        for i in 0...m {
            let x = 320 + (Double(i) - Double(m) / 2) * 104
            o += ##"<rect x="\##(js(x - 6))" y="290" width="12" height="78" rx="4" fill="#55595f"/>"##
        }
        o += ##"<rect x="-640" y="366" width="1920" height="100" fill="#6d747b"/>"##
        return (o + "</svg>", "#dfe3e8")
    }

    // MARK: bil
    static func strap(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double, _ w: Double) -> String {
        ##"<path d="M\##(tf(x1, 1)) \##(tf(y1, 1))L\##(tf(x2, 1)) \##(tf(y2, 1))" stroke="#1d1f24" stroke-width="\##(tf(w + 2, 1))" stroke-linecap="round"/><path d="M\##(tf(x1, 1)) \##(tf(y1, 1))L\##(tf(x2, 1)) \##(tf(y2, 1))" stroke="#5a5f6b" stroke-width="\##(tf(w, 1))" stroke-linecap="round"/><rect x="\##(tf(x2 - w * 0.9, 1))" y="\##(tf(y2 - w * 0.6, 1))" width="\##(tf(w * 1.8, 1))" height="\##(tf(w * 1.2, 1))" rx="2" fill="#c9ced3"/>"##
    }

    static func riders(_ st: GameState) -> String {
        let p = st.people[st.cur], kd = p.kid, pt = p.pet
        var o = ##"<clipPath id="rwin"><path d="M66 342L76 328L100 328L100 342Z"/></clipPath><g clip-path="url(#rwin)">"##
        if kd.age >= 0 {
            let L = Kids.look(st).0, a = kd.age != 0
            o += ##"<circle cx="91" cy="\##(a ? 337 : 340)" r="\##(a ? "5.2" : "4.2")" fill="\##(L.skin)"/><path d="M85.5 \##(a ? 337 : 340)Q85 \##(a ? 330 : 335) 91 \##(a ? 330 : 335)Q97 \##(a ? 330 : 335) 96.5 \##(a ? 336 : 339)Q92 \##(a ? 333 : 337) 88 \##(a ? 334 : 338)Z" fill="\##(L.hairColor)"/>"##
        }
        if pt.type != "none" { o += petSVG(pt.type, pt.color, kd.age >= 0 ? 76 : 84, 347, 0.17) }
        return o + "</g>"
    }

    static func carInSVG(_ st: GameState, beltMe: Bool, beltKid: Bool, _ op: SceneOpts = SceneOpts()) -> (String, String) {
        let mv = op.moving
        let insT = mv ? ##" transform="translate(\##(tf((-(st.life.cx * 0.8)).truncatingRemainder(dividingBy: 640), 1)) 0)""## : ""
        let whT = mv ? ##" transform="rotate(\##(tf(op.steer * -6, 0)) 465 334)""## : ""
        let kmt = mv ? "\(Int((abs(op.v) / 5 + 0.5).rounded(.down))) km/t" : "0 km/t"
        let p = st.people[st.cur], kd = p.kid, pt = p.pet, eve = st.house.time == "kveld"
        var rn = Rng(5)
        var stx = ""
        var x = 0
        while x < 640 {
            let k = 0.7 + rn.next() * 0.5
            stx += ##"<rect x="\##(x + 36)" y="\##(js(150 - 50 * k))" width="6" height="\##(js(50 * k))" fill="#6b4a35"/><circle cx="\##(x + 39)" cy="\##(js(150 - 58 * k))" r="\##(js(24 * k))" fill="#4f8f52"/>"##
            x += 80
        }
        var o = sc0(eve ? ["#232a4d", "#e59a78"] : ["#8fc1ea", "#e6f1f8"], "Inne i bilen") + ##"<clipPath id="bw"><path d="M110 40Q320 18 530 40L556 176L84 176Z"/></clipPath>"##
        o += ##"<rect x="-640" y="-600" width="1920" height="1000" fill="#2f323a"/>"##
        o += ##"<g clip-path="url(#bw)"><rect x="0" y="0" width="640" height="200" fill="\##(eve ? "#39446e" : "#a9d3f0")"/><rect x="0" y="140" width="640" height="60" fill="#7fae63"/><g id="ins"\##(insT)>\##(stx)<g transform="translate(640 0)">\##(stx)</g><g transform="translate(-640 0)">\##(stx)</g></g></g>"##
        o += ##"<path d="M110 40Q320 18 530 40L556 176L84 176Z" fill="none" stroke="#1d1f24" stroke-width="10"/><rect x="40" y="-60" width="560" height="70" rx="20" fill="#3a3e47"/><rect x="270" y="-6" width="100" height="26" rx="8" fill="#17181c"/><rect x="276" y="-1" width="88" height="16" rx="5" fill="#8fa7b8"/>"##
        o += ##"<rect x="40" y="168" width="560" height="140" rx="26" fill="#4a4f5a"/><rect x="40" y="168" width="560" height="22" rx="11" fill="#555b67"/>"## + [150, 320, 490].map { ##"<rect x="\##($0 - 38)" y="140" width="76" height="40" rx="12" fill="#555b67"/>"## }.joined()
        if kd.age >= 1 {
            let (L, F) = Kids.look(st)
            let g = Figure(s: L, f: F, child: true).svg(), k = 0.5 * F.h / 0.7
            o += ##"<svg x="0" y="0" width="640" height="300" viewBox="0 0 640 300"><g transform="translate(\##(tf(228 - 150 * k, 1)) \##(tf(262 - 375 * k, 1))) scale(\##(tf(k, 3)))">\##(g)</g></svg><path d="M200 222L256 222L260 290L196 290Z" fill="#2b2d33" opacity=".55"/>"##
            o += (beltKid ? strap(228 + (186 - 150) * k * 1.0, 262 + (222 - 375) * k, 228 + (116 - 150) * k, 262 + (372 - 375) * k, 9 * k) : strap(268, 214, 272, 290, 5))
        } else if kd.age == 0 {
            let L = Kids.look(st).0
            o += ##"<rect x="170" y="176" width="116" height="112" rx="22" fill="#34507a"/><rect x="182" y="190" width="92" height="90" rx="16" fill="#40609a"/>"## + Kids.baby(kd.look.topColor, L.skin, L.hairColor, 243, 262, 0.75)
            o += (beltKid ? strap(222, 232, 243, 268, 5) + strap(266, 232, 245, 268, 5) : "")
        }
        if pt.type != "none" { o += petSVG(pt.type, pt.color, 350, 272, 0.9) }
        o += ##"<rect x="60" y="250" width="230" height="170" rx="30" fill="#3b3f48"/><rect x="350" y="250" width="230" height="170" rx="30" fill="#3b3f48"/><rect x="128" y="214" width="94" height="58" rx="18" fill="#454a55"/><rect x="418" y="214" width="94" height="58" rx="18" fill="#454a55"/>"##
        let f = feat(st.cur).h, k2 = 0.62 * f
        o += ##"<svg x="0" y="0" width="640" height="356" viewBox="0 0 640 356"><g transform="translate(\##(tf(465 - 150 * k2, 1)) \##(tf(338 - 290 * k2, 1))) scale(\##(tf(k2, 3)))">\##(girl(st))</g></svg>"##
        o += ##"<rect x="-640" y="356" width="1920" height="100" fill="#22252b"/><rect x="-640" y="352" width="1920" height="8" fill="#383c45"/>"##
        o += beltMe ? strap(465 + (188 - 150) * k2, 338 + (134 - 290) * k2, 465 + (112 - 150) * k2, 338 + (284 - 290) * k2, 9 * k2) : strap(548, 236, 552, 330, 6)
        o += ##"<g id="wheel"\##(whT)><ellipse cx="465" cy="330" rx="72" ry="30" fill="none" stroke="#17181c" stroke-width="11"/><path d="M397 334L533 334M465 330L465 360" stroke="#17181c" stroke-width="8"/><circle cx="465" cy="334" r="13" fill="#2b2d33"/></g>"##
        o += ##"<rect x="500" y="364" width="120" height="44" rx="8" fill="#111317"/><text x="560" y="392" text-anchor="middle" font-family="Jost,sans-serif" font-size="15" fill="#7fe0c0" id="spd">\##(kmt)</text>"##
        return (o + (eve ? ##"<rect x="-640" y="-600" width="1920" height="1400" fill="#0c1233" opacity=".3"/>"## : "") + "</svg>", "#2f323a")
    }

    static func driveSVG(_ st: GameState, _ o: SceneOpts) -> (String, String) {
        if o.driveIn { return carInSVG(st, beltMe: o.beltMe, beltKid: o.beltKid, o) }
        let l = st.life, p = st.people[st.cur], H = st.house, eve = H.time == "kveld"
        let sky = st.rain ? ["#7d8794", "#bcc3ca"] : eve ? ["#232a4d", "#e59a78"] : ["#8fc1ea", "#e6f1f8"]
        var w = ##"<rect x="-600" y="306" width="4500" height="70" fill="#55585e"/><rect x="-600" y="304" width="4500" height="4" fill="#cfcac1"/>"##
        var x = -560
        while x < 3900 { w += ##"<rect x="\##(x)" y="338" width="44" height="5" fill="#f4f1ea" opacity=".85"/>"##; x += 90 }
        x = -500
        while x < 3800 {
            defer { x += 140 }
            if stops.contains(where: { abs($0.x - Double(x)) < 200 }) { continue }
            let k = 0.8 + Double((x * 7) % 5) * 0.08
            w += ##"<rect x="\##(x - 4)" y="\##(js(300 - 70 * k))" width="8" height="\##(js(70 * k))" fill="#6b4a35"/><circle cx="\##(x)" cy="\##(js(300 - 86 * k))" r="\##(js(34 * k))" fill="#4f8f52"/><circle cx="\##(js(Double(x) + 18 * k))" cy="\##(js(300 - 70 * k))" r="\##(js(22 * k))" fill="#458248"/>"##
        }
        func sign(_ x: Int, _ t: String) -> String {
            ##"<rect x="\##(x - 2)" y="258" width="4" height="46" fill="#6d747b"/><rect x="\##(x - 52)" y="236" width="104" height="26" rx="4" fill="#34507a"/><text x="\##(x)" y="254" text-anchor="middle" font-family="Jost,sans-serif" font-size="13" font-weight="600" fill="#fbfaf7">\##(t)</text>"##
        }
        w += ##"<rect x="230" y="212" width="130" height="92" fill="\##(H.wall)" stroke="#0002"/><path d="M218 214L295 160L372 214Z" fill="\##(H.roofColor)"/><rect x="282" y="250" width="26" height="54" fill="\##(H.door)"/><rect x="244" y="232" width="26" height="26" fill="#a9c6d8" stroke="#fff" stroke-width="3"/><rect x="320" y="232" width="26" height="26" fill="#a9c6d8" stroke="#fff" stroke-width="3"/>"## + sign(420, "HJEM")
        w += ##"<rect x="1010" y="120" width="180" height="184" fill="#c9b8a8" stroke="#0002"/><rect x="1004" y="112" width="192" height="10" fill="#6d747b"/>"## + (0..<4).map { r in (0..<4).map { i in ##"<rect x="\##(1026 + i * 40)" y="\##(136 + r * 38)" width="24" height="24" fill="#a9c6d8" stroke="#fff" stroke-width="2.5"/>"## }.joined() }.joined() + ##"<rect x="1086" y="268" width="28" height="36" fill="#5a3a32"/>"## + sign(1250, "VENNENE")
        w += ##"<rect x="1820" y="206" width="170" height="98" fill="#e7ddd0" stroke="#0002"/><path d="M1812 206h186l-10 26h-166z" fill="#9b3b47"/><path d="M1836 206l-4 26M1862 206l-2 26M1888 206v26M1914 206l2 26M1940 206l4 26M1966 206l6 26" stroke="#fbfaf7" stroke-width="5" opacity=".7"/><rect x="1836" y="244" width="60" height="40" fill="#a9c6d8" stroke="#fff" stroke-width="3"/><rect x="1930" y="246" width="30" height="58" fill="#34507a"/>"## + petSVG("katt", "#e08a3c", 1866, 278, 0.28) + sign(2050, "DYREBUTIKK")
        w += ##"<rect x="2680" y="214" width="250" height="90" fill="#dfe3e8" stroke="#0002"/><path d="M2680 214Q2805 176 2930 214Z" fill="#b9bec4"/><rect x="2696" y="234" width="218" height="46" fill="#9cc3dc"/><path d="M2740 234v46M2784 234v46M2828 234v46M2872 234v46" stroke="#dfe3e8" stroke-width="4"/><rect x="2958" y="120" width="16" height="184" fill="#c9ced3"/><path d="M2940 120h52l-8-28h-36z" fill="#34507a"/><rect x="2946" y="98" width="40" height="14" fill="#9cc3dc"/>"## + plane(2800, 150, 0.5) + sign(2620, "FLYPLASS")
        var car = ##"<g transform="translate(-130 -127) scale(1.25)"><ellipse cx="104" cy="389" rx="80" ry="4" fill="#000" opacity=".2"/><path d="M30 374L30 356Q32 346 48 344L62 328Q66 322 76 322L128 322Q138 322 146 330L160 344Q176 346 178 356L178 374Z" fill="\##(l.car)"/><path d="M66 342L76 328L100 328L100 342ZM104 328L128 328Q134 328 140 334L148 342L104 342Z" fill="#c5d8e4"/>"##
        car += ##"<circle cx="118" cy="335" r="6.5" fill="\##(p.skin)"/><path d="M110 336Q108 324 118 324Q128 324 126 334Q122 328 116 329Q112 330 110 336Z" fill="\##(p.hairColor)"/>"##
        car += riders(st) + ##"<path d="M34 352L176 352" stroke="#fff" opacity=".18" stroke-width="2"/><rect x="172" y="352" width="6" height="5" rx="1" fill="#f3e3a0"/><rect x="30" y="353" width="4" height="5" rx="1" fill="#c4313f"/>"##
        car += [62, 146].map { x in ##"<g class="wh" data-cx="\##(x)"\##(o.moving ? ##" transform="rotate(\##(tf(o.ang, 0)) \##(x) 375)""## : "")><circle cx="\##(x)" cy="375" r="13" fill="#1d1f23"/><circle cx="\##(x)" cy="375" r="6" fill="#9ba1a8"/><path d="M\##(x - 6) 375h12M\##(x) 369v12" stroke="#55595f" stroke-width="2"/></g>"## }.joined() + "</g>"
        var res = sc0(sky, "Bilturen")
        res += ##"<path d="M-640 300Q-300 230 0 280T640 250T1280 300Z" fill="#6f9f7a" opacity=".6"/>"## + gr("#7fae63", 296) + ##"<g id="dw" transform="translate(\##(tf(390 - l.cx, 1)) 0)">\##(w)</g><g transform="translate(390 0)"><g id="dflip" transform="scale(\##(js(o.dirn)) 1)">\##(car)</g></g>"##
        res += (eve ? ##"<rect x="-640" y="-600" width="1920" height="1400" fill="#0c1233" opacity=".4"/>"## : "")
        return (res + "</svg>", sky[0])
    }

    // MARK: hovedscene
    /// Scenen i Liv-fanen når 3D ikke brukes (ute, flyplass, reise, fly, bil, dyrebutikk, og 2D-reserve for hjemme/hos venn).
    static func lifeScene(_ st: GameState, _ op: SceneOpts = SceneOpts()) -> (String, String) {
        let l = st.life
        if op.flying != nil { return op.flyView == "out" ? flightSVG() : cabinSVG(st) }
        if l.place == "ute" {
            let r = HouseArt.house(st)
            let add = GDEFS + crowd(3, 396, 0.17, 1, -140, 780, t: op.t) + walkerG(st, l.x, 0.2, 390) + "</svg>"
            var s = r.0
            if let rg = s.range(of: "</svg>") { s.replaceSubrange(rg, with: add) }
            return (s, r.1)
        }
        if l.place == "venn" {
            let hf = figOf(st, hostEntry(st, l.friend)), fg = hf.0, k = 0.36 * hf.1
            let t = l.said.isEmpty ? lines[l.line % lines.count] : l.said
            let w = Double(t.utf16.count) * 6.4 + 26, bx = max(8, min(632 - w, 200 - w / 2))
            let mt = l.meSaid, mw = Double(mt.utf16.count) * 6.4 + 26, mx = max(8, min(632 - mw, l.x - mw / 2))
            let myB = mt.isEmpty ? "" : ##"<rect x="\##(js(mx))" y="58" width="\##(js(mw))" height="30" rx="10" fill="#1d1b22"/><text x="\##(js(mx + 13))" y="78" font-family="Jost,sans-serif" font-size="13" fill="#fff">\##(esc(mt))</text>"##
            let fr = friendRooms[l.friend % friendRooms.count]
            return HouseArt.room("stue", fr, st, extra: ##"<g transform="\##(wt(200, k, 366, 0))">\##(fg)</g><rect x="\##(js(bx))" y="96" width="\##(js(w))" height="30" rx="10" fill="#fff" stroke="#0003"/><path d="M196 125l4 12l10-12z" fill="#fff"/><text x="\##(js(bx + 13))" y="116" font-family="Jost,sans-serif" font-size="13" fill="#1d1b22">\##(esc(t))</text>"## + myB + walkerG(st, l.x, 0.36, 372))
        }
        if l.place == "flyplass" { return airportSVG(crowd(4, 372, 0.3, 3, -120, 760, t: op.t) + crewFigs(st, [300, 350, 60, 110, 400, 455], 0.34, 378) + walkerG(st, l.x, 0.34, 378)) }
        if l.place == "dyr" { return petShopSVG(st, walkerG(st, l.x, 0.34, 378)) }
        if l.place == "bil" { return driveSVG(st, op) }
        if l.place == "reise" {
            let pre = l.dest == "preikestolen"
            let c1 = crowd(pre ? 2 : 4, 370, 0.3, 7 + l.dest.utf16.count, -140, pre ? 400 : 780, t: op.t)
            let c2 = crewFigs(st, pre ? [60, 115, 230, 285, 290, 345] : [430, 485, 540, 595, 370, 320], 0.34, 376) + walkerG(st, l.x, 0.34, 376)
            return destSVG(l.dest, c1 + c2)
        }
        return HouseArt.room(l.room, st.house.inne[l.room], st, extra: walkerG(st, l.x, 0.36, 372), home: true)
    }
}

import Foundation

/// Liv: data og spillregler (oppdrag, behov, post, samtaler), overført fra nettversjonen.
enum LifeData {
    static let tasks: [String: (String, Int)] = [
        "cookperfect": ("Lag en perfekt stekt rett", 25), "eat": ("Spis et måltid", 10), "friend": ("Besøk en venn", 15), "give": ("Gi mat til en venn", 25),
        "shower": ("Ta en dusj", 10), "tv": ("Se på TV", 10), "sleep": ("Legg deg og sov", 10), "flyno": ("Fly til et sted i Norge", 30), "flyut": ("Fly til utlandet", 40),
        "pet": ("Klapp kjæledyret", 10), "petplay": ("Lek med kjæledyret", 15), "petfeed": ("Gi kjæledyret mat", 15), "adopt": ("Skaff et kjæledyr", 30),
        "stairs": ("Gå opp trappa", 10), "gift": ("Åpne en pakke", 10), "drive": ("Kjør bil til et sted", 15), "mail": ("Hent posten", 10),
        "sendmail": ("Send et brev til noen", 10), "talk": ("Snakk med en venn", 10), "toilet": ("Gå på do", 5), "wash": ("Vask hendene", 5),
        "bath": ("Ta et bad", 15), "cooktog": ("Lag mat og spis sammen med en venn", 30), "nabo": ("Hils på en nabo", 15), "kid": ("Ta deg av barnet", 15),
        "baker": ("Jobb en vakt i bakeriet", 25), "job": ("Jobb en vakt i Jobb-fanen", 20), "zoo": ("Jobb en vakt i dyreparken", 25),
    ]
    static let taskOrder = ["cookperfect", "eat", "friend", "give", "shower", "tv", "sleep", "flyno", "flyut", "pet", "petplay", "petfeed", "adopt", "stairs", "gift", "drive", "mail", "sendmail", "talk", "toilet", "wash", "bath", "cooktog", "nabo", "kid", "baker", "zoo", "job"]

    static let recipeOrder = ["pannekaker", "pizza", "taco", "pasta", "vafler", "omelett", "burger", "suppe", "kjottkaker", "frukt", "laks", "wok", "kake"]
    static let recipes: [String: (String, [String], Int)] = [
        "pannekaker": ("Pannekaker", ["Mel", "Egg", "Melk", "Smør"], 1), "pizza": ("Pizza", ["Pizzadeig", "Tomatsaus", "Ost", "Skinke"], 1),
        "taco": ("Taco", ["Tacoskjell", "Kjøttdeig", "Ost", "Salat"], 1), "pasta": ("Pasta med tomatsaus", ["Pasta", "Tomatsaus", "Løk", "Ost"], 1),
        "vafler": ("Vafler", ["Mel", "Egg", "Melk", "Sukker"], 2), "omelett": ("Omelett", ["Egg", "Melk", "Ost", "Skinke"], 2),
        "burger": ("Burger", ["Burgerbrød", "Kjøttdeig", "Ost", "Salat"], 3), "suppe": ("Tomatsuppe", ["Tomater", "Løk", "Fløte", "Buljong"], 3),
        "kjottkaker": ("Kjøttkaker", ["Kjøttdeig", "Løk", "Poteter", "Brun saus"], 4), "frukt": ("Fruktsalat", ["Banan", "Eple", "Jordbær", "Druer"], 4),
        "laks": ("Laks med poteter", ["Laks", "Poteter", "Smør", "Sitron"], 5), "wok": ("Wok", ["Nudler", "Kylling", "Paprika", "Soyasaus"], 5),
        "kake": ("Sjokoladekake", ["Mel", "Egg", "Sukker", "Sjokolade"], 6),
    ]
    static let allIng: [String] = recipeOrder.reduce(into: ["Fiskepinner"]) { a, k in for n in recipes[k]!.1 where !a.contains(n) { a.append(n) } }

    static let pets: [String: (String, Int, String)] = ["katt": ("Katt", 50, "Pusen"), "hund": ("Hund", 60, "Bamse"), "kanin": ("Kanin", 40, "Hopp")]
    static let petOrder = ["katt", "hund", "kanin"]
    static let petColors = ["#e08a3c", "#3a3330", "#e9e4dc", "#b98a5a", "#8c8f96"]
    static let carColors = ["#39475a", "#9b3b47", "#f4f1ea", "#1f1f24", "#5d7a5e", "#c9a227", "#7fa3c7"]

    static let lines = ["Så gøy at du kom!", "Liker du stilen min i dag?", "Skal vi lage mat hos deg neste gang?", "Jeg drømmer om å reise til Tokyo.", "Har du pusset opp hjemme?"]
    static let destOrder = ["oslo", "bergen", "tromso", "lofoten", "preikestolen", "paris", "london", "roma", "newyork", "tokyo", "egypt"]
    static let dest: [String: (String, String, String, Bool)] = [
        "oslo": ("Oslo", "Norge", "Operahuset i Oslo. Du kan gå helt opp på taket.", true), "bergen": ("Bergen", "Norge", "Bryggen i Bergen står på UNESCOs verdensarvliste.", true),
        "tromso": ("Tromsø", "Norge", "Ishavskatedralen. Her kan du se nordlys om vinteren.", true), "lofoten": ("Lofoten", "Norge", "Lofoten er kjent for spisse fjell og røde rorbuer.", true),
        "preikestolen": ("Preikestolen", "Norge", "Preikestolen rager 604 meter over Lysefjorden.", true), "paris": ("Paris", "Frankrike", "Eiffeltårnet er rundt 330 meter høyt.", false),
        "london": ("London", "England", "Klokketårnet heter Elizabeth Tower. Selve klokken heter Big Ben.", false), "roma": ("Roma", "Italia", "Colosseum er nesten 2000 år gammelt.", false),
        "newyork": ("New York", "USA", "Frihetsgudinnen var en gave fra Frankrike.", false), "tokyo": ("Tokyo", "Japan", "Fuji er Japans høyeste fjell, 3776 meter.", false),
        "egypt": ("Giza", "Egypt", "Pyramidene i Giza er rundt 4500 år gamle.", false),
    ]
    static let sayQ = ["Hei!", "Hvordan har du det?", "Så fint du har det her.", "Skal vi finne på noe gøy?", "Ha det bra!"]
    static let phrases = ["Hvordan har du det?", "Takk for sist!", "Jeg savner deg.", "Kom og besøk meg snart.", "Jeg har fått nytt kjæledyr.", "Jeg har pusset opp huset.", "Gratulerer med dagen!", "Klem fra meg."]

    static let ML: [String: [String]] = [
        "o": ["Takk for sist! Det var så hyggelig å se deg.", "Hei! Nå er det lenge siden vi har snakket sammen.", "Jeg satt og tenkte på deg i dag.", "Gjett hva som skjedde i går!", "Jeg måtte bare skrive noen ord til deg.", "Håper alt står bra til hos deg.", "Jeg har så mye å fortelle!", "God dag fra meg!", "Nå sitter jeg ved kjøkkenbordet og skriver til deg.", "Du aner ikke hvor glad jeg blir av å få post fra deg."],
        "m": ["Jeg har begynt å lære meg å bake. Den første kaken ble helt flat.", "Katten til naboen sov i sofaen min hele dagen.", "Jeg har malt rommet mitt i en ny farge. Du må komme og se.", "Jeg fant en gammel fotobok med bilder av oss.", "I går regnet det så mye at jeg ble inne og så film.", "Jeg har kjøpt nye sko, og de er veldig gode å gå i.", "Jeg prøvde en ny frisyre, men jeg vet ikke om jeg liker den.", "Jeg har lest en bok som jeg tror du vil like.", "Vi burde lage middag sammen en dag.", "Jeg drømte at vi fløy til Tokyo sammen.", "Jeg har plantet tomater i vinduskarmen.", "Jeg syklet en lang tur og ble helt støl.", "Jeg har ryddet hele klesskapet og fant en genser jeg hadde glemt.", "Jeg lærte meg en ny oppskrift på vafler.", "Det har flyttet inn nye naboer med tre barn og en hund.", "Jeg så en regnbue over hele byen i går."],
        "c": ["Jeg legger ved litt lommepenger til neste tur.", "Her er noen mynter til noe fint til huset.", "Jeg sender med litt til en flybillett.", "Kjøp deg noe godt for disse myntene.", "Litt småpenger fra meg til deg.", "Bruk myntene på en pakke, kanskje?", "Her er litt til noe du har lyst på."],
        "pc": ["Skulle ønske du var her.", "Vi må dra hit sammen en gang.", "Jeg har tatt hundre bilder allerede.", "Maten her er så god!", "Jeg har gått så mye at jeg har gnagsår.", "Været er helt perfekt."],
        "mt": ["Denne månedens trender: store gensere, vide bukser og gullsmykker.", "Denne månedens trender: blazer over hettegenser og hvite sneakers.", "Denne månedens trender: lange skjørt, boots og perleøredobber.", "Denne månedens trender: dongerijakke til alt.", "Denne månedens trender: sterke farger på leppene og enkle klær.", "Denne månedens trender: halvlangt hår og solbriller."],
        "mp": ["Månedens tips: Prøv en ny frisyre og en farge du aldri har brukt før.", "Månedens tips: Bytt farge på én vegg hjemme.", "Månedens tips: Heng opp et nytt bilde i stua.", "Månedens tips: Sett en plante i hvert rom.", "Månedens tips: Rydd klesskapet og finn en glemt favoritt.", "Månedens tips: Ta en lang dusj og en tidlig kveld."],
        "mr": ["Ukens rett: vafler med syltetøy.", "Ukens rett: hjemmelaget pizza.", "Ukens rett: tomatsuppe med egg.", "Ukens rett: taco med mye salat.", "Ukens rett: laks med poteter.", "Ukens rett: fruktsalat til dessert."],
        "r1": ["Tusen takk for brevet ditt! Jeg ble så glad da jeg åpnet postkassa.", "Så koselig å få brev fra deg! Jeg leste det to ganger.", "For en fin overraskelse å få post fra deg.", "Jeg smilte hele dagen etter at brevet ditt kom.", "Brevet ditt henger på kjøleskapet mitt nå."],
        "r2": ["Jeg har det bra, og jeg håper du har det fint i huset ditt.", "Her går dagene fort, og jeg tenker ofte på deg.", "Her er alt som før, men litt kjedeligere uten deg.", "Jeg har mye å gjøre, men alltid tid til deg.", "Jeg har fortalt alle om det fine huset ditt."],
        "r3": ["Skriv snart igjen!", "Kom og besøk meg snart.", "Neste gang må vi snakkes i virkeligheten.", "Jeg gleder meg til neste brev.", "Pass godt på deg selv."],
    ]
    static let MLmulti: [String: [[String]]] = [
        "bm": [["Jeg er på ferie ved sjøen og koser meg med bok og kaffe.", "Husk å spise ordentlig og legge deg tidlig!"], ["Jeg har strikket en lue til deg. Den kommer i neste pakke.", "Si fra hvilken farge du liker best."], ["I dag bakte jeg boller, og hele huset lukter kanel.", "Kom på besøk, så står det et fat klart."], ["Jeg har vært i hagen hele dagen. Rosene blomstrer.", "Hvordan går det med huset ditt?"], ["Bestefar og jeg var på konsert i går.", "Vi danset nesten, men bare nesten."], ["Jeg fant gamle tegninger du laget da du var liten.", "De henger på kjøleskapet nå."]],
        "ad": [["Visste du at dyrebutikken har katter, hunder og kaniner som venter på et hjem?", "Kom innom og hils på dem.", "Hilsen Dyrebutikken"], ["Fly til utlandet denne uka! Paris, London, Roma og Tokyo venter.", "Billettene får du på flyplassen.", "Hilsen Flyselskapet"], ["Nye pakker hver dag. Farger, kunst og overraskelser.", "Du vet aldri hva du får.", "Hilsen Pakkebutikken"], ["Vi vasker bilen din mens du venter.", "Blank bil gir godt humør.", "Hilsen Bilvasken"], ["Ukens tilbud: mel, egg og melk.", "Perfekt til pannekaker og vafler.", "Hilsen Matbutikken"]],
        "bl": [["Strømforbruk denne måneden: lys, varme og en god del dusjing.", "Hilsen Strømselskapet"], ["Vannforbruk denne måneden. Noen har visst badet mye.", "Hilsen Vannverket"], ["Abonnement på internett og TV.", "Hilsen Nettselskapet"], ["Årlig feiing av pipa er utført.", "Hilsen Feieren"], ["Henting av søppel og papir.", "Hilsen Renovasjonen"]],
    ]

    static func pick<T>(_ a: [T]) -> T { a.randomElement()! }

    /// Svar fra vennen på det du skriver selv.
    static func answer(_ t: String, pet: Pet) -> String {
        let q = t.lowercased()
        func has(_ w: String) -> Bool { q.range(of: w, options: .regularExpression) != nil }
        if has("dum|stygg|hater|teit|idiot") { return "Det var ikke så hyggelig sagt. Skal vi snakke om noe annet?" }
        if has("ha det|hade|farvel|må gå|snakkes") { return "Ha det bra! Kom snart igjen." }
        if has("hvordan (går|har)|går det|har du det") { return "Jeg har det kjempebra. Hva med deg?" }
        if has("^(hei|hallo|heisann|halla|god dag)") { return "Hei! Så hyggelig å se deg." }
        if has("mat|sulten|spise|pizza|kake|taco|vafl|middag|pannekake") { return "Jeg elsker mat! Kan du lage noe til meg neste gang?" }
        if has("dyr|katt|hund|kanin|valp|pus") { return pet.type != "none" ? "Hils \(pet.name) fra meg! Jeg vil gjerne klappe litt neste gang." : "Du burde skaffe deg et kjæledyr. Dyrebutikken har mange søte." }
        if has("reis|fly|ferie|tur|land|paris|london|tokyo|roma") { return "Jeg drømmer om å reise til \(dest[pick(destOrder)]!.0). Blir du med?" }
        if has("klær|kjole|hår|sminke|fin|pen|stil|antrekk") { return "Tusen takk! Jeg liker stilen din også." }
        if has("hus|rom|sofa|stue|pusse") { return "Huset ditt er så fint. Jeg vil pusse opp, jeg også." }
        if has("lek|spill|gøy|finne på|kjede") { return "Ja! La oss finne på noe gøy sammen." }
        if has("venn|glad i|savn|liker deg") { return "Du er bestevennen min." }
        if has("skole|lekse|jobb") { return "Uff, ja. Men nå har vi fri!" }
        if has("trøtt|sove|sliten") { return "Du kan hvile i sofaen min hvis du vil." }
        if has("takk") { return "Bare hyggelig!" }
        if has("bra|fint|topp|supert|flott") { return "Så bra! Det gjør meg glad." }
        if has("trist|lei meg|dårlig|vondt") { return "Å, så leit. Jeg er her for deg." }
        if has("\\?") { return pick(["Godt spørsmål. Hva tror du selv?", "Det må jeg tenke litt på.", "Ja, jeg tror det!"]) }
        return pick(["Fortell mer!", "Ja, det er jeg enig i.", "Så spennende!", "Haha, du er morsom."])
    }
}

extension GameState {
    var level: Int { game.xp / 100 + 1 }
    var pet: Pet { get { people[cur].pet } set { people[cur].pet = newValue } }
    var kid: Kid { get { people[cur].kid } set { people[cur].kid = newValue } }

    static func isCook(_ id: String) -> Bool { id.hasPrefix("cook:") }
    static func taskText(_ id: String) -> String {
        if isCook(id) { return "Lag " + (LifeData.recipes[String(id.dropFirst(5))]?.0.lowercased() ?? "mat") }
        return LifeData.tasks[id]?.0 ?? id
    }
    static func taskPay(_ id: String) -> Int { isCook(id) ? 20 : (LifeData.tasks[id]?.1 ?? 10) }

    mutating func newTask() -> String {
        let has = pet.type != "none"
        let cur = [game.tasks.a, game.tasks.b, game.tasks.c]
        let pool = LifeData.taskOrder.filter { k in k.hasPrefix("pet") ? has : k == "adopt" ? !has : k == "kid" ? kid.age >= 0 : true }
            + LifeData.recipeOrder.filter { LifeData.recipes[$0]!.2 <= level }.map { "cook:" + $0 }
        let p = pool.filter { !cur.contains($0) }
        let t = p.randomElement() ?? "eat"
        if t == "mail" && game.mail < 1 { game.mail = 1 }
        return t
    }

    /// Fullfører oppdrag. Gir tilbake tekst til en melding, og om man gikk opp et nivå.
    mutating func fire(_ ev: String) -> (String, Bool) {
        var got = "", up = false
        for sl in ["a", "b", "c"] {
            let t = sl == "a" ? game.tasks.a : sl == "b" ? game.tasks.b : game.tasks.c
            if t != ev { continue }
            let n = game.needs, happy = n.sult >= 50 && n.energi >= 50 && n.hygiene >= 50 && n.humor >= 50
            let pay = Int((Double(GameState.taskPay(ev)) * (happy ? 1.5 : 1)).rounded()), l0 = level
            game.coins += pay; game.xp += GameState.taskPay(ev)
            got = "Oppdrag fullført: \(GameState.taskText(ev)). +\(pay) mynter\(happy ? " med fornøyd-bonus" : "")."
            if level > l0 { up = true; got += " Du nådde nivå \(level)." }
            if sl == "a" { game.tasks.a = "" } else if sl == "b" { game.tasks.b = "" } else { game.tasks.c = "" }
            let nt = newTask()
            if sl == "a" { game.tasks.a = nt } else if sl == "b" { game.tasks.b = nt } else { game.tasks.c = nt }
        }
        return (got, up)
    }

    /// Behovene synker litt hvert sekund (kalles hvert 9. sekund som i nettversjonen).
    mutating func tick() -> String? {
        need("sult", -1.2); need("energi", -0.8); need("hygiene", -0.7); need("humor", -0.9)
        if pet.type != "none" { pet.glad = max(0, pet.glad - 1) }
        for i in people[cur].kids.indices {
            people[cur].kids[i].glad = max(0, people[cur].kids[i].glad - 0.8); people[cur].kids[i].mett = max(0, people[cur].kids[i].mett - 1)
        }
        if !life.pending.isEmpty && game.mail < 3 && Double.random(in: 0..<1) < 0.35 { game.mail += 1; return "Det har kommet post i postkassa." }
        if game.mail < 3 && Double.random(in: 0..<1) < 0.06 { game.mail += 1; return "Det har kommet post i postkassa." }
        return nil
    }

    var lowHint: String {
        let n = game.needs, nm = me.name.isEmpty ? "Hun" : me.name
        if n.sult < 25 { return nm + " er sulten. Lag noe mat." }
        if n.energi < 25 { return nm + " er trøtt og går saktere. Legg deg på soverommet." }
        if n.hygiene < 25 { return nm + " trenger en dusj." }
        if n.humor < 25 { return nm + " kjeder seg. Finn på noe gøy." }
        if kid.age >= 0 && kid.mett < 25 { return (kid.name.isEmpty ? "Barnet" : kid.name) + " er sulten. Gi barnet mat." }
        return ""
    }

    // MARK: post
    mutating func draw(_ n: String) -> String { let i = drawIndex(n, LifeData.ML[n]!.count); return LifeData.ML[n]![i] }
    mutating func drawMulti(_ n: String) -> [String] { let i = drawIndex(n, LifeData.MLmulti[n]!.count); return LifeData.MLmulti[n]![i] }

    /// Trekker uten å gjenta før alle er brukt (samme som posen i nettversjonen).
    mutating func drawIndex(_ n: String, _ count: Int) -> Int {
        var bag = (life.bags[n] ?? "").split(separator: ",").compactMap { Int($0) }.filter { $0 >= 0 && $0 < count }
        if bag.isEmpty {
            bag = Array(0..<count).shuffled()
            if bag.count > 1, String(bag[bag.count - 1]) == life.last[n] { bag.insert(bag.removeLast(), at: 0) }
        }
        let i = bag.removeLast()
        life.bags[n] = bag.map(String.init).joined(separator: ",")
        life.last[n] = String(i)
        return i
    }

    mutating func genMail() -> Letter {
        let fr = people.enumerated().filter { $0.offset != cur }.map { $0.element.name }
        let f = (fr.randomElement() ?? "").isEmpty ? "en venn" : fr.randomElement()!
        let vis = LifeData.destOrder.filter { life.stamps[$0] ?? false }
        if !life.pending.isEmpty {
            let w = life.pending, fam = ["Bestemor", "Bestefar", "Mamma", "Pappa"].contains(w)
            life.pending = ""; need("humor", 15)
            return Letter(t: "Svar fra " + w, body: [draw("r1"), draw("r2"), draw("r3")], sign: (fam ? "Stor klem fra " : "Klem fra ") + w, note: "Humøret steg.")
        }
        var kind = ""
        repeat {
            let r = Double.random(in: 0..<1)
            kind = r < 0.36 ? "brev" : r < 0.58 ? "kort" : r < 0.67 ? "lapp" : r < 0.8 ? "regning" : r < 0.94 ? "blad" : "reklame"
        } while kind == life.lastKind
        life.lastKind = kind
        switch kind {
        case "brev":
            let c = 5 + Int.random(in: 0..<11); game.coins += c; need("humor", 8)
            let x = Double.random(in: 0..<1)
            let mid = pet.type != "none" && x < 0.2 ? "Hvordan går det med \(pet.name)? Gi en klapp fra meg." : !vis.isEmpty && x < 0.4 ? "Jeg så bildene dine fra \(LifeData.dest[vis.randomElement()!]!.0). Det så fantastisk ut!" : draw("m")
            return Letter(t: "Brev fra " + f, body: [draw("o"), mid, draw("c")], sign: "Klem fra " + f, note: "Det lå \(c) mynter i konvolutten.")
        case "kort":
            need("humor", 12)
            if !vis.isEmpty && Double.random(in: 0..<1) < 0.7 {
                let d = LifeData.dest[vis.randomElement()!]!
                return Letter(t: "Postkort fra " + d.0, body: ["Hei! Jeg er i \(d.0) akkurat nå.", d.2, draw("pc")], sign: "Hilsen " + f, note: "Humøret steg.")
            }
            return Letter(t: "Postkort fra bestemor", body: drawMulti("bm"), sign: "Stor klem fra bestemor", note: "Humøret steg.")
        case "lapp":
            game.free += 1
            return Letter(t: "Hentelapp nr. \(1000 + Int.random(in: 0..<9000))", body: [LifeData.pick(["Du har en pakke som venter på deg.", "Vi prøvde å levere en pakke, men ingen var hjemme.", "En pakke til deg har kommet til postkontoret.", "Noen har sendt deg en overraskelse."]), "Gå til fanen Pakke, så får du åpne den uten å betale."], sign: "Hilsen Posten", note: "Du fikk en gratispakke.")
        case "regning":
            let c = min(game.coins, 6 + Int.random(in: 0..<12)), b = drawMulti("bl"); game.coins -= c
            return Letter(t: "Faktura", body: [b[0], "Beløp: \(c) mynter. Beløpet er trukket automatisk."], sign: b[1], note: "Du betalte \(c) mynter.")
        case "blad":
            need("humor", 15)
            return Letter(t: "Motebladet", body: [draw("mt"), draw("mp"), draw("mr")], sign: "Redaksjonen", note: "Humøret steg.")
        default:
            let a = drawMulti("ad")
            return Letter(t: "Reklame", body: [a[0], a[1]], sign: a[2], note: "")
        }
    }
}

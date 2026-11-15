import Foundation

struct Acc: Codable, Equatable {
    var halskjede = false, oredobber = false, solbriller = false, veske = false, smykker = false, lue = false
}

struct Pet: Codable, Equatable {
    var type = "none", name = "", color = "#e08a3c"
    var glad = 70.0
    var collar = "none"
    var leash = false
}

struct KidLook: Codable, Equatable {
    var freckles = false
    var skin = "", eyes = "", hair = "", hairColor = ""
    var top = "", topColor = "", bottom = "", bottomColor = ""
    var dress = "none", dressColor = "#7fa3c7", shoes = "", shoeColor = ""
}

struct Kid: Codable, Equatable {
    var age = -1
    var name = ""
    var xp = 0
    var glad = 70.0, mett = 70.0
    var girl = true
    var look = KidLook()
}

struct Look: Codable, Equatable {
    var name = ""
    var skin = Pal.skin[1], eyes = Pal.eyes[0], lips = "none"
    var gloss = false
    var shadow = "none"
    var mascara = false, liner = false
    var blush = "none"
    var freckles = false
    var hair = "langt", hairColor = Pal.hair[2]
    var dress = "none", dressColor = Pal.cloth[6]
    var top = "tskjorte", topColor = Pal.cloth[0]
    var bottom = "jeans", bottomColor = Pal.cloth[4]
    var outer = "none", outerColor = Pal.cloth[5]
    var shoes = "sneakers", shoeColor = Pal.cloth[0]
    var acc = Acc()
    var oops: String? = nil
    var pet = Pet()
    var kid = Kid()
}

struct Needs: Codable, Equatable { var sult = 70.0, energi = 80.0, hygiene = 75.0, humor = 70.0 }

struct Game: Codable, Equatable {
    var coins = 80
    var free = 0
    var xp = 0
    var needs = Needs()
}

struct Unlocked: Codable, Equatable {
    var solbriller = false, veske = false, skinnjakke = false, gallakjole = false, smykker = false
    var basseng = false, rosa = false, blaa = false, lue = false, gull = false
    subscript(_ id: String) -> Bool {
        get {
            switch id {
            case "solbriller": return solbriller
            case "veske": return veske
            case "skinnjakke": return skinnjakke
            case "gallakjole": return gallakjole
            case "smykker": return smykker
            case "basseng": return basseng
            case "rosa": return rosa
            case "blaa": return blaa
            case "lue": return lue
            case "gull": return gull
            default: return true
            }
        }
        set {
            switch id {
            case "solbriller": solbriller = newValue
            case "veske": veske = newValue
            case "skinnjakke": skinnjakke = newValue
            case "gallakjole": gallakjole = newValue
            case "smykker": smykker = newValue
            case "basseng": basseng = newValue
            case "rosa": rosa = newValue
            case "blaa": blaa = newValue
            case "lue": lue = newValue
            case "gull": gull = newValue
            default: break
            }
        }
    }
    var count: Int { [solbriller, veske, skinnjakke, gallakjole, smykker, basseng, rosa, blaa, lue, gull].filter { $0 }.count }
}

struct Extra: Codable, Equatable {
    var cloth: [String] = [], hair: [String] = [], wall: [String] = [], furn: [String] = [], band: [String] = [], art: [String] = []
}

struct GameState: Codable, Equatable {
    var v = 1
    var cur = 0
    var people: [Look] = People.start
    var game = Game()
    var unlocked = Unlocked()
    var extra = Extra()
    var opened = 0
    var snd = 2
}

enum People {
    static var start: [Look] {
        func p(_ f: (inout Look) -> Void) -> Look { var l = Look(); f(&l); return l }
        let S = Pal.skin, E = Pal.eyes, H = Pal.hair, C = Pal.cloth
        return [
            p { $0.name = "Nora" },
            p { $0.name = "Amina"; $0.skin = S[4]; $0.hair = "kroller"; $0.hairColor = H[0]; $0.top = "genser"; $0.topColor = C[9]; $0.bottom = "vide"; $0.bottomColor = C[1]; $0.shoes = "boots"; $0.shoeColor = C[1] },
            p { $0.name = "Sofie"; $0.skin = S[0]; $0.eyes = E[3]; $0.hair = "lob"; $0.hairColor = H[5]; $0.freckles = true; $0.top = "skjorte"; $0.topColor = C[5]; $0.bottom = "skjort"; $0.bottomColor = C[1]; $0.shoes = "ballerina"; $0.shoeColor = C[1] },
            p { $0.name = "Leah"; $0.skin = S[2]; $0.eyes = E[2]; $0.hair = "hestehale"; $0.hairColor = H[1]; $0.top = "hettegenser"; $0.topColor = C[8]; $0.bottom = "shorts"; $0.bottomColor = C[5]; $0.shoes = "sneakers"; $0.shoeColor = C[0] },
            p { $0.name = "Maja"; $0.skin = S[1]; $0.eyes = E[1]; $0.hair = "bolgete"; $0.hairColor = H[4]; $0.lips = Pal.lips[1]; $0.top = "singlet"; $0.topColor = C[7]; $0.bottom = "vide"; $0.bottomColor = C[3]; $0.shoes = "ballerina"; $0.shoeColor = C[0] },
            p { $0.name = "Emma"; $0.skin = S[5]; $0.eyes = E[0]; $0.hair = "knute"; $0.hairColor = H[0]; $0.top = "tskjorte"; $0.topColor = C[9]; $0.outer = "dongeri"; $0.outerColor = C[5]; $0.bottom = "jeans"; $0.bottomColor = C[1]; $0.shoes = "boots"; $0.shoeColor = C[1] },
            p { $0.name = "Jonas"; $0.skin = S[1]; $0.eyes = E[3]; $0.hair = "kort"; $0.hairColor = H[3]; $0.top = "hettegenser"; $0.topColor = C[4]; $0.bottom = "jeans"; $0.bottomColor = C[4]; $0.shoes = "sneakers"; $0.shoeColor = C[0] },
            p { $0.name = "Elias"; $0.skin = S[3]; $0.eyes = E[0]; $0.hair = "kort"; $0.hairColor = H[0]; $0.top = "skjorte"; $0.topColor = C[0]; $0.bottom = "vide"; $0.bottomColor = C[8]; $0.shoes = "boots"; $0.shoeColor = C[1] },
        ]
    }
}

/// Lagring: JSON-fil i appens dokumentmappe. Gamle lagringer flettes inn i standardverdiene,
/// slik at nye felt i senere versjoner ikke ødelegger lagrede spill.
enum Store {
    static var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return dir.appendingPathComponent("drommehuset.json")
    }

    static func merge(_ d: Any, _ s: Any?) -> Any {
        guard let dd = d as? [String: Any] else {
            if let s = s, !(s is NSNull) { return type(of: s) == type(of: d) || (s is NSNumber && d is NSNumber) || (s is String && d is String) ? s : d }
            return d
        }
        let sd = s as? [String: Any] ?? [:]
        var o: [String: Any] = [:]
        for (k, v) in dd { o[k] = merge(v, sd[k]) }
        // valgfrie felt som mangler i standardverdiene (som oops) tas med fra lagringen
        for (k, v) in sd where o[k] == nil && !(v is NSNull) { o[k] = v }
        return o
    }

    static func load() -> GameState {
        let def = GameState()
        guard let data = try? Data(contentsOf: url),
              let saved = try? JSONSerialization.jsonObject(with: data),
              let defData = try? JSONEncoder().encode(def),
              var defObj = try? JSONSerialization.jsonObject(with: defData) as? [String: Any]
        else { return def }
        // personer flettes én og én
        let sp = (saved as? [String: Any])?["people"] as? [Any] ?? []
        let dp = defObj["people"] as? [Any] ?? []
        defObj["people"] = dp.enumerated().map { i, p in merge(p, i < sp.count ? sp[i] : nil) }
        var savedObj = saved as? [String: Any] ?? [:]
        savedObj.removeValue(forKey: "people")
        var merged = merge(defObj, savedObj) as? [String: Any] ?? defObj
        merged["people"] = defObj["people"]
        guard let md = try? JSONSerialization.data(withJSONObject: merged),
              var st = try? JSONDecoder().decode(GameState.self, from: md)
        else { return def }
        if st.cur < 0 || st.cur >= st.people.count { st.cur = 0 }
        return st
    }

    static func save(_ s: GameState) {
        if let d = try? JSONEncoder().encode(s) { try? d.write(to: url, options: .atomic) }
    }
}

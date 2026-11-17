import SwiftUI
import UIKit

struct Cook: Equatable {
    var step = 1, tog = false, dish = ""
    var pick: [String: Bool] = [:]
    var opts: [String] = []
    var t0 = 0.0, q = "", wrong = 0
}

struct Writing: Equatable { var to = "", text = "" }

struct Drive: Equatable {
    var v = 0.0, dirn = 1.0, view = "in", meBelt = false, kidBelt = false, wt = 0.0
}

/// Handlingene i Liv (act i nettversjonen).
extension GameModel {
    var nm: String { s.me.name.isEmpty ? "Hun" : s.me.name }
    var use3: Bool { tab == "liv" && (s.life.place == "hjem" || s.life.place == "venn") && flying == nil }
    var belted: Bool { drive.meBelt && (s.kid.age < 0 || drive.kidBelt) }
    static var doorX: [String: Double] { ["moderne": 363, "hytte": 300] }
    var doorX: Double { GameModel.doorX[s.house.type] ?? 320 }

    func need(_ k: String, _ d: Double) { s.need(k, d) }

    func fire(_ ev: String) {
        let (got, up) = s.fire(ev)
        if !got.isEmpty {
            Sound.shared.sfx("coin")
            if up { DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { Sound.shared.sfx("level") } }
            say(got)
        }
    }

    func hostSay(_ t: String) { life3.hostSay(t) }

    /// Kobler 3D-motoren til spillet.
    func setupLife() {
        let e = life3
        e.m = self
        e.cooking = { [weak self] in self?.cook != nil }
        e.onLeave = { [weak self] in self?.leave3() }
        e.onStairs = { [weak self] in self?.fire("stairs") }
        e.onRoom = { [weak self] in self?.objectWillChange.send() }
        e.onShowerDone = { [weak self] in
            guard let self else { return }
            self.s.people[self.s.cur].oops = nil
            self.need("hygiene", 100); self.msg = self.nm + " er frisk og ren."; self.fire("shower")
        }
        e.onPetDone = { [weak self] k in
            guard let self else { return }
            let d: [String: (Double, Double, String)] = ["pet": (15, 10, " liker å bli klappet."), "petplay": (25, 15, " hentet ballen og logrer."), "petfeed": (30, 0, " spiste opp alt i skåla.")]
            guard let q = d[k] else { return }
            self.s.pet.glad = min(100, self.s.pet.glad + q.0); self.need("humor", q.1); self.msg = self.s.pet.name + q.2; self.fire(k)
        }
    }

    func leave3() {
        Sound.shared.sfx("door")
        life3.path = nil; life3.after = nil
        life3.savePos()
        s.life.place = "ute"; s.life.x = doorX; msg = ""
        life3.stop()
    }

    func walkTo(_ x: Double, _ z: Double, _ Y: Double, _ f: (() -> Void)? = nil) { life3.walkTo(x, z, Y, f) }

    // 2D-gåing (ute, flyplass, reise, dyrebutikk)
    func doAt(_ x: Double, _ f: @escaping () -> Void) {
        if abs(wx - x) < 4 { return f() }
        pending = f; tx = x
    }

    func act(_ a: String) {
        let parts = a.split(separator: ":", maxSplits: 1).map(String.init)
        let k = parts[0], v = parts.count > 1 ? parts[1] : ""
        let e = life3, p = s.me, place0 = s.life.place
        msg = ""
        defer {
            if s.life.place != place0 {
                wx = s.life.x; cx = s.life.cx; tx = nil
                Sound.shared.loop("engine", s.life.place == "bil")
                if s.life.place == "bil" { driveNear = Scenes2D.stops.first { abs($0.x - cx) < 120 }?.key ?? "" }
            }
        }
        if k.hasPrefix("job") { jobAct(k, v); return }
        if s.life.place == "bil" && ["friend", "petshop", "airport"].contains(k) { fire("drive") }
        switch k {
        case "letterdone": s.life.letter = nil; return
        case "petbed":
            e.petBed.toggle()
            msg = e.petBed ? p.pet.name + " går og legger seg i " + (p.pet.type == "hund" ? "hundesenga" : "senga si") + "." : p.pet.name + " kommer løpende."
            if !e.petBed { e.petJump = 0.8 }
            Sound.shared.sfx(p.pet.type == "hund" ? "bark" : p.pet.type == "katt" ? "meow" : "squeak"); return
        case "kidbed":
            if e.kbed { e.kbed = false; msg = p.kid.name + " er våken og vil leke."; Sound.shared.sfx("giggle"); return }
            walkTo(8.1, 3.3, 3) { [weak self] in
                guard let self else { return }
                e.kbed = true; self.s.kid.glad = min(100, self.s.kid.glad + 15); self.msg = p.kid.name + " sover i den grønne senga. God natt!"; self.fire("kid")
            }
            return
        case "cooktog":
            guard let hb = e.hb else { return }
            hb.mode = "cook"
            e.hostGo(13.45, 1.8, 0) { hb.ry = Double.pi }
            hostSay("Ja! Så gøy. Jeg hjelper deg.")
            walkTo(12.5, 1.78, 0) { [weak self] in e.me.ry = Double.pi; self?.cook = Cook(step: 1, tog: true) }
            return
        case "eattog":
            guard let hb = e.hb, let fd = s.life.food else { return }
            hb.mode = "eat"
            e.hostGo(15.55, 4.35, 0) { hb.act = "chair"; hb.seat = Seat(x: 15.2, y: 0.5, z: 4.35, r: -Double.pi / 2) }
            walkTo(12.8, 4.35, 0) { [weak self] in
                guard let self else { return }
                e.seat = Seat(x: 13.25, y: 0.5, z: 4.35, r: Double.pi / 2); e.act = "sit"
                self.need("sult", fd.ok ? 55 : 30); self.need("humor", 15); self.fire("eat"); self.fire("cooktog"); self.s.life.food = nil
                self.msg = "Dere spiser " + fd.name.lowercased() + " sammen."
                self.hostSay(fd.ok ? LifeData.pick(["Mmm, dette er skikkelig godt!", "Du må lære meg denne oppskriften."]) : LifeData.pick(["Det smaker litt rart, men det var koselig likevel.", "Neste gang blir den perfekt!"]))
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) { if e.hb?.mode == "eat" { e.hb?.mode = "sat" } }
            }
            return
        case "kid": kidAct(v); return
        case "write": writing = Writing(); return
        case "wto": writing?.to = v; return
        case "wadd":
            if var w = writing, let i = Int(v) {
                let t = w.text.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
                w.text = (t.isEmpty ? "" : t + " ") + LifeData.phrases[i]; writing = w
            }
            return
        case "wcancel": writing = nil; return
        case "wsend":
            guard let w = writing else { return }
            if w.to.isEmpty { msg = "Velg hvem brevet er til."; return }
            if w.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { msg = "Skriv noe i brevet først."; return }
            writing = nil
            doAt(doorX - 80) { [weak self] in
                guard let self else { return }
                self.s.life.pending = w.to; self.need("humor", 8); self.msg = "Brevet til \(w.to) ligger i postkassa og er på vei. Kanskje du får svar."; self.fire("sendmail")
            }
            return
        case "drive": s.life.place = "bil"; s.life.cx = 300; drive = Drive(); return
        case "belt":
            if v == "me" { drive.meBelt = true } else { drive.kidBelt = true }
            Sound.shared.sfx("buckle")
            msg = belted ? "Alle har setebeltet på. God tur!" : v == "me" ? "Setebeltet ditt er på." : p.kid.name + " har setebeltet på."
            return
        case "carcol": s.life.car = v; return
        case "carview": drive.view = drive.view == "in" ? "out" : "in"; return
        case "mail":
            doAt(doorX - 80) { [weak self] in
                guard let self else { return }
                if self.s.game.mail > 0 { self.s.game.mail -= 1; Sound.shared.sfx("rustle"); self.s.life.letter = self.s.genMail(); self.fire("mail") }
            }
            return
        default: break
        }
        if use3 {
            switch k {
            case "sleep":
                walkTo(8, 1.85, 3) { [weak self] in
                    guard let self else { return }
                    e.act = "lie"; if p.kid.age > 0 { e.kbed = true }; if p.pet.type != "none" { e.petBed = true }
                    if self.s.house.time == "dag" { self.s.house.time = "kveld" }
                    self.need("energi", 100); self.fire("sleep"); self.msg = self.nm + " sover. Trykk «Stå opp» når det er morgen."
                    e.sync()
                }
                return
            case "wake": e.endAct(quiet: true); e.kbed = false; e.petBed = false; s.house.time = "dag"; msg = "God morgen! En ny dag."; e.sync(); return
            case "sit": walkTo(7.1, 1.78, 0) { [weak self] in guard let self else { return }; e.seat = nil; e.act = "sit"; self.need("humor", 5); self.msg = self.nm + " slapper av i sofaen." }; return
            case "tv":
                if !s.house.inne.stue.has("tv") { msg = "Du har ingen TV. Sett inn en under Hus."; return }
                s.life.tv.toggle(); e.sync()
                if !s.life.tv { msg = "TV-en er slått av."; return }
                need("humor", 20); fire("tv"); msg = nm + " ser på TV."
                walkTo(7.1, 1.78, 0) { e.act = "sit" }
                return
            case "toilet":
                walkTo(13.05, 1.8, 3) { [weak self] in
                    guard let self else { return }
                    e.seat = Seat(x: 13.05, y: 3.47, z: 0.62, r: 0); e.act = "toilet"; e.actT = 3; self.msg = self.nm + " er på do."
                    e.actDone = { [weak self] in Sound.shared.sfx("flush"); self?.s.life.wash = true; self?.fire("toilet"); self?.msg = "Ferdig! Husk å vaske hendene." }
                }
                return
            case "wash":
                walkTo(14.2, 1.8, 3) { [weak self] in
                    guard let self else { return }
                    e.me.ry = Double.pi; e.act = "wash"; e.actT = 2.6; self.msg = self.nm + " vasker hendene."
                    e.actDone = { [weak self] in
                        guard let self else { return }
                        let w = self.s.life.wash; self.s.life.wash = false; self.need("hygiene", 10); self.fire("wash"); self.msg = w ? "Rene hender. Bra!" : "Hendene er rene og fine."
                    }
                }
                return
            case "bath":
                walkTo(15.4, 1.95, 3) { [weak self] in
                    guard let self else { return }
                    e.seat = Seat(x: 15.4, y: 3.22, z: 0.55, r: 0); e.act = "bath"; e.actT = 5; e.setTowel(true); Sound.shared.sfx("splash"); Sound.shared.loop("water", true)
                    e.built.foam?.isHidden = false; self.msg = self.nm + " ligger i badekaret."
                    e.actDone = { [weak self] in
                        guard let self else { return }
                        self.s.people[self.s.cur].oops = nil; self.need("hygiene", 100); self.need("humor", 12); self.need("energi", 10); self.fire("bath"); self.msg = "For et deilig bad!"
                    }
                }
                return
            case "shower":
                walkTo(11.9, 1.78, 3) { [weak self] in
                    guard let self else { return }
                    e.act = "shower"; e.actT = 3.6; e.setTowel(true); Sound.shared.loop("water", true); e.built.water?.isHidden = false
                    Mat3.m("#bfe0ec", "g").transparency = 0.78; self.msg = self.nm + " dusjer."
                }
                return
            case "wardrobe": walkTo(5.75, 1.8, 3) { [weak self] in self?.ward = true; e.me.ry = 0 }; return
            case "wardone": ward = false; e.sync(); return
            default: break
            }
        }
        let T3: [String: (Double, Double, Double)] = ["gang": (2.6, 3.1, 0), "stue": (8, 3.1, 0), "kjokken": (13, 3.1, 0), "oppe": (2.6, 3.1, 3), "soverom": (8, 3.1, 3), "bad": (13.3, 3.1, 3)]
        let SP: [String: (Double, Double, Double)] = ["tv": (7.2, 1.9, 0), "cook": (12.5, 1.78, 0), "sleep": (8, 1.85, 3), "shower": (11.8, 1.78, 3)]
        func at(_ n: String, _ x: Double, _ f: @escaping () -> Void) { if use3, let q = SP[n] { walkTo(q.0, q.1, q.2, f) } else { doAt(x, f) } }
        switch k {
        case "goto": if let q = T3[v] { walkTo(q.0, q.1, q.2) }
        case "out": walkTo(0.42, 3.1, 0) { [weak self] in self?.leave3() }
        case "sleep":
            at("sleep", 280) { [weak self] in
                guard let self else { return }
                self.s.house.time = self.s.house.time == "dag" ? "kveld" : "dag"; self.need("energi", 100); self.fire("sleep")
                self.msg = self.s.house.time == "dag" ? "God morgen! En ny dag." : "God natt. Det er blitt kveld."
            }
        case "shower": at("shower", 116) { [weak self] in guard let self else { return }; self.s.people[self.s.cur].oops = nil; self.need("hygiene", 100); self.fire("shower"); self.msg = self.nm + " er frisk og ren." }
        case "cook": at("cook", 290) { [weak self] in self?.cook = Cook(step: 1) }
        case "eat":
            guard let f = s.life.food else { return }
            need("sult", f.ok ? 55 : 25); fire("eat")
            msg = "\(nm) spiste \(f.name.lowercased()). \(f.ok ? "Det smakte nydelig." : "Det smakte ikke helt som det skulle.")"; s.life.food = nil
        case "dish":
            guard let r = LifeData.recipes[v] else { return }
            let tg = cook?.tog ?? false
            if tg { hostSay(LifeData.pick(["Mmm, \(r.0.lowercased())! Det er favoritten min.", "Godt valg! Jeg finner fram en panne.", "Jeg vet akkurat hva som skal i."])) }
            let rest = Array(LifeData.allIng.filter { !r.1.contains($0) }.shuffled().prefix(5))
            cook = Cook(step: 2, tog: tg, dish: v, pick: [:], opts: (r.1 + rest).shuffled())
        case "ing": cook?.pick[v] = !(cook?.pick[v] ?? false)
        case "heat":
            if cook?.tog == true { hostSay("Nå begynner det å lukte godt! Følg med på fargen.") }
            Sound.shared.loop("sizzle", true)
            cook?.step = 3; cook?.t0 = CACurrentMediaTime()
            let t0 = cook?.t0
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.7) { [weak self] in if self?.cook?.step == 3 && self?.cook?.t0 == t0 { self?.finishCook(CACurrentMediaTime() + 9.999) } }
        case "off": finishCook(CACurrentMediaTime())
        case "cookend":
            Sound.shared.loop("sizzle", false); cook = nil
            if let hb = e.hb, hb.mode == "cook" { hb.mode = "follow"; hb.idle = -6 }
        case "in":
            Sound.shared.sfx("door"); s.life.place = "hjem"; s.life.room = "gang"; s.life.x = 110; s.life.h3 = Pos(x: 0.9, z: 3.1, y: 0); e.me.ry = Double.pi / 2
            e.h.x = 0.9; e.h.z = 3.1; e.h.y = 0
        case "say": sayIt(sayText)
        case "sayq": if let i = Int(v) { sayIt(LifeData.sayQ[i]) }
        case "friend":
            e.hb = nil; s.life.meSaid = ""; need("humor", 20); fire((Int(v) ?? 0) >= s.people.count ? "nabo" : "friend")
            s.life.f3 = Pos(x: 0.9, z: 3.1, y: 0); e.me.ry = Double.pi / 2; e.h.x = 0.9; e.h.z = 3.1; e.h.y = 0
            s.life.place = "venn"; s.life.friend = Int(v) ?? 0; s.life.x = 420; s.life.line = 0; s.life.said = ""
        case "talk": s.life.meSaid = ""; s.life.line = (s.life.line + 1) % LifeData.lines.count; s.life.said = ""
        case "give":
            guard let f = s.life.food else { return }
            need("humor", 10); fire("give"); s.life.said = f.ok ? "Tusen takk! Det smakte nydelig." : "Øh, takk. Den var litt spesiell."; s.life.food = nil
        case "home": e.endAct(quiet: true); e.stop(); s.life.place = "ute"; s.life.x = doorX
        case "airport": s.life.place = "flyplass"; s.life.x = 200
        case "land": land()
        case "window": flyView = flyView == "out" ? "cabin" : "out"
        case "snack": if !snack { snack = true; need("sult", 15); msg = "Du fikk en bolle og et glass saft." }
        case "crew":
            s.life.crew[v] = !(s.life.crew[v] ?? false)
            let people = s.life.crew.filter { $0.value && $0.key != "f\(s.cur)" && $0.key != "kid" && $0.key != "pet" }.count
            if people > 4 { s.life.crew[v] = false; msg = "Du kan ha med deg fire stykker." }
        case "fly":
            let pr = v == "home" ? 0 : (LifeData.dest[v]?.3 == true ? 20 : 45)
            let c = flightCost(pr)
            if s.game.coins < c { msg = "Du har ikke nok mynter til billetten. Fullfør oppdrag for å tjene flere."; return }
            s.game.coins -= c; fly(v)
        case "petshop": s.life.place = "dyr"; s.life.x = 150
        case "ptype": s.life.shop.type = v
        case "pcol": s.life.shop.color = v
        case "adopt":
            guard let pt = LifeData.pets[s.life.shop.type] else { return }
            if s.game.coins < pt.1 { msg = "Du har ikke nok mynter. Fullfør oppdrag for å tjene flere."; return }
            s.game.coins -= pt.1
            s.pet = Pet(type: s.life.shop.type, name: s.life.shop.name.isEmpty ? pt.2 : s.life.shop.name, color: s.life.shop.color, glad: 80)
            msg = s.pet.name + " er blitt med hjem. Dyret følger deg rundt i huset."; fire("adopt")
        case "pet", "petplay", "petfeed":
            if use3 && e.petRig != nil {
                if e.h.z < 1.7 || (e.h.y > 0.05 && e.h.y < 2.95) { msg = "Gå bort fra trappa først."; return }
                e.startPet(k)
                msg = ["pet": nm + " klapper " + p.pet.name + ".", "petplay": nm + " kaster ballen.", "petfeed": nm + " setter fram matskåla."][k] ?? ""
                return
            }
            let d: [String: (Double, Double, String)] = ["pet": (15, 10, " liker å bli klappet."), "petplay": (25, 15, " hopper av glede."), "petfeed": (30, 0, " spiser opp alt.")]
            if let q = d[k] { s.pet.glad = min(100, s.pet.glad + q.0); need("humor", q.1); e.petJump = k == "petfeed" ? 0.4 : 1.2; msg = s.pet.name + q.2; fire(k) }
        default: break
        }
    }

    /// Hvor mye flybilletten koster for alle som blir med.
    func flightCost(_ pr: Int) -> Int {
        let cl = crewKinds()
        return pr * (1 + cl.people) + Int((Double(pr) / 2).rounded()) * cl.kids + (pr > 0 ? 10 : 0) * cl.pets
    }

    func crewKinds() -> (people: Int, kids: Int, pets: Int) {
        let c = s.life.crew
        var people = 0
        for (k, on) in c where on && k != "kid" && k != "pet" {
            if k.hasPrefix("f"), let i = Int(k.dropFirst()), i == s.cur || i >= s.people.count { continue }
            people += 1
        }
        let kids = (c["kid"] ?? false) && s.kid.age >= 0 ? 1 : 0
        let pets = (c["pet"] ?? false) && s.pet.type != "none" ? 1 : 0
        return (people, kids, pets)
    }

    func fly(_ id: String) {
        Sound.shared.loop("plane", true); flying = id; flyView = "cabin"; snack = false; tx = nil; pending = nil; msg = ""
    }

    func land() {
        guard let f = flying else { return }
        Sound.shared.loop("plane", false); Sound.shared.sfx("ding")
        var ev = ""
        if f == "home" { s.life.place = "ute"; s.life.x = doorX }
        else {
            s.life.place = "reise"; s.life.dest = f; s.life.stamps[f] = true; s.life.x = 170
            let ck = crewKinds()
            need("humor", 30 + Double(ck.people + ck.kids + ck.pets) * 5)
            ev = LifeData.dest[f]?.3 == true ? "flyno" : "flyut"
        }
        flying = nil; msg = ""
        if !ev.isEmpty { fire(ev) }
    }

    func finishCook(_ now: Double) {
        Sound.shared.loop("sizzle", false)
        guard var c = cook, c.step == 3, let r = LifeData.recipes[c.dish] else { return }
        let p = (now - c.t0) / 3.6
        let q = p < 0.55 ? "raa" : p <= 0.78 ? "perfekt" : "brent"
        let wrong = r.1.filter { !(c.pick[$0] ?? false) }.count + c.pick.filter { $0.value && !r.1.contains($0.key) }.count
        c.step = 4; c.q = q; c.wrong = wrong; cook = c
        s.life.food = Food(key: c.dish, name: r.0, q: q, ok: q == "perfekt" && wrong == 0)
        need("energi", -5); fire("cook:" + c.dish)
        if s.life.food?.ok == true { fire("cookperfect") }
        if c.tog {
            hostSay(q == "perfekt" && wrong == 0 ? LifeData.pick(["Perfekt! Du er en mesterkokk.", "Wow, se så fin den ble!"]) : q == "raa" ? "Hmm, den er visst litt rå." : q == "brent" ? "Oi, den ble litt brent. Vi spiser den likevel!" : "Noen ingredienser var feil, men det gjør ingenting.")
        }
    }

    func sayIt(_ t0: String) {
        let t = String(t0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        if t.isEmpty { return }
        s.life.meSaid = t; s.life.said = "…"; sayText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            guard let self, self.s.life.place == "venn" else { return }
            let a = LifeData.answer(t, pet: self.s.pet)
            self.s.life.said = a; self.hostSay(a); self.need("humor", 3); self.fire("talk")
        }
    }

    func kidAct(_ v: String) {
        let e = life3
        if v == "play" || v == "cuddle" { DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { Sound.shared.sfx("giggle") } }
        var T = ["bottle": " drikker flaska si.", "cuddle": " koser seg i armene dine.", "song": " sovner til sangen din.", "play": " ler og hopper.", "read": " hører på eventyret.", "food": " spiser opp maten sin."][v] ?? ""
        let done: () -> Void = { [weak self] in
            guard let self else { return }
            var kd = self.s.kid
            kd.xp += 1; kd.glad = min(100, kd.glad + 20); self.need("humor", 8); self.msg = kd.name + T
            if kd.age == 0 && kd.xp >= 4 { kd.age = 1; self.msg = kd.name + " har vokst og kan gå selv!"; self.say(self.msg) }
            else if kd.age == 1 && kd.xp >= 10 { kd.age = 2; self.msg = kd.name + " er blitt et stort barn."; self.say(self.msg) }
            self.s.kid = kd
            self.fire("kid")
            e.sync()
        }
        if v == "bottle" { s.kid.mett = min(100, s.kid.mett + 45) }
        if v == "food" {
            let own = s.life.food
            let dish = own?.name.lowercased() ?? LifeData.pick(["grøt", "fiskepinner", "pannekaker", "brødskive med ost", "fruktbiter"])
            if own != nil { s.life.food = nil }
            s.kid.mett = min(100, s.kid.mett + (own != nil ? 60 : 45))
            T = " spiser " + dish + (own?.ok == true ? ". Det smakte kjempegodt!" : ".")
            if use3 && s.life.place == "hjem" && s.kid.age > 0 && s.house.inne.kjokken.has("spisebord") {
                msg = nm + " setter fram mat til " + s.kid.name + "."
                let kn = s.kid.name
                walkTo(12.7, 3.4, 0) { [weak self] in
                    e.me.ry = atan2(0.55, 0.95); e.kseat = KidSeat(t: 4.5, done: done); self?.msg = kn + " spiser " + dish + " ved kjøkkenbordet."
                }
                return
            }
        }
        if use3 && s.life.place == "hjem" && s.kid.age == 0 {
            let kn = s.kid.name
            if v == "carry" {
                if e.carry { return }
                msg = nm + " går bort til sprinkelsenga."
                walkTo(9.55, 2.3, 3) { [weak self] in e.me.ry = Double.pi / 2; e.setCarry(true); Sound.shared.sfx("giggle"); self?.msg = self!.nm + " bærer " + kn + ". Babyen blir med der du går." }
                return
            }
            if v == "down" {
                walkTo(9.55, 2.3, 3) { [weak self] in e.me.ry = Double.pi / 2; e.endAct(quiet: true); e.setCarry(false); self?.msg = kn + " ligger i sprinkelsenga igjen." }
                return
            }
            let begin: () -> Void = { [weak self] in
                guard let self else { return }
                e.startBaby(v, done)
                self.msg = v == "song" ? self.nm + " synger «Bæ, bæ, lille lam» for " + kn + "." : v == "bottle" ? self.nm + " gir " + kn + " flaska." : self.nm + " koser med " + kn + "."
            }
            if e.carry { begin() } else { walkTo(9.55, 2.3, 3) { e.me.ry = Double.pi / 2; begin() } }
            return
        }
        if use3 && s.kid.age > 0 { e.kjump = 1.1; e.act = "bend"; e.actT = 1.6 }
        done()
    }
}

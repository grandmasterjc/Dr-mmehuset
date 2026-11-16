import SwiftUI
import UIKit

/// Holder spillet i minnet, lagrer automatisk og varsler skjermen om endringer.
@MainActor
final class GameModel: ObservableObject {
    @Published var s: GameState { didSet { Store.save(s) } }
    @Published var tab = "sminke"
    @Published var faceView = true
    @Published var ask: String? = nil
    @Published var toast: String? = nil
    @Published var gift: GiftResult? = nil
    @Published var shaking = false
    @Published var kform = KidForm()

    // Liv
    let life3 = Life3D()
    @Published var msg = ""
    @Published var cook: Cook? = nil
    @Published var writing: Writing? = nil
    @Published var flying: String? = nil
    @Published var flyView = "cabin"
    @Published var snack = false
    @Published var drive = Drive()
    @Published var sayText = ""
    var wx = 320.0, cx = 300.0, wheelAng = 0.0, driveDir = 0.0, driveNear = ""
    let loop2D = Loop2D()
    @Published var ward = false
    @Published var job: Job? = nil
    var tx: Double? = nil
    var pending: (() -> Void)? = nil
    var ticker: Timer? = nil

    init() {
        s = Store.load()
        // brukes av den automatiske testen på GitHub for å ta skjermbilder av ulike faner
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-tab"), i + 1 < a.count { tab = a[i + 1] }
        if let i = a.firstIndex(of: "-husvis"), i + 1 < a.count { s.house.view = a[i + 1] }
        if let i = a.firstIndex(of: "-rom"), i + 1 < a.count { s.house.inne.rom = a[i + 1] }
        if let i = a.firstIndex(of: "-tid"), i + 1 < a.count { s.house.time = a[i + 1] }
        if let i = a.firstIndex(of: "-sted"), i + 1 < a.count { s.life.place = a[i + 1] }
        for sl in ["a", "b", "c"] {
            let t = sl == "a" ? s.game.tasks.a : sl == "b" ? s.game.tasks.b : s.game.tasks.c
            let ok = GameState.isCook(t) ? LifeData.recipes[String(t.dropFirst(5))] != nil : LifeData.tasks[t] != nil
            if !ok { let n = s.newTask(); if sl == "a" { s.game.tasks.a = n } else if sl == "b" { s.game.tasks.b = n } else { s.game.tasks.c = n } }
        }
        Sound.shared.level = s.snd
        Sound.shared.evening = s.house.time == "kveld"
        Life3D.hostLookFn = { Scenes2D.hostLook($0, $1) }
        setupLife()
        if s.life.place == "bakeri" || s.life.place == "dyrepark" { jobAct("job", s.life.place == "bakeri" ? "baker" : "zoo") }
        ticker = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.tab == "liv", self.flying == nil, self.cook == nil else { return }
                if let t = self.s.tick() { self.say(t) }
            }
        }
    }

    var me: Look { s.me }

    func set<T>(_ kp: WritableKeyPath<Look, T>, _ v: T) { s.people[s.cur][keyPath: kp] = v }

    func say(_ t: String) {
        toast = t
        let id = t
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in if self?.toast == id { self?.toast = nil } }
    }

    func choose(_ i: Int) { s.cur = i; gift = nil; ask = nil }

    func buy(_ id: String) {
        guard let it = Shop.item(id) else { return }
        if s.buy(id) { ask = nil; Haptics.success(); say("Du kjøpte \(it.name.lowercased()) for \(it.price) mynter.") }
    }

    func randomize() { var g = SystemRandomNumberGenerator(); s.randomize(using: &g); Haptics.tap() }

    func openGift() {
        guard !shaking else { return }
        if s.game.free == 0 && s.game.coins < s.giftPrice { say("En pakke koster \(s.giftPrice) mynter. Du har \(s.game.coins)."); return }
        gift = nil
        shaking = true
        Haptics.tap()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self else { return }
            var g = SystemRandomNumberGenerator()
            self.gift = self.s.openGift(using: &g)
            self.shaking = false
            if self.gift?.good == true { Haptics.success() } else { Haptics.warn() }
            if let r = self.gift { self.faceView = r.face }
            self.fire("gift")
        }
    }
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warn() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

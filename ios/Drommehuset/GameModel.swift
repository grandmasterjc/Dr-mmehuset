import SwiftUI
import UIKit

/// Holder spillet i minnet, lagrer automatisk og varsler skjermen om endringer.
final class GameModel: ObservableObject {
    @Published var s: GameState { didSet { Store.save(s) } }
    @Published var tab = "sminke"
    @Published var faceView = true
    @Published var ask: String? = nil
    @Published var toast: String? = nil
    @Published var gift: GiftResult? = nil
    @Published var shaking = false
    @Published var kform = KidForm()

    init() {
        s = Store.load()
        // brukes av den automatiske testen på GitHub for å ta skjermbilder av ulike faner
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-tab"), i + 1 < a.count { tab = a[i + 1] }
        if let i = a.firstIndex(of: "-husvis"), i + 1 < a.count { s.house.view = a[i + 1] }
        if let i = a.firstIndex(of: "-rom"), i + 1 < a.count { s.house.inne.rom = a[i + 1] }
        if let i = a.firstIndex(of: "-tid"), i + 1 < a.count { s.house.time = a[i + 1] }
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
        }
    }
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warn() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

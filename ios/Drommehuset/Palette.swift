import Foundation

// Farger og faste verdier, overført fra nettversjonen av Drømmehuset.
enum Pal {
    static let skin = ["#f6ddcc", "#eac4a6", "#d3a17c", "#a8734f", "#7b5137", "#55382a"]
    static let eyes = ["#6b4226", "#8a6a3a", "#5d7f56", "#5f87ad", "#7d8a94"]
    static let lips = ["#c9736b", "#d98a80", "#b3475a", "#c4313f", "#8e2f45", "#6e2233"]
    static let shadow = ["#b08a72", "#8a5a4a", "#c79a8e", "#6f6a7d", "#b99a4e", "#59708a"]
    static let blush = ["#e58a8a", "#d9806a", "#c76b8a"]
    static let hair = ["#1c1513", "#3b2416", "#6a4226", "#9a6b3f", "#c9a063", "#e8d5a8", "#9c4a25", "#7a2337"]
    static let cloth = ["#f5f3ee", "#1f1f24", "#8c8f96", "#d8c3a5", "#34507a", "#7fa3c7", "#9b3b47", "#c97b84", "#5d7a5e", "#c9a227"]
    static let wall = ["#f4f1ea", "#2e3338", "#b9b2a6", "#8b2f2a", "#d9c36a", "#56707f", "#7a5a3e"]
    static let roof = ["#2b2d31", "#6d747b", "#5a3a32", "#8a3b2e"]
    static let door = ["#1f1f24", "#f4f1ea", "#8b2f2a", "#34507a", "#5d7a5e", "#c9a227", "#7a5a3e"]
    static let wallIn = ["#f4f1ea", "#e7ddd0", "#c7b299", "#d7dfd6", "#8a9a84", "#cfd9e3", "#e9cfd0", "#3a4250"]
    static let furn = ["#d8c3a5", "#f4f1ea", "#8c8f96", "#2e3338", "#34507a", "#5d7a5e", "#9b3b47", "#c97b84", "#c9a227"]
    static let gold = "#d4a843"
    static let rosa = "#e88fb5"
    static let blaa = "#5b7fd1"
}

/// Gjør en farge mørkere (a < 0) eller lysere (a > 0), samme regnestykke som i nettversjonen.
func shade(_ hex: String, _ a: Double) -> String {
    let n = Int(hex.dropFirst(), radix: 16) ?? 0
    let t: Double = a < 0 ? 0 : 255
    let p = abs(a)
    func f(_ c: Int) -> Int { Int((Double(c) + (t - Double(c)) * p).rounded()) }
    let r = f(n >> 16), g = f((n >> 8) & 255), b = f(n & 255)
    let v = (1 << 24) + (r << 16) + (g << 8) + b
    return "#" + String(String(v, radix: 16).dropFirst())
}

func hsl(_ h: Double, _ s0: Double, _ l0: Double) -> String {
    let s = s0 / 100, l = l0 / 100
    func k(_ n: Double) -> Double { (n + h / 30).truncatingRemainder(dividingBy: 12) }
    let a = s * min(l, 1 - l)
    func f(_ n: Double) -> Int { Int((255 * (l - a * max(-1, min(k(n) - 3, 9 - k(n), 1)))).rounded()) }
    return "#" + [f(0), f(8), f(4)].map { String(format: "%02x", $0) }.joined()
}

/// Tall skrevet slik JavaScript skriver dem (3 i stedet for 3.0).
func js(_ x: Double) -> String {
    if x == x.rounded(), abs(x) < 1e15 { return String(Int(x)) }
    return "\(x)"
}
func js(_ x: Int) -> String { String(x) }
/// Som JavaScripts toFixed: runder halve opp (bort fra null).
func fx(_ x: Double, _ d: Int) -> String {
    let p = pow(10.0, Double(d)), y = x * p
    if abs(y - y.rounded(.towardZero)) == 0.5 {
        let r = y.rounded(.toNearestOrAwayFromZero) / p
        return String(format: "%.\(d)f", r)
    }
    return String(format: "%.\(d)f", x)
}

/// Samme tilfeldige tall-rekke som rng() i nettversjonen (gir samme kunstverk og mønstre).
struct Rng {
    var s: Double
    init(_ seed: Double) { s = seed }
    mutating func next() -> Double { s = (s * 16807).truncatingRemainder(dividingBy: 2147483647); return s / 2147483647 }
}

struct Feat: Codable, Equatable {
    var face: String
    var er: Double
    var es: Double
    var lip: Double
    var bx: Double
    var h: Double
}

enum Feats {
    static let people: [Feat] = [
        Feat(face: "oval", er: 0, es: 1, lip: 1, bx: 1, h: 1),
        Feat(face: "rund", er: -5, es: 1.05, lip: 1.3, bx: 1.06, h: 0.96),
        Feat(face: "kantet", er: 3, es: 0.92, lip: 0.88, bx: 0.95, h: 1),
        Feat(face: "rund", er: -2, es: 0.98, lip: 1.12, bx: 1, h: 0.92),
        Feat(face: "oval", er: -4, es: 1.02, lip: 1.15, bx: 0.98, h: 0.95),
        Feat(face: "kantet", er: 1, es: 0.96, lip: 1.05, bx: 1.02, h: 1),
        Feat(face: "kantet", er: 2, es: 0.86, lip: 0.75, bx: 1.16, h: 1.06),
        Feat(face: "oval", er: 0, es: 0.88, lip: 0.78, bx: 1.12, h: 1.04),
    ]
    static let head: [String: String] = [
        "oval": "M150 30C170 30 181 46 181 66C181 80 176 92 167 100C161 106 155 109 150 109C145 109 139 106 133 100C124 92 119 80 119 66C119 46 130 30 150 30Z",
        "rund": "M150 30C171 30 182 46 182 66C182 84 177 96 168 102C161 107 155 109.5 150 109.5C145 109.5 139 107 132 102C123 96 118 84 118 66C118 46 129 30 150 30Z",
        "kantet": "M150 30C170 30 181 46 181 66C181 78 178 89 171 97C164 104 157 109 150 109C143 109 136 104 129 97C122 89 119 78 119 66C119 46 130 30 150 30Z",
    ]
}

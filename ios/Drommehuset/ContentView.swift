import SwiftUI

@main
struct DrommehusetApp: App {
    @StateObject private var model = GameModel()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(model).preferredColorScheme(.light)
        }
    }
}

let tabs = opts([("sminke", "Sminke"), ("haar", "Hår"), ("klaer", "Klær"), ("hus", "Hus"), ("barn", "Barn"), ("liv", "Liv"), ("pakke", "Pakke")])

struct ContentView: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 760
            VStack(spacing: 10) {
                Header()
                if wide {
                    HStack(alignment: .top, spacing: 18) {
                        Stage().frame(maxWidth: .infinity, maxHeight: .infinity)
                        VStack(spacing: 10) { TabBar(); PanelArea() }.frame(maxWidth: .infinity)
                    }
                } else {
                    Stage().frame(height: geo.size.height * 0.5)
                    TabBar()
                    PanelArea()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}

struct Header: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        HStack(spacing: 10) {
            Text("Drømmehuset").font(Theme.title(26)).foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.6)
            Spacer(minLength: 4)
            HStack(spacing: 6) {
                Circle().fill(Theme.gold).frame(width: 12, height: 12).overlay(Circle().stroke(Color(hex: "#b5892a"), lineWidth: 2))
                Text("\(m.s.game.coins)").font(.system(size: 16, weight: .semibold)).monospacedDigit()
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(Theme.panel)).overlay(Capsule().stroke(Theme.line))
            .accessibilityLabel("\(m.s.game.coins) mynter")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(m.s.people.indices, id: \.self) { i in
                        Button { m.choose(i) } label: { Avatar(look: m.s.people[i], feat: Feats.people[i], on: i == m.s.cur) }
                            .buttonStyle(.plain).accessibilityLabel(m.s.people[i].name)
                    }
                }
                .padding(3)
            }
            .frame(maxWidth: 360)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct Avatar: View {
    let look: Look
    let feat: Feat
    var on = false
    var body: some View {
        SVGView(svg: Figure(s: look, f: feat).svg(), viewBox: CGRect(x: 108, y: 20, width: 84, height: 96), alignBottom: false)
            .frame(width: 40, height: 40)
            .background(Color(hex: "#ddd7d5"))
            .clipShape(Circle())
            .overlay(Circle().stroke(on ? Theme.accent : Theme.line, lineWidth: on ? 2.5 : 1))
    }
}

struct Stage: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        let s = m.me, f = m.s.feat, fig = Figure(s: s, f: f).svg()
        ZStack {
            RadialGradient(colors: [Color(hex: "#f5f2f0"), Color(hex: "#ddd7d5"), Color(hex: "#c4bdbb")], center: UnitPoint(x: 0.5, y: 0.28), startRadius: 0, endRadius: 520)
            if m.faceView {
                SVGView(svg: fig, viewBox: CGRect(x: 86, y: 0, width: 128, height: 166), alignBottom: false)
            } else {
                SVGView(svg: "<g transform=\"translate(150 598) scale(\(js(f.h))) translate(-150 -598)\">\(fig)</g>")
                    .padding(.top, 12)
            }
            VStack {
                HStack {
                    if s.oops != nil {
                        StageButton(label: "Fiks det", dark: true) { m.set(\.oops, nil) }
                    }
                    Spacer()
                    StageButton(label: m.faceView ? "Hel figur" : "Nærbilde") { m.faceView.toggle() }
                }
                Spacer()
                HStack(alignment: .bottom) {
                    Text(s.name).font(Theme.title(22)).foregroundStyle(Theme.ink)
                    Spacer()
                    StageButton(label: "Tilfeldig stil") { m.randomize() }
                }
            }
            .padding(10)
            if let t = m.toast {
                VStack {
                    Text(t).font(.system(size: 15)).foregroundStyle(.white).multilineTextAlignment(.center)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 9).fill(Theme.ink.opacity(0.93)))
                        .padding(.top, 54).padding(.horizontal, 12)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: m.toast)
    }
}

struct StageButton: View {
    let label: String
    var dark = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .foregroundStyle(dark ? Color.white : Theme.ink)
                .background(RoundedRectangle(cornerRadius: 7).fill(dark ? Theme.ink : Color.white.opacity(0.88)))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.ink.opacity(dark ? 0 : 0.15)))
        }
        .buttonStyle(.plain)
    }
}

struct TabBar: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { t in
                Button { m.tab = t.id; m.ask = nil; Haptics.tap() } label: {
                    VStack(spacing: 6) {
                        Text(t.label.uppercased()).font(.system(size: 12, weight: .medium)).kerning(0.6)
                            .foregroundStyle(m.tab == t.id ? Theme.ink : Theme.soft)
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Rectangle().fill(m.tab == t.id ? Theme.accent : Color.clear).frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .bottom)
    }
}

struct PanelArea: View {
    @EnvironmentObject var m: GameModel
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                Group {
                    switch m.tab {
                    case "sminke": SminkePanel()
                    case "haar": HaarPanel()
                    case "klaer": KlaerPanel()
                    case "pakke": PakkePanel()
                    case "hus": SnartPanel(title: "Hus")
                    case "barn": SnartPanel(title: "Barn")
                    default: SnartPanel(title: "Liv")
                    }
                }
                .padding(16)
                .padding(.bottom, m.ask != nil ? 150 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.panel))
            if let id = m.ask, let it = Shop.item(id) { BuyBar(item: it) }
        }
    }
}

struct BuyBar: View {
    @EnvironmentObject var m: GameModel
    let item: ShopItem
    var body: some View {
        let c = m.s.game.coins, miss = item.price - c
        VStack(alignment: .leading, spacing: 10) {
            (Text(item.name).bold() + Text(" koster \(item.price) mynter. Du har \(c)."))
            if miss > 0 {
                Text("Du mangler \(miss) mynter. Vinn den i en pakke, eller tjen mynter når Liv kommer i appen.").font(.system(size: 14)).foregroundStyle(Theme.soft)
                Chip(label: "Ok") { m.ask = nil }
            } else {
                HStack {
                    PrimaryButton(label: "Kjøp for \(item.price) mynter") { m.buy(item.id) }
                    Chip(label: "Ikke nå") { m.ask = nil }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.panel).shadow(color: .black.opacity(0.1), radius: 8, y: -3))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line))
    }
}

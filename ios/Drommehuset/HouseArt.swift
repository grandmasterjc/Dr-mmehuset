import Foundation

let GDEFS = "<defs><filter id=\"b1\" x=\"-30%\" y=\"-30%\" width=\"160%\" height=\"160%\"><feGaussianBlur stdDeviation=\".8\"/></filter><filter id=\"b2\" x=\"-50%\" y=\"-50%\" width=\"200%\" height=\"200%\"><feGaussianBlur stdDeviation=\"2.2\"/></filter></defs>"

func isLight(_ c: String) -> Bool {
    let n = Int(c.dropFirst(), radix: 16) ?? 0
    return Double(n >> 16) * 0.3 + Double((n >> 8) & 255) * 0.59 + Double(n & 255) * 0.11 > 150
}

/// Tegninger av huset utenfra og rommene innenfra, overført fra nettversjonen.
enum HouseArt {
    static func skyColors(_ st: GameState) -> [String] {
        st.rain ? ["#7d8794", "#bcc3ca"] : st.house.time == "kveld" ? ["#232a4d", "#e59a78"] : ["#8fc1ea", "#e6f1f8"]
    }

    static func doorX(_ t: String) -> Int { t == "moderne" ? 363 : t == "hytte" ? 300 : 320 }

    // MARK: huset utenfra
    static func house(_ st: GameState) -> (String, String) {
        let h = st.house, g = h.garden, eve = h.time == "kveld", rain = st.rain
        let W = h.wall, R = h.roofColor, T = h.trim == "svart" ? "#26282c" : "#f6f4ef", Td = shade(T, h.trim == "svart" ? 0.2 : -0.15), D = h.door
        let sky = skyColors(st)
        var lit: [(Double, Double, Double, Double, String)] = []
        var o = ""
        func win(_ x: Double, _ y: Double, _ w: Double, _ hh: Double, _ cols: Int, _ rows: Int) -> String {
            var m = ""
            if cols > 1 { for i in 1..<cols { m += "M\(js(x + w * Double(i) / Double(cols))) \(js(y))L\(js(x + w * Double(i) / Double(cols))) \(js(y + hh))" } }
            if rows > 1 { for i in 1..<rows { m += "M\(js(x)) \(js(y + hh * Double(i) / Double(rows)))L\(js(x + w)) \(js(y + hh * Double(i) / Double(rows)))" } }
            lit.append((x, y, w, hh, m))
            return "<rect x=\"\(js(x - 3))\" y=\"\(js(y - 3))\" width=\"\(js(w + 6))\" height=\"\(js(hh + 6))\" fill=\"\(T)\"/><rect x=\"\(js(x))\" y=\"\(js(y))\" width=\"\(js(w))\" height=\"\(js(hh))\" fill=\"url(#glass)\"/>"
                + "<path d=\"M\(js(x)) \(js(y + hh * 0.7))L\(js(x + w * 0.45)) \(js(y))L\(js(x + w * 0.7)) \(js(y))L\(js(x)) \(js(y + hh))Z\" fill=\"#fff\" opacity=\".16\"/>" + (m.isEmpty ? "" : "<path d=\"\(m)\" stroke=\"\(T)\" stroke-width=\"2\"/>")
                + "<rect x=\"\(js(x - 5))\" y=\"\(js(y + hh + 3))\" width=\"\(js(w + 10))\" height=\"3\" fill=\"\(Td)\"/>"
        }
        o += "<svg viewBox=\"0 0 640 400\" preserveAspectRatio=\"xMidYMax meet\" role=\"img\" aria-label=\"Huset ditt\"><defs>"
            + "<linearGradient id=\"sky\" gradientUnits=\"userSpaceOnUse\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"300\"><stop offset=\"0\" stop-color=\"\(sky[0])\"/><stop offset=\"1\" stop-color=\"\(sky[1])\"/></linearGradient>"
            + "<linearGradient id=\"lawn\" gradientUnits=\"userSpaceOnUse\" x1=\"0\" y1=\"296\" x2=\"0\" y2=\"400\"><stop offset=\"0\" stop-color=\"#7fae63\"/><stop offset=\"1\" stop-color=\"#55894a\"/></linearGradient>"
            + "<linearGradient id=\"glass\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#a9c6d8\"/><stop offset=\"1\" stop-color=\"#6f93ab\"/></linearGradient>"
            + "<linearGradient id=\"water\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"#6fcbdc\"/><stop offset=\"1\" stop-color=\"#2f9fc0\"/></linearGradient>"
            + "<filter id=\"gl\" x=\"-60%\" y=\"-60%\" width=\"220%\" height=\"220%\"><feGaussianBlur stdDeviation=\"7\"/></filter></defs>"
        o += "<rect x=\"-640\" y=\"-600\" width=\"1920\" height=\"900\" fill=\"url(#sky)\"/>"
        if !eve || rain {
            let cc = rain ? "#8d95a0" : "#ffffff"
            o += "<g fill=\"\(cc)\" opacity=\"\(rain ? "0.95" : "0.85")\"><ellipse cx=\"110\" cy=\"70\" rx=\"60\" ry=\"14\"/><ellipse cx=\"90\" cy=\"60\" rx=\"30\" ry=\"14\"/><ellipse cx=\"130\" cy=\"56\" rx=\"34\" ry=\"18\"/><ellipse cx=\"500\" cy=\"96\" rx=\"70\" ry=\"13\"/><ellipse cx=\"520\" cy=\"84\" rx=\"36\" ry=\"16\"/>\(rain ? "<ellipse cx=\"310\" cy=\"50\" rx=\"150\" ry=\"26\"/><ellipse cx=\"300\" cy=\"34\" rx=\"90\" ry=\"24\"/>" : "")</g>"
        }
        var tl = ""
        var x = -420
        while x < 1060 {
            let hh = 30 + 18 * abs(sin(Double(x) * 0.37)) + 8 * sin(Double(x) * 0.11)
            tl += "M\(x - 13) 300L\(x) \(fx(300 - hh, 0))L\(x + 13) 300Z"
            x += 21
        }
        o += "<path d=\"\(tl)\" fill=\"#3f6b52\" opacity=\".5\"/><rect x=\"-640\" y=\"296\" width=\"1920\" height=\"300\" fill=\"url(#lawn)\"/>"
        for q in [(-70, "#d9c36a", "#5a3a32"), (560, "#56707f", "#2b2d31")] {
            o += "<rect x=\"\(q.0)\" y=\"214\" width=\"150\" height=\"86\" fill=\"\(q.1)\"/><path d=\"M\(q.0 - 12) 216L\(q.0 + 75) 164L\(q.0 + 162) 216Z\" fill=\"\(q.2)\"/><rect x=\"\(q.0 + 24)\" y=\"236\" width=\"26\" height=\"28\" fill=\"#a9c6d8\" stroke=\"#f6f4ef\" stroke-width=\"3\"/><rect x=\"\(q.0 + 100)\" y=\"236\" width=\"26\" height=\"28\" fill=\"#a9c6d8\" stroke=\"#f6f4ef\" stroke-width=\"3\"/><rect x=\"\(q.0 + 62)\" y=\"252\" width=\"24\" height=\"48\" fill=\"#f4f1ea\" stroke=\"#0003\"/>"
        }
        if g.hekk { o += "<g><rect x=\"-30\" y=\"262\" width=\"204\" height=\"42\" rx=\"10\" fill=\"#3d6e45\"/><rect x=\"468\" y=\"262\" width=\"204\" height=\"42\" rx=\"10\" fill=\"#3d6e45\"/><rect x=\"-30\" y=\"262\" width=\"204\" height=\"12\" rx=\"6\" fill=\"#4f8557\" opacity=\".8\"/><rect x=\"468\" y=\"262\" width=\"204\" height=\"12\" rx=\"6\" fill=\"#4f8557\" opacity=\".8\"/></g>" }
        if g.tre { o += "<rect x=\"96\" y=\"226\" width=\"10\" height=\"80\" fill=\"#6b4a35\"/><circle cx=\"74\" cy=\"214\" r=\"30\" fill=\"#458248\"/><circle cx=\"128\" cy=\"214\" r=\"30\" fill=\"#458248\"/><circle cx=\"101\" cy=\"194\" r=\"46\" fill=\"#4f8f52\"/><circle cx=\"92\" cy=\"172\" r=\"26\" fill=\"#62a25e\" opacity=\".8\"/>" }
        var cx = 320
        if h.type == "klassisk" {
            cx = 320
            var pl = ""; var px = 189; while px < 453 { pl += "M\(px) 194L\(px) 298"; px += 9 }
            var tiles = ""; var ty = 127
            while ty < 192 { let dx = Double(ty - 118) * 36 / 76; tiles += "M\(js(198 - dx)) \(ty)L\(js(442 + dx)) \(ty)"; ty += 9 }
            o += "<rect x=\"180\" y=\"190\" width=\"280\" height=\"110\" fill=\"\(W)\"/><path d=\"\(pl)\" stroke=\"#000\" stroke-width=\"1\" opacity=\".09\"/>"
                + "<rect x=\"180\" y=\"190\" width=\"7\" height=\"110\" fill=\"\(T)\"/><rect x=\"453\" y=\"190\" width=\"7\" height=\"110\" fill=\"\(T)\"/><rect x=\"178\" y=\"298\" width=\"284\" height=\"8\" fill=\"#9a968f\"/>"
                + "<path d=\"M162 194L198 118L442 118L478 194Z\" fill=\"\(R)\"/><path d=\"\(tiles)\" stroke=\"#000\" stroke-width=\"1\" opacity=\".16\"/><path d=\"M162 194L478 194\" stroke=\"\(T)\" stroke-width=\"4\"/>"
                + "<rect x=\"404\" y=\"94\" width=\"22\" height=\"34\" fill=\"#8a8480\"/><rect x=\"401\" y=\"90\" width=\"28\" height=\"5\" fill=\"#55514d\"/>"
                + "<rect x=\"292\" y=\"138\" width=\"56\" height=\"46\" fill=\"\(W)\"/><path d=\"M284 143L320 110L356 143Z\" fill=\"\(shade(R, -0.12))\"/><path d=\"M284 143L320 110L356 143\" stroke=\"\(T)\" stroke-width=\"2.5\" fill=\"none\"/>"
            o += win(305, 150, 30, 26, 2, 1) + win(206, 216, 48, 56, 2, 2) + win(386, 216, 48, 56, 2, 2)
            o += "<rect x=\"290\" y=\"224\" width=\"4\" height=\"76\" fill=\"\(T)\"/><rect x=\"346\" y=\"224\" width=\"4\" height=\"76\" fill=\"\(T)\"/><path d=\"M280 226L320 204L360 226Z\" fill=\"\(R)\"/><rect x=\"282\" y=\"224\" width=\"76\" height=\"4\" fill=\"\(T)\"/>"
                + "<rect x=\"302\" y=\"234\" width=\"36\" height=\"66\" fill=\"\(D)\" stroke=\"\(shade(D, -0.3))\" stroke-width=\"1\"/><rect x=\"307\" y=\"264\" width=\"26\" height=\"30\" fill=\"none\" stroke=\"\(shade(D, -0.3))\" stroke-width=\"1\"/><rect x=\"309\" y=\"240\" width=\"22\" height=\"18\" fill=\"url(#glass)\"/><circle cx=\"333.5\" cy=\"270\" r=\"1.8\" fill=\"#d9c9a0\"/>"
                + "<rect x=\"294\" y=\"300\" width=\"52\" height=\"5\" fill=\"#b5b0a8\"/><rect x=\"288\" y=\"305\" width=\"64\" height=\"5\" fill=\"#a5a098\"/>"
            lit.append((309, 240, 22, 18, ""))
        } else if h.type == "moderne" {
            cx = 363
            var pl = ""; var py = 160; while py < 298 { pl += "M200 \(py)L420 \(py)"; py += 8 }
            let W2 = shade(W, -0.12)
            o += "<rect x=\"420\" y=\"222\" width=\"122\" height=\"78\" fill=\"\(W2)\"/><rect x=\"414\" y=\"213\" width=\"134\" height=\"9\" fill=\"\(R)\"/>"
                + "<rect x=\"200\" y=\"152\" width=\"220\" height=\"148\" fill=\"\(W)\"/><path d=\"\(pl)\" stroke=\"#000\" stroke-width=\"1\" opacity=\".08\"/><rect x=\"192\" y=\"143\" width=\"236\" height=\"10\" fill=\"\(R)\"/>"
                + "<rect x=\"200\" y=\"298\" width=\"342\" height=\"6\" fill=\"#8f8b85\"/>"
            o += win(216, 172, 118, 36, 3, 1) + win(356, 172, 48, 36, 1, 1) + win(216, 232, 104, 62, 3, 1) + win(436, 236, 92, 58, 2, 1)
            o += "<rect x=\"336\" y=\"228\" width=\"54\" height=\"4\" fill=\"\(R)\"/><rect x=\"344\" y=\"236\" width=\"38\" height=\"64\" fill=\"\(D)\" stroke=\"\(shade(D, -0.3))\" stroke-width=\"1\"/><rect x=\"350\" y=\"242\" width=\"7\" height=\"52\" fill=\"url(#glass)\"/><rect x=\"375\" y=\"258\" width=\"2\" height=\"20\" fill=\"#cfcfcf\"/>"
                + "<rect x=\"338\" y=\"300\" width=\"50\" height=\"5\" fill=\"#a5a098\"/>"
            lit.append((350, 242, 7, 52, ""))
        } else if h.type == "villa" {
            cx = 320
            o += "<rect x=\"196\" y=\"84\" width=\"20\" height=\"30\" fill=\"#8a8480\"/><rect x=\"424\" y=\"84\" width=\"20\" height=\"30\" fill=\"#8a8480\"/><rect x=\"170\" y=\"150\" width=\"300\" height=\"150\" fill=\"\(W)\"/><path d=\"M170 226L470 226\" stroke=\"#000\" opacity=\".1\" stroke-width=\"2\"/><rect x=\"168\" y=\"298\" width=\"304\" height=\"8\" fill=\"#9a968f\"/>"
                + "<path d=\"M152 152L198 102L442 102L488 152Z\" fill=\"\(R)\"/><path d=\"M152 152L488 152\" stroke=\"\(T)\" stroke-width=\"5\"/>"
            o += win(194, 172, 34, 42, 2, 2) + win(250, 172, 34, 42, 2, 2) + win(356, 172, 34, 42, 2, 2) + win(412, 172, 34, 42, 2, 2) + win(304, 170, 32, 46, 2, 1)
            o += win(194, 240, 34, 46, 2, 2) + win(250, 240, 34, 46, 2, 2) + win(356, 240, 34, 46, 2, 2) + win(412, 240, 34, 46, 2, 2)
            o += "<rect x=\"280\" y=\"218\" width=\"80\" height=\"7\" fill=\"\(T)\"/><path d=\"M282 218L282 202L358 202L358 218M296 202L296 218M310 202L310 218M324 202L324 218M338 202L338 218\" stroke=\"\(Td)\" stroke-width=\"2\" fill=\"none\"/><rect x=\"284\" y=\"225\" width=\"8\" height=\"75\" fill=\"\(T)\"/><rect x=\"348\" y=\"225\" width=\"8\" height=\"75\" fill=\"\(T)\"/>"
                + "<rect x=\"302\" y=\"238\" width=\"36\" height=\"62\" fill=\"\(D)\" stroke=\"\(shade(D, -0.3))\"/><path d=\"M320 238L320 300\" stroke=\"\(shade(D, -0.3))\"/><circle cx=\"316\" cy=\"270\" r=\"1.8\" fill=\"#d9c9a0\"/><circle cx=\"324\" cy=\"270\" r=\"1.8\" fill=\"#d9c9a0\"/><rect x=\"290\" y=\"300\" width=\"60\" height=\"5\" fill=\"#b5b0a8\"/><rect x=\"282\" y=\"305\" width=\"76\" height=\"5\" fill=\"#a5a098\"/>"
        } else if h.type == "hytte" {
            cx = 300
            var lg = ""; var ly = 222; while ly < 298 { lg += "M190 \(ly)L450 \(ly)"; ly += 9 }
            o += "<rect x=\"398\" y=\"148\" width=\"28\" height=\"60\" fill=\"#8a8480\"/><path d=\"M398 162h28M398 178h28M398 194h28M412 148v14M405 162v16M419 178v16\" stroke=\"#0003\"/><rect x=\"190\" y=\"214\" width=\"260\" height=\"86\" fill=\"\(W)\"/><path d=\"\(lg)\" stroke=\"#000\" opacity=\".16\" stroke-width=\"1.5\"/>"
                + "<path d=\"M196 218L320 160L444 218Z\" fill=\"\(W)\"/><path d=\"\((0...4).map { i in "M\(226 + i * 18) \(212 - i * 9)L\(414 - i * 18) \(212 - i * 9)" }.joined())\" stroke=\"#000\" opacity=\".14\"/><path d=\"M166 222L320 148L474 222L460 226L320 160L180 226Z\" fill=\"\(R)\"/>"
            o += win(214, 240, 36, 30, 2, 2) + win(390, 240, 36, 30, 2, 2) + win(306, 182, 28, 22, 2, 1)
            o += "<rect x=\"282\" y=\"238\" width=\"36\" height=\"62\" fill=\"\(D)\" stroke=\"\(shade(D, -0.3))\"/><path d=\"M291 238v62M300 238v62M309 238v62\" stroke=\"\(shade(D, -0.3))\" opacity=\".6\"/><circle cx=\"313\" cy=\"270\" r=\"1.8\" fill=\"#d9c9a0\"/><rect x=\"262\" y=\"300\" width=\"76\" height=\"6\" fill=\"#8a6a4a\"/>"
            for r in 0...2 { for i in r...3 { o += "<circle cx=\"\(js(462 + Double(i) * 9 + Double(r) * 4.5))\" cy=\"\(295 - r * 8)\" r=\"4.5\" fill=\"#b08a62\" stroke=\"#6b4f36\"/>" } }
        } else if h.type == "byhus" {
            cx = 320
            o += "<rect x=\"120\" y=\"150\" width=\"112\" height=\"150\" fill=\"#b9b2a6\"/><rect x=\"408\" y=\"130\" width=\"112\" height=\"170\" fill=\"#a8a096\"/>"
                + (0...2).map { i in "<rect x=\"\(140 + i * 28)\" y=\"170\" width=\"14\" height=\"22\" fill=\"#7d8a94\"/><rect x=\"\(140 + i * 28)\" y=\"220\" width=\"14\" height=\"22\" fill=\"#7d8a94\"/><rect x=\"\(428 + i * 28)\" y=\"154\" width=\"14\" height=\"22\" fill=\"#7d8a94\"/><rect x=\"\(428 + i * 28)\" y=\"204\" width=\"14\" height=\"22\" fill=\"#7d8a94\"/>" }.joined()
                + "<rect x=\"230\" y=\"92\" width=\"180\" height=\"208\" fill=\"\(W)\"/><path d=\"M230 156L410 156M230 220L410 220\" stroke=\"\(T)\" stroke-width=\"3\"/><path d=\"M222 94L320 38L418 94Z\" fill=\"\(R)\"/><path d=\"M222 94L418 94\" stroke=\"\(T)\" stroke-width=\"4\"/><circle cx=\"320\" cy=\"72\" r=\"10\" fill=\"url(#glass)\" stroke=\"\(T)\" stroke-width=\"3\"/>"
            for wx in [248.0, 304, 360] { o += win(wx, 106, 32, 38, 2, 2) + win(wx, 170, 32, 38, 2, 2) }
            o += win(246, 238, 40, 44, 1, 1) + win(354, 238, 40, 44, 1, 1)
            o += "<rect x=\"302\" y=\"236\" width=\"36\" height=\"64\" fill=\"\(D)\" stroke=\"\(shade(D, -0.3))\"/><rect x=\"308\" y=\"242\" width=\"24\" height=\"16\" fill=\"url(#glass)\"/><circle cx=\"333\" cy=\"272\" r=\"1.8\" fill=\"#d9c9a0\"/><rect x=\"294\" y=\"300\" width=\"52\" height=\"6\" fill=\"#a5a098\"/>"
            lit.append((308, 242, 24, 16, ""))
        } else {
            cx = 320
            let stc = shade(W, -0.1)
            func cren(_ x0: Int, _ x1: Int, _ y: Int, _ c: String) -> String { var q = ""; var cxx = x0; while cxx < x1 - 6 { q += "<rect x=\"\(cxx)\" y=\"\(y - 10)\" width=\"11\" height=\"12\" fill=\"\(c)\"/>"; cxx += 20 }; return q }
            o += "<rect x=\"270\" y=\"118\" width=\"100\" height=\"60\" fill=\"\(stc)\"/>" + cren(270, 370, 118, stc) + "<path d=\"M320 108L320 70\" stroke=\"#4e4238\" stroke-width=\"2\"/><path d=\"M320 70L344 78L320 86Z\" fill=\"\(D)\"/>" + win(308, 134, 24, 30, 1, 1)
                + "<rect x=\"190\" y=\"172\" width=\"260\" height=\"128\" fill=\"\(W)\"/>" + cren(190, 450, 172, W)
            var bl = ""; var by = 186
            while by < 298 { var bx = 196 + ((by / 14) % 2) * 14; while bx < 444 { bl += "M\(bx) \(by)h14"; bx += 28 }; by += 14 }
            o += "<path d=\"\(bl)\" stroke=\"#000\" opacity=\".1\"/>"
                + [150, 434].map { x in "<rect x=\"\(x)\" y=\"110\" width=\"56\" height=\"190\" fill=\"\(stc)\"/><path d=\"M\(x - 6) 112L\(x + 28) 48L\(x + 62) 112Z\" fill=\"\(R)\"/><path d=\"M\(x + 28) 48L\(x + 28) 30\" stroke=\"#4e4238\" stroke-width=\"2\"/><path d=\"M\(x + 28) 30L\(x + 44) 36L\(x + 28) 42Z\" fill=\"\(D)\"/>" }.joined()
            o += win(170, 140, 16, 30, 1, 1) + win(454, 140, 16, 30, 1, 1) + win(170, 210, 16, 30, 1, 1) + win(454, 210, 16, 30, 1, 1) + win(228, 212, 26, 36, 1, 2) + win(386, 212, 26, 36, 1, 2)
            o += "<path d=\"M294 300L294 250Q320 218 346 250L346 300Z\" fill=\"\(D)\" stroke=\"\(shade(D, -0.35))\" stroke-width=\"2\"/><path d=\"M320 226L320 300M307 236L307 300M333 236L333 300M294 262L346 262M294 282L346 282\" stroke=\"\(shade(D, -0.35))\" opacity=\".7\"/>"
        }
        o += "<path d=\"M\(cx - 24) 310L\(cx + 24) 310L\(cx + 48) 400L\(cx - 48) 400Z\" fill=\"#cfcac1\"/><path d=\"M\(cx - 28) 326L\(cx + 28) 326M\(cx - 34) 348L\(cx + 34) 348M\(cx - 41) 374L\(cx + 41) 374\" stroke=\"#000\" opacity=\".12\"/>"
        if g.bed {
            let cols = ["#d9678a", "#f4f1ea", "#8f6bb8", "#e2b23c"]
            var f = ""
            for r in [(190, cx - 34), (cx + 34, 452)] {
                f += "<rect x=\"\(r.0)\" y=\"306\" width=\"\(r.1 - r.0)\" height=\"9\" rx=\"4\" fill=\"#5a4334\"/>"
                var bx = r.0 + 5, i = 0
                while bx < r.1 - 3 {
                    f += "<circle cx=\"\(bx)\" cy=\"\(305 - (i % 3) * 2)\" r=\"3.4\" fill=\"#4f8a4a\"/><circle cx=\"\(bx + 1)\" cy=\"\(302 - (i % 3) * 2)\" r=\"2.2\" fill=\"\(cols[(i * 7 + r.0) % 4])\"/>"
                    bx += 7; i += 1
                }
            }
            o += f
        }
        let lamps = [(cx - 36, 322), (cx + 36, 322), (cx - 56, 366), (cx + 56, 366)]
        if g.lys { for p in lamps { o += "<rect x=\"\(js(Double(p.0) - 1.5))\" y=\"\(p.1)\" width=\"3\" height=\"14\" fill=\"#33363b\"/><circle cx=\"\(p.0)\" cy=\"\(p.1)\" r=\"3.2\" fill=\"#fff3c4\"/>" } }
        if g.terrasse {
            var pk = ""; var py = 311; while py < 336 { pk += "M476 \(py)L616 \(py)"; py += 5 }
            o += "<rect x=\"476\" y=\"306\" width=\"140\" height=\"30\" fill=\"#b08a62\"/><path d=\"\(pk)\" stroke=\"#000\" opacity=\".14\"/>"
                + "<path d=\"M550 250L550 294\" stroke=\"#6b6660\" stroke-width=\"2\"/><path d=\"M510 258Q550 226 590 258Z\" fill=\"#efe7d6\" stroke=\"#cfc6b2\" stroke-width=\".8\"/>"
                + "<g fill=\"#4e4238\"><rect x=\"528\" y=\"292\" width=\"44\" height=\"4\"/><rect x=\"532\" y=\"296\" width=\"2.5\" height=\"22\"/><rect x=\"565.5\" y=\"296\" width=\"2.5\" height=\"22\"/>"
                + "<rect x=\"504\" y=\"284\" width=\"3\" height=\"36\"/><rect x=\"504\" y=\"302\" width=\"17\" height=\"3\"/><rect x=\"518\" y=\"302\" width=\"3\" height=\"18\"/>"
                + "<rect x=\"593\" y=\"284\" width=\"3\" height=\"36\"/><rect x=\"579\" y=\"302\" width=\"17\" height=\"3\"/><rect x=\"579\" y=\"302\" width=\"3\" height=\"18\"/></g>"
        }
        if g.basseng { o += "<rect x=\"452\" y=\"348\" width=\"170\" height=\"42\" rx=\"14\" fill=\"#d8d4cc\"/><rect x=\"458\" y=\"353\" width=\"158\" height=\"32\" rx=\"10\" fill=\"url(#water)\"/><path d=\"M474 363h18M510 371h22M548 362h20M580 374h16M486 377h14\" stroke=\"#fff\" stroke-width=\"1.4\" stroke-linecap=\"round\" opacity=\".55\"/>" }
        do {
            let mx = cx - 80
            o += "<rect x=\"\(mx - 2)\" y=\"318\" width=\"4\" height=\"36\" fill=\"#6b4f36\"/><rect x=\"\(mx - 14)\" y=\"298\" width=\"28\" height=\"21\" rx=\"5\" fill=\"#9b3b47\" stroke=\"#0003\"/><rect x=\"\(mx - 9)\" y=\"305\" width=\"18\" height=\"2.5\" fill=\"#1d1b22\" opacity=\".5\"/>"
                + (st.game.mail > 0 ? "<path d=\"M\(mx + 14) 314L\(mx + 14) 292L\(mx + 26) 297L\(mx + 14) 302\" fill=\"#f2c94c\" stroke=\"#6b4f36\"/><rect x=\"\(mx - 6)\" y=\"300\" width=\"12\" height=\"6\" fill=\"#fbfaf7\" stroke=\"#0003\"/>" : "")
        }
        if g.bil {
            o += "<path d=\"M4 400L38 334L192 334L204 400Z\" fill=\"#b9b5ae\"/><ellipse cx=\"104\" cy=\"388\" rx=\"80\" ry=\"5\" fill=\"#000\" opacity=\".18\"/>"
                + "<path d=\"M30 374L30 356Q32 346 48 344L62 328Q66 322 76 322L128 322Q138 322 146 330L160 344Q176 346 178 356L178 374Z\" fill=\"" + st.life.car + "\"/>"
                + "<path d=\"M66 342L76 328L100 328L100 342ZM104 328L128 328Q134 328 140 334L148 342L104 342Z\" fill=\"#c5d8e4\"/><path d=\"M34 352L176 352\" stroke=\"#fff\" opacity=\".15\" stroke-width=\"2\"/>"
                + "<circle cx=\"62\" cy=\"375\" r=\"13\" fill=\"#1d1f23\"/><circle cx=\"62\" cy=\"375\" r=\"6\" fill=\"#9ba1a8\"/><circle cx=\"146\" cy=\"375\" r=\"13\" fill=\"#1d1f23\"/><circle cx=\"146\" cy=\"375\" r=\"6\" fill=\"#9ba1a8\"/><rect x=\"172\" y=\"352\" width=\"6\" height=\"5\" rx=\"1\" fill=\"#f3e3a0\"/>"
        }
        if eve {
            o += "<rect x=\"-640\" y=\"-600\" width=\"1920\" height=\"1400\" fill=\"#0c1233\" opacity=\".46\"/>"
            if !rain { o += "<circle cx=\"548\" cy=\"64\" r=\"15\" fill=\"#f4eedc\"/>" + [[60, 40], [140, 80], [230, 34], [330, 70], [420, 30], [600, 120], [40, 130]].map { "<circle cx=\"\($0[0])\" cy=\"\($0[1])\" r=\"1.1\" fill=\"#fff\" opacity=\".8\"/>" }.joined() }
            for w in lit {
                o += "<rect x=\"\(js(w.0 - 4))\" y=\"\(js(w.1 - 4))\" width=\"\(js(w.2 + 8))\" height=\"\(js(w.3 + 8))\" fill=\"#ffcf7a\" opacity=\".45\" filter=\"url(#gl)\"/><rect x=\"\(js(w.0))\" y=\"\(js(w.1))\" width=\"\(js(w.2))\" height=\"\(js(w.3))\" fill=\"#ffd98f\"/>" + (w.4.isEmpty ? "" : "<path d=\"\(w.4)\" stroke=\"#4a4038\" stroke-width=\"2\"/>")
            }
            if g.lys { for p in lamps { o += "<circle cx=\"\(p.0)\" cy=\"\(p.1)\" r=\"15\" fill=\"#ffd98a\" opacity=\".6\" filter=\"url(#gl)\"/><circle cx=\"\(p.0)\" cy=\"\(p.1)\" r=\"3.2\" fill=\"#fff6d6\"/>" } }
            if g.basseng { o += "<rect x=\"458\" y=\"353\" width=\"158\" height=\"32\" rx=\"10\" fill=\"#7fe0ee\" opacity=\".55\"/>" }
        }
        if rain {
            var r = ""
            for i in 0..<90 { let rx = (i * 53) % 700 - 30, ry = (i * 97) % 390; r += "M\(rx) \(ry)l-6 18" }
            o += "<rect x=\"-640\" y=\"-600\" width=\"1920\" height=\"1400\" fill=\"#5d6672\" opacity=\".28\"/><path d=\"\(r)\" stroke=\"#e3ebf2\" stroke-width=\"1.2\" stroke-linecap=\"round\" opacity=\".6\"/>"
        }
        return (o + "</svg>", sky[0])
    }

    // MARK: rom innenfra (2D)
    static func art(_ r: Room, _ x: Int, _ y: Int) -> String {
        if r.art == "none" { return "" }
        var a = "<rect x=\"\(x)\" y=\"\(y)\" width=\"100\" height=\"70\" fill=\"#2b2d31\"/><rect x=\"\(x + 3)\" y=\"\(y + 3)\" width=\"94\" height=\"64\" fill=\"#f3efe6\"/>"
        if r.art == "abstrakt" {
            a += "<circle cx=\"\(x + 36)\" cy=\"\(y + 32)\" r=\"16\" fill=\"#c9736b\"/><rect x=\"\(x + 48)\" y=\"\(y + 22)\" width=\"30\" height=\"34\" fill=\"#34507a\" opacity=\".9\"/><path d=\"M\(x + 16) \(y + 56)Q\(x + 50) \(y + 36) \(x + 86) \(y + 54)\" stroke=\"#c9a227\" stroke-width=\"4\" fill=\"none\"/>"
        } else if r.art.hasPrefix("g") {
            let seed = Double(r.art.dropFirst()) ?? 0
            var rn = Rng(seed == 0 || seed.isNaN ? 7 : seed)
            a += "<rect x=\"\(x + 8)\" y=\"\(y + 8)\" width=\"84\" height=\"54\" fill=\"\(hsl(rn.next() * 360, 30, 88))\"/>"
            for _ in 0..<4 {
                let cx = Double(x) + 20 + rn.next() * 60, cy = Double(y) + 20 + rn.next() * 30, w = 6 + rn.next() * 12, c = hsl(rn.next() * 360, 55, 52)
                a += rn.next() < 0.5 ? "<circle cx=\"\(fx(cx, 0))\" cy=\"\(fx(cy, 0))\" r=\"\(fx(w, 0))\" fill=\"\(c)\" opacity=\".9\"/>" : "<rect x=\"\(fx(cx - w, 0))\" y=\"\(fx(cy - w * 0.6, 0))\" width=\"\(fx(w * 1.6, 0))\" height=\"\(fx(w * 1.2, 0))\" fill=\"\(c)\" opacity=\".9\"/>"
            }
        } else {
            a += "<rect x=\"\(x + 8)\" y=\"\(y + 8)\" width=\"84\" height=\"54\" fill=\"#cfe0ea\"/><circle cx=\"\(x + 70)\" cy=\"\(y + 22)\" r=\"7\" fill=\"#f2d48a\"/><path d=\"M\(x + 8) \(y + 62)L\(x + 8) \(y + 44)L\(x + 34) \(y + 26)L\(x + 56) \(y + 46)L\(x + 72) \(y + 36)L\(x + 92) \(y + 50)L\(x + 92) \(y + 62)Z\" fill=\"#5d7a5e\"/><path d=\"M\(x + 8) \(y + 62)L\(x + 8) \(y + 54)Q\(x + 50) \(y + 44) \(x + 92) \(y + 56)L\(x + 92) \(y + 62)Z\" fill=\"#3f6b52\"/>"
        }
        return a
    }

    static func plant(_ x: Int, _ k: Double? = nil) -> String {
        let leaves: [(Int, String, Int)] = [(-34, "#3d6e45", 30), (-14, "#4f8a4a", 36), (6, "#3d6e45", 38), (24, "#4f8a4a", 32), (40, "#3d6e45", 26)]
        return "<g transform=\"translate(\(x) \(k != nil ? js((1 - k!) * 290) : "0")) scale(\(k != nil ? js(k!) : "1"))\"><g transform=\"translate(0 0)\">"
            + leaves.map { "<ellipse cx=\"0\" cy=\"\(262 - $0.2)\" rx=\"7\" ry=\"\($0.2)\" fill=\"\($0.1)\" transform=\"rotate(\($0.0) 0 262)\"/>" }.joined()
            + "<path d=\"M-13 260L13 260L9 290L-9 290Z\" fill=\"#b9b2a6\" stroke=\"#0002\"/></g></g>"
    }

    static func room(_ rm: String, _ r: Room, _ st: GameState, extra: String = "", home: Bool = false) -> (String, String) {
        let h = st.house, eve = h.time == "kveld", rain = st.rain
        let sky = skyColors(st)
        let W = r.wall, C = r.main, Cd = shade(C, -0.14), wood = "#8a6a4a", woodD = "#6b4f36"
        var glow: [(Double, Double, Double, String, String?)] = []
        var o = "<svg viewBox=\"0 0 640 400\" preserveAspectRatio=\"xMidYMax meet\" role=\"img\" aria-label=\"Rommet\"><defs>"
            + "<linearGradient id=\"sky\" gradientUnits=\"userSpaceOnUse\" x1=\"0\" y1=\"40\" x2=\"0\" y2=\"180\"><stop offset=\"0\" stop-color=\"\(sky[0])\"/><stop offset=\"1\" stop-color=\"\(sky[1])\"/></linearGradient>"
            + "<linearGradient id=\"mir\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0\" stop-color=\"#e6eef2\"/><stop offset=\"1\" stop-color=\"#b3c2cc\"/></linearGradient>"
            + "<filter id=\"gl\" x=\"-80%\" y=\"-80%\" width=\"260%\" height=\"260%\"><feGaussianBlur stdDeviation=\"9\"/></filter></defs>" + GDEFS
        o += "<rect x=\"-640\" y=\"-600\" width=\"1920\" height=\"890\" fill=\"\(W)\"/>"
        let FL = ["parkett": "#c9a271", "mork": "#6b4a35", "fliser": "#d9d6d0", "teppe": "#b9ad9d"][r.floor] ?? "#c9a271"
        if rm == "bad" {
            var l = ""
            var y = 150; while y < 282 { l += "M-640 \(y)L1280 \(y)"; y += 26 }
            var x = -620; while x < 1280 { l += "M\(x) 150L\(x) 282"; x += 40 }
            o += "<rect x=\"-640\" y=\"150\" width=\"1920\" height=\"132\" fill=\"#fff\" opacity=\".45\"/><path d=\"\(l)\" stroke=\"#000\" opacity=\".08\"/>"
        }
        o += "<rect x=\"-640\" y=\"290\" width=\"1920\" height=\"400\" fill=\"\(FL)\"/>"
        if r.floor == "fliser" {
            var l = "M-640 306L1280 306M-640 330L1280 330M-640 362L1280 362"
            var x = -520; while x < 1200 { l += "M\(x) 400L\(fx(320 + Double(x - 320) * 0.62, 0)) 290"; x += 70 }
            o += "<path d=\"\(l)\" stroke=\"#000\" opacity=\".12\"/>"
        } else if r.floor != "teppe" {
            var l = ""
            let ys = [300, 313, 330, 352, 380], ye = [313, 330, 352, 380, 400]
            for (i, y) in ys.enumerated() {
                l += "M-640 \(y)L1280 \(y)"
                var x = -600 + (i % 2) * 90; while x < 1280 { l += "M\(x) \(y)L\(x) \(ye[i])"; x += 180 }
            }
            o += "<path d=\"\(l)\" stroke=\"#000\" opacity=\".13\"/>"
        }
        o += "<rect x=\"-640\" y=\"282\" width=\"1920\" height=\"8\" fill=\"\(shade(W, isLight(W) ? -0.08 : 0.25))\"/>"
        let wxs = ["stue": 414, "soverom": 440, "kjokken": 96]
        let wy = 48, ww = 118, wh = 124
        if let wx = wxs[rm] {
            o += "<rect x=\"\(wx - 5)\" y=\"\(wy - 5)\" width=\"\(ww + 10)\" height=\"\(wh + 10)\" fill=\"#f6f4ef\" stroke=\"#0002\"/><rect x=\"\(wx)\" y=\"\(wy)\" width=\"\(ww)\" height=\"\(wh)\" fill=\"url(#sky)\"/>"
            if eve && !rain { o += "<circle cx=\"\(wx + 86)\" cy=\"\(wy + 30)\" r=\"9\" fill=\"#f4eedc\"/>" }
            if !eve && !rain { o += "<ellipse cx=\"\(wx + 40)\" cy=\"\(wy + 40)\" rx=\"26\" ry=\"7\" fill=\"#fff\" opacity=\".85\"/><ellipse cx=\"\(wx + 50)\" cy=\"\(wy + 33)\" rx=\"14\" ry=\"8\" fill=\"#fff\" opacity=\".85\"/>" }
            o += "<path d=\"M\(wx) \(wy + wh)L\(wx) \(wy + wh - 22)Q\(wx + ww / 2) \(wy + wh - 40) \(wx + ww) \(wy + wh - 20)L\(wx + ww) \(wy + wh)Z\" fill=\"#3f6b52\" opacity=\".7\"/>"
            if rain {
                var l = ""
                for i in 0..<26 { l += "M\(wx + 6 + (i * 37) % (ww - 8)) \(wy + 4 + (i * 53) % (wh - 20))l-3 12" }
                o += "<path d=\"\(l)\" stroke=\"#e3ebf2\" stroke-linecap=\"round\" opacity=\".7\"/>"
            }
            o += "<path d=\"M\(wx + ww / 2) \(wy)L\(wx + ww / 2) \(wy + wh)M\(wx) \(wy + wh / 2)L\(wx + ww) \(wy + wh / 2)\" stroke=\"#f6f4ef\" stroke-width=\"4\"/><rect x=\"\(wx - 9)\" y=\"\(wy + wh + 5)\" width=\"\(ww + 18)\" height=\"5\" fill=\"#e4e0d8\"/>"
            if r.has("gardiner") {
                let b = rm == "kjokken" ? 8 : 52
                func cu(_ x: Int) -> String {
                    "<path d=\"M\(x) \(wy - 14)L\(x + 30) \(wy - 14)L\(x + 33) \(wy + wh + b)L\(x - 3) \(wy + wh + b)Z\" fill=\"#ece5d8\" stroke=\"#0002\"/><path d=\"M\(x + 8) \(wy - 12)L\(x + 7) \(wy + wh + b - 2)M\(x + 17) \(wy - 12)L\(x + 18) \(wy + wh + b - 2)M\(x + 25) \(wy - 12)L\(x + 27) \(wy + wh + b - 2)\" stroke=\"#000\" opacity=\".1\"/>"
                }
                o += cu(wx - 26) + cu(wx + ww - 4) + "<rect x=\"\(wx - 34)\" y=\"\(wy - 18)\" width=\"\(ww + 68)\" height=\"4\" rx=\"2\" fill=\"#4e4238\"/>"
            }
        }
        func rug(_ d: String) -> String { r.rug == "none" ? "" : "<path d=\"\(d)\" fill=\"\(r.rug)\" stroke=\"\(shade(r.rug, isLight(r.rug) ? -0.2 : 0.3))\" stroke-width=\"2\"/>" }
        if rm == "stue" {
            o += art(r, 190, 84) + rug("M112 312L398 312L430 378L80 378Z")
            if r.has("bokhylle") {
                o += "<rect x=\"556\" y=\"108\" width=\"74\" height=\"182\" fill=\"\(wood)\"/>"
                let bc = ["#c9736b", "#34507a", "#e7ddd0", "#5d7a5e", "#c9a227", "#8c8f96", "#9b3b47"]
                for k in 0..<4 {
                    let y = 113 + k * 44
                    o += "<rect x=\"561\" y=\"\(y)\" width=\"64\" height=\"39\" fill=\"\(woodD)\"/>"
                    var b = 0, x = 563
                    while x < 616 {
                        let w = 5 + (b * 7 + k * 3) % 5, hh = 24 + (b * 11 + k * 5) % 13
                        if x + w > 623 { break }
                        o += "<rect x=\"\(x)\" y=\"\(y + 39 - hh)\" width=\"\(w)\" height=\"\(hh)\" fill=\"\(bc[(b * 3 + k * 2) % 7])\"/>"
                        x += w + 1
                        if k % 2 == 1 && b == 4 { x += 14 }
                        b += 1
                    }
                }
            }
            let scr = "<rect x=\"428\" y=\"190\" width=\"92\" height=\"52\" fill=\"#86aede\"/><path d=\"M428 242L428 226L456 206L478 222L496 212L520 228L520 242Z\" fill=\"#4f79ad\"/>"
            let on = home && st.life.tv
            if r.has("tv") {
                o += "<rect x=\"408\" y=\"282\" width=\"5\" height=\"10\" fill=\"#33363b\"/><rect x=\"535\" y=\"282\" width=\"5\" height=\"10\" fill=\"#33363b\"/><rect x=\"404\" y=\"254\" width=\"140\" height=\"30\" rx=\"2\" fill=\"\(wood)\"/><path d=\"M474 256L474 282\" stroke=\"\(woodD)\"/>"
                    + "<rect x=\"468\" y=\"244\" width=\"12\" height=\"10\" fill=\"#17181b\"/><rect x=\"424\" y=\"186\" width=\"100\" height=\"60\" rx=\"3\" fill=\"#17181b\"/><rect x=\"428\" y=\"190\" width=\"92\" height=\"52\" fill=\"#262b34\"/>" + (on ? scr : "")
            }
            if r.has("plante") { o += plant(386) }
            if r.has("lampe") { o += "<ellipse cx=\"64\" cy=\"292\" rx=\"17\" ry=\"4\" fill=\"#33363b\"/><rect x=\"62.5\" y=\"150\" width=\"3\" height=\"142\" fill=\"#33363b\"/><path d=\"M45 152L83 152L76 118L52 118Z\" fill=\"#efe7d6\" stroke=\"#0002\"/>" }
            let pc = shade(C, isLight(C) ? -0.3 : 0.45)
            o += "<rect x=\"118\" y=\"294\" width=\"6\" height=\"11\" fill=\"#33363b\"/><rect x=\"356\" y=\"294\" width=\"6\" height=\"11\" fill=\"#33363b\"/>"
                + "<rect x=\"118\" y=\"198\" width=\"244\" height=\"74\" rx=\"14\" fill=\"\(C)\"/><rect x=\"126\" y=\"250\" width=\"228\" height=\"46\" rx=\"8\" fill=\"\(shade(C, 0.07))\"/><path d=\"M240 252L240 294\" stroke=\"\(Cd)\" stroke-width=\"1.5\"/>"
                + "<rect x=\"102\" y=\"228\" width=\"30\" height=\"68\" rx=\"11\" fill=\"\(Cd)\"/><rect x=\"348\" y=\"228\" width=\"30\" height=\"68\" rx=\"11\" fill=\"\(Cd)\"/>"
                + "<rect x=\"142\" y=\"220\" width=\"40\" height=\"34\" rx=\"8\" fill=\"\(pc)\" transform=\"rotate(-8 162 237)\"/><rect x=\"298\" y=\"220\" width=\"40\" height=\"34\" rx=\"8\" fill=\"\(pc)\" transform=\"rotate(7 318 237)\"/>"
            if r.has("bord") { o += "<rect x=\"204\" y=\"330\" width=\"5\" height=\"26\" fill=\"\(woodD)\"/><rect x=\"295\" y=\"330\" width=\"5\" height=\"26\" fill=\"\(woodD)\"/><rect x=\"194\" y=\"322\" width=\"116\" height=\"9\" rx=\"2\" fill=\"\(wood)\"/><rect x=\"226\" y=\"317\" width=\"34\" height=\"5\" fill=\"#e7ddd0\"/><rect x=\"230\" y=\"313\" width=\"26\" height=\"4\" fill=\"#9b3b47\"/><ellipse cx=\"282\" cy=\"318\" rx=\"7\" ry=\"4\" fill=\"#f4f1ea\" stroke=\"#0003\"/>" }
            if r.has("lampe") { glow.append((64, 136, 44, "<path d=\"M45 152L83 152L76 118L52 118Z\" fill=\"#fff1cc\"/>", nil)) }
            if r.has("tv") && (on || !home) { glow.append((474, 216, 50, scr, "#8fb6e6")) }
        } else if rm == "soverom" {
            o += art(r, 230, 80) + rug("M130 318L430 318L462 380L98 380Z")
            if r.has("lyslenke") {
                var pts: [(Double, Double)] = []
                var t = 0.0
                while t <= 1.001 {
                    let a = (1 - t) * (1 - t), b = 2 * t * (1 - t), c = t * t
                    pts.append((a * 36 + b * 190 + c * 320, a * 40 + b * 76 + c * 46))
                    if t > 0 { pts.append((a * 320 + b * 450 + c * 604, a * 46 + b * 16 + c * 50)) }
                    t += 0.1
                }
                o += "<path d=\"M36 40Q190 76 320 46Q450 16 604 50\" stroke=\"#6b6660\" stroke-width=\".9\" fill=\"none\"/>" + pts.map { "<circle cx=\"\(fx($0.0, 1))\" cy=\"\(fx($0.1 + 3, 1))\" r=\"2.8\" fill=\"#ffe9a8\"/>" }.joined()
                for q in pts { glow.append((q.0, q.1 + 3, 9, "<circle cx=\"\(fx(q.0, 1))\" cy=\"\(fx(q.1 + 3, 1))\" r=\"2.8\" fill=\"#fff6d6\"/>", nil)) }
            }
            if r.has("speil") { o += "<rect x=\"572\" y=\"138\" width=\"48\" height=\"154\" rx=\"9\" fill=\"#c9a36a\"/><rect x=\"576\" y=\"142\" width=\"40\" height=\"146\" rx=\"6\" fill=\"url(#mir)\"/><path d=\"M580 200L604 146L612 146L580 222Z\" fill=\"#fff\" opacity=\".35\"/>" }
            if r.has("plante") { o += plant(524) }
            if r.has("skrivebord") {
                o += "<rect x=\"30\" y=\"244\" width=\"4\" height=\"46\" fill=\"\(woodD)\"/><rect x=\"126\" y=\"244\" width=\"4\" height=\"46\" fill=\"\(woodD)\"/><rect x=\"22\" y=\"238\" width=\"116\" height=\"7\" rx=\"1.5\" fill=\"\(wood)\"/>"
                    + "<rect x=\"58\" y=\"212\" width=\"40\" height=\"24\" rx=\"2\" fill=\"#8c8f96\"/><rect x=\"60\" y=\"214\" width=\"36\" height=\"20\" fill=\"#cfd9e3\"/><rect x=\"52\" y=\"235\" width=\"52\" height=\"3\" rx=\"1\" fill=\"#6d747b\"/>"
                    + "<rect x=\"112\" y=\"222\" width=\"10\" height=\"16\" rx=\"2\" fill=\"#c9736b\"/><rect x=\"62\" y=\"266\" width=\"36\" height=\"5\" rx=\"2\" fill=\"#2e3338\"/><path d=\"M66 271L63 290M94 271L97 290\" stroke=\"#2e3338\" stroke-width=\"2.5\"/>"
            }
            o += "<rect x=\"156\" y=\"292\" width=\"6\" height=\"12\" fill=\"\(woodD)\"/><rect x=\"398\" y=\"292\" width=\"6\" height=\"12\" fill=\"\(woodD)\"/><rect x=\"158\" y=\"172\" width=\"244\" height=\"80\" rx=\"10\" fill=\"\(wood)\"/><rect x=\"148\" y=\"244\" width=\"264\" height=\"52\" rx=\"5\" fill=\"\(woodD)\"/>"
                + "<rect x=\"152\" y=\"240\" width=\"256\" height=\"24\" rx=\"6\" fill=\"#f4f1ea\"/><rect x=\"174\" y=\"216\" width=\"88\" height=\"32\" rx=\"11\" fill=\"#fbfaf7\" stroke=\"#0002\"/><rect x=\"298\" y=\"216\" width=\"88\" height=\"32\" rx=\"11\" fill=\"#fbfaf7\" stroke=\"#0002\"/>"
                + "<path d=\"M150 254Q150 246 160 246L400 246Q410 246 410 254L410 292L150 292Z\" fill=\"\(C)\"/><rect x=\"150\" y=\"246\" width=\"260\" height=\"11\" rx=\"5\" fill=\"\(shade(C, isLight(C) ? -0.1 : 0.28))\"/><path d=\"M196 262Q240 276 250 292M330 260Q352 274 356 292\" stroke=\"\(Cd)\" fill=\"none\" opacity=\".7\"/>"
            if r.has("nattbord") {
                o += "<rect x=\"420\" y=\"248\" width=\"46\" height=\"42\" rx=\"2\" fill=\"\(wood)\"/><path d=\"M424 268L462 268\" stroke=\"\(woodD)\"/><circle cx=\"443\" cy=\"258\" r=\"1.6\" fill=\"#d9c9a0\"/><circle cx=\"443\" cy=\"278\" r=\"1.6\" fill=\"#d9c9a0\"/>"
                    + "<rect x=\"440\" y=\"234\" width=\"6\" height=\"14\" fill=\"#33363b\"/><path d=\"M430 236L456 236L451 216L435 216Z\" fill=\"#efe7d6\" stroke=\"#0002\"/>"
                glow.append((443, 226, 34, "<path d=\"M430 236L456 236L451 216L435 216Z\" fill=\"#fff1cc\"/>", nil))
            }
        } else if rm == "kjokken" {
            func kn(_ x: Int, _ y: Int) -> String { "<rect x=\"\(x)\" y=\"\(y)\" width=\"2.5\" height=\"14\" rx=\"1\" fill=\"\(isLight(C) ? "#55595f" : "#e4e0d8")\"/>" }
            var bs = ""; var bx = 60.0; while bx <= 470 { bs += "M\(js(bx)) 140L\(js(bx)) 208"; bx += 20.5 }
            o += "<rect x=\"60\" y=\"140\" width=\"410\" height=\"68\" fill=\"#fff\" opacity=\".5\"/><path d=\"\(bs)M60 163L470 163M60 186L470 186\" stroke=\"#000\" opacity=\".07\"/>"
                + "<rect x=\"340\" y=\"58\" width=\"134\" height=\"80\" fill=\"\(C)\" stroke=\"\(Cd)\"/><path d=\"M407 58L407 138\" stroke=\"\(Cd)\"/>" + kn(399, 112) + kn(412, 112)
                + "<rect x=\"281\" y=\"-600\" width=\"18\" height=\"712\" fill=\"#c9ced3\"/><path d=\"M258 138L322 138L310 112L270 112Z\" fill=\"#b9bec4\" stroke=\"#9aa0a8\"/>"
            if r.has("kjoleskap") { o += "<rect x=\"492\" y=\"92\" width=\"78\" height=\"200\" rx=\"4\" fill=\"#cdd2d7\" stroke=\"#9aa0a8\"/><path d=\"M492 166L570 166\" stroke=\"#9aa0a8\"/><rect x=\"500\" y=\"116\" width=\"3\" height=\"38\" rx=\"1.5\" fill=\"#7d848c\"/><rect x=\"500\" y=\"180\" width=\"3\" height=\"54\" rx=\"1.5\" fill=\"#7d848c\"/>" }
            o += "<rect x=\"60\" y=\"216\" width=\"410\" height=\"76\" fill=\"\(C)\" stroke=\"\(Cd)\"/><path d=\"M128 218L128 290M196 218L196 290M398 218L398 290\" stroke=\"\(Cd)\"/>" + kn(120, 226) + kn(134, 226) + kn(202, 226) + kn(390, 226) + kn(404, 226)
                + "<rect x=\"250\" y=\"216\" width=\"80\" height=\"76\" fill=\"#2b2d31\"/><rect x=\"258\" y=\"238\" width=\"64\" height=\"44\" rx=\"3\" fill=\"#17181b\" stroke=\"#55595f\"/><rect x=\"262\" y=\"227\" width=\"56\" height=\"3\" rx=\"1.5\" fill=\"#9aa0a8\"/>"
                + "<rect x=\"54\" y=\"207\" width=\"422\" height=\"10\" rx=\"2\" fill=\"#ece9e3\" stroke=\"#0002\"/><rect x=\"254\" y=\"204\" width=\"72\" height=\"4\" fill=\"#17181b\"/>"
                + "<rect x=\"270\" y=\"186\" width=\"40\" height=\"18\" rx=\"3\" fill=\"#8c8f96\"/><path d=\"M263 191L270 191M310 191L317 191\" stroke=\"#55595f\" stroke-width=\"3\" stroke-linecap=\"round\"/><rect x=\"268\" y=\"183\" width=\"44\" height=\"4\" rx=\"2\" fill=\"#6d747b\"/>"
                + "<rect x=\"120\" y=\"204\" width=\"70\" height=\"5\" rx=\"1\" fill=\"#b9bec4\"/><path d=\"M155 205L155 188Q155 179 166 179L171 179\" stroke=\"#9aa0a8\" stroke-width=\"3.5\" fill=\"none\" stroke-linecap=\"round\"/>"
            if r.has("plante") { o += "<g transform=\"translate(0 -84)\">\(plant(440, 0.5))</g>" }
            o += rug("M372 332L574 332L594 386L352 386Z")
            if r.has("spisebord") {
                o += "<rect x=\"402\" y=\"330\" width=\"6\" height=\"44\" fill=\"\(woodD)\"/><rect x=\"540\" y=\"330\" width=\"6\" height=\"44\" fill=\"\(woodD)\"/><rect x=\"392\" y=\"322\" width=\"164\" height=\"9\" rx=\"2\" fill=\"\(wood)\"/>"
                    + "<g fill=\"#2e3338\"><rect x=\"372\" y=\"300\" width=\"4\" height=\"74\"/><rect x=\"372\" y=\"336\" width=\"26\" height=\"4\"/><rect x=\"394\" y=\"336\" width=\"4\" height=\"38\"/><rect x=\"572\" y=\"300\" width=\"4\" height=\"74\"/><rect x=\"550\" y=\"336\" width=\"26\" height=\"4\"/><rect x=\"550\" y=\"336\" width=\"4\" height=\"38\"/></g>"
                    + "<ellipse cx=\"474\" cy=\"320\" rx=\"16\" ry=\"4\" fill=\"#f4f1ea\" stroke=\"#0003\"/><circle cx=\"470\" cy=\"317\" r=\"4\" fill=\"#c4313f\"/><circle cx=\"478\" cy=\"316\" r=\"4\" fill=\"#c9a227\"/>"
            }
        } else if rm == "bad" {
            o += rug("M326 304L440 304L452 334L314 334Z")
                + "<rect x=\"52\" y=\"288\" width=\"128\" height=\"6\" fill=\"#fbfaf7\" stroke=\"#b9bec4\"/><rect x=\"56\" y=\"84\" width=\"120\" height=\"206\" fill=\"#cfe3ec\" opacity=\".45\" stroke=\"#9aa0a8\" stroke-width=\"2\"/><path d=\"M116 84L116 290\" stroke=\"#9aa0a8\"/>"
                + "<path d=\"M72 250L72 112Q72 100 88 100L96 100\" stroke=\"#9aa0a8\" stroke-width=\"3\" fill=\"none\"/><rect x=\"92\" y=\"96\" width=\"20\" height=\"6\" rx=\"2\" fill=\"#9aa0a8\"/><circle cx=\"72\" cy=\"196\" r=\"4\" fill=\"#9aa0a8\"/>"
                + "<rect x=\"226\" y=\"204\" width=\"50\" height=\"40\" rx=\"5\" fill=\"#fbfaf7\" stroke=\"#b9bec4\"/><path d=\"M228 246L274 246Q276 278 261 290L241 290Q226 278 228 246Z\" fill=\"#fbfaf7\" stroke=\"#b9bec4\"/><rect x=\"224\" y=\"242\" width=\"54\" height=\"6\" rx=\"3\" fill=\"#fff\" stroke=\"#b9bec4\"/><rect x=\"258\" y=\"210\" width=\"10\" height=\"4\" rx=\"2\" fill=\"#b9bec4\"/>"
            if r.has("plante") { o += plant(302, 0.8) }
            o += "<rect x=\"330\" y=\"236\" width=\"104\" height=\"56\" fill=\"\(C)\" stroke=\"\(Cd)\"/><path d=\"M382 238L382 290\" stroke=\"\(Cd)\"/><rect x=\"374\" y=\"258\" width=\"2.5\" height=\"12\" fill=\"#d9d9d9\"/><rect x=\"387.5\" y=\"258\" width=\"2.5\" height=\"12\" fill=\"#d9d9d9\"/>"
                + "<rect x=\"326\" y=\"229\" width=\"112\" height=\"8\" rx=\"2\" fill=\"#fbfaf7\" stroke=\"#b9bec4\"/><ellipse cx=\"382\" cy=\"230\" rx=\"27\" ry=\"4.5\" fill=\"#dfe6ea\" stroke=\"#b9bec4\"/><path d=\"M382 226L382 212Q382 206 390 206\" stroke=\"#9aa0a8\" stroke-width=\"3\" fill=\"none\" stroke-linecap=\"round\"/>"
            if r.has("speil") { o += "<circle cx=\"382\" cy=\"150\" r=\"40\" fill=\"#c9a36a\"/><circle cx=\"382\" cy=\"150\" r=\"36\" fill=\"url(#mir)\"/><path d=\"M356 160L384 118L394 120L360 172Z\" fill=\"#fff\" opacity=\".35\"/>" }
            if r.has("handkle") { o += "<path d=\"M468 174L550 174\" stroke=\"#9aa0a8\" stroke-width=\"3\" stroke-linecap=\"round\"/><rect x=\"476\" y=\"174\" width=\"28\" height=\"56\" rx=\"2\" fill=\"\(C)\"/><rect x=\"512\" y=\"174\" width=\"28\" height=\"44\" rx=\"2\" fill=\"\(shade(C, isLight(C) ? -0.15 : 0.4))\"/>" }
            if r.has("badekar") { o += "<rect x=\"466\" y=\"288\" width=\"8\" height=\"8\" fill=\"#b9bec4\"/><rect x=\"602\" y=\"288\" width=\"8\" height=\"8\" fill=\"#b9bec4\"/><path d=\"M454 248L622 248L614 286Q612 292 606 292L470 292Q464 292 462 286Z\" fill=\"#fbfaf7\" stroke=\"#b9bec4\"/><rect x=\"448\" y=\"243\" width=\"180\" height=\"7\" rx=\"3.5\" fill=\"#fff\" stroke=\"#b9bec4\"/><path d=\"M470 243L470 226Q470 220 478 220\" stroke=\"#9aa0a8\" stroke-width=\"3\" fill=\"none\" stroke-linecap=\"round\"/>" }
        } else {
            let D = h.door, Dd = shade(D, -0.3)
            o += rug("M60 316L190 316L206 352L44 352Z")
                + "<rect x=\"54\" y=\"102\" width=\"96\" height=\"190\" fill=\"#f6f4ef\" stroke=\"#0002\"/><rect x=\"61\" y=\"109\" width=\"82\" height=\"183\" fill=\"\(D)\" stroke=\"\(Dd)\"/><rect x=\"72\" y=\"120\" width=\"60\" height=\"44\" fill=\"url(#sky)\" stroke=\"\(Dd)\"/><rect x=\"72\" y=\"178\" width=\"60\" height=\"100\" fill=\"none\" stroke=\"\(Dd)\"/><rect x=\"132\" y=\"196\" width=\"4\" height=\"16\" rx=\"2\" fill=\"#d9c9a0\"/>"
            if r.has("knagger") {
                o += "<rect x=\"206\" y=\"118\" width=\"138\" height=\"8\" rx=\"2\" fill=\"\(wood)\"/>" + [222, 256, 290, 324].map { "<path d=\"M\($0) 126L\($0) 134\" stroke=\"#33363b\" stroke-width=\"3\" stroke-linecap=\"round\"/>" }.joined()
                    + "<path d=\"M204 150Q206 134 222 132Q238 134 240 150L242 214L202 214Z\" fill=\"\(C)\" stroke=\"\(Cd)\"/><path d=\"M222 134L222 214\" stroke=\"\(Cd)\"/><path d=\"M276 148Q278 134 290 132Q302 134 304 148L306 228L274 228Z\" fill=\"#34507a\" stroke=\"#22344f\"/><path d=\"M318 136Q324 132 330 136L332 176Q324 182 316 176Z\" fill=\"#c9a227\"/>"
            }
            if r.has("skohylle") {
                o += "<rect x=\"210\" y=\"262\" width=\"5\" height=\"30\" fill=\"\(woodD)\"/><rect x=\"335\" y=\"262\" width=\"5\" height=\"30\" fill=\"\(woodD)\"/><rect x=\"204\" y=\"256\" width=\"142\" height=\"8\" rx=\"2\" fill=\"\(wood)\"/><rect x=\"212\" y=\"252\" width=\"126\" height=\"5\" rx=\"2.5\" fill=\"\(C)\"/><path d=\"M214 280L336 280\" stroke=\"\(woodD)\" stroke-width=\"2\"/>"
                    + "<g><rect x=\"222\" y=\"272\" width=\"22\" height=\"8\" rx=\"4\" fill=\"#f4f1ea\" stroke=\"#0003\"/><rect x=\"248\" y=\"272\" width=\"22\" height=\"8\" rx=\"4\" fill=\"#f4f1ea\" stroke=\"#0003\"/><rect x=\"284\" y=\"268\" width=\"14\" height=\"12\" rx=\"3\" fill=\"#1f1f24\"/><rect x=\"302\" y=\"268\" width=\"14\" height=\"12\" rx=\"3\" fill=\"#1f1f24\"/></g>"
            }
            if r.has("speil") { o += "<rect x=\"392\" y=\"104\" width=\"58\" height=\"160\" rx=\"6\" fill=\"#c9a36a\"/><rect x=\"396\" y=\"108\" width=\"50\" height=\"152\" rx=\"4\" fill=\"url(#mir)\"/><path d=\"M400 176L430 110L440 110L400 204Z\" fill=\"#fff\" opacity=\".35\"/>" }
            if r.has("plante") { o += plant(606) }
            if r.has("kommode") {
                o += art(r, 486, 112) + "<rect x=\"490\" y=\"288\" width=\"5\" height=\"8\" fill=\"\(woodD)\"/><rect x=\"577\" y=\"288\" width=\"5\" height=\"8\" fill=\"\(woodD)\"/><rect x=\"484\" y=\"232\" width=\"104\" height=\"58\" rx=\"2\" fill=\"\(wood)\"/><path d=\"M488 252L584 252M488 271L584 271\" stroke=\"\(woodD)\"/>"
                    + [242, 261, 280].map { "<circle cx=\"536\" cy=\"\($0)\" r=\"1.7\" fill=\"#d9c9a0\"/>" }.joined()
                    + "<ellipse cx=\"512\" cy=\"230\" rx=\"12\" ry=\"3.5\" fill=\"#f4f1ea\" stroke=\"#0003\"/><rect x=\"556\" y=\"218\" width=\"5\" height=\"14\" fill=\"#33363b\"/><path d=\"M546 220L571 220L567 200L550 200Z\" fill=\"#efe7d6\" stroke=\"#0002\"/>"
                glow.append((558, 210, 32, "<path d=\"M546 220L571 220L567 200L550 200Z\" fill=\"#fff1cc\"/>", nil))
            }
        }
        o += extra
        if eve {
            o += "<rect x=\"-640\" y=\"-600\" width=\"1920\" height=\"1400\" fill=\"#0c1233\" opacity=\".42\"/>"
            for g in glow { o += "<circle cx=\"\(js(g.0))\" cy=\"\(js(g.1))\" r=\"\(js(g.2))\" fill=\"\(g.4 ?? "#ffd98a")\" opacity=\".55\" filter=\"url(#gl)\"/>\(g.3)" }
        }
        return (o + "</svg>", eve ? shade(W, -0.3) : W)
    }
}

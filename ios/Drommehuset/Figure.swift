import Foundation

/// Tegner en figur som SVG-tekst. Dette er en direkte overføring av tegnekoden fra nettversjonen,
/// slik at figuren ser helt lik ut. Teksten tegnes på skjermen av SVGView.
struct Figure {
    let s: Look
    let f: Feat
    var child = false

    // små hjelpere, samme som i nettversjonen
    func mir(_ x: String) -> String { x + "<g transform=\"translate(300 0) scale(-1 1)\">" + x + "</g>" }
    func F(_ c: String) -> String { "fill=\"\(c)\" stroke=\"\(shade(c, -0.3))\" stroke-width=\".8\" stroke-linejoin=\"round\"" }
    func ln(_ d: String, _ c: String, _ w: Double = 1, _ op: Double? = nil) -> String {
        "<path d=\"\(d)\" stroke=\"\(c)\" stroke-width=\"\(js(w))\" fill=\"none\" stroke-linecap=\"round\"" + (op != nil ? " opacity=\"\(js(op!))\"" : "") + "/>"
    }
    func limb(_ d: String, _ c: String, _ w: Double) -> String {
        "<path d=\"\(d)\" stroke=\"\(shade(c, -0.3))\" stroke-width=\"\(js(w + 1.6))\" fill=\"none\" stroke-linecap=\"round\"/><path d=\"\(d)\" stroke=\"\(c)\" stroke-width=\"\(js(w))\" fill=\"none\" stroke-linecap=\"round\"/>"
    }

    // MARK: hår
    func hairBack() -> String {
        let c = s.hairColor, h = s.hair
        var o = ""
        let cap = "<path d=\"M118 72C113 16 187 16 182 72Z\"/>"
        if h == "langt" || h == "pannelugg" { o = "<path d=\"M117 70C112 16 188 16 183 70C186 120 192 170 191 216Q150 228 109 216C108 170 114 120 117 70Z\"/>" }
        else if h == "bolgete" { o = "<path d=\"M117 70C112 16 188 16 183 70Q196 100 186 126Q198 152 188 178Q198 204 190 226Q150 238 110 226Q102 204 112 178Q102 152 114 126Q104 100 117 70Z\"/>" }
        else if h == "lob" { o = "<path d=\"M117 70C112 16 188 16 183 70C186 96 188 116 186 134Q150 142 114 134C112 116 114 96 117 70Z\"/>" }
        else if h == "hestehale" { o = cap + "<path d=\"M160 24C198 16 208 60 201 112C198 150 192 176 184 192C182 160 187 120 180 80Z\"/>" }
        else if h == "knute" { o = cap + "<circle cx=\"150\" cy=\"18\" r=\"15\"/>" }
        else if h == "fletter" || h == "kort" { o = cap }
        else if h == "kroller" {
            o = "<ellipse cx=\"150\" cy=\"62\" rx=\"42\" ry=\"44\"/>"
            var a = -210
            while a <= 30 {
                let r = Double(a) * .pi / 180
                o += "<circle cx=\"\(fx(150 + 44 * cos(r), 1))\" cy=\"\(fx(64 + 48 * sin(r), 1))\" r=\"13\"/>"
                a += 14
            }
            o += mir("<circle cx=\"111\" cy=\"98\" r=\"12\"/><circle cx=\"109\" cy=\"114\" r=\"12\"/><circle cx=\"110\" cy=\"130\" r=\"12\"/><circle cx=\"113\" cy=\"146\" r=\"11\"/>")
        }
        return "<g fill=\"\(c)\">\(o)</g>"
    }

    func hairFront() -> String {
        let c = s.hairColor, hl = shade(c, 0.25), h = s.hair
        var o = "", x = ""
        func strand(_ d: String) -> String { ln(d, hl, 0.9, 0.32) }
        if h == "langt" || h == "pannelugg" {
            o = mir("<path d=\"M150 27C130 24 115 42 117 72C116 110 110 160 110 210Q117 216 125 208C124 160 125 120 122 86C122 62 132 44 151 37Z\"/>")
            x = mir(strand("M140 33C127 44 121 62 120 92") + strand("M119 100C116 140 115 170 115 204"))
            if h == "pannelugg" {
                o += "<path d=\"M121 66C122 40 140 30 150 30C160 30 178 40 179 66C172 62 168 61 163 61.5C158 60 154 61 150 60.5C146 61 142 60 137 61.5C132 61 128 62 121 66Z\"/>"
                x += strand("M136 38Q131 48 131 59") + strand("M150 34L150 58") + strand("M164 38Q169 48 169 59")
            }
        } else if h == "bolgete" {
            o = mir("<path d=\"M150 27C130 24 115 42 117 72Q106 98 116 122Q104 148 114 174Q104 200 112 222Q120 226 126 216Q118 196 127 174Q118 150 127 124Q120 104 123 86C122 62 132 44 151 37Z\"/>")
            x = mir(strand("M140 33C127 44 121 62 120 86") + strand("M119 96Q113 110 120 124Q111 148 119 172Q111 196 117 214"))
        } else if h == "lob" {
            o = mir("<path d=\"M150 27C130 24 115 42 117 72C115 96 112 116 113 132Q120 138 128 130C125 112 124 98 122 86C122 62 132 44 151 37Z\"/>")
            x = mir(strand("M140 33C127 44 121 62 120 92") + strand("M119 98Q117 114 118 128"))
        } else if h == "hestehale" || h == "knute" {
            o = "<path d=\"M119 68C113 12 187 12 181 68C180 52 170 40 150 39C130 40 120 52 119 68Z\"/>"
            x = strand("M132 34Q150 28 168 34") + strand("M125 46Q150 32 175 46")
            if h == "knute" { x += strand("M140 14Q150 6 160 14") + strand("M138 22Q150 14 162 22") }
            else { x += strand("M186 40C196 70 194 120 188 170") }
        } else if h == "fletter" {
            var b = ""
            for i in 0..<10 {
                let cx = 119 + (i % 2 == 1 ? 2 : -2), cy = 102 + Double(i) * 12.5
                b += "<ellipse cx=\"\(cx)\" cy=\"\(js(cy))\" rx=\"6\" ry=\"8.5\" transform=\"rotate(\(i % 2 == 1 ? 22 : -22) \(cx) \(js(cy)))\"/>"
            }
            o = mir("<path d=\"M150 27C130 24 115 42 117 72C116 84 116 92 118 100L125 98C123 92 122 90 122 86C122 62 132 44 151 37Z\"/>" + b + "<path d=\"M114 222L124 222L122 240Q119 244 116 240Z\"/>")
            x = mir(strand("M140 33C127 44 121 62 120 90") + "<rect x=\"113.5\" y=\"220\" width=\"11\" height=\"4\" rx=\"1.5\" fill=\"\(shade(c, -0.45))\"/>")
        } else if h == "kort" {
            o = "<path d=\"M118 78C112 14 188 14 182 78C182 62 177 51 169 46C158 54 140 57 126 50C121 57 118 66 118 78Z\"/>"
            x = strand("M130 40Q150 30 170 42") + strand("M128 48Q146 52 164 44")
        } else if h == "kroller" {
            for q in [[126, 47], [137, 39], [150, 36], [163, 39], [174, 47], [119, 60], [181, 60]] {
                o += "<circle cx=\"\(q[0])\" cy=\"\(q[1])\" r=\"9.5\"/>"
                x += ln("M\(q[0] - 4) \(q[1] + 1)Q\(q[0]) \(q[1] - 5) \(q[0] + 4) \(q[1] + 1)", hl, 1, 0.4)
            }
        }
        var fz = ""
        if s.oops == "frizz" {
            let pts: [[Double]] = [[124, 34, -12, -10], [134, 26, -6, -14], [146, 22, -2, -16], [158, 23, 4, -15], [170, 28, 9, -13], [180, 38, 13, -8], [114, 60, -13, -3], [186, 62, 13, -4], [112, 90, -12, 3], [189, 92, 12, 2], [120, 44, -14, -6], [184, 48, 14, -7]]
            fz = pts.map { q in ln("M\(js(q[0])) \(js(q[1]))q\(js(q[2] * 0.3)) \(js(q[3] * 0.8)) \(js(q[2])) \(js(q[3]))", c, 0.9) }.joined()
        }
        return "<g fill=\"\(c)\">\(o)</g>\(x)\(fz)"
    }

    // MARK: ansikt
    func face() -> String {
        let sk = s.skin
        var o = ""
        o += mir("<ellipse cx=\"119.5\" cy=\"74\" rx=\"3.6\" ry=\"8\" fill=\"\(shade(sk, -0.06))\"/>")
        o += "<path d=\"\(Feats.head[f.face] ?? Feats.head["oval"]!)\" fill=\"\(sk)\"/>"
        if s.blush != "none" { o += mir("<ellipse cx=\"130\" cy=\"86\" rx=\"7.5\" ry=\"4\" transform=\"rotate(-14 130 86)\" fill=\"\(s.blush)\" opacity=\".34\" filter=\"url(#b2)\"/>") }
        if s.freckles {
            let p: [[Double]] = [[133, 82], [136, 85], [130, 85.5], [139, 82.5], [127, 83], [134, 88], [141, 86], [145, 84.5], [148, 86.5]]
            o += mir("<g fill=\"#7a4a2a\" opacity=\".5\">" + p.map { "<circle cx=\"\(js($0[0]))\" cy=\"\(js($0[1]))\" r=\".6\"/>" }.joined() + "</g>")
        }
        var e = ""
        if s.shadow != "none" { e += "<path d=\"M128 71.5Q130 61.5 138 61Q145.5 61.5 147.5 70.5Q143 66 138 66Q133 66 128 71.5Z\" fill=\"\(s.shadow)\" opacity=\".75\" filter=\"url(#b1)\"/>" }
        e += ln("M130 66.6Q137.5 61.6 146 66.4", "#000", 0.7, 0.13)
            + "<path d=\"M129.5 71.5Q133 66.5 138 66.5Q142.5 66.8 145.5 71Q141 74.5 137 74.5Q133 74.5 129.5 71.5Z\" fill=\"#fbf8f5\"/>"
            + "<circle cx=\"137.6\" cy=\"70.5\" r=\"3.9\" fill=\"\(s.eyes)\" stroke=\"#000\" stroke-opacity=\".35\" stroke-width=\".6\"/><circle cx=\"137.6\" cy=\"70.5\" r=\"1.7\" fill=\"#120c0c\"/><circle cx=\"138.9\" cy=\"69.2\" r=\".9\" fill=\"#fff\"/>"
            + ln("M131 73.6Q137 76 144 73.3", "#000", 0.6, 0.16)
            + ln("M129 71.8Q133 66 138 66Q143 66.2 146 71.2", "#2b1a17", s.liner ? 1.7 : s.mascara ? 1.4 : 1)
        if s.mascara { e += ln("M130.4 69.6L128.9 68.2M132 68L130.8 66.3M134.3 66.7L133.6 65M137.4 66L137.2 64.3M140.4 66.2L140.7 64.6M143.2 67.4L144 66", "#1a1212", 0.5) }
        if s.liner { e += "<path d=\"M129.2 71.9L126.2 68.6L131 69.6Z\" fill=\"#1a1212\"/>" }
        if s.oops == "maskara" { e += "<g filter=\"url(#b1)\" opacity=\".6\">\(ln("M133 75L132 85M139 75.5L140 83M136 76L136 80", "#1a1212", 1.7))</g>" }
        e += "<path d=\"M127.5 62Q133 57.2 141 58L147 60.2Q141 59.7 137 59.9Q132 60.1 127.5 62Z\" fill=\"\(shade(s.hairColor, -0.3))\" opacity=\".9\"/>"
        o += mir("<g transform=\"translate(137.5 70.5) rotate(\(js(f.er))) scale(\(js(f.es))) translate(-137.5 -70.5)\">\(e)</g>")
        o += ln("M144.6 90.6Q146.4 93.2 150 92.5Q153.6 93.2 155.4 90.6", "#000", 0.8, 0.22) + "<circle cx=\"150\" cy=\"88.4\" r=\"1.7\" fill=\"#fff\" opacity=\".22\"/>"
        let nat = s.lips == "none", lc = nat ? "#b5616a" : s.lips, lo = nat ? " opacity=\".7\"" : ""
        var L = "<path d=\"M141.5 98.6Q145 96.4 148 96Q150 96.8 152 96Q155 96.4 158.5 98.6Q154 99.3 150 99.1Q146 99.3 141.5 98.6Z\" fill=\"\(shade(lc, -0.14))\"\(lo)/>"
            + "<path d=\"M141.5 98.6Q146 99.3 150 99.1Q154 99.3 158.5 98.6Q155 103.6 150 103.8Q145 103.6 141.5 98.6Z\" fill=\"\(lc)\"\(lo)/>"
            + ln("M141.5 98.6Q146 99.5 150 99.1Q154 99.5 158.5 98.6", "#000", 0.5, 0.35)
        if s.gloss { L += ln("M146 101.3Q150 102.3 154 101.3", "#fff", 0.9, 0.6) }
        return o + "<g transform=\"translate(150 99.2) scale(1 \(js(f.lip))) translate(-150 -99.2)\">\(L)</g>"
    }

    // MARK: kropp og klær
    func longSleeve(_ c: String, _ a: Double, _ b: Double) -> String {
        mir(limb("M107 146L98 230", c, a) + limb("M98 230L94 292", c, b) + "<path d=\"M107 146L98 230\" stroke=\"\(c)\" stroke-width=\"\(js(a))\" stroke-linecap=\"round\"/>" + ln("M\(js(94 - b / 2)) 296L\(js(94 + b / 2)) 298", shade(c, -0.25), 2))
    }
    func shortSleeve(_ c: String) -> String { mir("<path d=\"M118 137Q104 131 96 141L89 186L114 190Z\" \(F(c))/>") }

    func shoes() -> String {
        let c = s.shoeColor, d = shade(c, -0.3)
        if s.shoes == "ballerina" { return mir("<path d=\"M127.5 570Q137 562 147.5 570L148 580Q148 592 138 592Q126 592 127 580Z\" \(F(c))/>") }
        if s.shoes == "haeler" { return mir("<path d=\"M128 566Q137 560 147 566L144 588Q138 602 132 588Z\" \(F(c))/>" + ln("M129 554L146 554", c, 2.4)) }
        if s.shoes == "boots" { return mir("<path d=\"M122 468L150 468Q151 520 149 552L151 580Q151 593 138 593Q123 593 124 580L125 552Q120 520 122 468Z\" \(F(c))/><path d=\"M124 582Q124 594 138 594Q151 594 151 582Z\" fill=\"\(d)\"/>") }
        return mir("<path d=\"M126 546L148 546L150 578Q150 592 138 592Q124 592 124 580Z\" \(F(c))/><path d=\"M124 581Q124 594 138 594Q150 594 150 581Z\" fill=\"#f2f0ec\" stroke=\"#0003\" stroke-width=\".6\"/>" + ln("M131 556L144 556M131 562L145 562M131 568L145 568", "#fff", 1.2, 0.8))
    }

    func bottom() -> String {
        let c = s.bottomColor, d = shade(c, -0.22), b = s.bottom, top = "M123 230L177 230Q187 262 189 292"
        if b == "skjort" { return "<path d=\"\(top)Q194 318 198 340Q150 350 102 340Q106 318 111 292Q113 262 123 230Z\" \(F(c))/>" + ln("M136 236Q132 300 128 343M164 236Q168 300 172 343", d, 0.8, 0.6) }
        if b == "midi" { return "<path d=\"M123 230L177 230Q196 320 206 468Q150 482 94 468Q104 320 123 230Z\" \(F(c))/>" + ln("M134 236Q124 360 116 472M150 238L150 476M166 236Q176 360 184 472", d, 0.8, 0.6) }
        if b == "shorts" { return "<path d=\"\(top)L191 336L153 336L150 312L147 336L109 336L111 292Q113 262 123 230Z\" \(F(c))/>" + ln("M150 232L150 310M124 238L176 238", d, 0.8) + ln("M127 240Q130 256 116 262M173 240Q170 256 184 262", d, 0.8) }
        if b == "vide" { return "<path d=\"\(top)L198 562L156 562L150 320L144 562L102 562L111 292Q113 262 123 230Z\" \(F(c))/>" + ln("M150 232L150 318M124 238L176 238", d, 0.8) + ln("M133 250L124 560M167 250L176 560", d, 0.8, 0.5) }
        return "<path d=\"\(top)Q188 360 180 420Q180 490 173 552L153 552Q152 470 152 420L150 310L148 420Q148 470 147 552L127 552Q120 490 120 420Q112 360 111 292Q113 262 123 230Z\" \(F(c))/>"
            + ln("M150 232L150 308M124 238L176 238", d, 0.8) + ln("M127 240Q130 256 116 262M173 240Q170 256 184 262", d, 0.8)
            + mir("<ellipse cx=\"133\" cy=\"350\" rx=\"5\" ry=\"48\" fill=\"#fff\" opacity=\".06\"/>") + ln("M128 546L146 546M154 546L172 546", d, 0.8)
    }

    func topParts() -> (String, String) {
        let c = s.topColor, d = shade(c, -0.22), t = s.top
        var o = "", sl = ""
        if t == "singlet" {
            o = "<path d=\"M127 133L136 128Q150 152 164 128L173 133Q181 160 184 182Q178 215 177 234Q182 256 184 268L116 268Q118 256 123 234Q122 215 116 182Q119 160 127 133Z\" \(F(c))/>"
        } else if t == "genser" || t == "hettegenser" {
            o = "<path d=\"M106 136Q128 126 138 122Q150 133 162 122Q172 126 194 136L190 190Q186 240 188 284L112 284Q114 240 110 190Z\" \(F(c))/>" + ln("M112 277L188 277", d, 0.9)
            if t == "hettegenser" {
                o += "<path d=\"M131 121Q150 148 169 121Q178 134 169 146Q150 160 131 146Q122 134 131 121Z\" fill=\"\(shade(c, -0.1))\" stroke=\"\(shade(c, -0.3))\" stroke-width=\".8\"/>"
                    + ln("M144 150L143 180M156 150L157 180", "#f2f0ec", 1.3) + "<path d=\"M128 242L172 242L180 272L120 272Z\" fill=\"none\" stroke=\"\(d)\" stroke-width=\".9\"/>"
            } else { o += ln("M138 122Q150 135 162 122", d, 2.2) }
            sl = longSleeve(c, 29, 24)
        } else {
            let hem = t == "skjorte" ? 280 : 272
            o = "<path d=\"M110 136Q128 128 138 123Q150 136 162 123Q172 128 190 136L184 182Q178 215 177 234Q182 258 185 \(hem)L115 \(hem)Q118 258 123 234Q122 215 116 182Z\" \(F(c))/>"
            if t == "skjorte" {
                o += ln("M150 140L150 280", d, 0.8) + [156, 180, 204, 228, 252].map { "<circle cx=\"150\" cy=\"\($0)\" r=\"1.2\" fill=\"\(d)\"/>" }.joined()
                    + mir("<path d=\"M139 121L150 140L141 149L133 127Z\" \(F(c))/>")
                sl = longSleeve(c, 25, 20)
            } else { sl = shortSleeve(c) }
        }
        return (o, sl)
    }

    func dressParts() -> (String, String) {
        let c = s.dressColor, d = shade(c, -0.22), t = s.dress
        if t == "sommer" {
            return ("<path d=\"M127 134L136 129Q150 152 164 129L173 134Q181 160 184 182Q179 215 178 232Q200 320 206 410Q150 424 94 410Q100 320 122 232Q121 215 116 182Q119 160 127 134Z\" \(F(c))/>"
                + ln("M122 232Q150 238 178 232", d, 0.9) + ln("M138 238Q132 320 124 414M162 238Q168 320 176 414M150 239L150 418", d, 0.8, 0.5), "")
        }
        if t == "galla" {
            return ("<path d=\"M117 170Q133 156 150 170Q167 156 183 170Q179 215 177 232Q192 300 198 400Q206 520 218 598Q150 612 82 598Q94 520 102 400Q108 300 123 232Q121 215 117 170Z\" \(F(c))/>"
                + ln("M132 244Q118 400 106 594", "#fff", 6, 0.16) + ln("M150 240L150 604M166 242Q180 400 192 600", d, 0.8, 0.5) + ln("M123 232Q150 238 177 232", d, 0.9), "")
        }
        return ("<path d=\"M110 136Q128 128 138 124Q150 137 162 124Q172 128 190 136L184 182Q178 215 177 234Q188 262 190 296L187 372L113 372L110 296Q112 262 123 234Q122 215 116 182Z\" \(F(c))/>", shortSleeve(c))
    }

    func jacket() -> String {
        let t = s.outer
        if t == "none" { return "" }
        let c = s.outerColor, d = shade(c, -0.25), H = t == "blazer" ? 302 : 264
        var p = "<path d=\"M137 121Q120 127 104 136L108 190Q106 240 106 \(H)L134 \(H)Q130 220 137 121Z\" \(F(c))/>"
        if t == "dongeri" {
            p += "<path d=\"M112 176L128 176L128 190L120 194L112 190Z\" fill=\"none\" stroke=\"\(d)\" stroke-width=\".9\"/>" + ln("M108 \(H - 8)L134 \(H - 8)", d, 0.9)
                + [150, 180, 210, 240].map { "<circle cx=\"132.5\" cy=\"\($0)\" r=\"1.3\" fill=\"#c9a36a\"/>" }.joined() + "<path d=\"M137 121L130 127L135 143L143 131Z\" \(F(c))/>"
        } else {
            p += "<path d=\"M137 121L126 172L139 202Q133 160 137 121Z\" fill=\"\(d)\"/>" + (t == "blazer" ? "<circle cx=\"133\" cy=\"232\" r=\"1.8\" fill=\"\(shade(c, -0.45))\"/>" : ln("M108 \(H - 7)L134 \(H - 7)", d, 1.2) + ln("M112 200L126 206", d, 1))
        }
        let z = t == "skinn" ? "<path d=\"M164.5 150Q168 210 166 \(H)\" stroke=\"#c9c9c9\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"1.4 1.4\"/>" : ""
        return mir(p) + z + longSleeve(c, 28, 23)
    }

    /// Hele figuren (300 x 610 punkter, føttene ved y = 598).
    func svg() -> String {
        let sk = s.skin, skd = shade(sk, -0.14), ch = child
        let H = ch ? "<g transform=\"translate(150 104) scale(1.32) translate(-150 -104)\">" : "", He = ch ? "</g>" : ""
        let Lg = ch ? "<g transform=\"translate(0 290) scale(1 .72) translate(0 -290)\">" : "", Le = ch ? "</g>" : ""
        let shadowE = "<ellipse cx=\"150\" cy=\"598\" rx=\"74\" ry=\"6\" fill=\"#000\" opacity=\".12\"/>"
        var o = ""
        o += H + hairBack() + He + "<g transform=\"translate(150 0) scale(\(js(f.bx)) 1) translate(-150 0)\">"
        o += Lg + mir("<path d=\"M112 286L150 286L150 304Q149 380 147 420Q150 480 145 556L130 556Q122 480 122 420Q111 360 112 286Z\" fill=\"\(sk)\"/>" + ln("M128 418Q134 424 141 419", skd, 1.1)
            + "<path d=\"M129 552L146 552L148 580Q148 591 138 591Q126 591 127 580Z\" fill=\"\(sk)\"/>")
        o += shoes() + Le
        o += "<path d=\"M141 104L141 120Q138 130 110 136L116 182Q122 215 123 232Q113 262 112 290L188 290Q187 262 177 232Q178 215 184 182L190 136Q162 130 159 120L159 104Z\" fill=\"\(sk)\"/>"
            + "<path d=\"M141 105Q150 119 159 105L159 104L141 104Z\" fill=\"#000\" opacity=\".09\"/>" + mir(ln("M127 139Q137 142.5 146 139.5", skd, 1))
        var sl = ""
        if s.dress == "none" { o += Lg + bottom() + Le; let t = topParts(); o += t.0; sl = t.1 }
        else { let t = dressParts(); o += t.0; sl = t.1 }
        if s.oops == "flekk" { o += "<path d=\"M158 196q9 -5 14 3q6 9 -3 15q-10 5 -15 -4q-4 -8 4 -14z\" fill=\"#6b4423\" opacity=\".6\"/><circle cx=\"151\" cy=\"221\" r=\"2.6\" fill=\"#6b4423\" opacity=\".55\"/>" }
        if s.acc.halskjede { o += ln("M140 122Q150 138 160 122", "#c9ccd1", 0.9) + "<circle cx=\"150\" cy=\"130.5\" r=\"1.8\" fill=\"#e8eaee\" stroke=\"#9aa0a8\" stroke-width=\".4\"/>" }
        if s.acc.smykker { o += ln("M139.5 121Q150 135 160.5 121M137 123Q150 147 163 123", "#d4a843", 1) + "<circle cx=\"150\" cy=\"135.5\" r=\"2.2\" fill=\"#d4a843\"/>" }
        if s.acc.veske { o += ln("M193 334Q207 304 221 334", "#4a2f22", 3) + "<rect x=\"185\" y=\"332\" width=\"45\" height=\"36\" rx=\"5\" fill=\"#7a4b33\" stroke=\"#4a2f22\" stroke-width=\".8\"/><path d=\"M185 344Q207.5 356 230 344\" stroke=\"#4a2f22\" stroke-width=\"1\" fill=\"none\"/><rect x=\"204.5\" y=\"347\" width=\"6\" height=\"5\" rx=\"1\" fill=\"#d4a843\"/>" }
        o += mir("<path d=\"M107 146L98 230\" stroke=\"\(sk)\" stroke-width=\"21\" stroke-linecap=\"round\"/><path d=\"M98 230L93 304\" stroke=\"\(sk)\" stroke-width=\"16.5\" stroke-linecap=\"round\"/>") + sl + jacket()
            + mir("<path d=\"M86 302Q84 322 88 336Q92 342 97 336Q101 320 100 302Z\" fill=\"\(sk)\"/>")
        o += "</g>" + H + face()
        if s.acc.oredobber { o += mir("<circle cx=\"119.3\" cy=\"81\" r=\"1.9\" fill=\"#f6f2ea\" stroke=\"#b9b2a6\" stroke-width=\".4\"/>") }
        if s.acc.smykker { o += mir("<circle cx=\"119\" cy=\"86\" r=\"5\" fill=\"none\" stroke=\"#d4a843\" stroke-width=\"1.4\"/>") }
        if s.acc.solbriller { o += mir("<rect x=\"126.5\" y=\"63\" width=\"21.5\" height=\"15.5\" rx=\"6.5\" fill=\"#161418\" opacity=\".93\"/>" + ln("M130 67Q134 65 139 65.4", "#fff", 0.9, 0.25) + ln("M126.8 68L119.6 70", "#161418", 1.4)) + ln("M148 68Q150 66.4 152 68", "#161418", 1.4) }
        o += hairFront()
        if ch { o += He; return shadowE + "<g transform=\"translate(0 85)\">" + o + "</g>" }
        if s.acc.lue { o += "<circle cx=\"150\" cy=\"20\" r=\"8\" fill=\"#c97b84\"/><path d=\"M116 62C112 14 188 14 184 62Q150 48 116 62Z\" fill=\"#9b3b47\"/><path d=\"M114 58Q150 44 186 58L186 70Q150 56 114 70Z\" fill=\"#7d2e39\"/><path d=\"M124 56L125 66M136 52L136 62M150 50L150 60M164 52L164 62M176 56L175 66\" stroke=\"#000\" opacity=\".15\"/>" }
        return shadowE + o
    }
}

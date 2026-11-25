// CONTAINMENT — Part 2 rendering: tactical map, visor effects, HUD telemetry, modals.

import AppKit

private let lightGrad: CGGradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
    colors: [rgba(0, 0, 0, 0).cgColor, rgba(0, 0, 0, 1).cgColor] as CFArray, locations: [0.25, 1])!
private let fogGrad: CGGradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
    colors: [rgba(1, 1, 1, 0).cgColor, rgba(0.9, 0.95, 1, 1).cgColor] as CFArray, locations: [0.45, 1])!

extension FieldScene {

    func draw(_ g: G) {
        let ctx = g.ctx
        g.fill(R(0, 0, W, H), m.ground)
        g.save()
        let wob = nic > 0.5 ? CGFloat(sin(realT * 2.1) * min(nic, 3) * 3) : 0
        ctx.translateBy(x: -cam.x + wob, y: -cam.y + wob * 0.6)
        drawWorld(g)
        g.restore()

        // darkness with a light pool around the wearer
        let sp = pos - cam
        if m.dark > 0 {
            g.save(); ctx.setAlpha(CGFloat(m.dark))
            ctx.drawRadialGradient(lightGrad, startCenter: sp, startRadius: 0, endCenter: sp, endRadius: 560, options: [.drawsAfterEndLocation])
            g.restore()
        }
        if m.ash {
            for (i, a) in ash.enumerated() { g.fill(R(a.x, a.y, i % 3 == 0 ? 3 : 2, i % 3 == 0 ? 3 : 2), rgba(0.75, 0.72, 0.68, 0.55)) }
        }
        effects(g, sp)
        visorRim(g)
        hud(g)
        drawModal(g)
        if notebook { drawNotebook(g) }
        guide.draw(g)
    }

    // MARK: World

    private func drawWorld(_ g: G) {
        let view = R(cam.x - 40, cam.y - 40, W + 80, H + 80)
        for a in m.areas where a.r.intersects(view) {
            g.fill(a.r, a.floor)
            g.text(a.name, a.r.minX + 24, a.r.minY + 26, 12, Pal.greenDim.a(0.8), bold: true)
        }
        // 2 m tactical grid
        var x = (floor(view.minX / 80)) * 80
        while x < view.maxX { g.fill(R(x, view.minY, 1, view.height), Pal.green.a(0.035)); x += 80 }
        var y = (floor(view.minY / 80)) * 80
        while y < view.maxY { g.fill(R(view.minX, y, view.width, 1), Pal.green.a(0.035)); y += 80 }

        // exit / decon line
        g.save(); g.alpha(0.5); g.hazardStripes(m.exit, Pal.green.a(0.4), Pal.dark, step: 20); g.restore()
        g.stroke(m.exit, Pal.green, 2)
        g.text("DECON LINE", m.exit.midX, m.exit.minY + 10, 13, Pal.green, bold: true, align: .center)
        g.text("EXIT [E]", m.exit.midX, m.exit.maxY - 24, 12, Pal.green, align: .center)

        for c in m.contam where c.glow {
            for k in stride(from: 3, to: 0, by: -1) {
                g.circle(c.p, c.r * CGFloat(k) / 3, Pal.cyan.a(0.05 + 0.02 * CGFloat(3 - k)))
            }
        }
        for p in m.puddles { g.circle(p.p, p.r, p.color); g.ring(p.p, p.r, p.color.a(0.6), 1) }
        for (i, pw) in m.powders.enumerated() {
            for k in 0..<26 {
                let a = Double(k * 37 + i * 11), rr = Double((k * 53 + i * 7) % 100) / 100
                let pt = pw.p + CGPoint(x: cos(a) * pw.r * rr, y: sin(a) * pw.r * rr)
                g.fill(R(pt.x, pt.y, 2.5, 2.5), Pal.white.a(0.75))
            }
        }
        let w = windVec
        for p in m.plumes {
            guard let c = p.color else { continue }
            for k in 0..<16 {
                let d = CGFloat(k) * p.length / 14
                let drift = CGFloat(sin(realT * 0.7 + Double(k)) * 8)
                let ctr = p.p + w * d + CGPoint(x: -w.y, y: w.x) * drift
                g.circle(ctr, p.spread + d * 0.22, c.a(c.alphaComponent * CGFloat(1 - Double(k) / 16)))
            }
        }
        for pr in m.props {
            g.fill(pr.0, pr.1); g.stroke(pr.0, Pal.black.a(0.6), 2)
            g.text(pr.2, pr.0.midX, pr.0.midY - 7, 11, Pal.black.a(0.75), bold: true, align: .center)
        }
        for wl in m.walls where wl.r.intersects(view) {
            g.fill(wl.r, rgba(0.24, 0.25, 0.24))
            g.fill(R(wl.r.minX, wl.r.minY, wl.r.width, 2), rgba(0.38, 0.39, 0.37))
        }
        for s in m.rad where !s.name.isEmpty {
            switch s.name {
            case "BREACHED CORE":
                let pulse = CGFloat(0.5 + 0.5 * sin(realT * 3))
                g.circle(s.p, 90 + pulse * 10, rgba(1, 0.45, 0.1, 0.18)); g.circle(s.p, 50, rgba(1, 0.6, 0.2, 0.35))
            case "graphite block", "fuel fragment":
                g.poly([s.p + P(-14, -8), s.p + P(4, -14), s.p + P(15, -2), s.p + P(8, 12), s.p + P(-10, 10)], rgba(0.06, 0.06, 0.06))
                g.text(s.name, s.p.x, s.p.y + 14, 10, Pal.grey, align: .center)
            case "SOURCE CAPSULE REMNANT":
                g.circle(s.p, 26, Pal.cyan.a(0.25 * (shieldMul[0] == nil ? 1 : 0.2))); g.roundRect(R(s.p.x - 10, s.p.y - 7, 20, 14), 4, Pal.grey)
            default:
                g.roundRect(R(s.p.x - 9, s.p.y - 7, 18, 14), 3, Pal.yellow.a(0.8))
            }
        }
        // markers
        for s in m.samples where !s.taken {
            g.poly([s.p + P(0, -12), s.p + P(12, 0), s.p + P(0, 12), s.p + P(-12, 0)], Pal.amber.a(0.85))
            g.text("S", s.p.x, s.p.y - 8, 12, Pal.black, bold: true, align: .center)
            if s.p.dist(pos) < 220 { g.text(s.label, s.p.x, s.p.y + 15, 11, Pal.amber, align: .center) }
        }
        for v in m.victims where !v.rescued {
            if v.litter {
                g.roundRect(R(v.p.x - 26, v.p.y - 12, 52, 24), 4, rgba(0.30, 0.10, 0.10))
                g.text("LITTER", v.p.x, v.p.y - 26, 10, Pal.red, bold: true, align: .center)
            }
            g.fill(R(v.p.x - 18, v.p.y - 6, 30, 12), rgba(0.35, 0.40, 0.55))
            g.circle(v.p + P(16, 0), 7, rgba(0.85, 0.70, 0.55))
            if v.choice != nil { g.circle(v.p + P(-22, -12), 5, Pal.amber) }
            else if Int(realT * 2) % 2 == 0 { g.ring(v.p, 26, Pal.red.a(0.7), 1.5) }
            if v.p.dist(pos) < 220 { g.text(v.name, v.p.x, v.p.y + 14, 11, Pal.white, align: .center) }
        }
        for c in m.clues {
            g.fill(R(c.p.x - 8, c.p.y - 10, 16, 20), c.read ? Pal.grey : Pal.white)
            g.text("i", c.p.x, c.p.y - 8, 13, Pal.black, bold: true, align: .center)
            if c.p.dist(pos) < 200 { g.text(c.title, c.p.x, c.p.y + 13, 10, Pal.white.a(0.8), align: .center) }
        }
        for s in m.surveys {
            g.ring(s.p, 16, s.logged ? Pal.greenDim : Pal.cyan, 2)
            g.text("R", s.p.x, s.p.y - 8, 12, s.logged ? Pal.greenDim : Pal.cyan, bold: true, align: .center)
        }
        for t in m.tasks {
            g.roundRect(R(t.p.x - 12, t.p.y - 12, 24, 24), 4, t.done ? Pal.greenDim : Pal.amber)
            g.text(t.done ? "✓" : "T", t.p.x, t.p.y - 8, 13, Pal.black, bold: true, align: .center)
            if t.p.dist(pos) < 220 { g.text(t.name, t.p.x, t.p.y + 15, 11, Pal.amber, align: .center) }
        }
        if let t = moveTo {
            let pul = CGFloat(0.5 + 0.5 * sin(realT * 7))
            g.ring(t, 10 + pul * 5, Pal.cyan.a(0.8), 2)
            g.line(t + P(-6, 0), t + P(6, 0), Pal.cyan.a(0.7), 1.5)
            g.line(t + P(0, -6), t + P(0, 6), Pal.cyan.a(0.7), 1.5)
        }
        drawSquad(g)
        drawPlayer(g)
    }

    private func drawPlayer(_ g: G) {
        let ctx = g.ctx
        let dir = CGPoint(x: cos(facing), y: sin(facing))
        g.circle(pos + P(3, 4), 16, Pal.black.a(0.4))
        // flashlight cone
        let perp = CGPoint(x: -dir.y, y: dir.x)
        g.poly([pos + dir * 14, pos + dir * 150 + perp * 60, pos + dir * 150 - perp * 60], Pal.yellow.a(0.05))
        g.save(); ctx.translateBy(x: pos.x, y: pos.y); ctx.rotate(by: facing)
        if lo.resp == .scba { g.roundRect(R(-24, -7, 14, 14), 4, lo.suit.encapsulated ? lo.suit.color.blended(withFraction: 0.2, of: .black)! : Pal.grey) }
        g.circle(.zero, 14, lo.suit.color)
        g.ring(.zero, 14, lo.suit.trim, 2)
        g.ctx.setFillColor(Pal.cyan.a(0.8).cgColor)
        g.ctx.beginPath(); g.ctx.addArc(center: .zero, radius: 10, startAngle: -0.8, endAngle: 0.8, clockwise: false); g.ctx.addLine(to: .zero); g.ctx.fillPath()
        g.restore()
    }

    // MARK: Effects & visor

    private func effects(_ g: G, _ sp: CGPoint) {
        let ctx = g.ctx
        let mio = max(0, chol - antidote * 1.1)
        if mio > 0.25 {   // miosis: the world goes dim and narrows
            g.fill(R(0, 0, W, H), Pal.black.a(CGFloat(min(0.5, mio * 0.22))))
            g.save(); ctx.setAlpha(CGFloat(min(0.9, mio * 0.35)))
            ctx.drawRadialGradient(lightGrad, startCenter: sp, startRadius: 0, endCenter: sp, endRadius: 360, options: [.drawsAfterEndLocation])
            g.restore()
        }
        if atropineTox > 0.2 { g.fill(R(0, 0, W, H), Pal.white.a(CGFloat(min(0.18, atropineTox * 0.12)))) }
        let grey = min(0.6, hypoxia * 0.6 + coLoad * 0.6)
        if grey > 0.05 { g.fill(R(0, 0, W, H), rgba(0.3, 0.3, 0.3, CGFloat(grey))) }
        let fog = min(0.55, heat * 0.4 + (hr > 140 ? (hr - 140) / 200 : 0))
        if fog > 0.05 {
            g.save(); ctx.setAlpha(CGFloat(fog))
            ctx.drawRadialGradient(fogGrad, startCenter: P(W / 2, H / 2), startRadius: 0, endCenter: P(W / 2, H / 2), endRadius: 760, options: [.drawsAfterEndLocation])
            g.restore()
        }
        if irritant > 0.3 && Int(realT * 3) % 7 == 0 { g.fill(R(0, 0, W, H), Pal.red.a(0.05)) }
    }

    private func visorRim(_ g: G) {
        let p = CGPath(roundedRect: R(6, 6, W - 12, H - 12), cornerWidth: 70, cornerHeight: 70, transform: nil)
        g.ctx.addPath(p); g.ctx.setStrokeColor(rgba(0.02, 0.02, 0.02, 0.9).cgColor); g.ctx.setLineWidth(16); g.ctx.strokePath()
        g.ctx.addPath(CGPath(roundedRect: R(14, 14, W - 28, H - 28), cornerWidth: 64, cornerHeight: 64, transform: nil))
        g.ctx.setStrokeColor(Pal.amber.a(0.25).cgColor); g.ctx.setLineWidth(1.5); g.ctx.strokePath()
        g.line(P(W * 0.72, 30), P(W * 0.80, 90), Pal.white.a(0.06), 10)
    }

    // MARK: HUD

    private func hudPanel(_ g: G, _ r: CGRect, _ title: String, alarm: Bool = false) {
        g.fill(r, rgba(0.01, 0.03, 0.02, 0.72))
        let c = alarm && Int(realT * 4) % 2 == 0 ? Pal.red : Pal.green.a(0.6)
        g.stroke(r, c, alarm ? 2 : 1)
        g.text(title, r.minX + 8, r.minY + 5, 11, alarm ? Pal.red : Pal.green, bold: true)
    }

    private func hud(_ g: G) {
        // --- respiratory
        let frac = air / airMax
        let ac = frac < 0.33 ? Pal.red : (frac < 0.5 ? Pal.amber : Pal.green)
        if lo.resp == .scba {
            hudPanel(g, R(26, 24, 290, 92), "SCBA // \(Int(lo.cylinder.liters / 40))-MIN CYL", alarm: frac < 0.33)
            g.text("\(Int(lo.cylinder.psi * frac))", 36, 42, 34, ac, bold: true)
            g.text("PSI", 160, 60, 13, ac)
            let lpm = lastLpm
            let minLeft = lpm > 0 ? air / lpm : 0
            g.text("≈\(Int(minLeft)) min @ \(Int(lpm)) L/min", 306, 44, 12, Pal.green, align: .right)
            g.text(Input.down("shift") ? "SPRINTING: AIR ×2" : "", 306, 62, 11, Pal.red, align: .right)
            g.bar(R(36, 90, 270, 10), frac, ac)
            g.fill(R(36 + 270 * 0.33, 86, 2, 18), Pal.red)
        } else {
            hudPanel(g, R(26, 24, 290, 92), "\(lo.resp.short) // CBRN CANISTER", alarm: frac < 0.33 || raw.o2 < 19.5)
            g.text("FILTER \(Int(frac * 100))%", 36, 44, 26, ac, bold: true)
            g.text(raw.o2 < 19.5 ? "O2 BELOW 19.5%: APR UNSAFE" : "O2 ≥19.5% · NO CO · BELOW IDLH", 36, 74, 11, raw.o2 < 19.5 ? Pal.red : Pal.greenDim)
            g.bar(R(36, 92, 270, 10), frac, ac)
        }
        // --- vitals
        hudPanel(g, R(26, 126, 290, 136), "VITALS // BIOTELEMETRY")
        g.text("♥ \(Int(hr)) bpm", 36, 146, 20, hr > 150 ? Pal.red : (hr > 120 ? Pal.amber : Pal.green), bold: true)
        g.text("HEAT", 190, 150, 11, Pal.greenDim); g.bar(R(226, 152, 80, 9), heat, heat > 0.7 ? Pal.red : Pal.amber)
        var sy: CGFloat = 176
        var sym: [String] = []
        let mio = chol - antidote * 1.1
        if mio > 0.25 { sym.append("Vision dimming, runny nose (miosis)") }
        if mio > 1.0 { sym.append("Chest tight, twitching. INJECT [Q]") }
        if nic > 0.5 { sym.append("Nausea, sweating, racing pulse") }
        if nic > 1.5 { sym.append("Tremor, weakness") }
        if atropineTox > 0.2 { sym.append("Dry mouth, hot skin, blurred (atropine)") }
        if irritant > 0.3 { sym.append("Burning throat, cough") }
        if cns > 0.3 { sym.append("Dizzy, headache") }
        if hypoxia > 0.15 { sym.append("Air hunger, confusion (HYPOXIA)") }
        if coLoad > 0.15 { sym.append("Headache, nausea (CO)") }
        if heat > 0.6 { sym.append("Heat stress: visor fogging") }
        if sym.isEmpty { sym.append("No symptoms") }
        for s in sym.prefix(3) { g.text("• " + s, 36, sy, 11, s == "No symptoms" ? Pal.greenDim : Pal.amber); sy += 16 }
        if !rad { g.text("AUTOINJECTORS \(injectors)   GLOVES \(glove == nil ? "CLEAN" : "USED [G]")", 36, 240, 11, Pal.green) }
        else { g.text("GLOVES \(glove == nil ? "CLEAN" : "USED: change [G]")", 36, 240, 11, Pal.green) }

        drawSquadPanel(g, R(26, 272, 290, 136))

        // --- clock / objectives
        let win = run.def.window * 60
        let over = simT > win
        hudPanel(g, R(W / 2 - 200, 24, 400, 64), "ENTRY CLOCK // \(run.def.op)", alarm: over)
        g.text("T+ \(clockStr(simT)) / \(clockStr(win))", W / 2, 40, 18, over ? Pal.red : Pal.amber, bold: true, align: .center)
        let tri = m.victims.filter { $0.choice != nil }.count
        var obj = "SAMPLES \(samples.count)/\(run.def.required) · TRIAGE \(tri)/\(m.victims.count) · READINGS \(m.surveys.filter { $0.logged }.count)/\(m.surveys.count)"
        if !m.tasks.isEmpty { obj += " · TASKS \(m.tasks.filter { $0.done }.count)/\(m.tasks.count)" }
        if litterCount > 0 { obj += " · RESCUED \(rescued)/\(litterCount)" }
        g.text(obj, W / 2, 66, 11, Pal.green, align: .center)

        // --- instruments (right)
        let rx = W - 316
        var ry: CGFloat = 24
        if rad {
            let alarm = shown.rate > 1_000 || (run.def.doseLimit > 0 && dose + nDose > run.def.doseLimit * 0.8)
            hudPanel(g, R(rx, ry, 290, 150), "ION CHAMBER + EPD", alarm: alarm)
            g.text(fmtRate(shown.rate), rx + 10, ry + 22, 26, shown.rate > 10_000 ? Pal.red : (shown.rate > 100 ? Pal.amber : Pal.green), bold: true)
            let lf = (log10(max(shown.rate, 0.1)) + 1) / 8
            g.bar(R(rx + 10, ry + 58, 270, 8), lf, shown.rate > 10_000 ? Pal.red : Pal.amber)
            let tot = dose + nDose
            let lim = run.def.doseLimit
            g.text("DOSE \(f(tot, 2)) / \(Int(lim)) mSv", rx + 10, ry + 74, 14, tot > lim ? Pal.red : Pal.green, bold: true)
            g.bar(R(rx + 10, ry + 94, 270, 8), tot / lim, tot > lim * 0.8 ? Pal.red : Pal.green)
            let hasN = m.rad.contains { $0.neutron > 0 }
            g.text(hasN ? "NEUTRON \(fmtRate(shown.nRate))" : "NEUTRON —", rx + 10, ry + 108, 12, shown.nRate > 1000 ? Pal.red : Pal.green)
            ry += 160
            // Geiger-Müller pancake probe: contamination, with an audible click rate
            let hot = shown.cpm > 10_000
            hudPanel(g, R(rx, ry, 290, 74), "GEIGER-MÜLLER COUNTER", alarm: hot)
            g.text(fmtCpm(shown.cpm), rx + 10, ry + 20, 22, hot ? Pal.red : (shown.cpm > 1_000 ? Pal.amber : Pal.green), bold: true)
            // click train
            let bar = R(rx + 10, ry + 50, 270, 14)
            g.fill(bar, rgba(0.02, 0.04, 0.03))
            let rate = min(1.0, log10(max(shown.cpm, 1)) / 6)
            for k in 0..<28 {
                let on = Double((k * 7 + Int(realT * 60)) % 29) / 29.0 < rate
                if on { g.fill(R(bar.minX + 4 + CGFloat(k) * 9.5, bar.minY + 3, 3, 8), hot ? Pal.red : Pal.green) }
            }
            ry += 84
        }
        let rows: [(String, String, Bool)] = [
            ("O2", f(shown.o2) + " %vol", shown.o2 < 19.5 || shown.o2 > 23.5),
            ("LEL", "\(Int(shown.lel)) %", shown.lel >= 10),
            ("CO", "\(Int(shown.co)) ppm", shown.co >= 35),
            ("H2S", f(shown.h2s) + " ppm", shown.h2s >= 10),
            (lo.sensor5.tag, f(shown.s5, lo.sensor5 == .cl2 ? 2 : 1) + " ppm", shown.s5 >= lo.sensor5.alarm),
        ]
        let anyA = rows.contains { $0.2 }
        hudPanel(g, R(rx, ry, 290, 120), "5-GAS METER", alarm: anyA)
        for (i, r) in rows.enumerated() {
            let yy = ry + 22 + CGFloat(i) * 19
            if r.2 { g.fill(R(rx + 4, yy - 2, 282, 18), Pal.red.a(0.25)) }
            g.text(r.0, rx + 12, yy, 13, r.2 ? Pal.red : Pal.greenDim, bold: true)
            g.text(r.1, rx + 280, yy, 13, r.2 ? Pal.red : Pal.green, bold: true, align: .right)
        }
        ry += 130
        if !rad {
            let gb = bars(shown.imsG), hb = bars(shown.imsH)
            hudPanel(g, R(rx, ry, 290, 66), "IMS CW-AGENT DETECTOR", alarm: gb > 0 || hb > 0)
            g.text("G " + String(repeating: "▮", count: gb) + String(repeating: "▯", count: 8 - gb), rx + 12, ry + 22, 14, gb > 0 ? Pal.red : Pal.greenDim, bold: true)
            g.text("H " + String(repeating: "▮", count: hb) + String(repeating: "▯", count: 8 - hb), rx + 12, ry + 42, 14, hb > 0 ? Pal.red : Pal.greenDim, bold: true)
            ry += 76
            // AP4C flame spectrophotometer: element bands, never an agent name
            let anyBand = apBands.contains { $0 > 1 }
            hudPanel(g, R(rx, ry, 290, 86), "AP4C FLAME SPECTROPHOTOMETER", alarm: anyBand)
            if apRunning > 0 {
                g.text("SAMPLING…", rx + 12, ry + 22, 13, Pal.cyan, bold: true)
                g.bar(R(rx + 12, ry + 42, 266, 10), 1 - apRunning / 3.2, Pal.cyan)
                let fx = rx + 150 + CGFloat(sin(realT * 23) * 3)
                g.poly([P(fx, ry + 70), P(fx - 7, ry + 58), P(fx, ry + 46), P(fx + 7, ry + 58)], Pal.cyan.a(0.8))
            } else {
                for (k, nm) in ap4cBands.enumerated() {
                    let x = rx + 14 + CGFloat(k) * 70
                    let v = min(1.0, apBands[k] / 24)
                    let on = apBands[k] > 1
                    g.text(nm, x, ry + 20, 13, on ? Pal.red : Pal.greenDim, bold: true)
                    g.fill(R(x, ry + 38, 54, 10), Pal.dark)
                    g.fill(R(x, ry + 38, 54 * CGFloat(v), 10), on ? Pal.red : Pal.greenDim)
                }
                g.text(anyBand ? "ELEMENT ONLY — NOT AN AGENT ID" : "[P] sample", rx + 12, ry + 58, 11, anyBand ? Pal.amber : Pal.greenDim, bold: anyBand)
            }
            ry += 96
            hudPanel(g, R(rx, ry, 290, 64), "BIO TRIGGER / FENTANYL STRIP", alarm: shown.fluor > 0.5 || fentStrip?.0 == "POSITIVE")
            g.text("\(Int(shown.bio)) part/L · fluor \(Int(shown.fluor * 100))%", rx + 12, ry + 20, 12, shown.fluor > 0.5 ? Pal.red : Pal.green)
            if let fs = fentStrip {
                let posv = fs.0 == "POSITIVE"
                g.roundRect(R(rx + 12, ry + 38, 110, 18), 3, Pal.white.a(0.85))
                g.fill(R(rx + 32, ry + 41, 5, 12), Pal.red)
                if posv { g.fill(R(rx + 86, ry + 41, 5, 12), Pal.red) }
                g.text(fs.0, rx + 132, ry + 40, 13, posv ? Pal.red : Pal.green, bold: true)
            } else {
                g.text("[O] fentanyl test strip", rx + 12, ry + 40, 11, Pal.greenDim)
            }
        }
        // wind
        let wc = P(W - 60, H - 90)
        g.circle(wc, 28, rgba(0, 0, 0, 0.5)); g.ring(wc, 28, Pal.greenDim, 1)
        let wv = windVec
        g.line(wc - wv * 20, wc + wv * 20, Pal.amber, 2.5)
        g.circle(wc + wv * 20, 4, Pal.amber)
        g.text("WIND \(compass(run.def.windDeg))", wc.x, wc.y + 32, 10, Pal.amber, align: .center)

        // --- interaction prompt
        if let a = action {
            let names = ["COLLECTING", "WORKING", "CHANGING GLOVES"]
            let label = a.kind == 0 ? m.samples[a.idx].label : (a.kind == 1 ? m.tasks[a.idx].name : "outer gloves")
            hudPanel(g, R(W / 2 - 220, H - 120, 440, 50), names[a.kind] + ": " + label.uppercased())
            g.bar(R(W / 2 - 210, H - 96, 420, 14), a.prog / a.total, Pal.amber)
        } else if let (kind, i) = nearest {
            var t = ""
            switch kind {
            case "sample": t = "[E] COLLECT \(m.samples[i].kind.rawValue): \(m.samples[i].label)"
            case "victim": t = m.victims[i].litter && m.victims[i].choice != nil
                ? "[T] ORDER LITTER CARRY: \(m.victims[i].name)"
                : "[E] ASSESS / TRIAGE: \(m.victims[i].name)" + (m.victims[i].litter ? "  (STRETCHER CASE)" : "")
            case "task": t = "[E] \(m.tasks[i].name.uppercased())"
            case "clue": t = "[E] READ: \(m.clues[i].title)"
            case "survey": t = "[R] LOG READING: \(m.surveys[i].name)"
            default: t = "[E] EXIT TO DECON LINE (\(samples.count)/\(run.def.required) samples)"
            }
            let w = CGFloat(t.count) * G.charW(14, true) + 30
            g.fill(R(W / 2 - w / 2, H - 110, w, 30), rgba(0, 0, 0, 0.7)); g.stroke(R(W / 2 - w / 2, H - 110, w, 30), Pal.amber, 1)
            g.text(t, W / 2, H - 104, 14, Pal.amber, bold: true, align: .center)
        }
        // toasts
        var ty = H - 70 - CGFloat(toasts.count) * 18
        for t in toasts {
            g.text(t.0, 30, ty, 12, t.2.a(CGFloat(min(1, t.1))), bold: true); ty += 18
        }
        if help > 0 {
            let hr = R(W / 2 - 330, H / 2 + 100, 660, 130)
            g.fill(hr, rgba(0, 0, 0, 0.75)); g.stroke(hr, Pal.green.a(0.5))
            g.para("[WASD/ARROWS] or CLICK to move   [SHIFT] sprint (air ×2)   [E] interact / collect   [R] log reading   [G] change outer gloves   [Q] autoinjector   [P] AP4C   [O] fentanyl strip   [T] order litter carry   [5] squad on me   [6] squad hold   [TAB] notebook   [F] guide   [H] help   [ESC] pause",
                   hr.minX + 14, hr.minY + 12, w: 632, size: 13, color: Pal.green, lineH: 18)
        }
    }

    // MARK: Modals

    private func drawModal(_ g: G) {
        guard let md = modal else { return }
        g.fill(R(0, 0, W, H), Pal.black.a(0.6))
        let r = R(W / 2 - 420, 150, 840, 480)
        switch md {
        case .victim(let i):
            let v = m.victims[i]
            g.panel(r, title: "CASUALTY ASSESSMENT")
            g.text(v.name.uppercased(), r.minX + 24, r.minY + 26, 20, Pal.amber, bold: true)
            let h = g.para(v.signs, r.minX + 24, r.minY + 60, w: r.width - 48, size: 15, color: Pal.white, lineH: 21)
            g.text("SELECT TRIAGE / TREATMENT:", r.minX + 24, r.minY + 80 + h, 12, Pal.greenDim, bold: true)
            modalOpts.draw(g, x: r.minX + 20, y: r.minY + 104 + h, w: r.width - 40, size: 14, gap: 8)
        case .clue(let i):
            let c = m.clues[i]
            g.panel(r, title: "FIELD INTELLIGENCE")
            g.text(c.title, r.minX + 24, r.minY + 26, 20, Pal.amber, bold: true)
            g.para(c.text, r.minX + 24, r.minY + 64, w: r.width - 48, size: 16, color: Pal.white, lineH: 23)
            g.text("[ENTER] close", r.minX + 24, r.maxY - 34, 13, Pal.greenDim)
        case .exitConfirm:
            g.panel(r, title: "EXIT THE HOT ZONE?")
            var y = r.minY + 30
            let short = samples.count < run.def.required
            g.text("SAMPLES SEALED: \(samples.count) / \(run.def.required) required", r.minX + 24, y, 16, short ? Pal.red : Pal.green, bold: true); y += 28
            g.text(lo.resp == .scba ? "AIR REMAINING: \(Int(air / airMax * 100))%" : "FILTER REMAINING: \(Int(air / airMax * 100))%", r.minX + 24, y, 15, Pal.green); y += 26
            g.text("TRIAGED: \(m.victims.filter { $0.choice != nil }.count) / \(m.victims.count)   READINGS: \(m.surveys.filter { $0.logged }.count) / \(m.surveys.count)", r.minX + 24, y, 15, Pal.green); y += 40
            if short { g.para("Too few samples will make lab identification unreliable or impossible.", r.minX + 24, y, w: 780, size: 13, color: Pal.amber); y += 30 }
            modalOpts.draw(g, x: r.minX + 20, y: y, w: 600, size: 16)
        case .pause:
            g.panel(R(W / 2 - 250, 280, 500, 200), title: "PAUSED")
            modalOpts.draw(g, x: W / 2 - 230, y: 320, w: 460, size: 16)
        case .result(let s):
            g.panel(r, title: "NOTICE"); g.para(s, r.minX + 24, r.minY + 30, w: 780, size: 15, color: Pal.white)
        }
    }

    private func drawNotebook(_ g: G) {
        g.fill(R(0, 0, W, H), Pal.black.a(0.75))
        let r = R(80, 70, 1120, 660)
        g.panel(r, title: "FIELD NOTEBOOK // \(run.def.op)")
        var y = r.minY + 26
        g.text("SAMPLES (CHAIN OF CUSTODY)", r.minX + 24, y, 13, Pal.amber, bold: true); y += 22
        if samples.isEmpty { g.text("None yet.", r.minX + 24, y, 13, Pal.greenDim); y += 18 }
        for (i, s) in samples.enumerated() {
            g.text("#\(i + 1)  \(s.label)  [\(s.kind.rawValue)]  sealed T+\(clockStr(simT))", r.minX + 24, y, 13, Pal.green); y += 18
        }
        y += 12
        g.text("INSTRUMENT READINGS", r.minX + 24, y, 13, Pal.amber, bold: true); y += 22
        for l in readingsLog.suffix(12) { y += g.para(l, r.minX + 24, y, w: 1070, size: 12, color: Pal.green, lineH: 16) + 2 }
        y += 12
        g.text("INTELLIGENCE READ", r.minX + 24, y, 13, Pal.amber, bold: true); y += 22
        let read = m.clues.filter { $0.read }.map { $0.title }
        g.para(read.isEmpty ? "None yet." : read.joined(separator: " · "), r.minX + 24, y, w: 1070, size: 13, color: Pal.green)
        g.text("[TAB] close", r.minX + 24, r.maxY - 30, 12, Pal.greenDim)
    }
}

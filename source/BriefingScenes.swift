// CONTAINMENT — Part 1: intelligence briefing + threat assessment, then suit & equipment loadout.

import AppKit

func compass(_ deg: Double) -> String {
    let bearing = (deg + 90).truncatingRemainder(dividingBy: 360)
    return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Int((bearing + 22.5) / 45) % 8]
}

// MARK: - Briefing

final class BriefingScene: Scene {
    let run: MissionRun
    let lines: [String]
    var shown = 0
    var pos = 0.0
    var pause = 0.0
    var phase = 0
    var assess = OptionList(Threat.allCases.map { $0.label })
    var t = 0.0
    var guide = GuideOverlay()

    init(_ r: MissionRun) {
        run = r
        lines = r.def.briefing(r.variant)
        Audio.shared.reset()
        Audio.shared.radioStatic = 0.22
        Audio.shared.hum = 0.15
        if r.def.siren { Audio.shared.alarm = 4 }
    }

    func update(_ dt: Double) {
        t += dt
        if run.def.siren && t > 9 && Audio.shared.alarm == 4 { Audio.shared.alarm = 0 }
        guard phase == 0 else { return }
        if shown >= lines.count { phase = 1; Audio.shared.squelch(); return }
        let L = lines[shown]
        if pos < Double(L.count) {
            let b = Int(pos); pos += dt * 90
            if Int(pos) / 3 != b / 3 { Audio.shared.tick() }
        } else {
            pause += dt
            if pause > 0.35 { advance() }
        }
    }
    private func advance() {
        shown += 1; pos = 0; pause = 0
        if shown < lines.count {
            if lines[shown].hasPrefix(">>") { Audio.shared.squelch() }
            if lines[shown].hasPrefix("!!") { Audio.shared.blip(1800, 0.12, 0.12) }
        }
    }

    func draw(_ g: G) {
        let d = run.def
        header(g, "PART 1 // INTELLIGENCE BRIEFING", "\(d.op) // \(d.year)")
        g.panel(R(40, 90, 800, 520), title: "SECURE TERMINAL: INCOMING TRAFFIC")
        var y: CGFloat = 116
        for i in 0..<min(shown + 1, lines.count) {
            var L = lines[i]
            let full = i < shown
            var col = Pal.green
            if L.hasPrefix(">>") { col = Pal.cyan } else if L.hasPrefix("--") { col = Pal.amber } else if L.hasPrefix("!!") { col = Pal.red }
            if !full { L = String(L.prefix(Int(pos))) + (Int(t * 3) % 2 == 0 ? "█" : "") }
            var shownText = L
            if L.hasPrefix(">>") && full {   // radio traffic gets fragmented with static
                shownText = String(L.enumerated().map { (j, c) in (j * 31 + i * 7) % 23 == 0 && c != " " ? "▒" : c })
            }
            y += g.para(shownText, 60, y, w: 760, size: 14, color: col, lineH: 19) + 5
        }
        // Telemetry panel
        g.panel(R(870, 90, 370, 520), title: "TELEMETRY")
        let c = P(1055, 210)
        g.ring(c, 70, Pal.greenDim, 1.5); g.ring(c, 40, Pal.greenDim.a(0.5), 1)
        g.text("N", c.x, c.y - 92, 13, Pal.green, bold: true, align: .center)
        let w = run.wind
        let tip = c + w * 62, tail = c - w * 62
        g.line(tail, tip, Pal.amber, 3)
        let nrm = CGPoint(x: -w.y, y: w.x)
        g.poly([tip, tip - w * 16 + nrm * 9, tip - w * 16 - nrm * 9], Pal.amber)
        g.text("WIND → \(compass(d.windDeg))  \(f(d.windSpeed)) m/s", 1055, 295, 14, Pal.amber, bold: true, align: .center)
        var ty: CGFloat = 330
        func kv(_ k: String, _ v: String, _ col: NSColor = Pal.green) {
            g.text(k, 890, ty, 12, Pal.greenDim); g.text(v, 1220, ty, 12, col, bold: true, align: .right); ty += 22
        }
        kv("LOCATION", String(d.location.prefix(24)))
        kv("INCIDENT", d.title.uppercased())
        kv("ENTRY WINDOW", "\(Int(d.window)) MIN", d.window <= 30 ? Pal.red : Pal.amber)
        kv("ACUITY", d.window <= 30 ? "HIGH (ACUTE)" : "LOWER (CONTAINMENT)", d.window <= 30 ? Pal.red : Pal.amber)
        if d.doseLimit > 0 { kv("TURN-BACK DOSE", "\(Int(d.doseLimit)) mSv", Pal.red) }
        kv("SAMPLES REQUIRED", "\(d.required)")
        kv("CAUSE", "UNKNOWN", Pal.red)
        g.text(d.inspired, 890, ty + 8, 11, Pal.greenDim)
        // waveform
        let base: CGFloat = 575
        var prev = P(890, base)
        for i in 0..<60 {
            let x = 890 + CGFloat(i) * 5.5
            let amp = phase == 0 ? 14.0 : 3.0
            let yv = base + CGFloat(sin(t * 9 + Double(i) * 0.7) * amp * Double.random(in: 0.3...1))
            let p = P(x, yv); g.line(prev, p, Pal.cyan.a(0.7), 1.2); prev = p
        }

        if phase == 1 {
            g.panel(R(40, 630, 1200, 140), title: "INITIAL THREAT ASSESSMENT: WHAT IS THIS?")
            assess.draw(g, x: 60, y: 650, w: 1160, size: 13, gap: 0)
        } else if phase == 2 {
            g.panel(R(40, 630, 1200, 140), title: "THREAT & SCBA OXYGEN TIMER ASSIGNED")
            let real = Int(d.realSecs / 60)
            g.text("ENTRY WINDOW: \(Int(d.window)) SIMULATED MINUTES  (≈ \(real)–\(real + 1) real minutes)", 60, 656, 16, Pal.amber, bold: true)
            g.para("Initial assessment logged: \(run.initialThreat?.label ?? "-"). You'll revise it after lab analysis. Pacing matters: sprinting roughly doubles your breathing rate and air burn, and the low-air alarm sounds at 33% remaining.",
                   60, 684, w: 1160, size: 13, color: Pal.green)
        }
        guide.draw(g)
        footer(g, phase == 0 ? "[ENTER] skip   [F] field guide   [ESC] abort" : (phase == 1 ? "[1-5] assess threat   [F] field guide" : "[ENTER] proceed to suit & equipment selection"))
    }

    func keyDown(_ k: String) {
        if guide.key(k) { return }
        if k == "f" { guide.show(run.def.division == .nuclear ? 0 : 1); return }
        if k == "esc" && phase < 2 { Game.shared.go(MissionSelectScene()); return }
        switch phase {
        case 0: if k == "enter" || k == "space" { shown = lines.count; phase = 1 }
        case 1:
            if let i = assess.key(k) { run.initialThreat = Threat.allCases[i]; phase = 2; Audio.shared.stamp() }
        default:
            if k == "enter" || k == "space" { Game.shared.go(LoadoutScene(run)) }
        }
    }
    func mouseMoved(_ p: CGPoint) { if phase == 1 { assess.hover(p) }; guide.mouseMoved(p) }
    func mouseDown(_ p: CGPoint) {
        if phase == 1, let i = assess.click(p) { run.initialThreat = Threat.allCases[i]; phase = 2; Audio.shared.stamp() }
        else { keyDown("enter") }
    }
}

// MARK: - Suit rendering (side view)

func drawSuit(_ g: G, _ c: CGPoint, _ s: CGFloat, _ suit: Suit, _ resp: Resp) {
    let col = suit.color, trim = suit.trim
    // SCBA cylinder behind the body (worn outside unless encapsulated)
    if resp == .scba && !suit.encapsulated {
        g.roundRect(R(c.x + 34 * s, c.y - 70 * s, 30 * s, 110 * s), 12 * s, Pal.grey)
        g.fill(R(c.x + 34 * s, c.y - 40 * s, 30 * s, 6 * s), Pal.red)
    }
    // legs
    g.roundRect(R(c.x - 36 * s, c.y + 40 * s, 30 * s, 110 * s), 10 * s, col)
    g.roundRect(R(c.x + 6 * s, c.y + 40 * s, 30 * s, 110 * s), 10 * s, col)
    g.fill(R(c.x - 40 * s, c.y + 140 * s, 38 * s, 18 * s), Pal.dark)
    g.fill(R(c.x + 2 * s, c.y + 140 * s, 38 * s, 18 * s), Pal.dark)
    g.fill(R(c.x - 36 * s, c.y + 120 * s, 72 * s, 6 * s), trim)
    // torso
    if suit.encapsulated {
        g.roundRect(R(c.x - 60 * s, c.y - 150 * s, 120 * s, 200 * s), 40 * s, col)
        g.roundRect(R(c.x - 38 * s, c.y - 128 * s, 76 * s, 52 * s), 20 * s, Pal.cyan.a(0.55))
        g.roundRect(R(c.x - 30 * s, c.y - 122 * s, 26 * s, 12 * s), 6 * s, Pal.white.a(0.5))
        g.fill(R(c.x - 60 * s, c.y - 20 * s, 120 * s, 8 * s), trim)
        if suit.gammaMid > 0.05 {   // shielding panels
            g.roundRect(R(c.x - 44 * s, c.y - 60 * s, 88 * s, 60 * s), 8 * s, Pal.suitGrey.a(0.85))
            g.roundRect(R(c.x - 44 * s, c.y + 6 * s, 88 * s, 40 * s), 8 * s, Pal.suitGrey.a(0.85))
        }
    } else {
        g.roundRect(R(c.x - 48 * s, c.y - 80 * s, 96 * s, 130 * s), 24 * s, col)
        g.fill(R(c.x - 48 * s, c.y - 10 * s, 96 * s, 8 * s), trim)
        // head + full-face mask
        g.circle(P(c.x, c.y - 112 * s), 34 * s, col)
        g.roundRect(R(c.x - 26 * s, c.y - 134 * s, 52 * s, 46 * s), 16 * s, Pal.dark)
        g.roundRect(R(c.x - 20 * s, c.y - 128 * s, 40 * s, 22 * s), 8 * s, Pal.cyan.a(0.55))
        if resp == .apr || resp == .papr {
            g.roundRect(R(c.x - 40 * s, c.y - 104 * s, 22 * s, 26 * s), 5 * s, Pal.olive)   // canister
            g.fill(R(c.x - 40 * s, c.y - 96 * s, 22 * s, 4 * s), Pal.amber)
        } else {
            g.circle(P(c.x, c.y - 96 * s), 8 * s, Pal.grey)   // regulator
        }
        if resp == .papr {
            g.roundRect(R(c.x - 30 * s, c.y + 20 * s, 60 * s, 24 * s), 6 * s, Pal.dark)  // blower
            g.line(P(c.x - 30 * s, c.y + 26 * s), P(c.x - 30 * s, c.y - 96 * s), Pal.grey, 5 * s)
        }
    }
    // arms
    g.roundRect(R(c.x - 84 * s, c.y - 70 * s, 26 * s, 110 * s), 12 * s, col)
    g.roundRect(R(c.x + 58 * s, c.y - 70 * s, 26 * s, 110 * s), 12 * s, col)
    g.fill(R(c.x - 86 * s, c.y + 26 * s, 30 * s, 20 * s), Pal.dark)
    g.fill(R(c.x + 56 * s, c.y + 26 * s, 30 * s, 20 * s), Pal.dark)
    g.fill(R(c.x - 84 * s, c.y + 18 * s, 26 * s, 5 * s), trim)
    g.fill(R(c.x + 58 * s, c.y + 18 * s, 26 * s, 5 * s), trim)
}

// MARK: - Loadout

final class LoadoutScene: Scene {
    let run: MissionRun
    let suits: [Suit]
    var si = 0, ri = 0, ci = 1, ki = 0, s5 = 0
    var row = 0
    var guide = GuideOverlay()

    init(_ r: MissionRun) {
        run = r
        suits = allSuits.filter { $0.division == r.def.division }
        s5 = r.def.suggestedSensor.rawValue
        Audio.shared.reset(); Audio.shared.hum = 0.2; Audio.shared.breathRate = 14; Audio.shared.breathGain = 0.25
    }
    var suit: Suit { suits[si] }
    var resp: Resp { suit.resp[min(ri, suit.resp.count - 1)] }

    func update(_ dt: Double) {}

    func draw(_ g: G) {
        header(g, "PRE-DEPLOYMENT: SUIT & EQUIPMENT", "HAZMAT RATING \(run.def.division.rating)")
        g.panel(R(40, 90, 560, 650), title: "LOADOUT")
        let rows: [(String, String)] = [
            ("SUIT", "\(suit.name)  [\(suit.level)]"),
            ("RESPIRATOR", resp.name + (suit.resp.count > 1 ? "" : "  (fixed by suit)")),
            (resp == .scba ? "SCBA CYLINDER" : "FILTER", resp == .scba ? cylinders[ci].name : canisters[ki].name),
            ("5-GAS: 5TH SENSOR", "O2 · LEL · CO · H2S + " + Sensor5(rawValue: s5)!.name),
            ("DEPLOY", "▶ ENTER THE HOT ZONE"),
        ]
        var y: CGFloat = 116
        for (i, r) in rows.enumerated() {
            let selected = i == row
            if selected { g.fill(R(52, y - 4, 536, i == 4 ? 34 : 56), Pal.amber.a(0.14)); g.fill(R(52, y - 4, 4, i == 4 ? 34 : 56), Pal.amber) }
            g.text(r.0, 66, y, 12, selected ? Pal.amber : Pal.greenDim, bold: true)
            if i == 4 { g.text(r.1, 66, y + 4, 16, selected ? Pal.amber : Pal.green, bold: true) }
            else { g.para("◀ " + r.1 + " ▶", 66, y + 18, w: 520, size: 13, color: selected ? Pal.amber : Pal.green) }
            y += i == 4 ? 44 : 66
        }
        // estimates
        y += 6
        if resp == .scba {
            let cyl = cylinders[ci]
            let rated = cyl.liters / 40
            let work = cyl.liters / (40 * suit.airMult * cyl.exertion)
            let sprint = cyl.liters / (88 * suit.airMult * cyl.exertion)
            g.text("RATED \(Int(rated)) min @ 40 L/min · \(Int(cyl.psi)) psi", 66, y, 13, Pal.green); y += 20
            g.text("EST. MODERATE WORK IN THIS SUIT: \(Int(work)) min", 66, y, 13, Pal.amber, bold: true); y += 20
            g.text("EST. IF SPRINTING: \(Int(sprint)) min · LOW-AIR ALARM AT 33%", 66, y, 13, Pal.red); y += 26
        } else {
            g.text("CANISTER SERVICE LIFE ≈ \(Int(canisters[ki].lifeMin)) min (shorter at high concentration)", 66, y, 13, Pal.amber); y += 20
            g.para("AIR-PURIFYING: not permitted below 19.5% O2, above IDLH, or in unknown atmospheres. No protection against CO.", 66, y, w: 520, size: 12, color: Pal.red); y += 40
        }
        g.text("KIT", 66, y, 12, Pal.greenDim, bold: true); y += 18
        let kit = run.def.division == .nuclear
            ? "Ion-chamber survey meter (to 10 Sv/h) · electronic personal dosimeter · alpha/beta frisker · neutron REM meter · 5-gas meter · sample kit · KI (can't be taken through a facepiece)"
            : "IMS chemical-agent detector · M8/M9 paper · 5-gas meter · DuoDote ×3 · midazolam ×1 · RSDL · bio swab kit · spare outer gloves"
        g.para(kit, 66, y, w: 520, size: 12, color: Pal.green)

        // Suit card
        g.panel(R(620, 90, 620, 650), title: "SUIT PROFILE")
        drawSuit(g, P(760, 400), 1.15, suit, resp)
        let sx: CGFloat = 900
        var sy: CGFloat = 120
        func stat(_ n: String, _ v: Double, _ txt: String? = nil, _ col: NSColor = Pal.green) {
            g.text(n, sx, sy, 12, Pal.greenDim)
            g.bar(R(sx + 130, sy + 2, 150, 10), v, col)
            g.text(txt ?? "\(Int(v * 100))%", sx + 320, sy, 12, col, bold: true, align: .right)
            sy += 22
        }
        stat("SKIN VAPOR", suit.vapor); stat("LIQUID SPLASH", suit.liquid); stat("PARTICULATE", suit.particulate)
        stat("RESP. APF", log10(resp.apf) / 4, "\(Int(resp.apf))", Pal.cyan)
        stat("BETA", suit.beta); stat("γ <200 keV", suit.gammaLow); stat("γ Cs-137", suit.gammaMid); stat("γ >1 MeV", suit.gammaHigh)
        stat("NEUTRON", suit.neutron)
        stat("MOBILITY", suit.mobility, nil, Pal.amber)
        stat("AIR BURN", min(1, (suit.airMult - 0.8) / 0.8), "×" + f(suit.airMult, 2), Pal.red)
        stat("HEAT STRESS", min(1, suit.heat / 1.8), "×" + f(suit.heat, 2), Pal.red)
        g.para(suit.desc, 640, 600, w: 580, size: 12, color: Pal.green, lineH: 16)
        guide.draw(g)
        footer(g, "[↑↓] row   [←→] change   [ENTER] deploy   [F] field guide   [ESC] back to briefing")
    }

    func keyDown(_ k: String) {
        if guide.key(k) { return }
        switch k {
        case "f": guide.show(3)
        case "esc": Game.shared.go(BriefingScene(run))
        case "up", "w": row = (row + 4) % 5; Audio.shared.blip(900, 0.02)
        case "down", "s": row = (row + 1) % 5; Audio.shared.blip(900, 0.02)
        case "left", "a": change(-1)
        case "right", "d": change(1)
        case "enter", "space": if row == 4 { deploy() } else { change(1) }
        default: break
        }
    }
    private func change(_ d: Int) {
        Audio.shared.blip(1100, 0.03)
        switch row {
        case 0: si = (si + d + suits.count) % suits.count; ri = 0
        case 1: ri = (ri + d + suit.resp.count) % suit.resp.count
        case 2: if resp == .scba { ci = (ci + d + cylinders.count) % cylinders.count } else { ki = (ki + d + canisters.count) % canisters.count }
        case 3: s5 = (s5 + d + Sensor5.allCases.count) % Sensor5.allCases.count
        default: break
        }
    }
    private func deploy() {
        run.loadout = Loadout(suit: suit, resp: resp, cylinder: cylinders[ci], canister: canisters[ki], sensor5: Sensor5(rawValue: s5)!)
        Audio.shared.confirm()
        Game.shared.go(FieldScene(run))
    }
    func mouseMoved(_ p: CGPoint) { guide.mouseMoved(p) }
    func mouseDown(_ p: CGPoint) {
        if p.x < 600 && p.y > 110 && p.y < 420 {
            let r = min(4, Int((p.y - 110) / 66))
            if r == row { if row == 4 { deploy() } else { change(p.x < 320 ? -1 : 1) } } else { row = r }
        }
    }
}

// CONTAINMENT — title, security screening, clearance assignment, mission select.

import AppKit

// MARK: - Shared UI

func header(_ g: G, _ title: String, _ sub: String = "") {
    g.fill(R(0, 0, W, 54), Pal.panel)
    g.hazardStripes(R(0, 54, W, 6), Pal.amber, Pal.black, step: 18)
    g.text("CONTAINMENT", 24, 14, 22, Pal.amber, bold: true)
    g.text("//  " + title, 210, 18, 16, Pal.green, bold: true)
    if !sub.isEmpty { g.text(sub, W - 24, 20, 13, Pal.greenDim, align: .right) }
}

func footer(_ g: G, _ hint: String) {
    g.fill(R(0, H - 30, W, 30), Pal.panel)
    g.text(hint, 24, H - 23, 13, Pal.greenDim)
    g.text("[`] mute", W - 24, H - 23, 13, Pal.greenDim, align: .right)
}

func trefoil(_ g: G, _ c: CGPoint, _ r: CGFloat, _ col: NSColor, rot: CGFloat = 0) {
    let ctx = g.ctx
    ctx.setFillColor(col.cgColor)
    for k in 0..<3 {
        let a0 = rot + CGFloat(k) * 2 * .pi / 3 - .pi / 2 - .pi / 6
        let a1 = a0 + .pi / 3
        ctx.beginPath()
        ctx.addArc(center: c, radius: r, startAngle: a0, endAngle: a1, clockwise: false)
        ctx.addArc(center: c, radius: r * 0.3, startAngle: a1, endAngle: a0, clockwise: true)
        ctx.closePath(); ctx.fillPath()
    }
    g.circle(c, r * 0.18, col)
}

// MARK: - Title

final class TitleScene: Scene {
    var menu = OptionList([])
    var t = 0.0
    init() { rebuild(); Audio.shared.reset(); Audio.shared.wind = 0.15 }

    private func rebuild() {
        let s = Game.shared.state
        var items: [String] = []
        if s.screened && s.trained { items.append("REPORT FOR DUTY: \(s.division.title)") }
        if s.screened && !s.trained { items.append("ENTER CBRN RESPONSE ACADEMY (required)") }
        if s.screened && s.trained { items.append("CBRN ACADEMY: REVIEW / RE-EXAMINE") }
        items.append(s.screened ? "RE-TAKE SECURITY SCREENING" : "BEGIN SECURITY CLEARANCE SCREENING")
        if s.replayUnlocked { items.append("REPLAY SELECTOR (BOTH TRACKS)") }
        items.append("CBRN FIELD REFERENCE GUIDE")
        items.append("QUIT")
        menu = OptionList(items)
    }

    func update(_ dt: Double) { t += dt }

    func draw(_ g: G) {
        let rot = CGFloat(t * 0.25)
        trefoil(g, P(1010, 330), 190, Pal.amber.a(0.08), rot: rot)
        g.hazardStripes(R(0, 120, W, 14), Pal.amber, Pal.black, step: 22)
        g.text("CONTAINMENT", 80, 170, 84, Pal.amber, bold: true)
        g.text("CBRN EMERGENCY RESPONSE SIMULATION", 86, 270, 20, Pal.green, bold: true)
        g.text("TRAINING RECONSTRUCTIONS OF HISTORICAL AND INDUSTRIAL INCIDENTS, PERFORMED WITH CURRENT-GENERATION EQUIPMENT", 86, 300, 12, Pal.greenDim)
        g.panel(R(80, 360, 620, 300), title: "TERMINAL")
        menu.draw(g, x: 100, y: 390, w: 580, size: 17)
        let s = Game.shared.state
        g.para(s.screened ? (s.trained ? "On file: \(s.division.clearance) // \(s.division.rating) // ACADEMY PASSED \(s.trainScore)/10 — posted to an entry team."
                                          : "On file: \(s.division.clearance) // \(s.division.rating). Academy not completed — you are not on a team yet.")
                          : "No clearance on file. Screening is required before deployment.",
               80, 680, w: 700, size: 13, color: Pal.greenDim)
        let blink = Int(t * 2) % 2 == 0
        g.text(blink ? "■ SECURE LINK ESTABLISHED" : "□ SECURE LINK ESTABLISHED", W - 80, 700, 13, Pal.green, align: .right)
        footer(g, "[↑↓] select   [ENTER] confirm   [1-9] quick pick   mouse supported")
    }

    func keyDown(_ k: String) { if let i = menu.key(k) { pick(i) } }
    func mouseMoved(_ p: CGPoint) { menu.hover(p) }
    func mouseDown(_ p: CGPoint) { if let i = menu.click(p) { pick(i) } }

    private func pick(_ i: Int) {
        let label = menu.items[i]
        if label.hasPrefix("REPORT FOR DUTY") { Game.shared.go(MissionSelectScene()) }
        else if label.contains("ACADEMY") { Game.shared.go(AcademyScene()) }
        else if label.contains("SCREENING") { Game.shared.go(ScreeningScene()) }
        else if label.hasPrefix("REPLAY") { Game.shared.go(MissionSelectScene(replay: true)) }
        else if label.hasPrefix("CBRN") { Game.shared.go(GuideScene(back: { TitleScene() })) }
        else { NSApp.terminate(nil) }
    }
}

// MARK: - Screening

// MARK: - Clearance result

final class ClearanceScene: Scene {
    var t = 0.0
    var stamped = false
    init() { Audio.shared.reset(); Audio.shared.hum = 0.3 }
    func update(_ dt: Double) {
        t += dt
        if t > 1.2 && !stamped { stamped = true; Audio.shared.stamp() }
    }
    func draw(_ g: G) {
        let s = Game.shared.state
        header(g, "CLEARANCE ADJUDICATION", "CLEARANCE SCORE \(s.score) / 100")
        g.panel(R(80, 100, 1120, 600), title: "DETERMINATION")
        g.text("SUBJECT CLEARANCE SCORE", 120, 140, 16, Pal.greenDim)
        g.text("\(min(s.score, Int(t * 80)))", 120, 165, 64, Pal.amber, bold: true)
        g.bar(R(330, 200, 820, 16), Double(min(s.score, Int(t * 80))) / 100, s.division == .nuclear ? Pal.amber : Pal.green)
        g.text("70 ▲ NUCLEAR THRESHOLD", 330 + 820 * 0.70, 222, 11, Pal.greenDim)
        if stamped {
            let c = s.division == .nuclear ? Pal.red : Pal.amber
            g.save(); g.ctx.translateBy(x: 640, y: 330); g.ctx.rotate(by: -0.05)
            g.stroke(R(-460, -46, 920, 92), c, 5)
            g.text("\(s.division.clearance)  //  \(s.division.title)", 0, -16, 24, c, bold: true, align: .center)
            g.restore()
            var y: CGFloat = 420
            g.text("HAZMAT RATING:  " + s.division.rating, 120, y, 18, Pal.green, bold: true); y += 34
            g.text("MISSION TRACK:  " + (s.division == .nuclear ? "Nuclear & Radiological ONLY" : "Chemical & Biological ONLY (no radiological missions)"), 120, y, 16, Pal.green); y += 30
            g.text("UNLOCKED SUITS:", 120, y, 16, Pal.green); y += 26
            for su in allSuits where su.division == s.division {
                g.text("■ \(su.name)  [\(su.level)]  " + su.resp.map { $0.short }.joined(separator: "/"), 150, y, 14, Pal.amber); y += 22
            }
            g.para(s.division == .nuclear ? "Your answers suggest unusual composure and rule-following. Or you lied very consistently. Either way, welcome to the Nuclear & Radiological Division."
                                           : "Assigned to the Chemical & Biological Division. The screening panel would also like you to see someone about the button thing.",
                   120, y + 16, w: 1040, size: 14, color: Pal.greenDim)
        }
        footer(g, "[ENTER] proceed to mandatory training")
    }
    func keyDown(_ k: String) { if stamped && (k == "enter" || k == "space") { Game.shared.go(AcademyScene()) } else { t = 1.2 } }
    func mouseDown(_ p: CGPoint) { keyDown("enter") }
}


// MARK: - Standby roster (incidents stay anonymous until the callout)

final class MissionSelectScene: Scene {
    var replay: Bool
    var track: Division
    var list = OptionList([], numberKeys: false)
    var defs: [MissionDef] = []
    var t = 0.0

    init(replay: Bool = false) {
        self.replay = replay
        track = Game.shared.state.division
        Audio.shared.reset(); Audio.shared.hum = 0.25; Audio.shared.radioStatic = 0.05
        rebuild()
    }
    private func rebuild() {
        defs = missions(for: track)
        let done = Game.shared.state.completed
        var items = ["▶ TAKE THE NEXT CALLOUT"]
        for (i, d) in defs.enumerated() {
            if let gr = done[d.id] {
                items.append(String(format: "CALLOUT %02d · %@ · CLOSED [%@] — %@", i + 1, d.op, gr, d.title))
            } else {
                items.append(String(format: "CALLOUT %02d · %@ · PENDING — nature unknown", i + 1, d.op))
            }
        }
        list = OptionList(items, numberKeys: false)
    }
    func update(_ dt: Double) { t += dt }

    func draw(_ g: G) {
        let s = Game.shared.state
        header(g, replay ? "REPLAY SELECTOR" : "STANDBY ROTATION", "\(s.division.clearance) // \(track.title)")
        g.panel(R(60, 100, 740, 600), title: track == .nuclear ? "NUCLEAR & RADIOLOGICAL DUTY LOG" : "CHEMICAL & BIOLOGICAL DUTY LOG")
        list.draw(g, x: 80, y: 130, w: 700, size: 14, gap: 10)

        g.panel(R(830, 100, 390, 600), title: "FILE")
        var y: CGFloat = 130
        let i = list.sel - 1
        if i < 0 {
            g.text("NEXT CALLOUT", 850, y, 18, Pal.amber, bold: true); y += 34
            y += g.para("Takes whichever incident comes in next. You will not be told what it is until the alert sounds. This is how it actually works.",
                        850, y, w: 350, size: 14, color: Pal.white, lineH: 20) + 20
        } else {
            let d = defs[i]
            let closed = Game.shared.state.completed[d.id] != nil
            g.text(d.op, 850, y, 18, Pal.amber, bold: true); y += 30
            if closed {
                y += g.para(d.title + " // " + d.year, 850, y, w: 350, size: 14, color: Pal.green, bold: true) + 6
                y += g.para(d.location, 850, y, w: 350, size: 12, color: Pal.greenDim) + 6
                y += g.para(d.inspired, 850, y, w: 350, size: 12, color: Pal.greenDim) + 14
                g.text("GRADE  " + (Game.shared.state.completed[d.id] ?? "-"), 850, y, 14, Pal.amber, bold: true); y += 26
            } else {
                for line in ["INCIDENT TYPE", "LOCATION", "AGENT", "CAUSE", "CASUALTIES"] {
                    g.text(line, 850, y, 12, Pal.greenDim, bold: true)
                    g.fill(R(990, y - 2, 210, 16), Pal.dark)
                    g.text("[ SEALED ]", 1095, y, 12, Pal.red, bold: true, align: .center)
                    y += 24
                }
                y += 14
                y += g.para("Nothing is released before the alert sounds. You will size it up from the dispatch traffic like everyone else.",
                            850, y, w: 350, size: 13, color: Pal.amber, lineH: 19) + 14
            }
        }
        y = 440
        g.text("STANDING ORDERS", 850, y, 12, Pal.greenDim, bold: true); y += 20
        y += g.para("1 Intelligence briefing — classify the incident\n2 Hot zone — squad entry, readings, samples, rescue\n3 Forward lab — identify the agent\n4 Decon & after-action",
                    850, y, w: 350, size: 12, color: Pal.green, lineH: 18) + 16
        let blink = Int(t * 1.5) % 2 == 0
        g.fill(R(850, 620, 350, 34), (blink ? Pal.green : Pal.greenDim).a(0.18))
        g.text(blink ? "● ON STANDBY" : "○ ON STANDBY", 1025, 629, 15, Pal.green, bold: true, align: .center)
        footer(g, replay ? "[ENTER] deploy   [TAB] switch track   [ESC] back" : "[↑↓] select   [ENTER] accept callout   [ESC] back to terminal")
    }
    func keyDown(_ k: String) {
        if k == "esc" { Game.shared.go(TitleScene()); return }
        if k == "tab" && replay { track = track == .nuclear ? .chembio : .nuclear; rebuild(); Audio.shared.blip(700); return }
        if let i = list.key(k) { start(i) }
    }
    func mouseMoved(_ p: CGPoint) { list.hover(p) }
    func mouseDown(_ p: CGPoint) { if let i = list.click(p) { start(i) } }

    private func start(_ i: Int) {
        var d: MissionDef
        if i == 0 {
            let done = Game.shared.state.completed
            d = defs.first { done[$0.id] == nil } ?? defs.randomElement()!
        } else { d = defs[i - 1] }
        Game.shared.go(RedAlertScene(MissionRun(d)))
    }
}

// MARK: - Red alert callout

final class RedAlertScene: Scene {
    let run: MissionRun
    var t = 0.0
    var lines: [String] = []
    var shown = 0
    var pos = 0.0

    init(_ r: MissionRun) {
        run = r
        Audio.shared.reset()
        Audio.shared.alarm = 4
        Audio.shared.radioStatic = 0.3
        lines = [
            "INCIDENT DECLARED — MULTI-AGENCY RESPONSE",
            "CALLSIGN ............ " + r.def.op,
            "LOCATION ............ " + r.def.alertLoc,
            "DISPATCH ............ " + r.def.alertDispatch,
            "NATURE .............. UNKNOWN — TREAT AS CBRN UNTIL CLEARED",
            "ENTRY TEAM .......... YOU + 4",
            "",
            "ALL UNITS RESPOND.",
        ]
    }

    func update(_ dt: Double) {
        t += dt
        if t > 7.5 && Audio.shared.alarm == 4 { Audio.shared.alarm = 0 }
        guard shown < lines.count else { return }
        if pos < Double(lines[shown].count) {
            let b = Int(pos); pos += dt * 120
            if Int(pos) / 3 != b / 3 { Audio.shared.tick() }
        } else {
            shown += 1; pos = 0
            if shown < lines.count && !lines[shown].isEmpty { Audio.shared.blip(1500, 0.04, 0.08) }
        }
    }

    func draw(_ g: G) {
        let pulse = 0.5 + 0.5 * sin(t * 5)
        g.fill(R(0, 0, W, H), rgba(0.14, 0.01, 0.01).blended(withFraction: CGFloat(pulse) * 0.5, of: rgba(0.30, 0.02, 0.02))!)
        // rotating beacon wash
        for side in [CGFloat(0), W] {
            g.save(); g.alpha(CGFloat(0.10 + 0.14 * pulse))
            g.poly([P(side, 0), P(side == 0 ? 520 : W - 520, H / 2), P(side, H)], Pal.red)
            g.restore()
        }
        g.hazardStripes(R(0, 86, W, 22), Pal.red, Pal.black, step: 26)
        g.hazardStripes(R(0, H - 108, W, 22), Pal.red, Pal.black, step: 26)
        let flash = Int(t * 3) % 2 == 0
        if flash { g.text("RED ALERT", W / 2, 130, 86, Pal.red.a(0.3), bold: true, align: .center) }
        g.text("RED ALERT", W / 2, 130, 86, flash ? Pal.red : rgba(0.85, 0.20, 0.16), bold: true, align: .center)
        trefoil(g, P(150, 180), 56, Pal.red.a(CGFloat(0.35 + 0.4 * pulse)), rot: CGFloat(t))
        trefoil(g, P(W - 150, 180), 56, Pal.red.a(CGFloat(0.35 + 0.4 * pulse)), rot: CGFloat(-t))

        g.panel(R(180, 260, 920, 340), title: "DISPATCH", color: Pal.red)
        var y: CGFloat = 292
        for i in 0..<min(shown + 1, lines.count) {
            var L = lines[i]
            if i == shown { L = String(L.prefix(Int(pos))) + (Int(t * 4) % 2 == 0 ? "█" : "") }
            let col: NSColor = i == 0 ? Pal.red : (i == lines.count - 1 ? Pal.amber : Pal.white)
            y += g.para(L, 210, y, w: 870, size: i == 0 || i == lines.count - 1 ? 20 : 16,
                        color: col, lineH: 26, bold: i == 0 || i == lines.count - 1) + 6
        }
        if shown >= lines.count {
            g.text(Int(t * 2) % 2 == 0 ? "[ENTER] ROLL" : " ", W / 2, 640, 24, Pal.amber, bold: true, align: .center)
        }
        footer(g, "[ENTER] respond")
    }
    func keyDown(_ k: String) {
        if k == "enter" || k == "space" {
            if shown < lines.count { shown = lines.count; return }
            Audio.shared.reset(); Game.shared.go(BriefingScene(run))
        }
        if k == "esc" { Audio.shared.reset(); Game.shared.go(MissionSelectScene()) }
    }
    func mouseDown(_ p: CGPoint) { keyDown("enter") }
}

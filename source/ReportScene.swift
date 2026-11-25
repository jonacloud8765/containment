// CONTAINMENT — Part 4b: after-action report. Grades identification accuracy, air/dose discipline,
// decon safety, casualty care and mission outcome, then shows the real history behind the scenario.

import AppKit

struct Grade {
    var rows: [(String, Double, String)] = []   // label, 0..1, detail
    var total = 0.0
    var letter = "F"
    var outcome = ""
}

func gradeRun(_ run: MissionRun) -> Grade {
    var gr = Grade()
    let f0 = run.field
    let lab = run.lab
    let dec = run.decon

    // 1. Identification
    let idScore = lab?.idScore ?? 0
    let enough = f0.samples.count >= run.def.required
    var idDetail = "\(f0.samples.count) of \(run.def.required) required samples returned · "
    idDetail += f0.samples.isEmpty ? "no laboratory identification possible" : "\(Int(idScore * 100))% of samples identified correctly"
    let crossN = f0.samples.filter { $0.cross }.count
    if crossN > 0 { idDetail += " · \(crossN) cross-contaminated by unchanged gloves" }
    let idFinal = idScore * (enough ? 1 : 0.6) * (crossN > 0 ? 0.88 : 1)
    gr.rows.append(("AGENT IDENTIFICATION", idFinal, idDetail))

    // 2. Threat assessment + protocol
    var ta = 0.0
    var taD: [String] = []
    if lab?.threatCorrect == true { ta += 0.5; taD.append("final classification correct") }
    else { taD.append("final classification wrong (actual: \(run.def.threat(run.variant).label))") }
    if lab?.protocolCorrect == true { ta += 0.5; taD.append("protocol correct") }
    else { taD.append("protocol not the recommended one") }
    if run.initialThreat == run.def.threat(run.variant) { taD.append("called it right at the briefing too") }
    gr.rows.append(("THREAT CALL & PROTOCOL", ta, taD.joined(separator: " · ")))

    // 3. Air / exposure discipline
    var air = 1.0
    var airD: [String] = []
    let left = f0.airStart > 0 ? f0.airLeft / f0.airStart : 0
    if run.loadout?.resp == .scba {
        airD.append("\(Int(left * 100))% air remaining on exit")
        if left <= 0 { air -= 0.6; airD.append("CYLINDER EMPTIED") }
        else if left < 0.15 { air -= 0.3; airD.append("exited on reserve air") }
        else if left < 0.33 { air -= 0.12; airD.append("exited past the low-air alarm") }
        else if left > 0.55 { airD.append("good margin") }
    } else {
        airD.append("\(Int(left * 100))% filter life remaining")
        if f0.hypoxia > 0 { air -= 0.4; airD.append("air-purifying respirator used in a low-oxygen atmosphere") }
        if f0.coLoad > 0 { air -= 0.4; airD.append("carbon monoxide exposure through a canister") }
    }
    if f0.heat > 0.7 { air -= 0.15; airD.append("severe heat stress") }
    if f0.simMinutes > run.def.window { air -= 0.2; airD.append("overran the entry window by \(Int(f0.simMinutes - run.def.window)) min") }
    gr.rows.append(("AIR & TIME MANAGEMENT", clamp(air, 0, 1), airD.joined(separator: " · ")))

    // 4. Personal exposure
    var ex = 1.0
    var exD: [String] = []
    if run.def.doseLimit > 0 {
        let tot = f0.dose + f0.neutronDose
        exD.append("dose \(f(tot, 2)) mSv of a \(Int(run.def.doseLimit)) mSv turn-back limit")
        if f0.neutronDose > 0.01 { exD.append("neutron \(f(f0.neutronDose, 2)) mSv") }
        if tot > run.def.doseLimit { ex -= 0.5; exD.append("LIMIT EXCEEDED") }
        else if tot > run.def.doseLimit * 0.6 { ex -= 0.15 }
        else { exD.append("well managed") }
    }
    if f0.skinChem + f0.inhaledChem > 0.05 {
        ex -= min(0.5, f0.skinChem + f0.inhaledChem)
        exD.append("agent exposure index \(f(f0.skinChem + f0.inhaledChem, 2)) (skin \(f(f0.skinChem, 2)))")
    } else if run.def.doseLimit == 0 { exD.append("no measurable agent exposure") }
    if f0.needlessInjectors > 0 { ex -= 0.2; exD.append("\(f0.needlessInjectors) autoinjector(s) used without indication") }
    gr.rows.append(("PERSONAL EXPOSURE", clamp(ex, 0, 1), exD.joined(separator: " · ")))

    // 5. Casualty care
    var vs = 0.0
    var vD: [String] = []
    if f0.victims.isEmpty { vs = 1; vD.append("no casualties on scene") }
    else {
        var right = 0, partial = 0
        for v in f0.victims {
            guard let c = v.choice else { continue }
            if v.best.contains(c) { right += 1 } else if v.ok.contains(c) { partial += 1 }
        }
        let triaged = f0.victims.filter { $0.choice != nil }.count
        vs = (Double(right) + Double(partial) * 0.5) / Double(f0.victims.count)
        vD.append("\(right)/\(f0.victims.count) correct, \(f0.victims.count - triaged) never assessed")
    }
    if f0.litters > 0 {
        let frac = Double(f0.rescued) / Double(f0.litters)
        vs = vs * 0.55 + frac * 0.45
        vD.append("\(f0.rescued)/\(f0.litters) stretcher cases carried out")
    }
    if f0.squadDown > 0 { vs -= Double(f0.squadDown) * 0.25; vD.append("\(f0.squadDown) of your own squad went down") }
    gr.rows.append(("CASUALTY CARE & TRIAGE", clamp(vs, 0, 1), vD.joined(separator: " · ")))

    // 6. Scene work
    var sc = 0.0
    var scD: [String] = []
    let sTot = Double(max(1, f0.surveysTotal)), cTot = Double(max(1, f0.cluesTotal))
    sc += Double(f0.surveysLogged) / sTot * 0.4 + Double(f0.cluesRead) / cTot * 0.3
    scD.append("\(f0.surveysLogged)/\(f0.surveysTotal) readings logged · \(f0.cluesRead)/\(f0.cluesTotal) intel read")
    if f0.tasksTotal > 0 {
        sc += Double(f0.tasksDone) / Double(f0.tasksTotal) * 0.3
        scD.append("\(f0.tasksDone)/\(f0.tasksTotal) field tasks completed")
    } else { sc += 0.3 }
    gr.rows.append(("SCENE DOCUMENTATION", clamp(sc, 0, 1), scD.joined(separator: " · ")))

    // 7. Decon
    var dsc = dec?.score ?? 0
    var dD: [String] = []
    if let d = dec {
        dD.append(d.errors.isEmpty ? "no decon errors" : "\(d.errors.count) decon error(s)")
        if let l = lab, l.contamination > 0 { dsc -= 0.1; dD.append("\(l.contamination) sample(s) opened outside containment") }
    }
    if f0.gloveChanges > 0 { dD.append("\(f0.gloveChanges) glove change(s) in the hot zone") }
    gr.rows.append(("DECONTAMINATION", clamp(dsc, 0, 1), dD.joined(separator: " · ")))

    let weights = [0.22, 0.16, 0.14, 0.14, 0.14, 0.08, 0.12]
    var tot = 0.0
    for (i, r) in gr.rows.enumerated() { tot += r.1 * weights[i] }
    if f0.extracted { tot *= 0.6 }
    gr.total = clamp(tot, 0, 1)
    let p = gr.total * 100
    gr.letter = p >= 93 ? "A" : p >= 85 ? "A-" : p >= 78 ? "B+" : p >= 70 ? "B" : p >= 62 ? "C+" : p >= 54 ? "C" : p >= 45 ? "D" : "F"
    if f0.extracted {
        gr.outcome = "MISSION FAILED — TEAM EXTRACTED. " + (f0.incidents.first { $0.hasPrefix("EXTRACTED") }?.replacingOccurrences(of: "EXTRACTED: ", with: "") ?? "")
    } else if !enough || (lab?.idScore ?? 0) < 0.5 {
        gr.outcome = "MISSION INCOMPLETE — the agent was not reliably identified, so the public-health response had to proceed on guesswork."
    } else if f0.litters > 0 && f0.rescued < f0.litters {
        gr.outcome = "MISSION PARTIAL — \(f0.litters - f0.rescued) non-ambulatory casualt\(f0.litters - f0.rescued == 1 ? "y was" : "ies were") left inside the hot zone when the team withdrew."
    } else if lab?.threatCorrect == true && lab?.protocolCorrect == true && gr.total > 0.78 {
        gr.outcome = "MISSION SUCCESS — agent identified, cause correctly classified, correct protocol recommended, team out clean."
    } else {
        gr.outcome = "MISSION PARTIAL — the identification held up, but the response recommendation or the team's own safety fell short."
    }
    return gr
}

final class ReportScene: Scene {
    let run: MissionRun
    let gr: Grade
    var t = 0.0
    var page = 0
    var menu = OptionList(["Next mission (assignments)", "Review the real history", "Return to terminal"])
    var guide = GuideOverlay()

    init(_ r: MissionRun) {
        run = r
        gr = gradeRun(r)
        var st = Game.shared.state
        let prev = st.completed[r.def.id]
        let order = ["F", "D", "C", "C+", "B", "B+", "A-", "A"]
        if prev == nil || (order.firstIndex(of: gr.letter) ?? 0) > (order.firstIndex(of: prev!) ?? 0) {
            st.completed[r.def.id] = gr.letter
        }
        if st.completed.count >= 2 { st.replayUnlocked = true }
        st.save(); Game.shared.state = st
        Audio.shared.reset(); Audio.shared.hum = 0.25
        Audio.shared.blip(500, 0.2, 0.08)
    }

    func update(_ dt: Double) { t += dt }

    func draw(_ g: G) {
        header(g, "AFTER-ACTION REPORT", "\(run.def.op) // \(run.def.year) // \(run.def.title)")
        if page == 1 { drawHistory(g); guide.draw(g); return }

        // score block
        g.panel(R(40, 90, 330, 300), title: "OVERALL")
        let shownPct = min(gr.total, t * 0.6) * 100
        g.text(gr.letter, 205, 130, 86, gr.total > 0.7 ? Pal.green : (gr.total > 0.5 ? Pal.amber : Pal.red), bold: true, align: .center)
        g.text("\(Int(shownPct))%", 205, 240, 28, Pal.amber, bold: true, align: .center)
        g.bar(R(60, 288, 290, 12), shownPct / 100, gr.total > 0.7 ? Pal.green : Pal.amber)
        g.para(run.field.extracted ? "EMERGENCY EXTRACTION" : "TEAM OUT UNDER OWN POWER", 60, 316, w: 290, size: 12,
               color: run.field.extracted ? Pal.red : Pal.green, bold: true)
        let best = Game.shared.state.completed[run.def.id] ?? "-"
        g.text("BEST ON FILE: \(best)", 60, 352, 12, Pal.greenDim)

        // breakdown
        g.panel(R(390, 90, 830, 300), title: "BREAKDOWN")
        var y: CGFloat = 114
        for (i, r) in gr.rows.enumerated() {
            guard t > Double(i) * 0.22 else { continue }
            let c: NSColor = r.1 > 0.75 ? Pal.green : (r.1 > 0.5 ? Pal.amber : Pal.red)
            g.text(r.0, 408, y, 12, Pal.greenDim, bold: true)
            g.bar(R(640, y + 1, 180, 10), r.1, c)
            g.text("\(Int(r.1 * 100))%", 844, y, 12, c, bold: true)
            let h = g.para(r.2, 890, y - 1, w: 318, size: 11, color: Pal.green, lineH: 14)
            y += max(24, h + 8)
        }

        // outcome + incidents
        g.panel(R(40, 410, 580, 330), title: "OUTCOME")
        var oy: CGFloat = 438
        oy += g.para(gr.outcome, 60, oy, w: 540, size: 14, color: gr.total > 0.7 ? Pal.green : Pal.amber, bold: true) + 12
        if !run.field.incidents.isEmpty {
            g.text("SAFETY INCIDENTS", 60, oy, 12, Pal.red, bold: true); oy += 18
            for inc in run.field.incidents.prefix(6) {
                oy += g.para("⚠ " + inc.replacingOccurrences(of: "EXTRACTED: ", with: ""), 60, oy, w: 540, size: 12, color: Pal.red) + 3
            }
        } else { g.text("No safety incidents logged.", 60, oy, 13, Pal.green); oy += 20 }
        if let d = run.decon, !d.errors.isEmpty {
            oy += 6
            g.text("DECON FINDINGS", 60, oy, 12, Pal.amber, bold: true); oy += 18
            for e in d.errors.prefix(3) { oy += g.para("• " + e, 60, oy, w: 540, size: 12, color: Pal.amber) + 3 }
        }

        // lab findings — the classification block is pinned to the bottom, samples fill what's left
        let lp = R(640, 410, 580, 320)
        g.panel(lp, title: "LABORATORY FINDINGS")
        if let lab = run.lab {
            let footTop = lp.maxY - (lab.protocolCorrect ? 74 : 92)
            var ly: CGFloat = 436
            for l in lab.lines {
                if ly > footTop - 46 {
                    g.text("… \(lab.lines.count) samples in total", 682, ly, 11, Pal.greenDim)
                    break
                }
                g.text(l.1 ? "✓" : "✗", 660, ly, 13, l.1 ? Pal.green : Pal.red, bold: true)
                ly += g.para(l.0, 682, ly, w: 520, size: 12, color: Pal.white, lineH: 15) + 1
                ly += g.para(l.2, 682, ly, w: 520, size: 11, color: l.1 ? Pal.greenDim : Pal.red, lineH: 14) + 6
            }
            var fy = footTop
            g.line(P(lp.minX + 12, fy - 8), P(lp.maxX - 12, fy - 8), Pal.green.a(0.25))
            g.text("CALLED IT:  " + lab.threat.label, 660, fy, 11, lab.threatCorrect ? Pal.green : Pal.red, bold: true); fy += 16
            g.text("ACTUALLY:   " + run.def.threat(run.variant).label, 660, fy, 11, Pal.amber); fy += 16
            fy += g.para("PROTOCOL: " + run.def.protocols[lab.protoChoice], 660, fy, w: 548, size: 11,
                         color: lab.protocolCorrect ? Pal.green : Pal.red, lineH: 14)
            if !lab.protocolCorrect {
                let b = run.def.bestProtocol(run.variant).first ?? 0
                g.para("SHOULD HAVE BEEN: " + run.def.protocols[b], 660, fy + 2, w: 548, size: 11, color: Pal.amber, lineH: 14)
            }
        } else { g.text("No laboratory work completed.", 660, 436, 13, Pal.red) }

        if t > 1.6 {
            g.fill(R(0, H - 44, W, 44), Pal.panel)
            g.hazardStripes(R(0, H - 46, W, 3), Pal.amber, Pal.black, step: 18)
            var mx: CGFloat = 24
            for (i, item) in menu.items.enumerated() {
                let label = "[\(i + 1)] " + item
                let w = CGFloat(label.count) * G.charW(14, true) + 26
                let r = R(mx, H - 38, w, 28)
                menu.rects.count > i ? (menu.rects[i] = r) : menu.rects.append(r)
                if i == menu.sel { g.fill(r, Pal.amber.a(0.2)); g.stroke(r, Pal.amber, 1) }
                g.text(label, mx + 13, H - 31, 14, i == menu.sel ? Pal.amber : Pal.green, bold: i == menu.sel)
                mx += w + 12
            }
        }
        guide.draw(g)
    }

    private func drawHistory(_ g: G) {
        g.panel(R(80, 100, 1120, 580), title: "WHAT ACTUALLY HAPPENED")
        g.text(run.def.year + " — " + run.def.title, 110, 130, 24, Pal.amber, bold: true)
        g.text(run.def.location, 110, 166, 14, Pal.greenDim)
        var y: CGFloat = 206
        y += g.para(run.def.history(run.variant), 110, y, w: 1060, size: 16, color: Pal.white, lineH: 25) + 26
        let actual = run.def.threat(run.variant)
        g.text("CLASSIFICATION: " + actual.label, 110, y, 15, Pal.amber, bold: true); y += 34
        if let lab = run.lab {
            let truth = Set(run.field.samples.flatMap { $0.contents }).subtracting(["CLEAN", "NONE"])
            if let first = truth.sorted().first {
                let a = agent(first)
                g.text("AGENT: " + a.name, 110, y, 14, Pal.cyan, bold: true); y += 24
                y += g.para("SIGNS: " + a.signs, 110, y, w: 1060, size: 13, color: Pal.green) + 8
                y += g.para("COUNTERMEASURE: " + a.treat, 110, y, w: 1060, size: 13, color: Pal.green) + 8
                y += g.para("DECON: " + a.decon, 110, y, w: 1060, size: 13, color: Pal.green) + 8
            }
            _ = lab
        }
        g.para("This is a training simulation. Details are simplified and compressed for play. Nothing here is operational guidance: it points at the public record and at published responder doctrine.",
               110, 640, w: 1060, size: 12, color: Pal.greenDim)
        footer(g, "[ENTER/ESC] back to the report")
    }

    func keyDown(_ k: String) {
        if guide.key(k) { return }
        if k == "f" { guide.show(3); return }
        if page == 1 { if ["enter", "esc", "space", "2"].contains(k) { page = 0 }; return }
        if let i = menu.key(k) { pick(i) }
    }
    func mouseMoved(_ p: CGPoint) { if page == 0 { menu.hover(p) }; guide.mouseMoved(p) }
    func mouseDown(_ p: CGPoint) {
        if page == 1 { page = 0; return }
        if let i = menu.click(p) { pick(i) }
    }
    private func pick(_ i: Int) {
        switch i {
        case 0: Game.shared.go(MissionSelectScene(replay: Game.shared.state.replayUnlocked))
        case 1: page = 1
        default: Game.shared.go(TitleScene())
        }
    }
}

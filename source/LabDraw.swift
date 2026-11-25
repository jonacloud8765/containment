// CONTAINMENT — Part 3 rendering: transport cutscene, HPGe spectrum display, wet-chem / bio bench.

import AppKit

let specRect = R(430, 150, 790, 330)

extension LabScene {

    func draw(_ g: G) {
        switch phase {
        case 0: drawTransport(g)
        case 1: drawBench(g)
        case 2: drawThreat(g)
        default: drawProtocol(g)
        }
        guide.draw(g)
    }

    // MARK: Transport cutscene

    private func drawTransport(_ g: G) {
        header(g, "PART 3 // SAMPLE TRANSPORT", "CHAIN OF CUSTODY")
        // road scrolling past
        g.fill(R(0, 430, W, 370), rgba(0.07, 0.08, 0.08))
        for i in 0..<28 {
            let x = (CGFloat(i) * 90 - CGFloat(t * 320).truncatingRemainder(dividingBy: 90)).truncatingRemainder(dividingBy: W + 90)
            g.fill(R(x, 600, 50, 6), Pal.amber.a(0.5))
        }
        g.fill(R(0, 80, W, 350), rgba(0.03, 0.04, 0.05))
        for i in 0..<40 {
            let x = CGFloat((i * 137) % 1280), hh = CGFloat(40 + (i * 53) % 150)
            g.fill(R(x, 430 - hh, 60, hh), rgba(0.05, 0.06, 0.07))
        }
        // the lab truck
        let bob = CGFloat(sin(t * 7) * 2)
        let bx: CGFloat = 330
        g.roundRect(R(bx, 430 + bob, 480, 150), 10, rgba(0.88, 0.88, 0.85))
        g.roundRect(R(bx + 480, 470 + bob, 130, 110), 10, rgba(0.80, 0.80, 0.78))
        g.fill(R(bx + 500, 490 + bob, 90, 50), Pal.cyan.a(0.4))
        g.hazardStripes(R(bx, 560 + bob, 480, 18), Pal.amber, Pal.black, step: 20)
        g.text("FORWARD MOBILE LABORATORY", bx + 24, 460 + bob, 15, Pal.black, bold: true)
        g.text(run.def.division == .nuclear ? "RADIOANALYTICAL // HPGe" : "CBRN ANALYTICAL // GC-MS / BSL-3", bx + 24, 484 + bob, 12, Pal.dark)
        trefoil(g, P(bx + 400, 520 + bob), 26, run.def.division == .nuclear ? Pal.black : Pal.dark)
        g.circle(P(bx + 110, 592 + bob), 26, Pal.dark); g.circle(P(bx + 110, 592 + bob), 12, Pal.grey)
        g.circle(P(bx + 420, 592 + bob), 26, Pal.dark); g.circle(P(bx + 420, 592 + bob), 12, Pal.grey)
        if Int(t * 3) % 2 == 0 { g.circle(P(bx + 600, 486 + bob), 7, Pal.red) }

        g.panel(R(60, 100, 1160, 300), title: "CHAIN OF CUSTODY LOG")
        var y: CGFloat = 128
        if samples.isEmpty {
            g.text("NO SAMPLES SUBMITTED. Lab identification will not be possible.", 80, y, 16, Pal.red, bold: true)
        }
        for (i, s) in samples.enumerated() where i < 7 {
            let typed = Int(max(0, (t - 0.5 - Double(i) * 0.45) * 60))
            let line = "#\(i + 1)  \(s.kind.rawValue.padding(toLength: 16, withPad: " ", startingAt: 0)) \(s.label)"
            g.text(String(line.prefix(typed)), 80, y, 14, Pal.green)
            if typed > line.count {
                g.text(s.cross ? "SEAL OK · CROSS-CONTAM RISK" : "SEAL OK · INTACT", 1200, y, 12, s.cross ? Pal.red : Pal.greenDim, align: .right)
            }
            y += 22
        }
        if t > 4 {
            g.text(run.def.division == .nuclear
                   ? "Samples into the shielded HPGe well. Counting now."
                   : (bioMode ? "Samples into the Class II biosafety cabinet. Gloves changed between each." : "Samples into the fume hood. GC-MS warming up."),
                   80, 370, 14, Pal.amber, bold: true)
        }
        footer(g, "[ENTER] skip to the bench")
    }

    // MARK: Bench

    private func drawBench(_ g: G) {
        header(g, "PART 3 // FORWARD LAB", "LAB CLOCK +\(Int(labMin)) min   //   \(run.def.op)")
        // sample rack
        g.panel(R(40, 90, 370, 540), title: "SAMPLE RACK")
        var y: CGFloat = 116
        for (i, s) in samples.enumerated() {
            let r = R(52, y - 4, 346, 54)
            if i == sel { g.fill(r, Pal.amber.a(0.15)); g.fill(R(r.minX, r.minY, 4, r.height), Pal.amber) }
            g.text("#\(i + 1) [\(s.kind.rawValue)]", 66, y, 11, i == sel ? Pal.amber : Pal.greenDim, bold: true)
            g.para(s.label, 66, y + 15, w: 320, size: 12, color: i == sel ? Pal.white : Pal.green)
            let done = !chosen[i].isEmpty
            g.text(done ? "✓ ID" : "—", 392, y, 12, done ? Pal.green : Pal.grey, align: .right)
            if done { g.text(chosen[i].map { agent($0).id }.sorted().joined(separator: "+"), 392, y + 16, 11, Pal.green, align: .right) }
            y += 58
        }
        g.para(note, 52, 596, w: 346, size: 12, color: Pal.amber)

        if radMode { drawSpectro(g) } else { drawWetBench(g) }

        if var pk = picker {
            g.fill(R(0, 0, W, H), Pal.black.a(0.6))
            g.panel(R(340, 160, 600, 460), title: "ASSIGN IDENTIFICATION")
            g.para("Sample #\(sel + 1): \(samples[sel].label)", 360, 190, w: 560, size: 14, color: Pal.white)
            pk.draw(g, x: 356, y: 230, w: 568, size: 15, gap: 4)
            picker = pk
            g.text("[ESC] cancel", 360, 596, 12, Pal.greenDim)
        }
        let ready = samples.allSatisfy { _ in true }
        footer(g, radMode
               ? "[↑↓] sample  [←→] cursor (+SHIFT fast)  [M] mark peak  [T] recount later  [1-\(candidates.count)] toggle nuclide  [ENTER] confirm  [X] submit  [F] guide"
               : "[↑↓] sample  [1-\(tests.count)] run test  [B] \(bioMode ? "biosafety cabinet" : "fume hood") \(hood ? "ON" : "OFF")  [I] assign ID  [X] submit  [F] guide")
        _ = ready
    }

    // MARK: Gamma spectroscopy

    private func drawSpectro(_ g: G) {
        let s = samples[sel]
        g.panel(R(430, 90, 790, 440), title: "HPGe GAMMA SPECTRUM // \(s.kind.rawValue) #\(sel + 1)")
        let sp = spectrum(sel)
        let r = specRect
        g.fill(r, rgba(0.01, 0.02, 0.02))
        // log grid
        for d in 0...4 {
            let yy = r.maxY - CGFloat(d) * r.height / 4
            g.line(P(r.minX, yy), P(r.maxX, yy), Pal.green.a(0.12))
            g.text("1e\(d)", r.minX - 6, yy - 6, 10, Pal.greenDim, align: .right)
        }
        for e in stride(from: 0, through: 3000, by: 250) {
            let x = r.minX + CGFloat(e) / 3000 * r.width
            g.line(P(x, r.minY), P(x, r.maxY), Pal.green.a(0.10))
            g.text("\(e)", x, r.maxY + 6, 10, Pal.greenDim, align: .center)
        }
        g.text("keV", r.maxX, r.maxY + 20, 10, Pal.greenDim, align: .right)
        // trace
        var prev = P(r.minX, r.maxY)
        for b in 0..<1000 {
            let x = r.minX + CGFloat(b) / 1000 * r.width
            let v = max(1.0, sp[b])
            let yy = r.maxY - CGFloat(min(1, log10(v) / 4)) * r.height
            let p = P(x, yy)
            if b > 0 { g.line(prev, p, Pal.green.a(0.95), 1.2) }
            prev = p
        }
        // marked peaks
        for e in marks[sel] {
            let x = r.minX + CGFloat(e) / 3000 * r.width
            g.line(P(x, r.minY), P(x, r.maxY), Pal.cyan.a(0.55), 1)
            g.text(f(e, 1), x, r.minY - 14, 10, Pal.cyan, align: .center)
        }
        // cursor
        let cx = r.minX + CGFloat(cursor) / 3000 * r.width
        g.line(P(cx, r.minY), P(cx, r.maxY), Pal.amber, 1.5)
        let bin = Int(cursor / 3)
        g.text("\(f(cursor, 1)) keV   \(Int(sp[min(999, bin)])) counts", cx + 6, r.minY + 6, 12, Pal.amber, bold: true)
        // decay state
        g.text("COUNT TIME: " + (step[sel] == 0 ? "t0 (reference)" : "t0 + " + fmtHours(decaySteps[step[sel]])), r.minX, r.minY - 36, 13, Pal.amber, bold: true)
        g.text("[T] recount later: short-lived peaks fade, long-lived stay", r.maxX, r.minY - 34, 11, Pal.greenDim, align: .right)

        // library + selection
        g.panel(R(430, 550, 790, 190), title: "NUCLIDE LIBRARY  //  MARKED: " + (marks[sel].isEmpty ? "none" : marks[sel].map { f($0, 1) }.joined(separator: ", ")))
        var yy: CGFloat = 574
        var xx: CGFloat = 444
        for (i, id) in candidates.enumerated() {
            let a = agent(id)
            let on = chosen[sel].contains(id)
            let lines = a.gammaKeV.isEmpty ? "—" : a.gammaKeV.map { f($0, 1) }.joined(separator: " · ")
            let hit = !marks[sel].isEmpty && a.gammaKeV.contains { e in marks[sel].contains { abs($0 - e) < 5 } }
            let box = R(xx, yy - 2, 380, 20)
            if on { g.fill(box, Pal.amber.a(0.2)) }
            g.text("[\(i + 1)]", xx, yy, 11, on ? Pal.amber : Pal.greenDim, bold: true)
            g.text(a.id, xx + 30, yy, 11, on ? Pal.amber : (hit ? Pal.cyan : Pal.green), bold: hit)
            g.text(lines, xx + 100, yy, 11, hit ? Pal.cyan : Pal.greenDim)
            g.text(a.halfLifeText, xx + 300, yy, 11, Pal.greenDim)
            yy += 20
            if yy > 716 { yy = 574; xx += 390 }
        }
    }

    // MARK: Wet chemistry / microbiology bench

    private func drawWetBench(_ g: G) {
        let s = samples[sel]
        g.panel(R(430, 90, 790, 300), title: (bioMode ? "BIOSAFETY CABINET" : "FUME HOOD") + " // " + (hood ? "SASH DOWN, AIRFLOW OK" : "⚠ OPEN BENCH"), color: hood ? Pal.green : Pal.red)
        // cabinet art
        let box = R(455, 120, 740, 250)
        g.fill(box, rgba(0.05, 0.07, 0.07))
        g.stroke(box, hood ? Pal.green.a(0.6) : Pal.red.a(0.7), 2)
        if hood {
            g.fill(R(box.minX, box.minY, box.width, 36), Pal.cyan.a(0.10))
            for i in 0..<16 {
                let x = box.minX + 20 + CGFloat(i) * 45
                let ph = CGFloat(sin(t * 3 + Double(i)) * 6)
                g.line(P(x, box.minY + 6), P(x, box.minY + 30 + ph), Pal.cyan.a(0.35), 1)
            }
            g.text("HEPA ↓ LAMINAR FLOW", box.midX, box.minY + 10, 11, Pal.cyan, align: .center)
        } else {
            g.text("⚠ VAPOR / AEROSOL ESCAPING TO THE ROOM  [B] CLOSE THE SASH", box.midX, box.minY + 12, 13, Pal.red, bold: true, align: .center)
        }
        // sample vessel
        let vc = P(box.minX + 90, box.midY + 40)
        g.roundRect(R(vc.x - 26, vc.y - 60, 52, 90), 6, Pal.white.a(0.14))
        let liq: NSColor = s.kind == .swab || s.kind == .wipe ? Pal.white.a(0.5) : rgba(0.8, 0.75, 0.5, 0.6)
        g.roundRect(R(vc.x - 22, vc.y - 14, 44, 42), 4, liq)
        g.text(s.kind.rawValue, vc.x, vc.y + 40, 11, Pal.green, align: .center)
        // last-test visual
        if let lt = lastTest, let txt = results[sel][lt] {
            let p = P(box.minX + 260, box.midY)
            switch lt {
            case "m8":
                let c: NSColor = txt.contains("Yellow") ? Pal.yellow : (txt.contains("Red") || txt.contains("pink") ? rgba(0.9, 0.3, 0.45) : (txt.contains("green") ? rgba(0.15, 0.45, 0.2) : Pal.white.a(0.75)))
                g.roundRect(R(p.x - 40, p.y - 50, 80, 100), 4, Pal.white.a(0.8)); g.roundRect(R(p.x - 30, p.y - 30, 60, 60), 4, c)
                g.text("M8 PAPER", p.x, p.y + 56, 11, Pal.green, align: .center)
            case "enzyme":
                let blue = txt.contains("INHIB") ? Pal.white.a(0.7) : rgba(0.2, 0.35, 0.95)
                g.roundRect(R(p.x - 50, p.y - 26, 100, 52), 6, Pal.white.a(0.2)); g.roundRect(R(p.x - 40, p.y - 16, 80, 32), 4, blue)
                g.text("ChE TICKET", p.x, p.y + 34, 11, Pal.green, align: .center)
            case "pH":
                let acid = txt.contains("acid"), alk = txt.contains("lkaline")
                let c: NSColor = acid ? rgba(0.9, 0.25, 0.2) : (alk ? rgba(0.2, 0.4, 0.9) : rgba(0.3, 0.75, 0.35))
                g.roundRect(R(p.x - 12, p.y - 60, 24, 120), 3, c)
                g.text("pH STRIP", p.x, p.y + 66, 11, Pal.green, align: .center)
            case "alkaloid":
                let pos = txt.contains("POSITIVE")
                g.roundRect(R(p.x - 30, p.y - 50, 60, 100), 20, Pal.white.a(0.15))
                g.roundRect(R(p.x - 24, p.y - 10, 48, 54), 14, pos ? rgba(0.95, 0.45, 0.1, 0.9) : rgba(0.7, 0.65, 0.3, 0.35))
                if pos { for i in 0..<8 { g.circle(P(p.x - 16 + CGFloat(i % 4) * 10, p.y + 30 + CGFloat(i / 4) * 8), 3, rgba(0.9, 0.3, 0.05)) } }
                g.text("DRAGENDORFF", p.x, p.y + 56, 11, Pal.green, align: .center)
            case "iodine":
                let pos = txt.contains("BLUE")
                g.roundRect(R(p.x - 44, p.y - 30, 88, 60), 6, pos ? rgba(0.1, 0.1, 0.35) : rgba(0.55, 0.45, 0.15, 0.5))
                g.text("IODINE / STARCH", p.x, p.y + 38, 11, Pal.green, align: .center)
            case "gram", "spore":
                g.circle(p, 54, Pal.white.a(0.08)); g.ring(p, 54, Pal.green.a(0.5), 1.5)
                let rods = txt.contains("rods")
                var seed = UInt32(sel &* 7919 &+ 3)
                func rnd() -> CGFloat { seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5; return CGFloat(seed % 1000) / 1000 }
                for _ in 0..<26 {
                    let a = rnd() * 6.28, rr = rnd() * 46
                    let q = p + P(cos(a) * rr, sin(a) * rr)
                    if rods {
                        g.save(); g.ctx.translateBy(x: q.x, y: q.y); g.ctx.rotate(by: rnd() * 3.14)
                        g.roundRect(R(-7, -2.5, 14, 5), 2, lt == "spore" ? rgba(0.3, 0.7, 0.95) : rgba(0.45, 0.25, 0.65))
                        if lt == "spore" { g.circle(.zero, 2.4, rgba(0.95, 0.35, 0.3)) }
                        g.restore()
                    } else { g.circle(q, 2 + rnd() * 2, Pal.white.a(0.3)) }
                }
                g.text(lt == "spore" ? "SPORE STAIN 1000×" : "GRAM STAIN 1000×", p.x, p.y + 62, 11, Pal.green, align: .center)
            case "gcms", "tube", "ims", "pcr", "hha", "culture":
                if lt == "gcms" {
                    let rr = R(p.x - 110, p.y - 54, 300, 110)
                    g.fill(rr, rgba(0.01, 0.03, 0.02)); g.stroke(rr, Pal.green.a(0.4))
                    var prev = P(rr.minX, rr.maxY - 4)
                    let known = !txt.contains("No significant")
                    for i in 0..<120 {
                        let x = rr.minX + CGFloat(i) / 120 * rr.width
                        var v = 0.03 + 0.02 * sin(Double(i) * 1.7)
                        if known { for (c, h) in [(34, 0.92), (58, 0.3), (82, 0.14)] { let z = Double(i - c) / 2.2; v += h * exp(-z * z) } }
                        if txt.contains("trace") { let z = Double(i - 96) / 2.0; v += 0.22 * exp(-z * z) }
                        let q = P(x, rr.maxY - 4 - CGFloat(v) * (rr.height - 12))
                        g.line(prev, q, Pal.cyan, 1.2); prev = q
                    }
                    g.text("TIC / MASS SPECTRUM", rr.midX, rr.maxY + 6, 11, Pal.green, align: .center)
                } else if lt == "pcr" {
                    let rr = R(p.x - 110, p.y - 54, 300, 110)
                    g.fill(rr, rgba(0.01, 0.03, 0.02)); g.stroke(rr, Pal.green.a(0.4))
                    let det = txt.contains("DETECTED")
                    let weak = txt.contains("WEAK")
                    for (k, col) in [(0, Pal.cyan), (1, Pal.amber), (2, Pal.green)] {
                        var prev = P(rr.minX, rr.maxY - 6)
                        for i in 0..<120 {
                            let x = rr.minX + CGFloat(i) / 120 * rr.width
                            let ct = weak ? 95.0 : 60.0 + Double(k) * 6
                            let v = det || weak ? 1 / (1 + exp(-(Double(i) - ct) / 6)) * (weak ? 0.45 : 0.9) : 0.02
                            let q = P(x, rr.maxY - 6 - CGFloat(v) * (rr.height - 14))
                            g.line(prev, q, col, 1.2); prev = q
                        }
                    }
                    g.text("REAL-TIME PCR AMPLIFICATION", rr.midX, rr.maxY + 6, 11, Pal.green, align: .center)
                } else if lt == "hha" {
                    g.roundRect(R(p.x - 70, p.y - 24, 160, 48), 6, Pal.white.a(0.85))
                    g.fill(R(p.x - 30, p.y - 16, 8, 32), Pal.red.a(0.9))                      // control line
                    let pos = txt.contains("POSITIVE") || txt.contains("cross") || txt.contains("Faint")
                    if pos { g.fill(R(p.x + 20, p.y - 16, 8, 32), Pal.red.a(txt.contains("Faint") ? 0.35 : 0.85)) }
                    g.text("C        T", p.x - 4, p.y + 28, 11, Pal.dark, align: .center)
                    g.text("IMMUNOASSAY", p.x + 10, p.y + 44, 11, Pal.green, align: .center)
                } else if lt == "culture" {
                    g.circle(p, 56, rgba(0.85, 0.80, 0.62, 0.85)); g.ring(p, 56, Pal.greenDim, 1.5)
                    if !txt.contains("No growth") && !txt.contains("No significant") {
                        let few = txt.contains("Two colonies")
                        for i in 0..<(few ? 2 : 14) {
                            let a = Double(i) * 2.3, rr = Double((i * 37) % 40)
                            g.circle(p + P(cos(a) * rr, sin(a) * rr), few ? 5 : 4,
                                     txt.contains("hemolytic") ? rgba(0.7, 0.75, 0.7) : rgba(0.78, 0.78, 0.74))
                        }
                    }
                    g.text("BLOOD AGAR 18 h", p.x, p.y + 64, 11, Pal.green, align: .center)
                } else {
                    let pos = txt.contains("POSITIVE") || txt.contains("alarm")
                    g.roundRect(R(p.x - 14, p.y - 60, 28, 120), 4, Pal.white.a(0.2))
                    g.roundRect(R(p.x - 10, p.y - 10 - (pos ? 40 : 0), 20, 66 + (pos ? 40 : 0)), 3, pos ? rgba(0.95, 0.75, 0.1) : Pal.white.a(0.3))
                    g.text(lt == "tube" ? "COLOR TUBE" : "IMS", p.x, p.y + 66, 11, Pal.green, align: .center)
                }
            default: break
            }
        }
        if busy != nil {
            g.text("RUNNING…", box.maxX - 20, box.minY + 12, 13, Pal.amber, bold: true, align: .right)
        }
        // test menu + results
        g.panel(R(430, 408, 380, 332), title: "TEST BENCH")
        var y: CGFloat = 434
        for (i, t) in tests.enumerated() {
            let done = results[sel][t.key] != nil
            g.text("[\(i + 1)] \(t.name)", 446, y, 13, done ? Pal.greenDim : Pal.green, bold: !done)
            g.text("\(Int(t.minutes)) min", 794, y, 11, Pal.greenDim, align: .right)
            y += 22
        }
        g.para("[B] toggle \(bioMode ? "biosafety cabinet" : "fume hood")   [I] assign identification   [X] submit report",
               446, y + 10, w: 350, size: 12, color: Pal.amber)
        g.panel(R(830, 408, 390, 332), title: "RESULTS // SAMPLE #\(sel + 1)")
        y = 434
        if results[sel].isEmpty { g.text("No tests run on this sample.", 846, y, 12, Pal.greenDim) }
        for t in tests {
            guard let r = results[sel][t.key] else { continue }
            g.text(t.name.uppercased(), 846, y, 11, Pal.amber, bold: true); y += 15
            y += g.para(r, 846, y, w: 360, size: 12, color: Pal.green, lineH: 15) + 7
            if y > 710 { break }
        }
    }

    // MARK: Threat + protocol

    private func drawThreat(_ g: G) {
        header(g, "PART 3 // ANALYTICAL CONCLUSION", "LAB CLOCK +\(Int(labMin)) min")
        g.panel(R(60, 100, 560, 560), title: "FINDINGS")
        var y: CGFloat = 128
        for (i, s) in samples.enumerated() {
            g.text("#\(i + 1) \(s.label)", 80, y, 12, Pal.greenDim); y += 16
            let ids = chosen[i].isEmpty ? "NO IDENTIFICATION" : chosen[i].map { agent($0).name }.sorted().joined(separator: " + ")
            y += g.para("→ " + ids, 92, y, w: 510, size: 13, color: chosen[i].isEmpty ? Pal.red : Pal.amber, bold: true) + 10
        }
        if contamination > 0 {
            y += 10
            g.para("⚠ \(contamination) sample(s) handled outside containment. Analyst exposure and possible cross-contamination logged.", 80, y, w: 520, size: 12, color: Pal.red)
        }
        g.panel(R(650, 100, 570, 560), title: "FINAL THREAT CLASSIFICATION")
        g.para("Your field intelligence said: \(run.initialThreat?.label ?? "—"). With the lab results in hand, classify the incident. This is the call that decides the public response.",
               670, 128, w: 530, size: 13, color: Pal.green)
        threatList.draw(g, x: 666, y: 230, w: 540, size: 14, gap: 10)
        for (i, c) in run.def.briefing(run.variant).enumerated() where c.hasPrefix("##") && i == 0 {
            g.text(String(c.dropFirst(3)), 670, 600, 11, Pal.greenDim)
        }
        footer(g, "[1-5] classify   [ESC] back to the bench   [F] field guide")
    }

    private func drawProtocol(_ g: G) {
        header(g, "PART 3 // RESPONSE PROTOCOL", "LAB CLOCK +\(Int(labMin)) min")
        g.panel(R(60, 100, 1160, 240), title: "SUMMARY")
        var y: CGFloat = 128
        g.text("CLASSIFIED AS: " + threatPick.label, 80, y, 18, Pal.amber, bold: true); y += 34
        let ids = (0..<samples.count).flatMap { chosen[$0] }
        let uniq = Array(Set(ids)).sorted()
        g.text("AGENTS IDENTIFIED: " + (uniq.isEmpty ? "none" : uniq.map { agent($0).name }.joined(separator: ", ")), 80, y, 14, Pal.green); y += 26
        if let first = uniq.first(where: { $0 != "NONE" && $0 != "CLEAN" && $0 != "K40" }) {
            let a = agent(first)
            y += g.para("COUNTERMEASURE ON FILE: " + a.treat, 80, y, w: 1120, size: 13, color: Pal.cyan) + 8
        }
        g.panel(R(60, 360, 1160, 350), title: "SELECT THE RESPONSE PROTOCOL TO RECOMMEND")
        protoList.draw(g, x: 76, y: 390, w: 1130, size: 14, gap: 8)
        footer(g, "[1-\(run.def.protocols.count)] recommend   [ESC] back   [F] field guide")
    }
}

// CONTAINMENT — Part 4: decontamination corridor (solution choice + doffing order) and after-action report.

import AppKit

struct Station {
    let name: String
    let prompt: String
    let options: [String]
    let best: Set<Int>
    let ok: Set<Int>
    let why: String
    var pick: Int? = nil
}

/// Correct doffing order depends on where the respirator sits: the mask comes off LAST,
/// so an encapsulated suit (SCBA inside) is unzipped and stepped out of first.
func doffSteps(_ lo: Loadout) -> [String] {
    if lo.suit.encapsulated {
        return ["Have the attendant unzip the suit from behind", "Step out of the suit, rolling it outside-in, without touching the outer surface",
                "Remove boots and outer gloves", "Remove the SCBA harness and cylinder", "Remove the facepiece LAST, then inner gloves",
                "Step across the hot line and shower"]
    }
    if lo.resp == .scba {
        return ["Remove outer boots and outer gloves", "Have the attendant unzip and peel the splash suit outside-in",
                "Remove the SCBA harness and cylinder, keeping the facepiece ON", "Remove the facepiece, then inner gloves",
                "Step across the hot line and shower"]
    }
    return ["Remove outer boots and outer gloves", "Have the attendant peel the garment outside-in, keeping the mask ON",
            lo.resp == .papr ? "Remove the PAPR blower and belt, keeping the facepiece on" : "Remove the canister",
            "Remove the mask, then inner gloves", "Step across the hot line and shower"]
}

/// The seven posts on a mass-decon truck. Each has one correct person for it.
struct DeconPost {
    let title: String
    let duty: String
    let candidates: [String]
    let best: Int
    let why: String
    var pick: Int? = nil
}

func deconPosts() -> [DeconPost] { [
    DeconPost(title: "DECON COMMANDER", duty: "Owns the corridor. Sets the hot line, decides the solution, and is the only person who may release anyone to the cold zone.",
              candidates: ["The most experienced responder on scene, kept out of the line so they can see all of it",
                           "Whoever is already suited and standing closest to the truck",
                           "The driver, since they arrived first",
                           "Nobody — the entry team commander runs it over the radio from inside"],
              best: 0, why: "The corridor needs one person with the whole picture and no task of their own. A supervisor with their hands in a wash tub is not supervising, and the entry commander is busy being contaminated."),
    DeconPost(title: "DRIVER / PUMP OPERATOR", duty: "Positions the truck upwind and uphill, runs the pump, keeps water pressure and temperature steady, watches the tank level.",
              candidates: ["Stays at the pump panel for the whole evolution, upwind of the corridor",
                           "Parks downwind so the spray drifts away from the truck",
                           "Parks, then joins the scrub line to speed things up",
                           "Leaves the engine with a trainee and takes a casualty to hospital"],
              best: 0, why: "Position the apparatus upwind and uphill, then stay on the panel. Pressure loss or scalding water mid-corridor is how people get hurt, and nobody else is watching the tank."),
    DeconPost(title: "LOADER", duty: "Mixes and loads the decon solution to the correct concentration and keeps it coming.",
              candidates: ["Mixes to the ordered concentration, labels the batch, and logs what went in",
                           "Mixes it stronger than ordered — more bleach is more decon",
                           "Uses whatever is already in the tank from the last job",
                           "Adds an acid cleaner to the hypochlorite to cut through residue"],
              best: 0, why: "Concentration is a medical decision, not a preference. Stronger is not safer: it burns skin and destroys suits. Mixing hypochlorite with acid or ammonia makes chlorine gas inside your own corridor."),
    DeconPost(title: "POURER", duty: "Applies solution to the responder at the technical station, top down, without soaking the respirator inlet.",
              candidates: ["Works head to toe, keeping flow away from the facepiece inlet and the SCBA regulator",
                           "Starts at the boots so the dirtiest part is done first",
                           "Aims high pressure straight at the facepiece to clear the visor",
                           "Pours quickly from a bucket over the head"],
              best: 0, why: "Gravity does the work: contamination runs down and off. Driving water into a facepiece inlet or regulator is how you contaminate the one thing keeping the responder alive."),
    DeconPost(title: "SCRUBBER 1 (GROSS)", duty: "Soft-brush scrub at the gross station — knock down the bulk.",
              candidates: ["Soft brush, long strokes, downward, with the runoff captured in the berm",
                           "Stiff wire brush to really get it off",
                           "High-pressure jet at close range",
                           "Dry-brush first so the wet stage has less to do"],
              best: 0, why: "Soft brush, low pressure, downward strokes, runoff contained. Stiff brushes tear suits, high pressure drives contamination into seams, and dry brushing re-aerosolises powder."),
    DeconPost(title: "SCRUBBER 2 (DETAIL)", duty: "Works the places contamination actually hides.",
              candidates: ["Seams, zip flaps, boot welts, glove cuffs, under the SCBA harness and straps",
                           "The front of the suit, since that is what faced the hazard",
                           "Whatever still looks dirty",
                           "Skips the harness — equipment is station three's job"],
              best: 0, why: "Contamination collects in seams, cuffs, welts and under straps. The visibly dirty front is the part everyone already washed twice."),
    DeconPost(title: "HOSE / LINE TENDER", duty: "Manages and rolls the hose, keeps the corridor walkable, and watches for the thing nobody else sees.",
              candidates: ["Keeps lines flat and out of the walking path, and calls a stop if anyone stumbles or a seal looks breached",
                           "Coils the hose at the hot line so it is handy",
                           "Rolls hose only after the evolution so it does not slow anyone down",
                           "Doubles as a runner to carry samples to the lab vehicle"],
              best: 0, why: "A hose across a decon corridor trips exhausted people in suits they cannot see their feet through. The line tender is also the spare set of eyes: calling a stop is part of the post."),
] }

final class DeconScene: Scene {
    let run: MissionRun
    let lo: Loadout
    let cls: DeconClass
    let rule: DeconRule
    var stations: [Station] = []
    var idx = 0
    var opts = OptionList([])
    var phase = 0          // 0 crew/sprayer, 1 stations, 2 doffing, 3 result
    var order: [String]
    var remaining: [Int]
    var picked: [Int] = []
    var orderList = OptionList([], numberKeys: false)
    var errors: [String] = []
    var notes: [String] = []
    var orderErrors = 0
    var t = 0.0
    var showWhy: String? = nil
    var monitorVal = 0.0
    var guide = GuideOverlay()
    var posts = deconPosts()
    var pi = 0
    var postOpts = OptionList([])
    var postErrors = 0
    var confined = false          // small-space entry: backpack sprayer instead of the truck

    init(_ r: MissionRun) {
        run = r
        lo = r.loadout!
        cls = r.def.decon(r.variant)
        rule = deconRule(cls)
        order = doffSteps(lo)
        remaining = Array(0..<order.count)
        monitorVal = r.field.suitContam
        let agentHint = r.lab?.lines.first.map { _ in "" } ?? ""
        _ = agentHint
        stations = [
            Station(name: "STATION 1 // GROSS DECON", prompt: "Low-pressure water or detergent first, to knock down the bulk of the contamination.",
                    options: suitSolutions, best: [0, 1], ok: [], why: "Gross decon is a knock-down step: a low-pressure rinse or detergent wash. Concentrated oxidizers belong at the technical-decon station, never as the first blast."),
            Station(name: "STATION 2 // TECHNICAL DECON (SUIT)", prompt: "The main scrub of the suit, boots and gloves, chosen for THIS agent.",
                    options: suitSolutions, best: rule.suitBest, ok: rule.suitOK, why: rule.why),
            Station(name: "STATION 3 // EQUIPMENT & INSTRUMENTS", prompt: "Meters, sample cases, hand tools and the entry team's air packs.",
                    options: equipSolutions, best: rule.equipBest, ok: rule.equipOK, why: rule.why),
            Station(name: "STATION 4 // VERIFICATION", prompt: "Prove the suit is clean before anyone breaks the seal.",
                    options: verifyMethods, best: rule.verify, ok: [], why: "Verify with an instrument that actually responds to this hazard: a frisker for radioactive particulate, IMS for chemical vapor, swab-and-culture for spores, PID and gas meter for off-gassing."),
        ]
        confined = r.def.confinedDecon
        if confined { posts = [] } else { postOpts = OptionList(posts[0].candidates) }
        loadStation()
        Audio.shared.reset(); Audio.shared.wind = 0.1; Audio.shared.breathRate = 16; Audio.shared.breathGain = 0.5
    }

    private func loadStation() {
        if idx < stations.count { opts = OptionList(stations[idx].options) }
    }

    func update(_ dt: Double) { t += dt }

    // MARK: Input

    func keyDown(_ k: String) {
        if guide.key(k) { return }
        if k == "f" { guide.show(3); return }
        if showWhy != nil { if k == "enter" || k == "space" || k == "esc" { showWhy = nil; if phase == 1 { next() } }; return }
        switch phase {
        case 0:
            if confined { if k == "enter" || k == "space" { phase = 1; Audio.shared.spray(1.6) }; return }
            if let i = postOpts.key(k) { pickPost(i) }
        case 1:
            if let i = opts.key(k) { pickStation(i) }
        case 2:
            if let i = orderList.key(k) { pickOrder(i) }
        default:
            if k == "enter" || k == "space" { Game.shared.go(ReportScene(run)) }
        }
    }
    func mouseMoved(_ p: CGPoint) {
        if phase == 0 { postOpts.hover(p) } else if phase == 1 { opts.hover(p) } else if phase == 2 { orderList.hover(p) }
        guide.mouseMoved(p)
    }
    func mouseDown(_ p: CGPoint) {
        if showWhy != nil { showWhy = nil; if phase == 1 { next() }; return }
        if phase == 0 { if confined { phase = 1 } else if let i = postOpts.click(p) { pickPost(i) }; return }
        if phase == 1, let i = opts.click(p) { pickStation(i) }
        else if phase == 2, let i = orderList.click(p) { pickOrder(i) }
        else if phase == 3 { Game.shared.go(ReportScene(run)) }
    }

    private func pickPost(_ i: Int) {
        posts[pi].pick = i
        let p = posts[pi]
        if i == p.best { Audio.shared.confirm(); notes.append("\(p.title): correct.") }
        else {
            postErrors += 1
            Audio.shared.deny()
            errors.append("\(p.title): \(p.candidates[i])")
            showWhy = p.why
        }
        pi += 1
        if pi < posts.count { postOpts = OptionList(posts[pi].candidates) }
        else { phase = 1; Audio.shared.blip(1200, 0.08) }
    }

    private func pickStation(_ i: Int) {
        stations[idx].pick = i
        let s = stations[idx]
        let good = s.best.contains(i), okay = s.ok.contains(i)
        if good {
            Audio.shared.spray(1.2); Audio.shared.confirm()
            monitorVal *= 0.25
            notes.append("\(s.name): \(s.options[i]) — correct.")
        } else if okay {
            Audio.shared.spray(1.0)
            monitorVal *= 0.5
            notes.append("\(s.name): \(s.options[i]) — acceptable, not ideal.")
        } else {
            Audio.shared.deny()
            monitorVal *= 0.85
            let msg = badReason(i, s)
            errors.append("\(s.name): \(msg)")
            showWhy = msg + "\n\n" + s.why
            return
        }
        next()
    }

    private func badReason(_ i: Int, _ s: Station) -> String {
        let o = s.options[i]
        if o.hasPrefix("Skip") { return "Skipping \(s.name.contains("EQUIPMENT") ? "equipment decon" : "this station") left contamination on the team." }
        if o.contains("STB") && cls == .radParticulate { return "STB on a radiological suit does nothing to the activity and creates mixed hazardous waste." }
        if o.contains("STB") && cls == .hydrocarbon { return "STB is a strong oxidizer. On fuel-soaked gear it risks a reaction or fire." }
        if o.contains("STB") { return "STB (super tropical bleach) is for vehicles, tools and terrain. It's too corrosive for suit seams, visors and skin." }
        if o.contains("hypochlorite") && cls == .toxicGas { return "Hypochlorite products release more chlorine. For a chlorine release, use water and detergent." }
        if o.contains("hypochlorite") && cls == .radParticulate { return "Bleach can't neutralize radioactivity. It only adds chemical waste to the problem." }
        if o.contains("hypochlorite") && (cls == .nicotine || cls == .opioid) { return "Nicotine is water-soluble: soap and water is the answer. Bleach adds hazard for nothing." }
        if o.contains("5%") && cls == .bioSpore { return "5% is unnecessarily harsh here; 0.5% hypochlorite with contact time is the standard for spores." }
        if o.contains("RSDL") { return "RSDL is a skin decon lotion for spot use, not a suit wash-down." }
        if o.contains("Visual") { return "A visual check can't detect an invisible hazard." }
        if o.contains("HEPA") && cls != .radParticulate { return "Dry HEPA/tacky methods are for loose particulate, not for liquid agent or vapor." }
        if o.contains("Frisker") { return "A radiation frisker won't detect a chemical or biological agent." }
        if o.contains("IMS") { return "An IMS chemical detector won't detect radioactive particulate or spores." }
        if o.contains("culture") { return "Culture takes many hours. It can't clear a team at the hot line." }
        if o.contains("water rinse only") { return "A water rinse alone won't remove this hazard from the suit." }
        if o.contains("Soap") || o.contains("detergent") { return "Detergent alone is not enough for this agent at the technical-decon station." }
        return "Wrong solution for this hazard."
    }

    private func next() {
        idx += 1
        if idx < stations.count { loadStation() }
        else if phase == 1 {
            phase = 2
            orderList = OptionList(remaining.map { order[$0] }, numberKeys: false)
            Audio.shared.blip(900, 0.06)
        }
    }

    private func pickOrder(_ i: Int) {
        let step = remaining[i]
        if step == picked.count {
            picked.append(step)
            remaining.remove(at: i)
            Audio.shared.confirm()
            if step == order.count - 1 || remaining.isEmpty { finishDoff() }
            else { orderList = OptionList(remaining.map { order[$0] }, numberKeys: false) }
        } else {
            orderErrors += 1
            Audio.shared.deny()
            let maskStep = order.firstIndex { $0.lowercased().contains("facepiece") || $0.lowercased().contains("mask") } ?? 99
            if step >= maskStep && picked.count < maskStep {
                errors.append("Doffing: removed the respirator before the suit was off. Skin and airways exposed at the dirtiest moment.")
                showWhy = "You broke your respiratory protection while still contaminated. The facepiece ALWAYS comes off last, after the suit and gloves, on the clean side of the hot line."
            } else {
                errors.append("Doffing: step out of order (\(order[step])).")
                showWhy = "Out of order. The correct sequence is outer layers first, respirator last, inner gloves at the very end.\n\nNext correct step: \(order[picked.count])"
            }
            picked.append(step)
            remaining.remove(at: i)
            if remaining.isEmpty { finishDoff() } else { orderList = OptionList(remaining.map { order[$0] }, numberKeys: false) }
        }
    }

    private func finishDoff() {
        phase = 3
        var score = 1.0
        for s in stations {
            guard let p = s.pick else { score -= 0.25; continue }
            if s.best.contains(p) {} else if s.ok.contains(p) { score -= 0.07 } else { score -= 0.2 }
        }
        score -= Double(orderErrors) * 0.18
        score -= Double(postErrors) * 0.06
        if monitorVal > 0.05 {
            notes.append("Final survey still showed residual contamination (\(f(monitorVal * 100, 1))% of entry level).")
            score -= min(0.2, monitorVal)
        } else {
            notes.append("Final survey: at background. Team released from the decon line.")
        }
        if postErrors > 0 { errors.append("Decon crew: \(postErrors) post(s) filled wrongly.") }
        var dr = DeconResult()
        dr.score = clamp(score, 0, 1)
        dr.errors = errors
        dr.notes = notes
        run.decon = dr
        Audio.shared.reset()
        Audio.shared.breathRate = 0
    }

    // MARK: Draw

    func draw(_ g: G) {
        header(g, "PART 4 // DECONTAMINATION", "\(lo.suit.name) // \(lo.resp.short)")
        if phase == 0 { drawSetup(g); if let w = showWhy { drawWhy(g, w) }; guide.draw(g)
            footer(g, confined ? "[ENTER] begin decon" : "[↑↓] select   [ENTER] assign post   [F] field guide"); return }
        drawCorridor(g)
        switch phase {
        case 1:
            let s = stations[idx]
            g.panel(R(40, 400, 760, 340), title: s.name)
            g.para(s.prompt, 60, 428, w: 720, size: 15, color: Pal.white)
            opts.draw(g, x: 56, y: 476, w: 730, size: 14, gap: 6)
        case 2:
            g.panel(R(40, 400, 760, 340), title: "SUIT DOFFING SEQUENCE // PICK THE NEXT STEP")
            g.para("Order matters more than speed. Choose each step in the correct sequence for your ensemble.", 60, 428, w: 720, size: 14, color: Pal.white)
            orderList.draw(g, x: 56, y: 470, w: 730, size: 14, gap: 6)
            var y: CGFloat = 470 + CGFloat(remaining.count) * 34 + 10
            if !picked.isEmpty {
                g.text("DONE: " + picked.map { String($0 + 1) }.joined(separator: " → "), 60, min(y, 710), 12, Pal.greenDim)
                y += 18
            }
        default:
            g.panel(R(40, 400, 760, 340), title: "DECON COMPLETE")
            var y: CGFloat = 430
            g.text("DECON SCORE: \(Int((run.decon?.score ?? 0) * 100))%", 60, y, 22, Pal.amber, bold: true); y += 38
            for n in notes.prefix(5) { y += g.para("• " + n, 60, y, w: 720, size: 13, color: Pal.green) + 4 }
            y += 6
            for e in errors.prefix(4) { y += g.para("⚠ " + e, 60, y, w: 720, size: 13, color: Pal.red) + 4 }
            g.text("[ENTER] after-action report", 60, 706, 14, Pal.amber, bold: true)
        }
        // side monitor
        g.panel(R(820, 400, 400, 340), title: "CONTAMINATION MONITOR")
        let pct = monitorVal * 100
        let clean = monitorVal <= 0.05
        g.text(clean ? "BACKGROUND" : "\(f(pct, 1))% OF ENTRY", 840, 430, 20, clean ? Pal.green : Pal.red, bold: true)
        g.bar(R(840, 462, 360, 14), min(1, monitorVal * 4), clean ? Pal.green : Pal.red)
        var y: CGFloat = 492
        g.text("ENSEMBLE", 840, y, 11, Pal.greenDim, bold: true); y += 18
        y += g.para(lo.suit.name + " / " + lo.resp.name, 840, y, w: 360, size: 12, color: Pal.green) + 10
        g.text("HAZARD CLASS", 840, y, 11, Pal.greenDim, bold: true); y += 18
        let clsName = ["radParticulate": "Radioactive particulate", "cwaNerve": "Nerve agent (CWA)", "bioSpore": "Bacterial spores",
                       "toxicGas": "Toxic inhalation gas", "hydrocarbon": "Hydrocarbon / fuel", "opioid": "Synthetic opioid powder", "nicotine": "Alkaloid liquid (nicotine)", "none": "No agent confirmed"]
        let keyName: String
        switch cls {
        case .radParticulate: keyName = "radParticulate"
        case .cwaNerve: keyName = "cwaNerve"
        case .bioSpore: keyName = "bioSpore"
        case .toxicGas: keyName = "toxicGas"
        case .hydrocarbon: keyName = "hydrocarbon"
        case .opioid: keyName = "opioid"
        case .nicotine: keyName = "nicotine"
        case .none: keyName = "none"
        }
        g.text(clsName[keyName] ?? "-", 840, y, 13, Pal.amber, bold: true); y += 26
        g.text("STATIONS", 840, y, 11, Pal.greenDim, bold: true); y += 18
        for (i, s) in stations.enumerated() {
            let mark = s.pick == nil ? "…" : (s.best.contains(s.pick!) ? "✓" : (s.ok.contains(s.pick!) ? "~" : "✗"))
            let col: NSColor = s.pick == nil ? Pal.grey : (s.best.contains(s.pick!) ? Pal.green : (s.ok.contains(s.pick!) ? Pal.amber : Pal.red))
            g.text("\(mark) \(i + 1). " + s.name.components(separatedBy: "// ").last!, 840, y, 12, col)
            y += 17
        }
        if let w = showWhy { drawWhy(g, w) }
        guide.draw(g)
        footer(g, phase == 3 ? "[ENTER] after-action report" : "[↑↓] select   [ENTER] confirm   [F] field guide")
    }

    private func drawWhy(_ g: G, _ w: String) {
        g.fill(R(0, 0, W, H), Pal.black.a(0.72))
        g.panel(R(220, 240, 840, 300), title: "DECON ERROR", color: Pal.red)
        g.para(w, 244, 276, w: 790, size: 15, color: Pal.white, lineH: 22)
        g.text("[ENTER] continue", 244, 500, 13, Pal.amber, bold: true)
    }

    /// Phase 0: crew the mass-decon truck, or shoulder the backpack sprayer for a confined space.
    private func drawSetup(_ g: G) {
        if confined {
            g.panel(R(40, 90, 1180, 650), title: "CONFINED-SPACE DECON // PORTABLE SPRAYER")
            // one responder, one backpack unit
            let c = P(260, 250)
            drawSuit(g, c, 0.78, lo.suit, lo.resp)
            g.roundRect(R(c.x + 26, c.y - 56, 30, 74), 8, rgba(0.25, 0.45, 0.30))
            g.fill(R(c.x + 30, c.y - 40, 22, 8), Pal.amber)
            g.line(P(c.x + 40, c.y + 16), P(c.x + 96, c.y + 4), Pal.dark, 4)
            g.roundRect(R(c.x + 88, c.y - 8, 14, 16), 3, Pal.grey)
            g.poly([P(c.x + 96, c.y), P(c.x + 134, c.y - 12), P(c.x + 134, c.y + 12)], Pal.cyan.a(0.35))
            for k in 0..<14 {
                let d = CGFloat(k) * 9
                g.circle(P(c.x + 100 + d, c.y + CGFloat(sin(t * 6 + Double(k)) * 6)), 2, Pal.cyan.a(0.5))
            }
            g.text("BACKPACK SPRAYER · 1 OPERATOR · 15 L", c.x + 40, c.y + 60, 13, Pal.amber, bold: true)
            var y: CGFloat = 130
            g.text("NO ROOM FOR THE TRUCK.", 520, y, 20, Pal.amber, bold: true); y += 34
            y += g.para("This decon happens inside the structure: a stairwell landing, a platform, a plant room. There is no space for a mass-decon corridor and no time to walk casualties out first.",
                        520, y, w: 660, size: 14, color: Pal.white, lineH: 20) + 14
            y += g.para("One operator, one 15-litre backpack unit, a berm improvised from salvage covers. Same doctrine as the truck, a fiftieth of the water. You still pick the right solution, and you still doff in the right order.",
                        520, y, w: 660, size: 14, color: Pal.green, lineH: 20) + 24
            g.text("WHAT CHANGES IN A CONFINED SPACE", 520, y, 12, Pal.amber, bold: true); y += 22
            for line in ["• Runoff has nowhere to go. Berm it or you contaminate the floor below.",
                         "• Ventilation is the building's, and it may be feeding the rest of the structure.",
                         "• No shower, no water tank, no spare crew. One operator, one pass, get it right.",
                         "• Casualties come to you on litters. They are decontaminated where they lie.",
                         "• Everything that comes out is bagged. There is no equipment line down here."] {
                y += g.para(line, 520, y, w: 660, size: 13, color: Pal.green, lineH: 18) + 6
            }
            g.panel(R(60, 470, 440, 250), title: "CARRIED KIT")
            var ky: CGFloat = 500
            for (nm, det) in [("15 L backpack sprayer", "wand + cone nozzle, hand-pumped"),
                              ("Solution concentrate", "mixed on the clean side, carried in"),
                              ("Salvage covers", "improvised berm and catch basin"),
                              ("Waste bags + ties", "everything leaves with you"),
                              ("Hand survey instrument", "verification at the improvised hot line")] {
                g.text("■ " + nm, 80, ky, 13, Pal.amber, bold: true); ky += 18
                g.text("   " + det, 80, ky, 12, Pal.greenDim); ky += 24
            }
            footer(g, "[ENTER] begin decon")
            return
        }
        let p = posts[min(pi, posts.count - 1)]
        g.panel(R(40, 90, 700, 300), title: "MASS-DECON TRUCK // CREW OF 7")
        drawTruck(g, R(56, 120, 668, 250))
        g.panel(R(760, 90, 460, 300), title: "POST \(pi + 1) OF 7")
        g.text(p.title, 780, 122, 19, Pal.amber, bold: true)
        g.para(p.duty, 780, 152, w: 420, size: 13, color: Pal.white, lineH: 19)
        var fy: CGFloat = 250
        for (i, q) in posts.enumerated() {
            let filled = q.pick != nil
            let okp = q.pick == q.best
            g.text("\(i + 1)", 782, fy, 11, i == pi ? Pal.amber : Pal.greenDim, bold: true)
            g.text(q.title, 800, fy, 11, i == pi ? Pal.amber : (filled ? (okp ? Pal.green : Pal.red) : Pal.greenDim), bold: i == pi)
            g.text(filled ? (okp ? "✓" : "✗") : (i == pi ? "◀" : "—"), 1200, fy, 11, okp ? Pal.green : (filled ? Pal.red : Pal.greenDim), align: .right)
            fy += 18
        }
        g.panel(R(40, 410, 1180, 330), title: "ASSIGN THIS POST")
        postOpts.draw(g, x: 56, y: 442, w: 1150, size: 14, gap: 8)
    }

    private func drawTruck(_ g: G, _ r: CGRect) {
        // body
        g.roundRect(R(r.minX + 20, r.minY + 60, 420, 120), 8, rgba(0.82, 0.83, 0.80))
        g.roundRect(R(r.minX + 440, r.minY + 90, 120, 90), 8, rgba(0.74, 0.75, 0.72))
        g.fill(R(r.minX + 462, r.minY + 106, 80, 44), Pal.cyan.a(0.35))
        g.hazardStripes(R(r.minX + 20, r.minY + 162, 420, 18), Pal.amber, Pal.black, step: 22)
        g.text("MASS DECON", r.minX + 40, r.minY + 78, 15, Pal.black, bold: true)
        g.text("CBRN RESPONSE", r.minX + 40, r.minY + 100, 11, Pal.dark)
        g.circle(P(r.minX + 110, r.minY + 190), 22, Pal.dark); g.circle(P(r.minX + 110, r.minY + 190), 9, Pal.grey)
        g.circle(P(r.minX + 360, r.minY + 190), 22, Pal.dark); g.circle(P(r.minX + 360, r.minY + 190), 9, Pal.grey)
        g.circle(P(r.minX + 500, r.minY + 190), 22, Pal.dark); g.circle(P(r.minX + 500, r.minY + 190), 9, Pal.grey)
        if Int(t * 3) % 2 == 0 { g.circle(P(r.minX + 452, r.minY + 84), 7, Pal.red) }
        // pump panel + crew dots
        g.fill(R(r.minX + 150, r.minY + 110, 150, 46), rgba(0.25, 0.27, 0.26))
        for k in 0..<6 { g.circle(P(r.minX + 166 + CGFloat(k) * 24, r.minY + 124), 5, k % 2 == 0 ? Pal.amber : Pal.green) }
        g.text("PUMP", r.minX + 196, r.minY + 138, 10, Pal.white)
        let labels = ["CMD", "DRV", "LOAD", "POUR", "SCR1", "SCR2", "HOSE"]
        for (i, lab) in labels.enumerated() {
            let c = P(r.minX + 70 + CGFloat(i) * 86, r.minY + 26)
            let sp = (CGFloat(0), CGFloat(0), lab)
            let filled = i < posts.count && posts[i].pick != nil
            let okp = i < posts.count && posts[i].pick == posts[i].best
            g.circle(c, 13, filled ? (okp ? Pal.green : Pal.red) : (i == pi ? Pal.amber : Pal.dark))
            g.ring(c, 13, Pal.greenDim, 1)
            g.text(sp.2, c.x, c.y + 16, 9, i == pi ? Pal.amber : Pal.green, bold: i == pi, align: .center)
        }
    }

    private func drawCorridor(_ g: G) {
        let base = R(40, 80, 1180, 300)
        g.fill(base, rgba(0.05, 0.07, 0.06))
        g.stroke(base, Pal.green.a(0.3))
        // four berms + hot line
        let names = ["GROSS", "TECHNICAL", "EQUIPMENT", "VERIFY", "COLD ZONE"]
        for i in 0..<5 {
            let x = base.minX + CGFloat(i) * 236
            let r = R(x, base.minY, 236, base.height)
            let active = phase == 1 && i == idx
            if i < 4 {
                g.fill(r.insetBy(dx: 6, dy: 6), active ? Pal.amber.a(0.10) : rgba(0.07, 0.09, 0.08))
                g.fill(R(x + 24, base.minY + 190, 188, 70), rgba(0.10, 0.14, 0.16))   // pool
                for k in 0..<7 {
                    let px = x + 34 + CGFloat(k) * 26
                    let ph = CGFloat(sin(t * 4 + Double(k) + Double(i)) * 4)
                    g.line(P(px, base.minY + 120), P(px, base.minY + 190 + ph), Pal.cyan.a(active ? 0.45 : 0.15), 2)
                }
                g.fill(R(x + 90, base.minY + 70, 56, 52), rgba(0.25, 0.27, 0.26))      // shower head
            } else {
                g.fill(r.insetBy(dx: 6, dy: 6), rgba(0.06, 0.12, 0.08))
            }
            g.text("\(i < 4 ? "\(i + 1). " : "")" + names[i], r.midX, base.minY + 14, 12, active ? Pal.amber : Pal.greenDim, bold: true, align: .center)
            if i == 4 {
                g.hazardStripes(R(x, base.minY, 8, base.height), Pal.red, Pal.black, step: 14)
                g.text("HOT LINE", x + 50, base.minY + 36, 11, Pal.red, bold: true)
            } else if i > 0 { g.line(P(x, base.minY), P(x, base.maxY), Pal.green.a(0.25)) }
        }
        // the responder moves down the corridor
        let step = phase == 1 ? CGFloat(idx) : (phase == 2 ? 4 + CGFloat(picked.count) / CGFloat(order.count) : 4.6)
        let px = base.minX + 118 + step * 236
        let scale: CGFloat = 0.52
        let shown = phase >= 2 && picked.count >= order.count - 1
        if !shown {
            drawSuit(g, P(min(px, base.maxX - 70), base.minY + 175), scale, lo.suit, lo.resp)
        } else {
            // final: in clothing, mask off
            g.roundRect(R(px - 22, base.minY + 120, 44, 90), 10, rgba(0.35, 0.45, 0.55))
            g.circle(P(px, base.minY + 104), 17, rgba(0.85, 0.70, 0.55))
        }
    }
}

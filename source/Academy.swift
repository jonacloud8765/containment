// CONTAINMENT — Phase 0b: CBRN Response Academy.
// Mandatory after clearance. Teaches agent classification, detection tools and field procedures,
// then examines them. You are not on a team until you pass.

import AppKit

struct Lesson {
    let unit: String
    let title: String
    let diagram: Int              // 0 none, 1 classification tree, 2 detector bench, 3 PPE ladder, 4 decon corridor, 5 triage
    let body: [String]            // paragraphs; a line starting with "•" is a bullet
}

struct ExamQ {
    let unit: String
    let q: String
    let a: [String]
    let right: Int
    let why: String
}

let lessons: [Lesson] = [
    Lesson(unit: "UNIT 1", title: "CLASSIFICATION: THE FOUR LETTERS", diagram: 1, body: [
        "CBRN is four different problems wearing the same coveralls. Everything you do in the field follows from which letter you are standing in.",
        "• CHEMICAL — molecules that poison you in minutes. Nerve agents, blister agents, blood agents, choking agents, and the toxic industrial chemicals that sit in every rail yard in the country. Fast. Usually obvious. Detectable in real time.",
        "• BIOLOGICAL — living organisms or their toxins. Spores, bacteria, viruses. Silent, odourless, and invisible at the moment of exposure; the first sign is people getting sick days later. You cannot detect your way out of a biological event in real time.",
        "• RADIOLOGICAL — radioactive material spread around where it should not be. Contamination. You can measure it precisely, it does not act quickly, and panic does more damage than dose.",
        "• NUCLEAR — fission. Criticality, reactor accidents, weapons. Penetrating radiation that goes straight through your suit, plus neutrons, which almost nothing you can wear will stop.",
        "The trap: chemical and radiological incidents LOOK the same from the fence line. Both are 'people down, nobody knows why'. Your instruments separate them in the first ninety seconds. That is why you carry four of them.",
    ]),
    Lesson(unit: "UNIT 2", title: "CHEMICAL AGENT FAMILIES", diagram: 0, body: [
        "Classify by what the agent does to the body, not by its name. The name comes from the lab hours later. The effect is in front of you now.",
        "• NERVE (G-series, V-series, and the organophosphate pesticides that mimic them) — cholinesterase inhibitors. Pinpoint pupils, streaming nose, drooling, chest tightness, twitching, seizures. Atropine and pralidoxime. The classic field memory aid is SLUDGE: salivation, lacrimation, urination, defecation, gastric upset, emesis.",
        "• BLISTER / VESICANT (sulfur mustard, lewisite) — burns skin and airways, often with NO pain at the time of contact. Symptoms appear two to twenty-four hours later. There is no antidote for mustard. Decontamination within minutes is the whole treatment.",
        "• BLOOD (hydrogen cyanide) — stops cells using oxygen. Fast, and the casualty is often NOT blue. Hydroxocobalamin.",
        "• CHOKING / PULMONARY (chlorine, phosgene, ammonia) — damages the airways. Delayed fluid in the lungs up to twenty-four hours later. Oxygen and observation, not antidotes.",
        "• OPIOID / INCAPACITANT (fentanyl and its analogues) — pinpoint pupils and a slow, shallow stop to breathing. Looks like nerve agent at a glance and is treated completely differently: naloxone, not atropine.",
        "• ALKALOID (concentrated nicotine) — looks cholinergic, is not a cholinesterase inhibitor. Oximes do nothing.",
    ]),
    Lesson(unit: "UNIT 3", title: "DETECTION: WHAT EACH TOOL ACTUALLY SEES", diagram: 2, body: [
        "No instrument detects 'poison'. Each one responds to one physical property, and knowing what it is blind to is worth more than knowing what it sees.",
        "• AP4C (flame spectrophotometer) — burns a sample in a hydrogen flame and reads the light the burning elements give off. It reports ELEMENTS, not agents: P (phosphorus) points to nerve agents and organophosphates, S (sulfur) to mustard and sulfur compounds, As (arsenic) to lewisite, HNO (nitrogen) to nitrogen compounds. It will alarm on brake cleaner and fertiliser. It is fast, rugged and honest, and it never tells you the agent's name.",
        "• IMS (ion mobility spectrometry) — sorts ionised molecules by how fast they drift. Gives a G / H / blister style library alarm. Prone to false alarms from perfume, smoke and cleaning products.",
        "• 5-GAS METER — oxygen, flammability (LEL), carbon monoxide, hydrogen sulfide, plus one sensor you choose. This is a SURVIVAL instrument, not an agent detector. It tells you whether the atmosphere itself will kill you.",
        "• GEIGER-MÜLLER COUNTER — a pancake probe that clicks once per ionising particle. Superb at finding CONTAMINATION, poor at measuring dose rate, and it saturates in a strong field. Survey at about 5 cm, moving about 5 cm per second.",
        "• ION CHAMBER — measures DOSE RATE honestly across a huge range. This is the instrument that decides whether you may stand somewhere.",
        "• M8 / M9 PAPER — colour-change paper for LIQUID agent only. Yellow-gold for G, dark green for V, red for blister. Fuels and solvents give false positives.",
        "• FENTANYL TEST STRIP — lateral-flow immunoassay. Detects fentanyl and many analogues down to trace level, screening only. A negative strip does not clear a powder.",
        "• HAND-HELD IMMUNOASSAY (biological) — a screening ticket. Cross-reacts with harmless relatives. Never act on it alone: PCR and culture confirm.",
    ]),
    Lesson(unit: "UNIT 4", title: "PROTECTION: LEVELS AND LIMITS", diagram: 3, body: [
        "Protection is two separate decisions: what your lungs breathe, and what touches your skin.",
        "• LEVEL A — supplied air (SCBA) inside a gas-tight encapsulating suit. For unknown atmospheres and skin-absorbable vapour. Hottest, slowest, highest air burn.",
        "• LEVEL B — SCBA with a splash suit. Same respiratory protection as A, less skin vapour protection.",
        "• LEVEL C — air-purifying respirator (APR or PAPR) with a splash suit. Long working time, much cooler — but ONLY when the hazard is identified, measured below IDLH, and oxygen is at or above 19.5 percent.",
        "• LEVEL D — work uniform. No respiratory hazard.",
        "Assigned protection factors: pressure-demand SCBA 10,000. Tight-fitting full-face PAPR 1,000. Full-face APR 50.",
        "THREE THINGS A FILTER CANNOT DO: it cannot make oxygen, it cannot remove carbon monoxide, and it cannot protect you in an atmosphere nobody has measured. Every one of those has killed responders.",
        "Radiological PPE is for CONTAMINATION, not penetrating radiation. Nothing you can wear meaningfully stops high-energy gamma, and nothing stops fast neutrons. Time, distance and shielding — in that order of how quickly you can apply them.",
    ]),
    Lesson(unit: "UNIT 5", title: "PROCEDURE: THE ENTRY", diagram: 0, body: [
        "• SIZE UP FROM UPWIND AND UPHILL. Vapour and heavy gases run downhill and downwind. Read placards and UN numbers with binoculars before you read them with your face.",
        "• ESTABLISH ZONES. Hot (contaminated), warm (the decon corridor), cold (everything clean). Nobody crosses a line without being surveyed.",
        "• AIR MANAGEMENT. The low-air alarm at one third is not your exit cue — it is the alarm that says you should ALREADY be out. Plan on one third in, one third out, one third reserve.",
        "• NEVER BREAK A SEAL IN THE HOT ZONE. Not to talk, not to wipe your face, not because an officer asked you to.",
        "• SAMPLE DISCIPLINE. One sample, one container, one label, and fresh outer gloves between every single one. Cross-contaminate two samples and you have destroyed both, plus the investigation.",
        "• DOCUMENT AS YOU GO. A reading you did not log did not happen. The after-action, the inquiry and the court case all run on your notebook.",
        "• WORK IN PAIRS, ALWAYS. Nobody enters alone and nobody leaves alone.",
    ]),
    Lesson(unit: "UNIT 6", title: "PROCEDURE: CASUALTIES & TRIAGE", diagram: 5, body: [
        "• RED immediate, life-threatening but survivable. YELLOW delayed, serious and stable. GREEN minimal, walking. BLACK expectant or deceased.",
        "• LIFE BEFORE LIMB, LIMB BEFORE DECON. A patient who is not breathing does not need a shower first.",
        "• DISROBING IS DECONTAMINATION. Removing outer clothing takes most of the contamination with it, and it is the fastest intervention you have.",
        "• A CONTAMINATED PATIENT IS NOT CONTAGIOUS. Radiologically contaminated people do not irradiate the ward. Say it out loud, repeatedly — stigma did lasting harm after real incidents.",
        "• AN IRRADIATED PATIENT IS NOT CONTAMINATED. Someone who stood in a beam is not radioactive and needs no decon at all.",
        "• NEVER GIVE AN ANTIDOTE TO THE DIAGNOSIS YOU ASSUMED. Atropine into someone who is not poisoned causes atropine toxicity: hot, dry, flushed, confused, racing heart, no sweating — which in a sealed suit is its own emergency.",
        "• SEARCH AND RESCUE: move non-ambulatory casualties on stretchers, two carriers per stretcher, out of the hot zone to the decon line. Your squad carries; you command, read the meters, and keep the route safe.",
    ]),
    Lesson(unit: "UNIT 7", title: "PROCEDURE: DECONTAMINATION", diagram: 4, body: [
        "The solution must match the hazard. The wrong solution is not merely useless — it can be worse than nothing.",
        "• RADIOACTIVE MATERIAL cannot be neutralised, only removed and contained. Soap, water, HEPA vacuum, tacky wipes, strippable coating. Bleach accomplishes nothing and creates mixed waste.",
        "• NERVE AND BLISTER AGENT are oxidised by hypochlorite. 5 percent on PPE and equipment. STB (super tropical bleach — calcium hypochlorite and lime) is for VEHICLES, TOOLS AND TERRAIN only: it is far too aggressive for suit seams and visors, and it never goes near skin. RSDL is the skin product.",
        "• SPORES need a sporicide with contact time: 0.5 percent hypochlorite, ten minutes. Never dry-brush and never use compressed air — that puts the spores back in the air.",
        "• CHLORINE AND OTHER IRRITANT GASES leave with fresh air and water. Hypochlorite releases MORE chlorine.",
        "• HYDROCARBONS AND FUELS need surfactant. Oxidisers on fuel can react or ignite.",
        "• DOFFING ORDER IS THE WHOLE EXERCISE. Outer layers first, respirator LAST, inner gloves at the very end, across the hot line. Break your respiratory protection while still dirty and every minute of decon before it was wasted.",
    ]),
]

let examQs: [ExamQ] = [
    ExamQ(unit: "U1", q: "Casualties are down at a transport hub with no visible cloud and no smell. Your 5-gas meter is normal, your ion chamber is at background. What have you ruled out?",
          a: ["An atmosphere that is itself immediately dangerous, and a significant radiological source — but nothing else",
              "Everything. Two clean instruments means a false alarm",
              "A chemical attack, since the gas meter is clear",
              "A biological release, since nobody is sick yet"],
          right: 0, why: "A 5-gas meter is a survival instrument: it says the air will not kill you outright. It does not detect nerve agent at militarily relevant concentrations. A clean ion chamber rules out a strong radiological source. Chemical and biological remain wide open."),
    ExamQ(unit: "U2", q: "A casualty has pinpoint pupils and has stopped breathing effectively. There is NO drooling, no streaming nose, no sweating, no twitching. What should rise to the top of your list?",
          a: ["Opioid exposure (fentanyl or an analogue) — naloxone and ventilation",
              "Nerve agent — three autoinjectors immediately",
              "Blister agent — immediate decontamination",
              "Chlorine — oxygen and observation"],
          right: 0, why: "Both opioids and nerve agents cause pinpoint pupils and respiratory failure. Nerve agent floods the body with secretions — SLUDGE. A dry casualty with pinpoint pupils points to opioid, which needs naloxone and ventilation, not atropine and an oxime."),
    ExamQ(unit: "U3", q: "Your AP4C alarms on the P channel at a warehouse fire. What has it told you?",
          a: ["Phosphorus is present — consistent with a nerve agent OR an organophosphate pesticide OR several ordinary products. It has NOT named an agent",
              "A nerve agent is confirmed; go to the nerve-agent protocol",
              "The reading is a false alarm because it is a fire",
              "Phosgene is present"],
          right: 0, why: "The AP4C reports elements from a flame spectrum, not agent identities. P means phosphorus — nerve agent, pesticide, or something innocent. It is a fast screening tool that narrows the field; GC-MS names the compound."),
    ExamQ(unit: "U3", q: "Which instrument do you reach for first to find out whether loose radioactive contamination is on a surface?",
          a: ["Geiger-Müller pancake probe, surveyed slowly at about 5 cm",
              "Ion chamber",
              "IMS chemical detector",
              "Electronic personal dosimeter"],
          right: 0, why: "A GM pancake probe is the contamination-finding instrument — it clicks on individual particles and is extremely sensitive at low levels. The ion chamber measures dose RATE, which is the different question of whether you may stand there."),
    ExamQ(unit: "U4", q: "Oxygen reads 18.2 percent in a basement where an unidentified vapour is present. You are wearing a CBRN full-face respirator with a fresh canister.",
          a: ["Leave immediately. An air-purifying respirator cannot make oxygen, and the atmosphere is both oxygen-deficient and unidentified",
              "Continue — the canister is rated for CBRN agents",
              "Continue but work faster",
              "Swap to a particulate filter"],
          right: 0, why: "Below 19.5 percent oxygen, no filter helps: filters clean air, they do not supply it. An unidentified atmosphere also rules out air-purifying respirators on its own. This needs supplied air."),
    ExamQ(unit: "U5", q: "Your SCBA low-air alarm sounds at one third remaining. You are three minutes from finishing the last sample.",
          a: ["Exit now. The reserve is for emergencies, and the alarm means you are already late",
              "Finish the sample — three minutes is well within a third of a cylinder",
              "Switch to your partner's air",
              "Remove the mask briefly to save air"],
          right: 0, why: "The low-air alarm is not a work timer. The final third covers the walk out, a wrong turn, a snagged line, or carrying someone. Plan to be at the hot line before it sounds."),
    ExamQ(unit: "U6", q: "A casualty was irradiated by an unshielded industrial source. She is not externally contaminated. What does she need before entering the ambulance?",
          a: ["Nothing radiological. She is not radioactive — treat her injuries and transport",
              "A full decontamination shower first",
              "Prussian blue before anything else",
              "Isolation; she is a hazard to the crew"],
          right: 0, why: "Irradiation is not contamination. Someone exposed to a beam does not become radioactive and poses no risk to anyone. Delaying their care for an unnecessary shower is a real and recurring error."),
    ExamQ(unit: "U7", q: "You have confirmed caesium-137 contamination on your suit. Which technical decon solution?",
          a: ["Soap and water, then HEPA vacuum and tacky wipes on equipment, then survey",
              "STB slurry over the whole suit",
              "5 percent hypochlorite",
              "0.5 percent hypochlorite with ten minutes of contact time"],
          right: 0, why: "Radioactivity cannot be chemically neutralised. You are physically removing particles. Bleach and STB add corrosive mixed hazardous waste and do nothing to the activity."),
    ExamQ(unit: "U7", q: "Where does STB (super tropical bleach) correctly belong?",
          a: ["On vehicles, tools and terrain after chemical agent — never on skin, never on suit seams or visors",
              "As the first gross-decon wash over responders",
              "On a fuel spill, to break down the hydrocarbons",
              "On a chlorine release, to neutralise the gas"],
          right: 0, why: "STB is a caustic calcium hypochlorite and lime mixture for equipment, vehicles and ground. It destroys suit seams and visors, it is dangerous on skin, and as a strong oxidiser on fuel it risks fire."),
    ExamQ(unit: "U7", q: "In what order does an encapsulated Level A ensemble come off?",
          a: ["Suit unzipped and stepped out of, then boots and outer gloves, then the SCBA harness, then the facepiece LAST, then inner gloves",
              "Facepiece first so you can breathe freely while working",
              "SCBA harness, then facepiece, then the suit",
              "Inner gloves first, then everything else"],
          right: 0, why: "The respirator always comes off last, on the clean side. Removing the facepiece while the suit is still contaminated exposes your airway at the dirtiest moment of the entire operation."),
]

final class AcademyScene: Scene {
    enum Mode { case intro, lesson, exam, result, badge }
    var mode: Mode = .intro
    var li = 0
    var page = 0
    var ei = 0
    var opts = OptionList([])
    var answered: Int? = nil
    var correct = 0
    var wrong: [Int] = []
    var t = 0.0
    var reveal = 0.0
    var guide = GuideOverlay()

    init() { Audio.shared.reset(); Audio.shared.hum = 0.35 }

    var lesson: Lesson { lessons[li] }
    var exam: ExamQ { examQs[ei] }

    func update(_ dt: Double) {
        t += dt
        reveal += dt * 320
    }

    func draw(_ g: G) {
        switch mode {
        case .intro: drawIntro(g)
        case .lesson: drawLesson(g)
        case .exam: drawExam(g)
        case .result: drawResult(g)
        case .badge: drawBadge(g)
        }
        guide.draw(g)
    }

    // MARK: Intro

    private func drawIntro(_ g: G) {
        header(g, "CBRN RESPONSE ACADEMY", "MANDATORY PRE-DEPLOYMENT TRAINING")
        g.panel(R(120, 120, 1040, 520), title: "INDUCTION")
        g.text("YOU ARE NOT ON A TEAM YET.", 150, 158, 26, Pal.amber, bold: true)
        var y: CGFloat = 206
        y += g.para("Your clearance is adjudicated. That decides what you are allowed to see. It does not decide whether you are any use at an incident.", 150, y, w: 980, size: 16, color: Pal.white, lineH: 24) + 18
        y += g.para("Seven units: agent classification, detection tools, protection, entry procedure, casualty handling, search and rescue, and decontamination. Then a ten-item practical examination.", 150, y, w: 980, size: 15, color: Pal.green, lineH: 22) + 18
        y += g.para("Pass mark is 7 of 10. Fail and you retake it. There is no third option, and nobody deploys without the badge.", 150, y, w: 980, size: 15, color: Pal.amber, lineH: 22) + 24
        g.text("THE FIELD REFERENCE GUIDE IS OPEN TO YOU DURING TRAINING AND IN THE FIELD — PRESS [F] AT ANY TIME.", 150, y, 13, Pal.cyan, bold: true)
        let s = Game.shared.state
        g.text("TRAINEE: \(s.division.clearance) // \(s.division.rating)", 150, 560, 14, Pal.greenDim)
        if s.trained { g.text("BADGE ON FILE — best exam score \(s.trainScore)/10. You may review or re-examine.", 150, 586, 14, Pal.green, bold: true) }
        footer(g, "[ENTER] begin training   [F] field guide")
    }

    // MARK: Lesson

    private func drawLesson(_ g: G) {
        header(g, "ACADEMY // \(lesson.unit) OF \(lessons.count)", lesson.title)
        g.panel(R(40, 90, 760, 650), title: lesson.title)
        var y: CGFloat = 120
        var shown = Int(reveal)
        for p in lesson.body {
            if shown <= 0 { break }
            let txt = String(p.prefix(shown))
            shown -= p.count
            let bullet = p.hasPrefix("•")
            let col: NSColor = bullet ? Pal.green : Pal.white
            y += g.para(txt, bullet ? 76 : 62, y, w: bullet ? 706 : 720, size: 14, color: col, lineH: 20) + 10
            if y > 700 { break }
        }
        g.panel(R(820, 90, 400, 650), title: "FIGURE")
        drawDiagram(g, lesson.diagram, R(830, 115, 380, 600))
        let done = Int(reveal) > lesson.body.reduce(0) { $0 + $1.count }
        g.bar(R(40, 752, 760, 6), Double(li) / Double(lessons.count), Pal.amber)
        footer(g, done ? "[ENTER] next unit   [BACK] previous   [F] field guide" : "[ENTER] show all   [F] field guide")
    }

    private func drawDiagram(_ g: G, _ kind: Int, _ r: CGRect) {
        switch kind {
        case 1:   // classification tree
            let cx = r.midX
            g.roundRect(R(cx - 70, r.minY + 10, 140, 34), 6, Pal.amber)
            g.text("INCIDENT", cx, r.minY + 20, 13, Pal.black, bold: true, align: .center)
            let kinds: [(String, String, NSColor)] = [("CHEMICAL", "minutes · detectable", Pal.yellow),
                                                      ("BIOLOGICAL", "days · silent", rgba(0.5, 0.9, 0.6)),
                                                      ("RADIOLOGICAL", "measurable · slow", Pal.cyan),
                                                      ("NUCLEAR", "penetrating · neutrons", Pal.red)]
            for (i, k) in kinds.enumerated() {
                let yy = r.minY + 90 + CGFloat(i) * 92
                g.line(P(cx, r.minY + 44), P(cx, yy + 8), Pal.greenDim, 1)
                g.line(P(cx, yy + 8), P(r.minX + 30, yy + 8), Pal.greenDim, 1)
                g.roundRect(R(r.minX + 20, yy, 340, 56), 6, k.2.a(0.16))
                g.stroke(R(r.minX + 20, yy, 340, 56), k.2.a(0.7), 1)
                g.text(k.0, r.minX + 36, yy + 10, 15, k.2, bold: true)
                g.text(k.1, r.minX + 36, yy + 32, 12, Pal.greenDim)
            }
            g.para("Chemical and radiological look identical from the fence line. Instruments separate them.", r.minX + 20, r.minY + 480, w: 340, size: 12, color: Pal.amber)
        case 2:   // detector bench
            let tools: [(String, String, NSColor)] = [("AP4C", "elements: P · S · As · HNO", Pal.amber),
                                                      ("IMS", "library alarm: G / H", Pal.cyan),
                                                      ("5-GAS", "O2 · LEL · CO · H2S · +1", Pal.green),
                                                      ("GM COUNTER", "contamination, cpm", Pal.yellow),
                                                      ("ION CHAMBER", "dose rate, Sv/h", Pal.red),
                                                      ("M8 PAPER", "liquid agent, colour", Pal.white),
                                                      ("FENTANYL STRIP", "lateral flow, screen", rgba(0.9, 0.5, 0.9)),
                                                      ("IMMUNOASSAY", "bio screen only", rgba(0.6, 0.9, 0.7))]
            for (i, t) in tools.enumerated() {
                let yy = r.minY + 16 + CGFloat(i) * 70
                g.roundRect(R(r.minX + 14, yy, 352, 58), 5, rgba(0.07, 0.09, 0.08))
                g.stroke(R(r.minX + 14, yy, 352, 58), t.2.a(0.5), 1)
                g.fill(R(r.minX + 14, yy, 5, 58), t.2)
                g.text(t.0, r.minX + 30, yy + 10, 14, t.2, bold: true)
                g.text(t.1, r.minX + 30, yy + 32, 12, Pal.greenDim)
            }
        case 3:   // PPE ladder
            let levels: [(String, String, NSColor)] = [("LEVEL A", "SCBA + gas-tight encapsulating", Pal.suitYel),
                                                       ("LEVEL B", "SCBA + splash suit", Pal.suitRed),
                                                       ("LEVEL C", "APR/PAPR + splash suit", rgba(0.3, 0.62, 0.85)),
                                                       ("LEVEL D", "work uniform", Pal.grey)]
            for (i, l) in levels.enumerated() {
                let yy = r.minY + 20 + CGFloat(i) * 110
                g.roundRect(R(r.minX + 20, yy, 340, 90), 6, l.2.a(0.14))
                g.stroke(R(r.minX + 20, yy, 340, 90), l.2.a(0.8), 1.5)
                g.text(l.0, r.minX + 36, yy + 12, 17, l.2, bold: true)
                g.text(l.1, r.minX + 36, yy + 38, 12, Pal.green)
                let apf = ["APF 10,000", "APF 10,000", "APF 1,000 / 50", "—"][i]
                g.text(apf, r.minX + 344, yy + 12, 12, Pal.amber, bold: true, align: .right)
                if i < 3 { g.text("↑ more protection   ↓ more working time", r.minX + 36, yy + 64, 11, Pal.greenDim) }
            }
            g.para("A filter cannot make oxygen, cannot remove CO, and is never used in an unknown atmosphere.",
                   r.minX + 20, r.minY + 480, w: 340, size: 12, color: Pal.red)
        case 4:   // decon corridor
            let st = ["1 GROSS\nknock-down rinse", "2 TECHNICAL\nsolution matched to agent",
                      "3 EQUIPMENT\ntools, meters, air packs", "4 VERIFY\ninstrument that sees it",
                      "5 DOFF\nouter first, mask LAST"]
            for (i, s) in st.enumerated() {
                let yy = r.minY + 20 + CGFloat(i) * 96
                g.roundRect(R(r.minX + 20, yy, 340, 76), 6, i == 4 ? Pal.red.a(0.14) : Pal.cyan.a(0.10))
                g.stroke(R(r.minX + 20, yy, 340, 76), i == 4 ? Pal.red.a(0.7) : Pal.cyan.a(0.5), 1)
                let parts = s.components(separatedBy: "\n")
                g.text(parts[0], r.minX + 36, yy + 12, 15, i == 4 ? Pal.red : Pal.cyan, bold: true)
                g.text(parts[1], r.minX + 36, yy + 38, 12, Pal.green)
                if i < 4 { g.text("▼", r.midX, yy + 78, 12, Pal.greenDim, align: .center) }
            }
        case 5:   // triage
            let tags: [(String, String, NSColor)] = [("RED", "immediate · survivable", Pal.red),
                                                     ("YELLOW", "delayed · stable", Pal.yellow),
                                                     ("GREEN", "minimal · walking", Pal.green),
                                                     ("BLACK", "expectant / deceased", Pal.grey)]
            for (i, t) in tags.enumerated() {
                let yy = r.minY + 20 + CGFloat(i) * 92
                g.roundRect(R(r.minX + 20, yy, 340, 72), 6, t.2.a(0.18))
                g.fill(R(r.minX + 20, yy, 14, 72), t.2)
                g.text(t.0, r.minX + 50, yy + 14, 20, t.2, bold: true)
                g.text(t.1, r.minX + 50, yy + 42, 12, Pal.green)
            }
            g.para("LIFE BEFORE LIMB, LIMB BEFORE DECON.\n\nDisrobing is decontamination.\n\nA contaminated patient is not contagious.\nAn irradiated patient is not contaminated.",
                   r.minX + 20, r.minY + 400, w: 340, size: 13, color: Pal.amber, lineH: 19)
        default:
            g.para("No figure for this unit.\n\nRead carefully. Ten of these points appear on the examination.",
                   r.minX + 20, r.minY + 30, w: 340, size: 14, color: Pal.greenDim, lineH: 20)
        }
    }

    // MARK: Exam

    private func drawExam(_ g: G) {
        header(g, "ACADEMY // PRACTICAL EXAMINATION", "ITEM \(ei + 1) OF \(examQs.count)   //   CORRECT \(correct)")
        g.panel(R(60, 100, 1160, 580), title: "ITEM \(ei + 1) [\(exam.unit)]")
        var y: CGFloat = 132
        y += g.para(exam.q, 84, y, w: 1110, size: 18, color: Pal.amber, lineH: 25, bold: true) + 20
        opts.draw(g, x: 76, y: y, w: 1130, size: 15, gap: 8)
        if let a = answered {
            let ok = a == exam.right
            let by = R(76, 500, 1130, 160)
            g.fill(by, (ok ? Pal.green : Pal.red).a(0.12))
            g.stroke(by, ok ? Pal.green : Pal.red, 1.5)
            g.text(ok ? "✓ CORRECT" : "✗ INCORRECT", 96, 512, 17, ok ? Pal.green : Pal.red, bold: true)
            if !ok { g.para("Correct answer: " + exam.a[exam.right], 96, 536, w: 1090, size: 13, color: Pal.amber) }
            g.para(exam.why, 96, ok ? 540 : 576, w: 1090, size: 14, color: Pal.white, lineH: 20)
        }
        g.bar(R(60, 700, 1160, 8), Double(ei) / Double(examQs.count), Pal.amber)
        footer(g, answered == nil ? "[↑↓] select   [ENTER] answer   [1-4] quick answer   [F] field guide"
                                  : "[ENTER] next item   [F] field guide")
    }

    private func drawResult(_ g: G) {
        let passed = correct >= 7
        header(g, "ACADEMY // EXAMINATION RESULT", "\(correct) / \(examQs.count)")
        g.panel(R(180, 120, 920, 520), title: "RESULT")
        g.text("\(correct)/10", 640, 160, 72, passed ? Pal.green : Pal.red, bold: true, align: .center)
        g.text(passed ? "PASS" : "FAIL — RETAKE REQUIRED", 640, 256, 28, passed ? Pal.green : Pal.red, bold: true, align: .center)
        var y: CGFloat = 320
        if wrong.isEmpty {
            g.text("Every item correct. The instructor writes 'finally' in the margin.", 640, y, 15, Pal.amber, align: .center); y += 40
        } else {
            g.text("REVIEW THESE:", 230, y, 13, Pal.amber, bold: true); y += 22
            for w in wrong.prefix(5) {
                y += g.para("• [\(examQs[w].unit)] " + examQs[w].q, 230, y, w: 820, size: 12, color: Pal.green, lineH: 16) + 6
            }
        }
        g.para(passed ? "Pass mark met. Badge issued and you are posted to a response team."
                      : "Below the pass mark of 7. Review the units and sit the examination again. Nobody deploys without the badge.",
               230, 580, w: 820, size: 15, color: passed ? Pal.green : Pal.amber, lineH: 22)
        footer(g, passed ? "[ENTER] receive badge" : "[ENTER] review units   [R] retake examination now")
    }

    private func drawBadge(_ g: G) {
        let s = Game.shared.state
        header(g, "POSTING ORDER", "NATIONAL CBRN RESPONSE SERVICE")
        g.panel(R(240, 110, 800, 560), title: "YOU ARE ON THE TEAM")
        // badge
        let c = P(640, 250)
        g.ring(c, 92, Pal.amber, 3)
        g.ring(c, 80, Pal.amber.a(0.5), 1)
        trefoil(g, c, 52, Pal.amber.a(0.9), rot: CGFloat(t * 0.3))
        if t > 0.4 {
            g.save(); g.ctx.translateBy(x: 640, y: 390); g.ctx.rotate(by: -0.04)
            g.stroke(R(-300, -34, 600, 68), Pal.green, 4)
            g.text("QUALIFIED — CBRN RESPONDER", 0, -10, 21, Pal.green, bold: true, align: .center)
            g.restore()
        }
        var y: CGFloat = 450
        g.text("CLEARANCE   " + s.division.clearance + " // " + s.division.title, 290, y, 15, Pal.green, bold: true); y += 26
        g.text("HAZMAT RATING   " + s.division.rating, 290, y, 15, Pal.green); y += 26
        g.text("ACADEMY       \(s.trainScore)/10 — PASSED", 290, y, 15, Pal.green); y += 26
        g.text("POSTING       ENTRY TEAM COMMANDER, 4-PERSON SQUAD", 290, y, 15, Pal.amber, bold: true); y += 34
        g.para("You command the entry. Your squad follows you in, carries stretchers, and does what you order. Read the meters, keep the route clean, and bring everyone back across the hot line.",
               290, y, w: 700, size: 14, color: Pal.white, lineH: 21)
        g.text("STAND BY FOR CALLOUT.", 640, 630, 17, Int(t * 2) % 2 == 0 ? Pal.red : Pal.red.a(0.4), bold: true, align: .center)
        footer(g, "[ENTER] report for duty")
    }

    // MARK: Input

    func keyDown(_ k: String) {
        if guide.key(k) { return }
        if k == "f" { guide.show(3); return }
        switch mode {
        case .intro:
            if k == "enter" || k == "space" { mode = .lesson; li = 0; reveal = 0; Audio.shared.blip(900, 0.06) }
        case .lesson:
            let full = lesson.body.reduce(0) { $0 + $1.count }
            if k == "back" || k == "left" { if li > 0 { li -= 1; reveal = 1e9 }; return }
            if k == "enter" || k == "space" || k == "right" {
                if Int(reveal) <= full { reveal = 1e9; return }
                li += 1
                reveal = 0
                if li >= lessons.count { li = lessons.count - 1; startExam() }
                else { Audio.shared.blip(1000, 0.05) }
            }
        case .exam:
            if answered != nil {
                if k == "enter" || k == "space" { nextItem() }
                return
            }
            if let i = opts.key(k) { answer(i) }
        case .result:
            if correct >= 7 {
                if k == "enter" || k == "space" { issueBadge() }
            } else if k == "r" { startExam() }
            else if k == "enter" || k == "space" { mode = .lesson; li = 0; reveal = 0 }
        case .badge:
            if k == "enter" || k == "space" { Game.shared.go(MissionSelectScene()) }
        }
    }
    func mouseMoved(_ p: CGPoint) { if mode == .exam && answered == nil { opts.hover(p) }; guide.mouseMoved(p) }
    func mouseDown(_ p: CGPoint) {
        if mode == .exam, answered == nil, let i = opts.click(p) { answer(i); return }
        keyDown("enter")
    }

    private func startExam() {
        mode = .exam; ei = 0; correct = 0; wrong = []
        opts = OptionList(examQs[0].a)
        answered = nil
        Audio.shared.squelch()
    }
    private func answer(_ i: Int) {
        answered = i
        if i == exam.right { correct += 1; Audio.shared.confirm() } else { wrong.append(ei); Audio.shared.deny() }
    }
    private func nextItem() {
        ei += 1
        answered = nil
        if ei >= examQs.count {
            mode = .result
            var s = Game.shared.state
            s.trainScore = max(s.trainScore, correct)
            if correct >= 7 { s.trained = true }
            s.save(); Game.shared.state = s
            Audio.shared.stamp()
        } else { opts = OptionList(exam.a) }
    }
    private func issueBadge() { mode = .badge; t = 0; Audio.shared.stamp() }
}

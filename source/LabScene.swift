// CONTAINMENT — Part 3: transport cutscene + forward-lab analysis + identification report.
// Instrument visuals live in LabDraw.swift.

import AppKit

/// Relative gamma emission probabilities, aligned with Agent.gammaKeV.
let gammaYield: [String: [Double]] = [
    "CS137": [0.851], "CS134": [0.976, 0.855], "I131": [0.815, 0.072], "RU103": [0.91], "ZR95": [0.44, 0.55],
    "CO60": [0.999, 1.0], "IR192": [0.83, 0.48, 0.30], "AM241": [0.36], "K40": [0.107], "RA226": [0.36, 0.45, 0.15],
    "TC99M": [0.89], "NA24": [1.0, 0.999],
]
/// Relative activity of each nuclide in a sample (Chernobyl-like Cs-134/Cs-137 ≈ 0.5, fresh I-131 high).
let activityWeight: [String: Double] = ["I131": 1.6, "CS134": 0.5, "RU103": 0.8, "ZR95": 0.7, "K40": 0.8, "RA226": 0.9]

struct LabTest { let name: String; let minutes: Double; let key: String }
let chemTests = [LabTest(name: "M8 paper", minutes: 1, key: "m8"), LabTest(name: "IMS detector", minutes: 1, key: "ims"),
                 LabTest(name: "Enzyme ticket (ChE)", minutes: 3, key: "enzyme"), LabTest(name: "pH strip", minutes: 1, key: "pH"),
                 LabTest(name: "Alkaloid reagent", minutes: 4, key: "alkaloid"), LabTest(name: "Colorimetric tube", minutes: 3, key: "tube"),
                 LabTest(name: "GC-MS", minutes: 25, key: "gcms")]
let bioTests = [LabTest(name: "Immunoassay (HHA)", minutes: 15, key: "hha"), LabTest(name: "Gram stain", minutes: 10, key: "gram"),
                LabTest(name: "Spore stain", minutes: 20, key: "spore"), LabTest(name: "Iodine (starch)", minutes: 2, key: "iodine"),
                LabTest(name: "pH", minutes: 1, key: "pH"), LabTest(name: "Real-time PCR", minutes: 90, key: "pcr"),
                LabTest(name: "Culture (18 h)", minutes: 1080, key: "culture")]

func agentField(_ a: Agent, _ k: String) -> String {
    switch k {
    case "m8": return a.m8
    case "ims": return a.ims
    case "enzyme": return a.enzyme
    case "pH": return a.pH
    case "alkaloid": return a.alkaloid
    case "tube": return a.tube
    case "gcms": return a.gcms
    case "hha": return a.hha
    case "gram": return a.gram
    case "spore": return a.spore
    case "iodine": return a.iodine
    case "pcr": return a.pcr
    default: return a.culture
    }
}

final class LabScene: Scene {
    let run: MissionRun
    let samples: [Sample]
    let radMode: Bool
    let bioMode: Bool
    let tests: [LabTest]
    var phase = 0          // 0 transport, 1 bench, 2 threat, 3 protocol
    var t = 0.0
    var sel = 0
    var chosen: [Set<String>]
    var results: [[String: String]]
    var lastTest: String? = nil
    var hood = false
    var contamination = 0
    var labMin = 0.0
    var busy: (Int, Double)? = nil
    var picker: OptionList? = nil
    var threatList = OptionList(Threat.allCases.map { $0.label })
    var protoList: OptionList
    var guide = GuideOverlay()
    var note = ""
    // radiological
    var cursor: Double = 662
    var marks: [[Double]]
    var step: [Int]
    let decaySteps: [Double] = [0, 6, 24, 168, 720]
    var specCache: [String: [Double]] = [:]
    var threatPick: Threat = .accident

    init(_ r: MissionRun) {
        run = r
        samples = r.field.samples
        radMode = r.def.division == .nuclear
        bioMode = r.def.candidates.contains("BA")
        tests = bioMode ? bioTests : chemTests
        chosen = Array(repeating: [], count: samples.count)
        results = Array(repeating: [:], count: samples.count)
        marks = Array(repeating: [], count: samples.count)
        step = Array(repeating: 0, count: samples.count)
        protoList = OptionList(r.def.protocols)
        Audio.shared.reset(); Audio.shared.rumble = 0.25; Audio.shared.wind = 0.1
    }

    var candidates: [String] { run.def.candidates }

    func update(_ dt: Double) {
        t += dt
        if phase == 0 {
            if t > 7 { toBench() }
            if Int(t * 3) != Int((t - dt) * 3) && t < 5 { Audio.shared.tick() }
        }
        if var b = busy {
            b.1 += dt
            if b.1 > 0.9 { finishTest(b.0); busy = nil } else { busy = b }
        }
    }
    private func toBench() {
        phase = samples.isEmpty ? 2 : 1
        Audio.shared.reset(); Audio.shared.hum = 0.5
        if samples.isEmpty { note = "No samples reached the lab. Identification is impossible: report on field observations only." }
    }

    // MARK: Spectra

    func spectrum(_ i: Int) -> [Double] {
        let key = "\(i)-\(step[i])"
        if let c = specCache[key] { return c }
        let s = samples[i]
        let hours = decaySteps[step[i]]
        var bins = [Double](repeating: 0, count: 1000)
        var nuclides: [(String, Double)] = s.contents.filter { $0 != "NONE" }.map { ($0, 1.0) }
        nuclides += s.crossWith.map { ($0, 0.03) }
        nuclides.append(("K40", 0.04))   // environmental background in the shield
        var seed = UInt32(truncatingIfNeeded: i &* 2654435761 &+ 17)
        func rnd() -> Double { seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5; return Double(seed) / Double(UInt32.max) }
        for b in 0..<1000 { let e = Double(b) * 3; bins[b] = 25 * exp(-e / 380) + 2.5 }
        for (id, w0) in nuclides {
            let a = agent(id)
            guard let ys = gammaYield[id] else { continue }
            let decay = pow(0.5, hours / a.halfLifeH)
            let act = 6000 * w0 * (activityWeight[id] ?? 1) * decay
            for (j, e) in a.gammaKeV.enumerated() {
                let eff = e < 100 ? 0.4 + 0.6 * e / 100 : pow(e / 100, -0.75)
                let amp = act * ys[j] * eff
                let sig = 1.6 + 0.0009 * e
                let ec = e * (2 * e / 511) / (1 + 2 * e / 511)
                for b in 0..<1000 {
                    let x = Double(b) * 3
                    if x < ec { bins[b] += amp * 0.010 * (0.7 + 0.3 * x / ec) }
                    let z = (x - e) / sig
                    if abs(z) < 5 { bins[b] += amp * 0.9 * exp(-z * z / 2) }
                }
            }
        }
        for b in 0..<1000 { bins[b] *= (0.88 + 0.24 * rnd()) }
        specCache[key] = bins
        return bins
    }

    private func markPeak(_ i: Int) {
        let sp = spectrum(i)
        let c = Int(cursor / 3)
        var best = c
        for b in max(0, c - 4)...min(999, c + 4) where sp[b] > sp[best] { best = b }
        let lo = sp[max(0, best - 12)], hi = sp[min(999, best + 12)]
        let base = (lo + hi) / 2
        if sp[best] > base * 2.2 && sp[best] > 12 {
            // refine centroid
            var num = 0.0, den = 0.0
            for b in max(0, best - 2)...min(999, best + 2) { let w = max(0, sp[b] - base); num += Double(b) * 3 * w; den += w }
            let e = den > 0 ? num / den : Double(best) * 3
            if !marks[i].contains(where: { abs($0 - e) < 4 }) { marks[i].append(e); marks[i].sort() }
            Audio.shared.blip(1500, 0.05); note = "Peak marked at \(f(e, 1)) keV."
        } else { Audio.shared.deny(); note = "No significant peak at the cursor (net counts are within background)." }
    }

    // MARK: Chem / bio tests

    private func runTest(_ k: Int) {
        guard k < tests.count, busy == nil else { return }
        let s = samples[sel]
        if !hood && s.kind != .air && s.kind != .spectrum {
            contamination += 1
            note = bioMode ? "⚠ Sample opened on the open bench, outside the biosafety cabinet. Lab exposure logged."
                           : "⚠ Sample opened outside the fume hood. Analyst exposure logged."
            Audio.shared.deny()
        }
        busy = (k, 0); Audio.shared.blip(600, 0.3, 0.06)
    }
    private func finishTest(_ k: Int) {
        let test = tests[k]
        let s = samples[sel]
        let a = agent(s.primary)
        var r = agentField(a, test.key)
        if r == "—" { r = agentField(agent("CLEAN"), test.key) }
        if s.cross, let x = s.crossWith.first {
            if bioMode && x == "BA" && s.primary != "BA" {
                switch test.key {
                case "pcr": r = "pXO1 WEAK (Ct 37) · pXO2 WEAK (Ct 38) · chromosomal WEAK. Trace level, inconsistent with bulk powder."
                case "culture": r = "Two colonies resembling B. anthracis on an otherwise clean plate. Trace contamination?"
                case "hha": r = "Faint test line: indeterminate"
                default: r += " (rare rods seen)"
                }
            } else if test.key == "gcms" { r += " · minor peak: \(agent(x).name) (trace)" }
            else if !bioMode { r += " (+ faint secondary response)" }
        }
        results[sel][test.key] = r
        lastTest = test.key
        labMin += test.minutes
        Audio.shared.confirm()
        note = "\(test.name): done (+\(Int(test.minutes)) lab-min)."
    }

    // MARK: Input

    func keyDown(_ k: String) {
        if guide.key(k) { return }
        if k == "f" { guide.show(radMode ? 0 : (bioMode ? 2 : 1)); return }
        switch phase {
        case 0: if k == "enter" || k == "space" || k == "esc" { toBench() }
        case 1: benchKey(k)
        case 2:
            if k == "esc" && !samples.isEmpty { phase = 1; return }
            if let i = threatList.key(k) { threatPick = Threat.allCases[i]; phase = 3; Audio.shared.stamp() }
        default:
            if k == "esc" { phase = 2; return }
            if let i = protoList.key(k) { submit(i) }
        }
    }

    private func benchKey(_ k: String) {
        if var p = picker {
            if k == "esc" { picker = nil; return }
            if let i = p.key(k) { chosen[sel] = [candidates[i]]; picker = nil; note = "ID assigned: \(agent(candidates[i]).name)"; advanceSample() }
            else { picker = p }
            return
        }
        switch k {
        case "up", "w": sel = (sel + samples.count - 1) % samples.count; Audio.shared.blip(900, 0.02)
        case "down", "s": sel = (sel + 1) % samples.count; Audio.shared.blip(900, 0.02)
        case "tab": sel = (sel + 1) % samples.count
        case "x": phase = 2; Audio.shared.squelch()
        default: break
        }
        if radMode {
            let fast = Input.down("shift") ? 30.0 : 3.0
            switch k {
            case "left", "a": cursor = max(0, cursor - fast)
            case "right", "d": cursor = min(2997, cursor + fast)
            case "m": markPeak(sel)
            case "t": step[sel] = (step[sel] + 1) % decaySteps.count; labMin += 2; Audio.shared.blip(500, 0.1)
                note = step[sel] == 0 ? "Recount: reference time t0." : "Recount at t0 + \(fmtHours(decaySteps[step[sel]])): watch which peaks shrink."
            case "enter": if !chosen[sel].isEmpty { note = "ID confirmed for \(samples[sel].label)."; advanceSample() }
            default:
                if let n = Int(k), n >= 1, n <= candidates.count {
                    let id = candidates[n - 1]
                    if chosen[sel].contains(id) { chosen[sel].remove(id) } else {
                        if id == "NONE" { chosen[sel] = ["NONE"] } else { chosen[sel].remove("NONE"); chosen[sel].insert(id) }
                    }
                    Audio.shared.blip(1200, 0.03)
                }
            }
        } else {
            switch k {
            case "b": hood.toggle(); Audio.shared.blip(hood ? 1400 : 500, 0.08)
                note = hood ? (bioMode ? "Class II biosafety cabinet: sash down, airflow verified." : "Fume hood on: face velocity OK.") : "Working on the OPEN BENCH."
            case "i", "enter": picker = OptionList(candidates.map { agent($0).name })
            default: if let n = Int(k), n >= 1, n <= tests.count { runTest(n - 1) }
            }
        }
    }
    private func advanceSample() {
        if let nxt = (0..<samples.count).first(where: { chosen[$0].isEmpty }) { sel = nxt }
    }
    func mouseMoved(_ p: CGPoint) {
        if phase == 2 { threatList.hover(p) } else if phase == 3 { protoList.hover(p) }
        picker?.hover(p); guide.mouseMoved(p)
    }
    func mouseDown(_ p: CGPoint) {
        if phase == 0 { toBench(); return }
        if phase == 2, let i = threatList.click(p) { threatPick = Threat.allCases[i]; phase = 3; Audio.shared.stamp(); return }
        if phase == 3, let i = protoList.click(p) { submit(i); return }
        if phase == 1 && radMode && specRect.contains(p) { cursor = Double((p.x - specRect.minX) / specRect.width * 3000) }
        if phase == 1, var pk = picker, let i = pk.click(p) { chosen[sel] = [candidates[i]]; picker = nil; advanceSample() }
    }

    // MARK: Scoring

    private func submit(_ proto: Int) {
        var lr = LabResult()
        var total = 0.0
        for (i, s) in samples.enumerated() {
            let truth = Set(s.contents)
            let allowed = truth.union(s.crossWith)
            let ch = chosen[i]
            var ok: Bool
            var score: Double
            if radMode {
                let truthSet = truth.isEmpty ? ["NONE"] : truth
                ok = truthSet.isSubset(of: ch) && ch.isSubset(of: allowed.union(truthSet))
                let inter = Double(ch.intersection(truthSet).count), uni = Double(ch.union(truthSet).count)
                score = ok ? 1 : (uni > 0 ? inter / uni : 0)
            } else {
                ok = ch.count == 1 && (ch.first == s.primary || (s.primary == "CLEAN" && s.crossWith.contains(ch.first!)))
                score = ok ? 1 : 0
            }
            total += score
            let you = ch.isEmpty ? "no ID" : ch.map { agent($0).name }.sorted().joined(separator: ", ")
            let tru = (truth.isEmpty ? ["NONE"] : Array(truth)).map { agent($0).name }.sorted().joined(separator: ", ")
            lr.lines.append((s.label, ok, ok ? you : "you: \(you) · truth: \(tru)"))
        }
        lr.idScore = samples.isEmpty ? 0 : total / Double(samples.count)
        lr.threat = threatPick
        lr.threatCorrect = threatPick == run.def.threat(run.variant)
        lr.protoChoice = proto
        lr.protocolCorrect = run.def.bestProtocol(run.variant).contains(proto)
        lr.contamination = contamination
        lr.labMinutes = labMin
        run.lab = lr
        Audio.shared.reset()
        Game.shared.go(DeconScene(run))
    }

    func fmtHours(_ h: Double) -> String { h >= 48 ? "\(Int(h / 24)) d" : "\(Int(h)) h" }
}

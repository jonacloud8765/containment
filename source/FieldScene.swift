// CONTAINMENT — Part 2: hot-zone identification (simulation & input).
// Rendering lives in FieldDraw.swift.

import AppKit

struct Tox { let inh: Double; let skin: Double; let liq: Double; let cls: Int }   // cls: 0 cholinergic, 1 nicotinic, 2 irritant, 3 CNS, 4 bio
let toxTable: [String: Tox] = [
    "GB": Tox(inh: 0.05, skin: 0.03, liq: 0.5, cls: 0), "VX": Tox(inh: 0.05, skin: 0.05, liq: 0.9, cls: 0),
    "OPPEST": Tox(inh: 0.02, skin: 0.01, liq: 0.3, cls: 0), "NIC": Tox(inh: 0.02, skin: 0.004, liq: 0.6, cls: 1),
    "CL2": Tox(inh: 0.004, skin: 0.0002, liq: 0, cls: 2), "BENZENE": Tox(inh: 0.0002, skin: 0.00002, liq: 0.05, cls: 3),
    "BA": Tox(inh: 0.6, skin: 0, liq: 0, cls: 4),
]
let idlh: [String: Double] = ["CL2": 10, "BENZENE": 500, "CO": 1200]

struct Readings {
    var o2 = 20.9, lel = 0.0, co = 0.0, h2s = 0.0, s5 = 0.0
    var imsG = 0.0, imsH = 0.0, bio = 0.0, fluor = 0.0
    var rate = 0.0, nRate = 0.0, cpm = 50.0
}

enum FieldModal { case victim(Int), clue(Int), exitConfirm, pause, result(String) }

final class FieldScene: Scene {
    let run: MissionRun
    let lo: Loadout
    var m: FieldMap
    let rad: Bool
    var pos: CGPoint
    var facing: CGFloat = 0
    var cam = CGPoint.zero
    var speedNow: CGFloat = 0
    var simT = 0.0, realT = 0.0
    var air: Double, airMax: Double
    var hr = 82.0, heat = 0.0
    var dose = 0.0, nDose = 0.0
    var chol = 0.0, nic = 0.0, irritant = 0.0, cns = 0.0, bioDose = 0.0
    var skinTotal = 0.0, inhTotal = 0.0
    var atropineTox = 0.0, antidote = 0.0
    var injectors = 3
    var hypoxia = 0.0, coLoad = 0.0
    var suitContam = 0.0
    var glove: [String]? = nil
    var raw = Readings(), shown = Readings()
    var action: (kind: Int, idx: Int, prog: Double, total: Double)? = nil   // 0 sample, 1 task, 2 gloves
    var modal: FieldModal? = nil
    var modalOpts = OptionList([])
    var toasts: [(String, Double, NSColor)] = []
    var ash: [CGPoint] = []
    var incidents = Set<String>()
    var notebook = false
    var help = 8.0
    var guide = GuideOverlay()
    var samples: [Sample] = []
    var readingsLog: [String] = []
    var lowAirHit = false
    var gamma = 1.0, neutron = 1.0, shieldMul: [Int: Double] = [:]
    var ended = false
    var injectorsUsed = 0, needless = 0, gloveChanges = 0
    var lastLpm = 18.0
    var squad: [Squaddie] = []
    var rescued = 0
    var moveTo: CGPoint? = nil          // click-to-move destination
    var moveRoute: [CGPoint] = []
    var apRunning = 0.0                 // AP4C sampling cycle
    var apBands: [Double] = [0, 0, 0, 0]
    var fentStrip: (String, Double)? = nil
    var litterCount: Int { m.victims.filter { $0.litter }.count }
    /// Coarse navigation grid, built once, used for squad routing and click-to-move.
    var nav: [Bool] = []
    var navW = 0, navH = 0
    static let cell: CGFloat = 20

    init(_ r: MissionRun) {
        run = r
        lo = r.loadout!
        m = r.def.build(r.variant)
        rad = r.def.division == .nuclear
        pos = m.start
        if lo.resp == .scba { airMax = lo.cylinder.liters } else { airMax = lo.canister.lifeMin }
        air = airMax
        for _ in 0..<140 { ash.append(P(CGFloat.random(in: 0...W), CGFloat.random(in: 0...H))) }
        Audio.shared.reset()
        Audio.shared.breathRate = 14; Audio.shared.breathGain = lo.resp == .scba ? 0.75 : 0.45
        Audio.shared.wind = r.def.ambientWind; Audio.shared.rumble = r.def.ambientRumble
        Audio.shared.heartGain = 0.0
        if r.def.siren { Audio.shared.alarm = 4 }
        buildNav()
        squad = makeSquad()
        toast("ENTERING HOT ZONE: \(lo.suit.name) / \(lo.resp.short)", Pal.amber)
        if litterCount > 0 { toast("\(litterCount) stretcher case(s) reported. [T] orders a litter carry.", Pal.red) }
    }

    func toast(_ s: String, _ c: NSColor = Pal.green) {
        toasts.append((s, 6, c)); if toasts.count > 5 { toasts.removeFirst() }
    }
    func incident(_ s: String) { if incidents.insert(s).inserted { toast("⚠ " + s, Pal.red) } }

    var windVec: CGPoint {
        let a = (run.def.windDeg + 9 * sin(realT * 0.21) + 4 * sin(realT * 0.53)) * .pi / 180
        return CGPoint(x: cos(a), y: sin(a))
    }
    var timeScale: Double { run.timeScale }
    var paused: Bool { modal != nil || guide.open || notebook }

    // MARK: Geometry

    func blocked(_ p: CGPoint) -> Bool {
        let r: CGFloat = 13
        if p.x < r || p.y < r || p.x > m.size.width - r || p.y > m.size.height - r { return true }
        let box = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
        return m.walls.contains { $0.r.intersects(box) }
    }

    /// Product of wall transmissions along the straight line a→b.
    func transmission(_ a: CGPoint, _ b: CGPoint) -> Double {
        var t = 1.0
        for w in m.walls where segmentHits(a, b, w.r) { t *= w.shield }
        return t
    }
    func buildNav() {
        navW = Int(m.size.width / FieldScene.cell) + 1
        navH = Int(m.size.height / FieldScene.cell) + 1
        nav = [Bool](repeating: true, count: navW * navH)
        for gy in 0..<navH {
            for gx in 0..<navW {
                let p = P(CGFloat(gx) * FieldScene.cell + FieldScene.cell / 2, CGFloat(gy) * FieldScene.cell + FieldScene.cell / 2)
                nav[gy * navW + gx] = !blocked(p)
            }
        }
    }
    private func navIdx(_ p: CGPoint) -> (Int, Int) {
        (clamp(Int(p.x / FieldScene.cell), 0, navW - 1), clamp(Int(p.y / FieldScene.cell), 0, navH - 1))
    }
    /// Nearest open cell to p, so a goal sitting inside a prop still routes.
    private func openNear(_ p: CGPoint) -> (Int, Int)? {
        let (sx, sy) = navIdx(p)
        if nav[sy * navW + sx] { return (sx, sy) }
        for r in 1...6 {
            for dy in -r...r {
                for dx in -r...r where abs(dx) == r || abs(dy) == r {
                    let x = sx + dx, y = sy + dy
                    if x >= 0, y >= 0, x < navW, y < navH, nav[y * navW + x] { return (x, y) }
                }
            }
        }
        return nil
    }
    /// Breadth-first route between two world points, returned as waypoints. Empty if unreachable.
    func route(_ from: CGPoint, _ to: CGPoint) -> [CGPoint] {
        guard let s = openNear(from), let t = openNear(to), !nav.isEmpty else { return [] }
        if s == t { return [to] }
        var prev = [Int](repeating: -1, count: navW * navH)
        var seen = [Bool](repeating: false, count: navW * navH)
        var q = [s.1 * navW + s.0]
        seen[s.1 * navW + s.0] = true
        let goal = t.1 * navW + t.0
        var head = 0
        var found = false
        while head < q.count {
            let cur = q[head]; head += 1
            if cur == goal { found = true; break }
            let cx = cur % navW, cy = cur / navW
            for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let nx = cx + dx, ny = cy + dy
                guard nx >= 0, ny >= 0, nx < navW, ny < navH else { continue }
                let ni = ny * navW + nx
                if seen[ni] || !nav[ni] { continue }
                seen[ni] = true; prev[ni] = cur; q.append(ni)
            }
        }
        guard found else { return [] }
        var out: [CGPoint] = []
        var cur = goal
        while cur != -1 {
            let cx = cur % navW, cy = cur / navW
            out.append(P(CGFloat(cx) * FieldScene.cell + FieldScene.cell / 2, CGFloat(cy) * FieldScene.cell + FieldScene.cell / 2))
            if cur == s.1 * navW + s.0 { break }
            cur = prev[cur]
        }
        out.reverse()
        out.append(to)
        // string-pull: drop waypoints we can see past
        var simple: [CGPoint] = []
        var i = 0
        while i < out.count {
            var j = out.count - 1
            while j > i + 1 && !clearPath(out[i], out[j]) { j -= 1 }
            simple.append(out[j])
            if j == i { break }
            i = j
        }
        return simple
    }

    /// True when nothing solid sits on the straight line a→b.
    func clearPath(_ a: CGPoint, _ b: CGPoint) -> Bool {
        !m.walls.contains { segmentHits(a, b, $0.r.insetBy(dx: -14, dy: -14)) }
    }
    func segmentHits(_ a: CGPoint, _ b: CGPoint, _ r: CGRect) -> Bool {
        var t0: CGFloat = 0, t1: CGFloat = 1
        let dx = b.x - a.x, dy = b.y - a.y
        for (p, q) in [(-dx, a.x - r.minX), (dx, r.maxX - a.x), (-dy, a.y - r.minY), (dy, r.maxY - a.y)] {
            if p == 0 { if q < 0 { return false } } else {
                let u = q / p
                if p < 0 { t0 = max(t0, u) } else { t1 = min(t1, u) }
                if t0 > t1 { return false }
            }
        }
        return true
    }

    // MARK: Update

    func update(_ dt: Double) {
        if run.def.siren && realT > 10 && Audio.shared.alarm == 4 { Audio.shared.alarm = 0 }
        toasts = toasts.compactMap { $0.1 - dt > 0 ? ($0.0, $0.1 - dt, $0.2) : nil }
        if paused || ended { return }
        realT += dt
        help = max(0, help - dt)
        let dts = dt * timeScale
        simT += dts

        // ---- movement
        var mv = CGPoint.zero
        if Input.down("w") || Input.down("up") { mv.y -= 1 }
        if Input.down("s") || Input.down("down") { mv.y += 1 }
        if Input.down("a") || Input.down("left") { mv.x -= 1 }
        if Input.down("d") || Input.down("right") { mv.x += 1 }
        if mv.len > 0 { moveTo = nil; moveRoute = [] }        // keys always override a click
        if let t = moveTo {
            let d = t - pos
            if d.len < 14 {
                if !moveRoute.isEmpty { moveRoute.removeFirst() }
                moveTo = moveRoute.first
                if let nt = moveTo { mv = (nt - pos) * (1 / max(1, (nt - pos).len)) }
            } else { mv = d * (1 / d.len) }
        }
        let sprint = Input.down("shift")
        let impaired = (chol > 1 ? 0.75 : 1) * (nic > 1.5 ? 0.8 : 1) * (heat > 0.8 ? 0.8 : 1)
        var spd: CGFloat = 0
        if mv.len > 0 {
            mv = mv * (1 / mv.len)
            spd = 56 * CGFloat(lo.suit.mobility * impaired) * (sprint ? 1.85 : 1)
            facing = atan2(mv.y, mv.x)
            let step = mv * (spd * CGFloat(dt))
            let nx = CGPoint(x: pos.x + step.x, y: pos.y)
            if !blocked(nx) { pos = nx } else if moveTo != nil {
                let slide = CGPoint(x: pos.x, y: pos.y + (step.x > 0 ? 1 : -1) * abs(step.x))
                if !blocked(slide) { pos = slide }
            }
            let ny = CGPoint(x: pos.x, y: pos.y + step.y)
            if !blocked(ny) { pos = ny } else if moveTo != nil {
                let slide = CGPoint(x: pos.x + (step.y > 0 ? 1 : -1) * abs(step.y), y: pos.y)
                if !blocked(slide) { pos = slide }
            }
            if action != nil && action!.kind != 2 { action = nil; toast("Action interrupted: hold still.", Pal.amber) }
        }
        speedNow = spd


        // ---- actions
        if var a = action {
            a.prog += dt
            if a.prog >= a.total { completeAction(a.kind, a.idx); action = nil } else { action = a }
        }

        sense(dt)
        updateSquad(dt)
        if apRunning > 0 {
            apRunning -= dt
            if apRunning <= 0 { finishAP4C() }
        }
        if var fs = fentStrip { fs.1 -= dt; fentStrip = fs.1 > -8 ? fs : nil }
        physiology(dt, dts, moving: spd > 0, sprint: sprint && spd > 0)
        audioUpdate()

        // camera
        cam = CGPoint(x: clamp(pos.x - W / 2, 0, max(0, m.size.width - W)), y: clamp(pos.y - H / 2, 0, max(0, m.size.height - H)))
        for i in 0..<ash.count {
            ash[i].x += CGFloat(windVec.x * 30 * dt) + CGFloat.random(in: -0.4...0.4)
            ash[i].y += CGFloat(22 * dt)
            if ash[i].y > H { ash[i].y = 0; ash[i].x = CGFloat.random(in: 0...W) }
            if ash[i].x > W { ash[i].x = 0 } else if ash[i].x < 0 { ash[i].x = W }
        }
    }

    private func sense(_ dt: Double) {
        var r = Readings()
        // radiation
        var rate = 0.0, nr = 0.0
        for (i, s) in m.rad.enumerated() {
            let d = max(Double(pos.dist(s.p) / PX_PER_M), 0.5)
            let tr = transmission(pos, s.p)
            let att = [lo.suit.gammaLow, lo.suit.gammaMid, lo.suit.gammaHigh][s.band]
            let mul = shieldMul[i] ?? 1
            rate += s.rate / (d * d) * tr * (1 - att) * gamma * mul
            if s.neutron > 0 { nr += s.neutron / (d * d) * min(1, tr * 2) * (1 - lo.suit.neutron) * neutron }
        }
        var areaRate = 0.0
        for a in m.areas where a.r.contains(pos) { areaRate = a.rate }
        rate += areaRate * (1 - lo.suit.gammaMid) + 0.12
        r.rate = rate; r.nRate = nr
        var cpm = 50 + rate * 3
        var touching = 0.0
        for c in m.contam {
            let d = Double(pos.dist(c.p) / c.r)
            let v = c.cpm * exp(-d * d)
            cpm += v; if d < 1 { touching += v }
        }
        r.cpm = cpm
        if touching > 0 { suitContam += touching * 1e-6 * dt * (speedNow > 70 ? 2 : 1) }

        // chemical plumes
        let w = windVec
        for p in m.plumes {
            let rel = pos - p.p
            let along = Double(rel.x * w.x + rel.y * w.y)
            let cross = Double(abs(rel.x * -w.y + rel.y * w.x))
            let sp = Double(p.spread)
            var c: Double
            if along >= 0 {
                let sig = sp + along * 0.22
                c = p.q * (sp / sig) * exp(-cross * cross / (2 * sig * sig)) * exp(-along / Double(p.length))
            } else {
                c = p.q * exp(along / 40) * exp(-cross * cross / (2 * sp * sp))
            }
            if transmission(pos, p.p) < 0.5 { c *= 0.15 }
            switch p.agent {
            case "GB", "VX", "OPPEST": r.imsG += c; r.s5 += lo.sensor5 == .pid ? c * 0.2 : 0
            case "HD": r.imsH += c
            case "CL2": r.s5 += lo.sensor5 == .cl2 ? c : 0; r.h2s -= c * 0.2
            case "BENZENE": r.s5 += lo.sensor5 == .pid ? c : 0; r.lel += c / 12000 * 100
            case "NIC": r.s5 += lo.sensor5 == .pid ? c * 0.5 : 0
            case "SMOKE": r.co += c * 20; r.s5 += lo.sensor5 == .pid ? c * 4 : 0
            default: break
            }
            expose(p.agent, inhale: c, skinVapor: c, dt: dt)
        }
        for g in m.gas where g.r.contains(pos) {
            r.o2 = min(r.o2, g.o2); r.lel += g.lel; r.co += g.co; r.h2s += g.h2s
            switch lo.sensor5 {
            case .pid: r.s5 += g.voc
            case .cl2: r.s5 += g.cl2
            case .nh3: r.s5 += g.nh3
            case .hcn: r.s5 += g.hcn
            }
            if g.cl2 > 0 { r.h2s -= g.cl2 * 0.2; expose("CL2", inhale: g.cl2, skinVapor: g.cl2, dt: dt) }
            if g.voc > 1000 { expose("BENZENE", inhale: g.voc, skinVapor: g.voc, dt: dt) }
        }
        // liquids
        for pd in m.puddles where pos.dist(pd.p) < pd.r + 8 {
            let t = toxTable[pd.agent]
            let splash = speedNow > 70 ? 2.5 : 1
            let dose = pd.level * (t?.liq ?? 0) * (1 - lo.suit.liquid) * splash * dt * timeScale / 60
            addLoad(pd.agent, dose); skinTotal += dose
            suitContam += pd.level * 0.02 * dt
            if speedNow > 70 { incident("Ran through a liquid spill (splash)") }
            if !m.plumes.isEmpty { r.imsG += pd.agent == "GB" ? 8 : 0 }
        }
        // powders / bio aerosol
        for pw in m.powders {
            let d = Double(pos.dist(pw.p) / pw.r)
            if d < 3 {
                let stir = 0.25 + Double(speedNow) / 56 * 0.75
                let a = pw.level * exp(-d * d) * stir
                let fl = pw.agent == "BA" ? 0.85 : (pw.agent == "HOAX_STARCH" ? 0.35 : 0.08)
                r.bio += a * 400; r.fluor = max(r.fluor, fl * min(1, a * 3))
                if pw.agent == "BA" { expose("BA", inhale: a, skinVapor: 0, dt: dt) }
                suitContam += a * 0.01 * dt
                if speedNow > 70 && d < 1.2 { incident("Ran through powder (re-aerosolized spores)") }
            }
        }
        raw = r
        let k = 1 - exp(-dt / 0.9)
        shown.o2 += (r.o2 - shown.o2) * k; shown.lel += (r.lel - shown.lel) * k; shown.co += (r.co - shown.co) * k
        shown.h2s += (r.h2s - shown.h2s) * k; shown.s5 += (r.s5 - shown.s5) * k
        shown.imsG += (r.imsG - shown.imsG) * k; shown.imsH += (r.imsH - shown.imsH) * k
        shown.bio += (r.bio - shown.bio) * k; shown.fluor += (r.fluor - shown.fluor) * k
        shown.rate += (r.rate - shown.rate) * min(1, k * 2); shown.nRate += (r.nRate - shown.nRate) * min(1, k * 2)
        shown.cpm += (r.cpm - shown.cpm) * min(1, k * 2)

        // respiratory hazards for air-purifying respirators
        if lo.resp.airPurifying {
            if r.o2 < 19.5 {
                hypoxia += (19.5 - r.o2) * 0.08 * dt * timeScale / 60
                incident("Air-purifying respirator in an O2-deficient atmosphere (\(f(r.o2))%)")
            }
            if r.co > 35 {
                coLoad += r.co / 400 * dt * timeScale / 60
                incident("CBRN canisters don't remove carbon monoxide: CO \(Int(r.co)) ppm")
            }
        }
        dose += (r.rate / 1000) * (dt * timeScale / 3600)
        nDose += (r.nRate / 1000) * (dt * timeScale / 3600)
    }

    private func expose(_ agent: String, inhale c: Double, skinVapor: Double, dt: Double) {
        guard c > 0.001, let t = toxTable[agent] else { return }
        var apf = lo.resp.apf
        if lo.resp.airPurifying {
            if air <= 0 { apf = 1 }
            if let lim = idlh[agent], c > lim { apf /= 10; incident("Air-purifying respirator above IDLH (\(agent))") }
            air -= c * 0.002 * dt * timeScale / 60   // canister loading
        }
        let dm = dt * timeScale / 60
        let inh = c * t.inh / apf * dm
        let sk = skinVapor * t.skin * (1 - lo.suit.vapor) * dm
        inhTotal += inh; skinTotal += sk
        addLoad(agent, inh + sk)
    }
    private func addLoad(_ agent: String, _ v: Double) {
        guard let t = toxTable[agent] else { return }
        switch t.cls {
        case 0: chol += v
        case 1: nic += v
        case 2: irritant += v
        case 3: cns += v
        default: bioDose += v
        }
    }

    private func physiology(_ dt: Double, _ dts: Double, moving: Bool, sprint: Bool) {
        let dm = dts / 60
        let lpm = (sprint ? 88.0 : (moving ? 40.0 : (action != nil ? 28 : 18))) * lo.suit.airMult
            * (lo.resp == .scba ? lo.cylinder.exertion : 1) * (1 + heat * 0.25) * (1 + min(chol, 2) * 0.15)
        lastLpm = lpm
        if lo.resp == .scba { air -= lpm * dm } else { air -= dm }
        air = max(0, air)
        let frac = air / airMax
        if frac < 0.33 && !lowAirHit { lowAirHit = true; toast(lo.resp == .scba ? "LOW-AIR ALARM: 33% REMAINING. EXIT NOW." : "FILTER SERVICE LIFE LOW: EXIT", Pal.red) }
        heat += lo.suit.heat * (sprint ? 2.2 : (moving ? 1.0 : 0.55)) * (1 + atropineTox * 0.8) * dm / 38
        heat = max(0, heat - (lo.suit.encapsulated ? 0 : 0.002 * dm))
        let target = (sprint ? 162.0 : (moving ? 112 : 88)) + heat * 35 + atropineTox * 28 + (shown.rate > 10_000 ? 10 : 0)
            + (nic > 0.5 ? 25 : 0) - (nic > 2 ? 50 : 0)
        hr += (target - hr) * (1 - exp(-dt * 0.6))
        antidote = max(0, antidote - dm * 0.02)
        atropineTox = max(0, atropineTox - dm * 0.01)
        // forced extraction checks
        if lo.resp == .scba && air <= 0 { extract("SCBA air depleted. Rapid intervention team extraction.") }
        if heat >= 1 { extract("Heat exhaustion inside the suit. Buddy-assisted extraction.") }
        if chol - antidote * 1.2 >= 2.6 { extract("Incapacitated by nerve-agent exposure. Extracted by buddy team.") }
        if nic >= 3.2 { extract("Incapacitated by nicotine poisoning through the skin. Extracted.") }
        if hypoxia >= 1 { extract("Hypoxia: collapsed in an O2-deficient atmosphere on an air-purifying respirator.") }
        if coLoad >= 1 { extract("Carbon monoxide poisoning: a filter canister can't remove CO.") }
        if run.def.doseLimit > 0 {
            if dose + nDose > run.def.doseLimit { incident("Turn-back dose exceeded") }
            if dose + nDose > run.def.doseLimit * 2.5 { extract("Dose far past the turn-back limit. Ordered out by the radiation protection officer.") }
        }
        if simT > run.def.window * 60 { incident("Entry window exceeded") }
        if simT > (run.def.window + 6) * 60 { extract("Entry window overrun. Incident commander ordered an emergency withdrawal.") }
    }

    private func audioUpdate() {
        let au = Audio.shared
        let rtot = shown.rate + shown.nRate
        au.geigerCPS = rad ? min(1500, 2.5 * pow(rtot, 0.55)) : min(40, 2.5 * pow(shown.rate, 0.55))
        let inhale = hr / 6.2
        au.breathRate = clamp(inhale, 12, 38)
        au.heartBPM = hr; au.heartGain = hr > 130 ? (hr - 130) / 80 : 0
        let gasAlarm = shown.o2 < 19.5 || shown.o2 > 23.5 || shown.lel >= 10 || shown.co >= 35 || shown.h2s >= 10 || shown.s5 >= lo.sensor5.alarm || shown.imsG > 0.3 || shown.imsH > 0.3
        if run.def.siren && realT < 10 { return }
        if air / airMax < 0.33 { au.alarm = 2 }
        else if gasAlarm { au.alarm = 1 }
        else if rad && (shown.rate > 1_000 || (run.def.doseLimit > 0 && dose > run.def.doseLimit * 0.8)) { au.alarm = 3 }
        else { au.alarm = 0 }
    }

    // MARK: Interaction

    var nearest: (String, Int)? {
        let reach: CGFloat = 52
        if let i = m.samples.firstIndex(where: { !$0.taken && $0.p.dist(pos) < reach }) { return ("sample", i) }
        if let i = m.victims.firstIndex(where: { !$0.rescued && ($0.choice == nil || ($0.litter && $0.choice != nil)) && $0.p.dist(pos) < reach }) { return ("victim", i) }
        if let i = m.tasks.firstIndex(where: { !$0.done && $0.p.dist(pos) < reach }) { return ("task", i) }
        if let i = m.clues.firstIndex(where: { $0.p.dist(pos) < reach }) { return ("clue", i) }
        if let i = m.surveys.firstIndex(where: { !$0.logged && $0.p.dist(pos) < reach }) { return ("survey", i) }
        if m.exit.contains(pos) { return ("exit", 0) }
        return nil
    }

    func keyDown(_ k: String) {
        if guide.key(k) { return }
        if notebook { if ["tab", "esc", "n"].contains(k) { notebook = false }; return }
        if let md = modal { modalKey(md, k); return }
        switch k {
        case "e", "enter", "space": interact()
        case "t": if let v = nearestLitter() { orderLitter(v) } else { toast("No stretcher case in reach.", Pal.amber) }
        case "5": orderFollow()
        case "6": orderHold()
        case "p": startAP4C()
        case "o": runFentStrip()
        case "r":
            if let (kind, i) = nearest, kind == "survey" { logSurvey(i) } else { logSurvey(nil) }
        case "g": if action == nil { action = (2, 0, 0, 2.5); toast("Changing outer gloves…") }
        case "q": selfInject()
        case "tab", "n": notebook = true
        case "f": guide.show(rad ? 0 : 1)
        case "h": help = help > 0 ? 0 : 30
        case "esc": openModal(.pause)
        default: break
        }
    }
    func mouseMoved(_ p: CGPoint) { if modal != nil { modalOpts.hover(p) }; guide.mouseMoved(p) }
    func mouseDown(_ p: CGPoint) {
        if let md = modal { if let i = modalOpts.click(p) { modalPick(md, i) }; return }
        if guide.open || notebook { return }
        if p.y < 270 && p.x < 330 { return }            // HUD panels, not the world
        if p.y < 300 && p.x > W - 330 { return }
        let world = p + cam
        // clicking directly on something interactive walks there and acts on arrival
        if let i = m.victims.firstIndex(where: { $0.p.dist(world) < 30 && !$0.rescued }) {
            moveTo = m.victims[i].p
            if m.victims[i].litter && m.victims[i].choice != nil { orderLitter(i) }
            return
        }
        if let i = m.samples.firstIndex(where: { !$0.taken && $0.p.dist(world) < 26 }) { moveTo = m.samples[i].p; return }
        if blocked(world) { return }
        moveRoute = clearPath(pos, world) ? [world] : route(pos, world)
        moveTo = moveRoute.first
        if moveTo != nil { Audio.shared.blip(1500, 0.015, 0.05) }
    }

    func nearestLitter() -> Int? {
        m.victims.indices.filter { m.victims[$0].litter && !m.victims[$0].rescued }
            .min { m.victims[$0].p.dist(pos) < m.victims[$1].p.dist(pos) ? true : false }
    }

    // MARK: AP4C + fentanyl strip

    func startAP4C() {
        guard apRunning <= 0 else { return }
        apRunning = 3.2
        Audio.shared.spray(1.0)
        toast("AP4C sampling — hydrogen flame lit, drawing air…", Pal.cyan)
    }
    private func finishAP4C() {
        var b: [Double] = [0, 0, 0, 0]
        let w = windVec
        for pl in m.plumes {
            let rel = pos - pl.p
            let along = Double(rel.x * w.x + rel.y * w.y), cross = Double(abs(rel.x * -w.y + rel.y * w.x))
            guard along >= -60 else { continue }
            let sig = Double(pl.spread) + max(0, along) * 0.22
            let c = pl.q * (Double(pl.spread) / sig) * exp(-cross * cross / (2 * sig * sig)) * exp(-max(0, along) / Double(pl.length))
            for k in agent(pl.agent).bands { b[k] += c }
        }
        for pd in m.puddles where pos.dist(pd.p) < pd.r + 40 {
            for k in agent(pd.agent).bands { b[k] += pd.level * 14 }
        }
        for pw in m.powders where pos.dist(pw.p) < pw.r + 30 {
            for k in agent(pw.agent).bands { b[k] += pw.level * 6 }
        }
        // the AP4C is honest about interferents: fires and fuels push HNO and S
        for g in m.gas where g.r.contains(pos) {
            if g.co > 50 { b[3] += g.co / 40 }
            if g.voc > 800 { b[1] += g.voc / 1500 }
        }
        apBands = b
        let hits = (0..<4).filter { b[$0] > 1 }
        Audio.shared.confirm()
        if hits.isEmpty { toast("AP4C: no element bands above threshold.", Pal.green) }
        else {
            toast("AP4C: " + hits.map { ap4cBands[$0] }.joined(separator: " + ") + " band(s) — element only, not an agent ID.", Pal.red)
            readingsLog.append("T+\(clockStr(simT))  AP4C: " + hits.map { "\(ap4cBands[$0])" }.joined(separator: "+"))
        }
    }

    func runFentStrip() {
        guard fentStrip == nil || fentStrip!.1 < -0.5 else { return }
        var pos_ = false
        for pd in m.puddles where pos.dist(pd.p) < pd.r + 24 { if agent(pd.agent).fent.hasPrefix("POSITIVE") { pos_ = true } }
        for pw in m.powders where pos.dist(pw.p) < pw.r + 24 { if agent(pw.agent).fent.hasPrefix("POSITIVE") { pos_ = true } }
        for pl in m.plumes where pos.dist(pl.p) < 160 { if agent(pl.agent).fent.hasPrefix("POSITIVE") { pos_ = true } }
        let near = m.puddles.contains { pos.dist($0.p) < $0.r + 24 } || m.powders.contains { pos.dist($0.p) < $0.r + 24 }
        if !near { toast("Nothing here to put on a strip. Stand at a residue or powder.", Pal.amber); Audio.shared.deny(); return }
        fentStrip = (pos_ ? "POSITIVE" : "NEGATIVE", 9)
        readingsLog.append("T+\(clockStr(simT))  Fentanyl strip: \(pos_ ? "POSITIVE" : "negative") (screening only)")
        Audio.shared.blip(pos_ ? 1700 : 700, 0.12)
        toast(pos_ ? "FENTANYL STRIP: POSITIVE — screening only, confirm by GC-MS." : "Fentanyl strip: negative. A negative strip does not clear a powder.",
              pos_ ? Pal.red : Pal.green)
    }

    private func interact() {
        guard let (kind, i) = nearest else { return }
        switch kind {
        case "sample":
            action = (0, i, 0, m.samples[i].secs); toast("Collecting: \(m.samples[i].label). Hold still.")
        case "task": action = (1, i, 0, m.tasks[i].secs); toast("Working: \(m.tasks[i].name)…")
        case "victim":
            if m.victims[i].choice != nil && m.victims[i].litter { orderLitter(i) } else { openModal(.victim(i)) }
        case "clue": m.clues[i].read = true; openModal(.clue(i))
        case "survey": logSurvey(i)
        default: openModal(.exitConfirm)
        }
    }

    private func completeAction(_ kind: Int, _ i: Int) {
        switch kind {
        case 0:
            var s = m.samples[i]; s.taken = true; m.samples[i] = s
            let touch = [SampleKind.swab, .wipe, .soil, .evidence, .vial, .bio].contains(s.kind)
            var carried: [String] = []
            if touch, let gl = glove {
                carried = gl.filter { $0 != "CLEAN" && $0 != "NONE" && !s.contents.contains($0) }
            }
            let cross = !carried.isEmpty
            if touch { glove = s.contents }
            samples.append(Sample(label: s.label, kind: s.kind, contents: s.contents, crossWith: carried))
            Audio.shared.confirm()
            toast("Sealed & labelled: \(s.label) [\(s.kind.rawValue)]  \(samples.count)/\(run.def.required)", Pal.amber)
            if cross { readingsLog.append("NOTE: outer gloves not changed before \(s.label)") }
        case 1:
            m.tasks[i].done = true
            Audio.shared.confirm()
            switch m.tasks[i].effect {
            case "drain": gamma *= 0.3; neutron *= 0.05; toast("Cooling jacket drained. Neutron rate falling.", Pal.amber)
            case "boron": gamma *= 0.5; neutron = 0; toast("Boric acid injected. Criticality terminated.", Pal.amber)
            case "shield0": shieldMul[0] = 0.08; toast("Lead blanket placed. Dose rate at the shed cut ~90%.", Pal.amber)
            default: break
            }
        default:
            glove = nil; gloveChanges += 1; toast("Fresh outer gloves on.", Pal.green)
        }
    }

    private func logSurvey(_ i: Int?) {
        let rd = rad
            ? "γ \(fmtRate(shown.rate))" + (shown.nRate > 0.5 ? " · n \(fmtRate(shown.nRate))" : "") + " · " + fmtCpm(shown.cpm)
            : "IMS G\(bars(shown.imsG)) H\(bars(shown.imsH))"
        let gas = "O2 \(f(shown.o2))% LEL \(Int(shown.lel))% CO \(Int(shown.co)) H2S \(f(shown.h2s)) \(lo.sensor5.tag) \(f(shown.s5))"
        let name = i.map { m.surveys[$0].name } ?? "Ad-hoc (\(Int(pos.x / PX_PER_M)) m, \(Int(pos.y / PX_PER_M)) m)"
        readingsLog.append("T+\(clockStr(simT))  \(name): \(rd) | \(gas)")
        if let i = i { m.surveys[i].logged = true }
        Audio.shared.blip(1500, 0.05)
        toast("Reading logged: \(name)")
    }

    private func selfInject() {
        if rad { toast("KI is a tablet. You can't take it through a sealed facepiece. Exit first.", Pal.amber); return }
        guard injectors > 0 else { toast("No autoinjectors left.", Pal.red); return }
        injectors -= 1; injectorsUsed += 1
        Audio.shared.thud(0.25)
        if chol - antidote < 0.3 {
            needless += 1; atropineTox += 0.7
            incident("Self-injected atropine without nerve-agent signs (atropine toxicity)")
        } else {
            antidote += 0.8; chol = max(0, chol * 0.8)
            toast("DuoDote administered: secretions drying, chest easing.", Pal.amber)
        }
    }

    func openModal(_ md: FieldModal) {
        modal = md
        switch md {
        case .victim(let i): modalOpts = OptionList(m.victims[i].options)
        case .exitConfirm: modalOpts = OptionList(["Exit to the decon line", "Stay in the hot zone"])
        case .pause: modalOpts = OptionList(["Resume", "Abort mission (return to assignments)"])
        default: modalOpts = OptionList(["Close"])
        }
        Audio.shared.blip(800, 0.04)
    }
    private func modalKey(_ md: FieldModal, _ k: String) {
        if k == "esc" { if case .exitConfirm = md { modal = nil; return }; if case .pause = md { modal = nil; return }; if case .clue = md { modal = nil; return } }
        if let i = modalOpts.key(k) { modalPick(md, i) }
    }
    private func modalPick(_ md: FieldModal, _ i: Int) {
        switch md {
        case .victim(let v):
            m.victims[v].choice = i
            modal = nil
            toast("Triage logged: \(m.victims[v].name)", Pal.amber)
        case .exitConfirm:
            modal = nil
            if i == 0 { finish(extracted: false) }
        case .pause:
            modal = nil
            if i == 1 { ended = true; Audio.shared.reset(); Game.shared.go(MissionSelectScene()) }
        default: modal = nil
        }
    }

    func extract(_ why: String) {
        guard !ended else { return }
        incidents.insert("EXTRACTED: " + why)
        finish(extracted: true)
    }

    func finish(extracted: Bool) {
        guard !ended else { return }
        ended = true
        var fr = FieldResult()
        fr.samples = samples
        fr.airStart = airMax; fr.airLeft = air
        fr.lowAirAlarmHit = lowAirHit
        fr.dose = dose; fr.neutronDose = nDose
        fr.skinChem = skinTotal; fr.inhaledChem = inhTotal + bioDose
        fr.hypoxia = hypoxia; fr.coLoad = coLoad; fr.heat = heat
        fr.suitContam = suitContam + (rad ? min(1, dose / 50) * 0.3 : 0)
        fr.victims = m.victims
        fr.rescued = rescued
        fr.litters = litterCount
        fr.squadDown = squad.filter { $0.down }.count
        fr.surveysLogged = m.surveys.filter { $0.logged }.count; fr.surveysTotal = m.surveys.count
        fr.cluesRead = m.clues.filter { $0.read }.count; fr.cluesTotal = m.clues.count
        fr.tasksDone = m.tasks.filter { $0.done }.count; fr.tasksTotal = m.tasks.count
        fr.simMinutes = simT / 60
        fr.extracted = extracted
        fr.incidents = Array(incidents).sorted()
        fr.injectorsUsed = injectorsUsed; fr.needlessInjectors = needless
        fr.gloveChanges = gloveChanges
        fr.readings = readingsLog
        run.field = fr
        Audio.shared.reset()
        Game.shared.go(LabScene(run))
    }

    // MARK: Formatting

    func fmtRate(_ uSv: Double) -> String {
        if uSv >= 1_000_000 { return f(uSv / 1_000_000, 2) + " Sv/h" }
        if uSv >= 1_000 { return f(uSv / 1_000, uSv >= 100_000 ? 0 : 1) + " mSv/h" }
        return f(uSv, uSv >= 100 ? 0 : 2) + " µSv/h"
    }
    func bars(_ c: Double) -> Int { c < 0.05 ? 0 : Int(clamp(log10(c * 10 + 1) * 2.6, 1, 8)) }
    /// Contamination meters read out in kcpm / Mcpm rather than eight raw digits.
    func fmtCpm(_ v: Double) -> String {
        if v >= 1_000_000 { return f(v / 1_000_000, 1) + " Mcpm" }
        if v >= 10_000 { return f(v / 1_000, 0) + " kcpm" }
        return "\(Int(v)) cpm"
    }
    func clockStr(_ s: Double) -> String { String(format: "%02d:%02d", Int(s) / 60, Int(s) % 60) }
}

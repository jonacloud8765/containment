// CONTAINMENT — the entry squad. You are the commander; four responders follow you in,
// carry stretchers, and work casualties. Search & rescue: non-ambulatory casualties must be
// carried out to the decon line by two squad members on a litter.

import AppKit

enum SquadJob { case follow, holding, toStretcher, carrying, treating, waiting }

struct Squaddie {
    var route: [CGPoint] = []
    var reroute = 0.0
    var stuck = 0.0
    var name: String
    var role: String            // what they are rated for
    var p: CGPoint
    var facing: CGFloat = 0
    var job: SquadJob = .follow
    var target: CGPoint? = nil
    var victim: Int? = nil      // index into map victims
    var partner: Int? = nil     // index into squad
    var lead = false            // the front half of a litter pair
    var air = 1.0
    var dose = 0.0
    var exposure = 0.0
    var work = 0.0              // progress on the current task
    var says = ""
    var sayT = 0.0
    var down = false
    var color: NSColor = Pal.suitYel
}

let squadNames = [("ROUSSEL", "litter / breacher"), ("OKAFOR", "medic"), ("LINDQVIST", "survey / sampling"), ("TAN", "litter / decon")]

extension FieldScene {

    func makeSquad() -> [Squaddie] {
        var out: [Squaddie] = []
        for (i, n) in squadNames.enumerated() {
            let off = CGPoint(x: CGFloat(-34 - (i % 2) * 30), y: CGFloat((i / 2 == 0 ? -1 : 1) * 30))
            out.append(Squaddie(name: n.0, role: n.1, p: pos + off, color: lo.suit.color))
        }
        return out
    }

    func say(_ i: Int, _ s: String) {
        guard i < squad.count else { return }
        squad[i].says = s
        squad[i].sayT = 3.4
    }

    /// Nearest squad member not already busy with a casualty.
    func freeSquad(_ exclude: Set<Int> = []) -> [Int] {
        squad.indices.filter { !squad[$0].down && squad[$0].victim == nil && !exclude.contains($0) }
    }

    func updateSquad(_ dt: Double) {
        let dm = dt * timeScale / 60
        for i in squad.indices {
            var m = squad[i]
            m.sayT = max(0, m.sayT - dt)

            // Squad members take the same atmosphere you do, scaled by where they stand.
            if !m.down {
                var r = 0.0
                for (si, s) in self.m.rad.enumerated() {
                    let d = max(Double(m.p.dist(s.p) / PX_PER_M), 0.5)
                    r += s.rate / (d * d) * transmission(m.p, s.p) * (1 - lo.suit.gammaMid) * (shieldMul[si] ?? 1)
                }
                m.dose += r / 1000 * (dt * timeScale / 3600)
                for pl in self.m.plumes {
                    let rel = m.p - pl.p
                    let w = windVec
                    let along = Double(rel.x * w.x + rel.y * w.y), cross = Double(abs(rel.x * -w.y + rel.y * w.x))
                    if along >= 0 {
                        let sig = Double(pl.spread) + along * 0.22
                        let c = pl.q * (Double(pl.spread) / sig) * exp(-cross * cross / (2 * sig * sig)) * exp(-along / Double(pl.length))
                        if let t = toxTable[pl.agent] { m.exposure += c * t.inh / lo.resp.apf * dm }
                    }
                }
                m.air -= dm / (lo.resp == .scba ? lo.cylinder.liters / (44 * lo.suit.airMult) : airMax)
                m.air = max(0, m.air)
                if m.air <= 0 || m.exposure > 2.2 || m.dose > (run.def.doseLimit > 0 ? run.def.doseLimit * 1.6 : 1e9) {
                    m.down = true
                    m.job = .holding
                    incident("Squad member \(m.name) went down in the hot zone")
                    say(i, "I'M IN TROUBLE —")
                    Audio.shared.deny()
                }
            }

            // Behaviour
            var dest: CGPoint? = nil
            var finalDest: CGPoint? = nil
            var speed: CGFloat = 54 * CGFloat(lo.suit.mobility)
            switch m.job {
            case .follow:
                let slot = CGPoint(x: CGFloat(-40 - (i % 2) * 34), y: CGFloat((i / 2 == 0 ? -1 : 1) * 34))
                let want = pos + slot
                if m.p.dist(want) > 26 { dest = want; speed = m.p.dist(pos) > 240 ? 86 : 54 }
            case .holding, .waiting:
                break
            case .toStretcher:
                if let v = m.victim { finalDest = self.m.victims[v].p + (m.lead ? P(-26, 0) : P(26, 0)) }
                if let v = m.victim, m.p.dist(self.m.victims[v].p) < 46 {
                    if let pi = m.partner, squad[pi].p.dist(self.m.victims[v].p) < 50 {
                        m.job = .carrying
                        if m.lead { say(i, "On three — lift!") }
                    }
                }
            case .carrying:
                if let v = m.victim {
                    if !m.lead, let li = m.partner, li < squad.count, squad[li].job == .carrying {
                        // tethered to the lead — one stretcher, fixed spacing, no independent pathing
                        let lead = squad[li]
                        m.p = lead.p - CGPoint(x: cos(lead.facing), y: sin(lead.facing)) * 42
                        m.facing = lead.facing
                        squad[i] = m
                        continue
                    }
                    finalDest = P(self.m.exit.midX, self.m.exit.midY)
                    // the lead carries the casualty's position with them
                    if m.lead {
                        let d2 = finalDest! - m.p
                        let step = d2.len > 1 ? d2 * (1 / d2.len) : .zero
                        self.m.victims[v].p = m.p + step * 22
                    }
                    speed = 36 * CGFloat(lo.suit.mobility)
                    if m.p.dist(P(self.m.exit.midX, self.m.exit.midY)) < 70 {
                        if m.lead {
                            rescued += 1
                            self.m.victims[v].rescued = true
                            toast("\(self.m.victims[v].name) carried out to the decon line (\(rescued)/\(litterCount))", Pal.green)
                            Audio.shared.confirm()
                            say(i, "Casualty across the line.")
                        }
                        m.victim = nil; m.partner = nil; m.job = .follow; m.lead = false
                    }
                }
            case .treating:
                m.work += dt
                if m.work > 3 {
                    m.work = 0; m.job = .follow
                    if let v = m.victim { say(i, "\(self.m.victims[v].name) packaged.") }
                    m.victim = nil
                }
            }

            if let fd = finalDest {
                if clearPath(m.p, fd) { dest = fd; m.route = [] }
                else {
                    m.reroute -= dt
                    if m.route.isEmpty || m.reroute <= 0 {
                        m.route = route(m.p, fd)
                        m.reroute = 1.2
                    }
                    while let first = m.route.first, m.p.dist(first) < 16 { m.route.removeFirst() }
                    dest = m.route.first ?? fd
                }
            }
            if let d = dest, !m.down {
                let delta = d - m.p
                if delta.len > 4 {
                    let dir = delta * (1 / delta.len)
                    m.facing = atan2(dir.y, dir.x)
                    let step = dir * (speed * CGFloat(dt))
                    let before = m.p
                    let full = m.p + step
                    if !blocked(full) { m.p = full }
                    else {
                        let nx = CGPoint(x: m.p.x + step.x, y: m.p.y)
                        if !blocked(nx) { m.p = nx }
                        let ny = CGPoint(x: m.p.x, y: m.p.y + step.y)
                        if !blocked(ny) { m.p = ny }
                        if m.p.dist(before) < 0.1 {
                            // squeeze perpendicular to find a door edge, both ways, always checked
                            let perp = CGPoint(x: -dir.y, y: dir.x) * (speed * CGFloat(dt))
                            for cand in [m.p + perp, m.p - perp] where !blocked(cand) { m.p = cand; break }
                        }
                    }
                    if m.p.dist(before) < 0.4 {
                        m.stuck += dt
                        if m.stuck > 0.4 { m.route = []; m.reroute = 0; m.stuck = 0 }
                    } else { m.stuck = 0 }
                }
            }
            squad[i] = m
        }
    }

    /// Order the two nearest free members to litter-carry this casualty out.
    func orderLitter(_ v: Int) {
        guard m.victims[v].litter, !m.victims[v].rescued else { return }
        if m.victims.indices.contains(v), squad.contains(where: { $0.victim == v }) {
            toast("A pair is already on \(m.victims[v].name).", Pal.amber); return
        }
        let free = freeSquad().sorted { squad[$0].p.dist(m.victims[v].p) < squad[$1].p.dist(m.victims[v].p) }
        guard free.count >= 2 else {
            toast("Not enough free hands — a litter takes two. Recall the squad with [5].", Pal.red)
            Audio.shared.deny(); return
        }
        let (a, b) = (free[0], free[1])
        squad[a].victim = v; squad[a].partner = b; squad[a].lead = true; squad[a].job = .toStretcher
        squad[b].victim = v; squad[b].partner = a; squad[b].lead = false; squad[b].job = .toStretcher
        say(a, "Litter on \(m.victims[v].name).")
        toast("\(squad[a].name) + \(squad[b].name): litter carry — \(m.victims[v].name) to the decon line.", Pal.amber)
        Audio.shared.blip(1300, 0.06)
    }

    func orderHold() {
        for i in squad.indices where squad[i].victim == nil && !squad[i].down { squad[i].job = .holding }
        toast("Squad holding position.", Pal.amber)
        Audio.shared.blip(800, 0.05)
    }
    func orderFollow() {
        for i in squad.indices where squad[i].victim == nil && !squad[i].down { squad[i].job = .follow }
        toast("Squad on me.", Pal.amber)
        Audio.shared.blip(1100, 0.05)
    }

    func drawSquad(_ g: G) {
        for (i, m) in squad.enumerated() {
            // litter poles between a carrying pair
            if m.job == .carrying, m.lead, let pi = m.partner, pi < squad.count {
                let o = squad[pi].p
                let d = (o - m.p)
                if d.len > 1 {
                    let n = CGPoint(x: -d.y, y: d.x) * (1 / d.len)
                    g.line(m.p + n * 10, o + n * 10, Pal.grey, 3)
                    g.line(m.p - n * 10, o - n * 10, Pal.grey, 3)
                    let mid = (m.p + o) * 0.5
                    g.roundRect(R(mid.x - 20, mid.y - 9, 40, 18), 4, Pal.white.a(0.75))
                    g.fill(R(mid.x - 14, mid.y - 5, 28, 10), rgba(0.75, 0.25, 0.25))
                }
            }
            g.circle(m.p + P(2, 3), 12, Pal.black.a(0.35))
            g.save(); g.ctx.translateBy(x: m.p.x, y: m.p.y); g.ctx.rotate(by: m.facing)
            g.circle(.zero, 11, m.down ? Pal.grey : m.color.blended(withFraction: 0.18, of: .black)!)
            g.ring(.zero, 11, m.down ? Pal.red : lo.suit.trim, 1.6)
            g.ctx.setFillColor(Pal.cyan.a(0.7).cgColor)
            g.ctx.beginPath(); g.ctx.addArc(center: .zero, radius: 8, startAngle: -0.7, endAngle: 0.7, clockwise: false)
            g.ctx.addLine(to: .zero); g.ctx.fillPath()
            g.restore()
            let tag = "\(i + 1) " + m.name
            g.text(tag, m.p.x, m.p.y + 14, 10, m.down ? Pal.red : Pal.white.a(0.8), align: .center)
            if m.down { g.text("DOWN", m.p.x, m.p.y - 28, 11, Pal.red, bold: true, align: .center) }
            if m.sayT > 0 {
                let w = CGFloat(m.says.count) * G.charW(11, true) + 14
                g.roundRect(R(m.p.x - w / 2, m.p.y - 44, w, 18), 4, Pal.black.a(0.75))
                g.text(m.says, m.p.x, m.p.y - 40, 11, Pal.amber, bold: true, align: .center)
            }
        }
    }

    /// Squad strip in the HUD.
    func drawSquadPanel(_ g: G, _ r: CGRect) {
        g.fill(r, rgba(0.01, 0.03, 0.02, 0.72))
        g.stroke(r, Pal.green.a(0.6), 1)
        g.text("SQUAD // YOU ARE COMMANDER", r.minX + 8, r.minY + 5, 11, Pal.green, bold: true)
        for (i, m) in squad.enumerated() {
            let y = r.minY + 22 + CGFloat(i) * 21
            let job: String
            switch m.job {
            case .follow: job = "on me"
            case .holding: job = m.down ? "DOWN" : "holding"
            case .toStretcher: job = "to casualty"
            case .carrying: job = "carrying"
            case .treating: job = "treating"
            case .waiting: job = "standby"
            }
            let c: NSColor = m.down ? Pal.red : (m.air < 0.33 ? Pal.amber : Pal.green)
            g.text("\(i + 1) \(m.name)", r.minX + 10, y, 11, c, bold: true)
            g.text(job, r.minX + 120, y, 11, m.job == .carrying ? Pal.amber : Pal.greenDim)
            g.bar(R(r.minX + 212, y + 2, 50, 7), m.air, c)
            g.text(lo.resp == .scba ? "\(Int(m.air * 100))%" : "\(Int(m.air * 100))%", r.maxX - 8, y, 10, c, align: .right)
        }
        let litters = m.victims.filter { $0.litter }
        let out = litters.filter { $0.rescued }.count
        g.text("STRETCHER CASES  \(out)/\(litters.count) OUT", r.minX + 10, r.maxY - 18, 11,
               out == litters.count ? Pal.green : Pal.amber, bold: true)
    }
}

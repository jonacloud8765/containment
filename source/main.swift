// CONTAINMENT — app entry point, window, menu bar and the frame loop.
// A headless self-test (--selftest) walks every scene without opening a window.

import AppKit
import QuartzCore
import ImageIO

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var view: GameView!
    var timer: CVDisplayLink?
    var last = CACurrentMediaTime()
    var fpsTimer: Timer?

    func applicationDidFinishLaunching(_ n: Notification) {
        let style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800), styleMask: style, backing: .buffered, defer: false)
        window.title = "CONTAINMENT — CBRN Emergency Response Simulation"
        window.center()
        window.minSize = NSSize(width: 800, height: 500)
        window.backgroundColor = .black
        window.isReleasedWhenClosed = false
        view = GameView(frame: NSRect(x: 0, y: 0, width: 1280, height: 800))
        window.contentView = view
        window.makeFirstResponder(view)
        window.makeKeyAndOrderFront(nil)
        buildMenu()
        Audio.shared.start()
        Game.shared.go(TitleScene())
        // 60 Hz frame loop on the main run loop (cheap and predictable; no Metal, no CVDisplayLink thread).
        fpsTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(fpsTimer!, forMode: .common)
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = min(0.05, now - last)
        last = now
        Game.shared.update(dt)
        view.present(Game.shared.render())
    }

    func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About CONTAINMENT", action: #selector(about), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Toggle Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        appMenu.addItem(withTitle: "Mute / Unmute Audio", action: #selector(mute), keyEquivalent: "m")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Erase Saved Clearance", action: #selector(erase), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit CONTAINMENT", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)
        NSApp.mainMenu = main
    }
    @objc func about() {
        let a = NSAlert()
        a.messageText = "CONTAINMENT"
        a.informativeText = """
        A CBRN emergency-response training simulation.

        Scenarios are simplified reconstructions of public historical events and composite industrial accidents, played with current-generation equipment. Protection factors, alarm points, dose guidelines and countermeasures follow published responder references (OSHA, NIOSH, CDC/CHEMM/REMM, DOT ERG, EPA PAG).

        This is a game, not operational guidance.
        """
        a.runModal()
    }
    @objc func mute() { Audio.shared.muted.toggle() }
    @objc func erase() {
        let a = NSAlert()
        a.messageText = "Erase saved clearance and mission grades?"
        a.addButton(withTitle: "Erase"); a.addButton(withTitle: "Cancel")
        if a.runModal() == .alertFirstButtonReturn {
            UserDefaults.standard.removeObject(forKey: GameState.key)
            Game.shared.state = GameState()
            Game.shared.go(TitleScene())
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }
}

// MARK: - Headless self-test

func selfTest() -> Int32 {
    var failures: [String] = []
    let g = Game.shared
    g.headless = true
    // Drawing every simulated frame would make the test minutes long, so update every frame
    // (that's what the logic needs) and render a sample of them (that's what catches draw crashes).
    var frameNo = 0
    func frames(_ n: Int, _ dt: Double = 1.0 / 60) {
        for _ in 0..<n {
            autoreleasepool {
                g.update(dt)
                frameNo += 1
                if frameNo % 15 == 0 { _ = g.render() }
            }
        }
    }
    func check(_ cond: Bool, _ msg: String) { if !cond { failures.append(msg) } }

    print("CONTAINMENT self-test")
    print("• agents in reference guide: \(agents.count)")
    check(agents.count > 20, "agent table too small")
    for (id, a) in agents where a.kind == .isotope && id != "NONE" {
        check(!a.gammaKeV.isEmpty, "\(id) has no gamma lines")
        check(a.halfLifeH > 0, "\(id) has no half-life")
        check(gammaYield[id] == nil || gammaYield[id]!.count == a.gammaKeV.count, "\(id) yield/line count mismatch")
    }
    // menus
    g.go(TitleScene()); frames(30)
    g.go(ScreeningScene())
    for _ in 0..<questions.count {
        g.keyDown("enter"); frames(2)
        if let sc = g.scene as? ScreeningScene, sc.cur.multi { sc.opts.sel = 0; g.keyDown("enter"); frames(1); sc.opts.sel = sc.opts.items.count - 1 }
        g.keyDown("enter"); frames(2)
    }
    check(g.scene is ClearanceScene, "screening did not reach clearance")
    frames(120); g.keyDown("enter")
    check(g.scene is AcademyScene, "clearance did not route into the academy")
    // walk the academy: every lesson page, then answer the exam correctly
    if let ac = g.scene as? AcademyScene {
        g.keyDown("enter"); frames(2)
        for _ in 0..<lessons.count { ac.reveal = 1e9; frames(1); g.keyDown("enter"); frames(2) }
        check(ac.mode == .exam, "academy did not reach the examination")
        for qi in 0..<examQs.count {
            check(examQs[qi].right < examQs[qi].a.count, "exam item \(qi) has a right index out of range")
            g.keyDown("\(examQs[qi].right + 1)"); frames(2); g.keyDown("enter"); frames(2)
        }
        check(ac.mode == .result, "academy did not reach a result")
        check(ac.correct == examQs.count, "ideal academy run scored \(ac.correct)/\(examQs.count)")
        g.keyDown("enter"); frames(2)
        check(ac.mode == .badge, "passing the academy did not issue a badge")
        check(Game.shared.state.trained, "academy pass did not set the trained flag")
        g.keyDown("enter"); frames(2)
    }
    check(g.scene is MissionSelectScene, "academy did not reach the duty roster")
    // red alert gate
    if let ms = g.scene as? MissionSelectScene { _ = ms; g.keyDown("enter"); frames(5) }
    check(g.scene is RedAlertScene, "accepting a callout did not raise a red alert")
    g.keyDown("enter"); frames(2); g.keyDown("enter"); frames(2)
    check(g.scene is BriefingScene, "red alert did not lead into the briefing")

    for def in missionDefs {
        for v in 0..<def.variants {
            let run = MissionRun(def, variant: v)
            let label = "\(def.id)/v\(v)"
            check(!def.briefing(v).isEmpty, "\(label) empty briefing")
            check(def.required > 0, "\(label) requires no samples")
            let map = def.build(v)
            check(map.samples.count >= def.required, "\(label) has fewer sample points (\(map.samples.count)) than required (\(def.required))")
            check(!def.bestProtocol(v).isEmpty, "\(label) has no correct protocol")
            check(def.bestProtocol(v).allSatisfy { $0 < def.protocols.count }, "\(label) best protocol out of range")
            check(!def.history(v).isEmpty, "\(label) has no history note")
            // every sample's contents must be identifiable from the candidate list
            for s in map.samples {
                for c in s.contents {
                    check(def.candidates.contains(c), "\(label) sample '\(s.label)' contains \(c), not in the candidate list")
                    check(agents[c] != nil, "\(label) unknown agent id \(c)")
                }
            }
            for vi in map.victims {
                check(!vi.best.isEmpty, "\(label) victim \(vi.name) has no correct option")
                check(vi.best.allSatisfy { $0 < vi.options.count }, "\(label) victim \(vi.name) best index out of range")
                check(!vi.why.isEmpty, "\(label) victim \(vi.name) has no explanation")
            }
            // start position must be walkable
            let fm = map
            check(!fm.walls.contains { $0.r.insetBy(dx: -13, dy: -13).contains(fm.start) }, "\(label) start position is inside a wall")

            // play it: briefing → loadout → field → lab → decon → report
            g.go(BriefingScene(run)); frames(20); g.keyDown("enter"); frames(5); g.keyDown("3"); frames(5); g.keyDown("enter")
            check(g.scene is LoadoutScene, "\(label) briefing did not reach loadout")
            frames(5); g.keyDown("down"); g.keyDown("down"); g.keyDown("down"); g.keyDown("down"); g.keyDown("enter")
            guard let field = g.scene as? FieldScene else { failures.append("\(label) did not reach the field"); continue }
            frames(10)
            // teleport to each sample, collect, read clues, triage, log readings
            for i in 0..<field.m.samples.count {
                field.pos = field.m.samples[i].p
                frames(2); field.keyDown("e")
                frames(Int(field.m.samples[i].secs * 70))
            }
            check(field.samples.count == field.m.samples.count, "\(label) collected \(field.samples.count) of \(field.m.samples.count) samples")
            for i in 0..<field.m.clues.count { field.pos = field.m.clues[i].p; frames(2); field.keyDown("e"); frames(2); field.keyDown("enter"); frames(2) }
            for i in 0..<field.m.surveys.count { field.pos = field.m.surveys[i].p; frames(2); field.keyDown("r"); frames(2) }
            for i in 0..<field.m.victims.count {
                field.pos = field.m.victims[i].p; frames(2); field.keyDown("e"); frames(2)
                let b = (field.m.victims[i].best.first ?? 0) + 1
                field.keyDown("\(b)"); frames(2)
                if field.m.victims[i].litter { field.orderLitter(i); frames(2) }   // dispatch the carry at once
            }
            for i in 0..<field.m.tasks.count { field.pos = field.m.tasks[i].p; frames(2); field.keyDown("e"); frames(Int(field.m.tasks[i].secs * 70)) }
            check(field.squad.count == 4, "\(label) squad did not form up")
            field.keyDown("p"); frames(240)                      // AP4C cycle
            field.keyDown("o"); frames(5)                        // fentanyl strip
            // let the litter pairs finish their carry; dispatch any that are still waiting
            var rescueGuard = 0
            while !field.ended && field.rescued < field.litterCount && rescueGuard < 60 {
                let busy = Set(field.squad.compactMap { $0.victim })
                if let vi = field.m.victims.indices.first(where: { field.m.victims[$0].litter && !field.m.victims[$0].rescued && !busy.contains($0) }) {
                    field.orderLitter(vi)
                }
                frames(60)
                rescueGuard += 1
            }
            check(field.rescued == field.litterCount,
                  "\(label) rescued \(field.rescued) of \(field.litterCount) stretcher cases (ended=\(field.ended), sim=\(Int(field.simT / 60))min)")
            check(field.m.tasks.allSatisfy { $0.done }, "\(label) field tasks did not complete")
            field.pos = P(field.m.exit.midX, field.m.exit.midY)
            frames(3); field.keyDown("e"); frames(3); field.keyDown("1"); frames(5)
            guard let lab = g.scene as? LabScene else { failures.append("\(label) did not reach the lab"); continue }
            frames(500)   // transport cutscene
            check(lab.phase == 1, "\(label) lab did not reach the bench")
            // analyze every sample correctly
            for si in 0..<lab.samples.count {
                lab.sel = si
                if lab.radMode {
                    for st in 0..<lab.decaySteps.count { _ = lab.spectrum(si); if st > 0 { lab.keyDown("t") } }
                    lab.step[si] = 0
                    // mark each true gamma line
                    for id in lab.samples[si].contents {
                        for e in agent(id).gammaKeV {
                            lab.cursor = e; lab.keyDown("m"); frames(1)
                        }
                        if let n = lab.candidates.firstIndex(of: id) { lab.keyDown("\(n + 1)"); frames(1) }
                    }
                } else {
                    lab.keyDown("b")
                    for ti in 1...lab.tests.count { lab.keyDown("\(ti)"); frames(80) }
                    lab.keyDown("i"); frames(2)
                    if let n = lab.candidates.firstIndex(of: lab.samples[si].primary) { lab.keyDown("\(n + 1)"); frames(2) }
                }
            }
            check(lab.chosen.allSatisfy { !$0.isEmpty }, "\(label) some samples left unidentified in the self-test")
            lab.keyDown("x"); frames(3)
            check(lab.phase == 2, "\(label) lab did not reach threat classification")
            let tIdx = (Threat.allCases.firstIndex(of: def.threat(v)) ?? 0) + 1
            lab.keyDown("\(tIdx)"); frames(3)
            check(lab.phase == 3, "\(label) lab did not reach protocol selection")
            lab.keyDown("\((def.bestProtocol(v).first ?? 0) + 1)"); frames(5)
            guard let dec = g.scene as? DeconScene else { failures.append("\(label) did not reach decon"); continue }
            frames(5)
            if dec.confined { dec.keyDown("enter"); frames(2) }
            else {
                var pguard = 0
                while dec.phase == 0 && pguard < 12 {
                    dec.keyDown("\(dec.posts[dec.pi].best + 1)"); frames(2)
                    if dec.showWhy != nil { failures.append("\(label) decon post \(dec.posts[dec.pi].title): best choice rejected"); dec.keyDown("enter"); frames(2) }
                    pguard += 1
                }
            }
            check(dec.phase == 1, "\(label) decon did not reach the stations (phase \(dec.phase))")
            for _ in 0..<dec.stations.count {
                guard dec.phase == 1 else { break }
                let s = dec.stations[dec.idx]
                let best = (s.best.first ?? 0) + 1
                dec.keyDown("\(best)"); frames(3)
                if dec.showWhy != nil { failures.append("\(label) station \(s.name): best option rejected"); dec.keyDown("enter"); frames(2) }
            }
            check(dec.phase == 2, "\(label) decon did not reach doffing (phase \(dec.phase))")
            var guardCount = 0
            while dec.phase == 2 && guardCount < 20 {
                let want = dec.order[dec.picked.count]
                if let i = dec.orderList.items.firstIndex(of: want) {
                    dec.orderList.sel = i
                    dec.keyDown("enter"); frames(2)
                    if dec.showWhy != nil { failures.append("\(label) doffing: correct step rejected (\(want))"); dec.keyDown("enter") }
                } else { failures.append("\(label) doffing: next step missing from the list"); break }
                guardCount += 1
            }
            check(dec.phase == 3, "\(label) doffing did not complete")
            check((dec.run.decon?.errors.isEmpty ?? false), "\(label) perfect decon play still logged errors: \(dec.run.decon?.errors ?? [])")
            check((dec.run.decon?.score ?? 0) > 0.9, "\(label) perfect decon scored only \(f((dec.run.decon?.score ?? 0) * 100))%")
            dec.keyDown("enter"); frames(3)
            guard let rep = g.scene as? ReportScene else { failures.append("\(label) did not reach the report"); continue }
            frames(200)
            let grade = rep.gr
            check(grade.total > 0.75, "\(label) ideal play graded only \(Int(grade.total * 100))% (\(grade.letter)); rows: " +
                  grade.rows.map { "\($0.0)=\(Int($0.1 * 100))" }.joined(separator: ", "))
            check(!grade.outcome.contains("FAILED"), "\(label) ideal play reported failure: \(grade.outcome)")
            rep.page = 1; frames(5); _ = g.render(); rep.page = 0
            print("• \(label) \(def.title): ideal play → \(grade.letter) (\(Int(grade.total * 100))%)")
        }
    }
    // guide pages
    let gs = GuideScene(back: { TitleScene() })
    g.go(gs)
    for c in 0..<4 { gs.guide.show(c); for _ in 0..<max(1, gs.guide.list.items.count) { frames(1); gs.keyDown("down") } }
    // A deliberately bad run must be graded down, or the report means nothing.
    if let def = missionDefs.first(where: { $0.id == "C2" }) {
        let run = MissionRun(def, variant: 0)
        run.loadout = Loadout(suit: allSuits.first { $0.id == "HS-C" }!, resp: .papr, cylinder: cylinders[0],
                              canister: canisters[1], sensor5: .cl2)
        g.go(BriefingScene(run)); frames(10); g.keyDown("enter"); frames(2); g.keyDown("1"); frames(2); g.keyDown("enter")
        if let f = g.scene as? LoadoutScene { _ = f; g.go(FieldScene(run)) }
        if let field = g.scene as? FieldScene {
            field.pos = field.m.puddles.first.map { $0.p } ?? field.pos    // stand in the sarin puddle
            for _ in 0..<40 { field.keyDown("q") }                         // atropine with no indication
            frames(900)
            if !field.ended { field.finish(extracted: false) }
        }
        if let lab = g.scene as? LabScene {
            frames(460); lab.keyDown("x"); frames(2)
            lab.keyDown("3"); frames(2)                                    // wrong classification
            lab.keyDown("3"); frames(5)                                    // wrong protocol
        }
        if let dec = g.scene as? DeconScene {
            if dec.confined { dec.keyDown("enter"); frames(2) }
            while dec.phase == 0 {
                let p = dec.posts[dec.pi]
                let bad = (0..<p.candidates.count).first { $0 != p.best } ?? 0
                dec.keyDown("\(bad + 1)"); frames(2)
                if dec.showWhy != nil { dec.keyDown("enter"); frames(2) }
            }
            while dec.phase == 1 {
                let s = dec.stations[dec.idx]
                let bad = (0..<s.options.count).first { !s.best.contains($0) && !s.ok.contains($0) } ?? 0
                dec.keyDown("\(bad + 1)"); frames(2)
                if dec.showWhy != nil { dec.keyDown("enter"); frames(2) }
            }
            while dec.phase == 2 {                                          // mask off first: the cardinal error
                dec.orderList.sel = dec.orderList.items.count - 1
                dec.keyDown("enter"); frames(2)
                if dec.showWhy != nil { dec.keyDown("enter"); frames(2) }
            }
            dec.keyDown("enter"); frames(3)
        }
        if let rep = g.scene as? ReportScene {
            frames(60)
            check(rep.gr.total < 0.5, "deliberately bad play still graded \(Int(rep.gr.total * 100))% (\(rep.gr.letter))")
            check(rep.gr.rows[3].1 < 0.6, "unprotected exposure not penalized (\(Int(rep.gr.rows[3].1 * 100))%)")
            check(rep.gr.rows[6].1 < 0.6, "bad decon not penalized (\(Int(rep.gr.rows[6].1 * 100))%)")
            print("• negative control (worst-case play): \(rep.gr.letter) (\(Int(rep.gr.total * 100))%)")
        } else { failures.append("negative-control run did not reach the report") }
    }
    // Resident memory after playing everything.
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
    let kr = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    if kr == KERN_SUCCESS {
        let mb = Double(info.resident_size) / 1_048_576
        print("• resident memory after all missions: \(f(mb, 1)) MB")
        check(mb < 400, "resident memory \(f(mb, 1)) MB exceeds the 400 MB budget")
    }
    print(failures.isEmpty ? "\nSELF-TEST PASSED" : "\nSELF-TEST FAILED (\(failures.count))")
    for f in failures { print("  ✗ \(f)") }
    return failures.isEmpty ? 0 : 1
}

// MARK: - Offscreen screenshots (for visual checking without a window)

func shots(_ dir: String) -> Int32 {
    let g = Game.shared
    g.headless = true
    try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    func save(_ name: String) {
        g.fade = 0
        for _ in 0..<2 { g.update(1.0 / 60) }
        guard let img = g.render() else { return }
        let url = URL(fileURLWithPath: dir).appendingPathComponent(name + ".png")
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, img, nil)
        CGImageDestinationFinalize(dest)
        print("wrote \(name).png")
    }
    func run(_ n: Int) { for _ in 0..<n { g.update(1.0 / 60) } }

    var st = GameState(); st.screened = true; st.trained = true; st.trainScore = 9; st.score = 84; st.division = .nuclear; Game.shared.state = st
    g.go(TitleScene()); run(60); save("01-title")
    let sc = ScreeningScene(); g.go(sc); sc.typed = 1e9; run(10); save("02-screening")
    sc.idx = 5; sc.typed = 1e9; run(10); save("02b-screening-travel")
    g.go(ClearanceScene()); run(180); save("03-clearance")
    let ac = AcademyScene(); g.go(ac); run(20); save("03b-academy-intro")
    ac.mode = .lesson; ac.li = 0; ac.reveal = 1e9; run(4); save("03c-academy-unit1")
    ac.li = 2; ac.reveal = 1e9; run(4); save("03d-academy-tools")
    ac.li = 6; ac.reveal = 1e9; run(4); save("03e-academy-decon")
    ac.mode = .exam; ac.ei = 1; ac.opts = OptionList(examQs[1].a); ac.answered = 0; run(4); save("03f-academy-exam")
    ac.mode = .badge; ac.t = 2; run(4); save("03g-academy-badge")
    g.go(MissionSelectScene()); run(10); save("04-roster")
    let ra = RedAlertScene(MissionRun(radMissions[0], variant: 0)); g.go(ra); ra.shown = 99; run(30); save("04b-red-alert")
    let r1 = MissionRun(radMissions[0], variant: 0)
    g.go(BriefingScene(r1)); run(10); g.keyDown("enter"); run(10); save("05-briefing")
    g.keyDown("3"); run(10)
    g.go(LoadoutScene(r1)); g.keyDown("right"); run(10); save("06-loadout-shielded")
    r1.loadout = Loadout(suit: allSuits[1], resp: .scba, cylinder: cylinders[2], canister: canisters[0], sensor5: .pid)
    if let f = FieldScene(r1) as FieldScene? {
        g.go(f)
        f.pos = P(1100, 600); run(90); save("07-field-pripyat")
        f.pos = f.m.victims[0].p; run(4); f.keyDown("e"); run(4); save("08-triage")
        f.keyDown("1"); run(4)
        for i in 0..<f.m.samples.count { f.pos = f.m.samples[i].p; run(2); f.keyDown("e"); run(Int(f.m.samples[i].secs * 70)) }
        for i in 0..<f.m.surveys.count { f.pos = f.m.surveys[i].p; run(2); f.keyDown("r") }
        f.keyDown("tab"); run(4); save("09-notebook"); f.keyDown("tab")
        f.keyDown("f"); run(4); save("10-guide"); f.keyDown("esc")
        if let vi = f.m.victims.firstIndex(where: { $0.litter }) { f.orderLitter(vi); run(200); save("10b-litter-carry") }
        f.finish(extracted: false)
    }
    if let lab = g.scene as? LabScene {
        run(120); save("11-transport")
        run(400)
        lab.cursor = 661.7; lab.keyDown("m"); run(4); lab.keyDown("1"); run(4); save("12-lab-spectrum")
        for si in 0..<lab.samples.count {
            lab.sel = si
            for id in lab.samples[si].contents { if let n = lab.candidates.firstIndex(of: id) { lab.keyDown("\(n + 1)") } }
        }
        lab.keyDown("x"); run(4); save("13-threat")
        lab.keyDown("3"); run(4); save("14-protocol")
        lab.keyDown("1"); run(6)
    }
    if let dec = g.scene as? DeconScene {
        run(10); save("14b-decon-crew")
        while dec.phase == 0 { dec.keyDown("\(dec.posts[dec.pi].best + 1)"); run(3); if dec.showWhy != nil { dec.keyDown("enter"); run(2) } }
        run(6); save("15-decon")
        while dec.phase == 0 {
            dec.keyDown("\((dec.stations[dec.idx].best.first ?? 0) + 1)"); run(3)
            if dec.showWhy != nil { run(2); save("16-decon-error"); dec.keyDown("enter"); run(2) }
        }
        save("17-doffing")
        while dec.phase == 1 {
            let want = dec.order[dec.picked.count]
            if let i = dec.orderList.items.firstIndex(of: want) { dec.orderList.sel = i; dec.keyDown("enter"); run(3) } else { break }
            if dec.showWhy != nil { dec.keyDown("enter"); run(2) }
        }
        run(4); save("18-decon-done"); dec.keyDown("enter"); run(4)
    }
    if let rep = g.scene as? ReportScene {
        run(200); save("19-report")
        rep.page = 1; run(4); save("20-history")
    }
    // one chem/bio bench too
    let r3 = MissionRun(chemMissions[2], variant: 0)
    r3.loadout = Loadout(suit: allSuits.first { $0.id == "HS-B" }!, resp: .scba, cylinder: cylinders[1], canister: canisters[0], sensor5: .pid)
    let cf = FieldScene(r3)
    g.go(cf)
    cf.pos = P(700, 330); run(60); save("21-field-anthrax")
    for i in 0..<cf.m.samples.count { cf.pos = cf.m.samples[i].p; run(2); cf.keyDown("g"); run(170); cf.keyDown("e"); run(Int(cf.m.samples[i].secs * 70)) }
    cf.finish(extracted: false)
    if let lab = g.scene as? LabScene {
        run(460)
        lab.keyDown("b"); run(4)
        for t in [2, 1, 3, 6] { lab.keyDown("\(t)"); run(80) }
        save("22-lab-bio")
        lab.sel = 3; lab.keyDown("4"); run(80); save("23-lab-hoax")
    }
    let r5 = MissionRun(chemMissions[4], variant: 0)
    r5.loadout = Loadout(suit: allSuits.first { $0.id == "HS-A" }!, resp: .scba, cylinder: cylinders[1], canister: canisters[0], sensor5: .pid)
    let nf = FieldScene(r5)
    g.go(nf); nf.pos = P(760, 430); nf.startAP4C(); run(220); save("24-field-nicotine-ap4c")
    nf.pos = nf.m.victims[0].p; run(4); nf.keyDown("e"); run(4); save("25-nicotine-triage")
    // the mall callout: fentanyl strip + confined-space sprayer decon
    let r6 = MissionRun(extraChemMissions[0], variant: 0)
    r6.loadout = Loadout(suit: allSuits.first { $0.id == "HS-A" }!, resp: .scba, cylinder: cylinders[1], canister: canisters[0], sensor5: .pid)
    let mf = FieldScene(r6)
    g.go(mf); mf.pos = P(1500, 620); run(20); mf.runFentStrip(); run(40); save("26-mall-fentanyl")
    mf.finish(extracted: false)
    if let lab2 = g.scene as? LabScene { run(470); lab2.keyDown("b"); for t in [1, 3, 5, 7] { lab2.keyDown("\(t)"); run(80) }; save("27-mall-lab") }
    let r7 = MissionRun(extraChemMissions[0], variant: 0)
    r7.loadout = r6.loadout
    r7.field = FieldResult(); r7.lab = LabResult()
    g.go(DeconScene(r7)); run(10); save("28-sprayer-decon")
    return 0
}

// MARK: - App icon (drawn, then written as an .icns)

func drawIcon(_ ctx: CGContext, _ S: CGFloat) {
    let prev = NSGraphicsContext.current
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
    let g = G(ctx)
    let k = S / 1024
    // rounded dark plate with a hazard band
    g.roundRect(R(0, 0, S, S), 224 * k, rgba(0.045, 0.058, 0.050))
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: R(0, 0, S, S), cornerWidth: 224 * k, cornerHeight: 224 * k, transform: nil))
    ctx.clip()
    g.hazardStripes(R(0, 806 * k, S, 150 * k), Pal.amber, rgba(0.05, 0.05, 0.05), step: 150 * k)
    // faint scan lines
    var y: CGFloat = 0
    while y < S { g.fill(R(0, y, S, 2 * k), rgba(0, 0, 0, 0.16)); y += 8 * k }
    // trefoil, amber on dark, with a soft halo
    let c = P(S / 2, 452 * k)
    g.circle(c, 330 * k, Pal.amber.a(0.07))
    g.circle(c, 250 * k, Pal.amber.a(0.07))
    trefoil(g, c, 300 * k, Pal.amber)
    g.ring(c, 352 * k, Pal.amber.a(0.85), 14 * k)
    ctx.restoreGState()
    ctx.addPath(CGPath(roundedRect: R(6 * k, 6 * k, S - 12 * k, S - 12 * k), cornerWidth: 220 * k, cornerHeight: 220 * k, transform: nil))
    ctx.setStrokeColor(Pal.amber.a(0.35).cgColor); ctx.setLineWidth(10 * k); ctx.strokePath()
    NSGraphicsContext.current = prev
}

func makeIcon(_ path: String) -> Int32 {
    let set = (path as NSString).deletingLastPathComponent + "/Containment.iconset"
    try? FileManager.default.createDirectory(atPath: set, withIntermediateDirectories: true)
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    var written: [String] = []
    for (px, name) in [(16, "icon_16x16"), (32, "icon_16x16@2x"), (32, "icon_32x32"), (64, "icon_32x32@2x"),
                       (128, "icon_128x128"), (256, "icon_128x128@2x"), (256, "icon_256x256"),
                       (512, "icon_256x256@2x"), (512, "icon_512x512"), (1024, "icon_512x512@2x")] {
        guard let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else { continue }
        ctx.translateBy(x: 0, y: CGFloat(px)); ctx.scaleBy(x: 1, y: -1)
        drawIcon(ctx, CGFloat(px))
        guard let img = ctx.makeImage() else { continue }
        let url = URL(fileURLWithPath: set + "/" + name + ".png")
        guard let d = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { continue }
        CGImageDestinationAddImage(d, img, nil); CGImageDestinationFinalize(d)
        written.append(name)
    }
    print("iconset: \(written.count) sizes in \(set)")
    return 0
}

// MARK: - Launch

if let i = CommandLine.arguments.firstIndex(of: "--icon") {
    let out = CommandLine.arguments.count > i + 1 ? CommandLine.arguments[i + 1] : "./build/icon.icns"
    let app = NSApplication.shared
    app.setActivationPolicy(.prohibited)
    exit(makeIcon(out))
} else if let i = CommandLine.arguments.firstIndex(of: "--shots") {
    let dir = CommandLine.arguments.count > i + 1 ? CommandLine.arguments[i + 1] : "./shots"
    let app = NSApplication.shared
    app.setActivationPolicy(.prohibited)
    exit(shots(dir))
} else if CommandLine.arguments.contains("--selftest") {
    let app = NSApplication.shared
    app.setActivationPolicy(.prohibited)
    exit(selfTest())
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.activate(ignoringOtherApps: true)
    app.run()
}

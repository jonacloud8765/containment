// CONTAINMENT — Phase 0: Security Clearance & Psychological Screening.
// Standard vetting, genuine (and genuinely strange) US visa / SF-86 style questions, and
// intrusive psychological items. Satire, not a real form.

import AppKit

struct Q {
    let form: String          // the form box in the corner, e.g. "DS-160 PART 9"
    let preamble: String      // the small-print lead-in
    let q: String
    let a: [(String, Int)]
    var multi = false         // toggle several, then SUBMIT
}

let questions: [Q] = [

    Q(form: "SF-86-Δ · SECTION 1", preamble: "Before we begin: this interview is recorded, transcribed, and reviewed by a panel you will never meet. Answer in your own words. There are no wrong answers, except for the ones we have already marked.",
      q: "State the reason for your application to the National CBRN Response Service.",
      a: [("Public service. I want to be useful on the worst day of someone's life.", 3),
          ("Hazard pay, pension, and early retirement. I'd rather be honest with you now than lie on a polygraph in twenty minutes.", 3),
          ("I saw the suits on the news and thought: that's the one. That's my silhouette.", 1),
          ("A voice I have come to trust suggested it. It has been right about most things.", 0)]),

    Q(form: "DS-160 · PART 9", preamble: "The following question appears, word for word, on the United States nonimmigrant visa application. It is asked of tourists, students, grandmothers, and people connecting through Houston for ninety minutes.",
      q: "Do you seek to engage in terrorist activities while in the United States, or have you ever engaged in terrorist activities?",
      a: [("No.", 3),
          ("No. And I've always wondered who answers yes, and what happens in the four seconds after they tick that box.", 3),
          ("Not while in the United States.", 0),
          ("Define 'activities'. I want to be precise, because I respect this process.", 0)]),

    Q(form: "DS-160 · PART 9", preamble: "Also a real question. Also asked of grandmothers.",
      q: "Have you ever ordered, incited, committed, assisted, or otherwise participated in genocide?",
      a: [("No.", 3),
          ("No. I'd like to note that anyone who HAS participated in genocide is unlikely to be stopped by this question.", 3),
          ("I participated in a group project in university that several people have since described that way.", 1),
          ("I'd like to speak to a lawyer before answering, which I understand is itself an answer.", 0)]),

    Q(form: "DS-160 · PART 9", preamble: "The form asks about relatives. The form always asks about relatives.",
      q: "Has any member of your immediate family — parent, sibling, spouse, or child — ever been a member of, affiliated with, or provided material support to a terrorist organization?",
      a: [("No.", 3),
          ("No. Though my brother did join a multi-level marketing company in 2019, and the recruitment materials were structurally similar.", 2),
          ("My sister runs the neighbourhood association. The methods are comparable. The stakes are lower.", 1),
          ("I would like to report my brother for unrelated reasons while I have your attention.", 0)]),

    Q(form: "SF-86-Δ · SECTION 20C", preamble: "Standard counterintelligence item.",
      q: "Have you ever had contact — official, social, romantic, accidental, or at a wedding — with a representative of a foreign intelligence service?",
      a: [("No.", 3),
          ("Not knowingly. I accept that this is exactly what someone who had would say.", 3),
          ("Define 'contact'. There was a man at a conference in Vienna who was extremely interested in my work and bought all the drinks.", 1),
          ("Only on weekends, and we have an understanding.", 0)]),

    Q(form: "DS-160 · PART 8", preamble: "List all countries you have visited in the last five years. Select every one that applies. The system will cross-reference this against records you did not know existed.",
      q: "Where have you been?",
      a: [("Nowhere. I have not left this country in five years and I find the question slightly accusatory.", 2),
          ("Normal holidays. France, Spain, Italy, the usual postcard places.", 2),
          ("Work travel: Kazakhstan, Ukraine, Jordan, South Korea, Japan.", 3),
          ("Somewhere I am contractually unable to name on an unclassified form.", 2),
          ("A country that no longer exists under the name it had when I was there.", 2),
          ("I would prefer to discuss my travel history in a room with no windows.", 1)],
      multi: true),

    Q(form: "DS-160 · PART 9", preamble: "Another genuine item from the United States nonimmigrant visa application, reproduced here because nothing we could invent would be funnier.",
      q: "Are you coming to the United States to engage in prostitution or unlawful commercialized vice?",
      a: [("No.", 3),
          ("No, and I appreciate that the form specifies UNLAWFUL commercialized vice, which implies a lawful kind it has no objection to.", 3),
          ("I'm coming to contain a radiological release, but I'll keep my evenings free.", 1),
          ("Not commercialized.", 0)]),

    Q(form: "SF-86-Δ · SECTION 21", preamble: "Your answer to this item will be compared against your medical records, your pharmacy history, and a questionnaire your sister-in-law filled in last Tuesday without telling you.",
      q: "List every secret your family keeps. Begin with the one you would least like to say out loud in this room.",
      a: [("I decline. My family's private history has no bearing on my ability to wear a suit and read a dosimeter.", 3),
          ("My aunt's mushroom soup, 1998. Everyone recovered. Nobody discusses it. There is a reason she is not invited to Christmas.", 1),
          ("[The subject speaks without pause for six minutes. The transcript runs to four pages. Two members of the panel ask for a break.]", 0),
          ("My family has no secrets. We are completely open with one another about everything, always.", 1)]),

    Q(form: "PSYCH EVAL · ITEM 14", preamble: "There is no correct answer to the following. We will, however, be noting how long you take.",
      q: "AIRLOCK ETHICS. The airlock cycles one person at a time. You and your partner are both contaminated; your partner is also bleeding badly. You have forty seconds of air each. The cycle takes fifty seconds. Who goes first?",
      a: [("Neither of us goes alone. I call a Mayday, we share air, and we cycle together or we wait for the RIT. The question assumes I've already accepted losing someone.", 3),
          ("My partner. I hold my breath and I take my chances, and if I'm wrong, I was wrong for the right reason.", 2),
          ("Me. Someone has to come back out and open it from the clean side, and that someone should be conscious.", 1),
          ("We flip a coin. Fair is fair.", 0)]),

    Q(form: "PSYCH EVAL · ITEM 15", preamble: "Answer quickly. The polygraph is more interested in the pause than the words.",
      q: "During an entry you notice a sharp metallic taste at the back of your mouth. Your partner has not mentioned anything. Command has not called anything. The taste is getting stronger.",
      a: [("I call it immediately. A metallic taste can be an exposure symptom, and a symptom I hide is a symptom nobody can act on.", 3),
          ("I note the time, check my meters, and call it within thirty seconds if the readings support it.", 2),
          ("I finish the task. We're four minutes from done and the samples matter more than my mouth.", 0),
          ("I find it comforting. It reminds me of the taste of pennies, and of my grandmother's house.", 0)]),

    Q(form: "PSYCH EVAL · ITEM 16", preamble: "Everyone has these. We are only interested in whether you know you have them.",
      q: "Do you experience intrusive thoughts about pressing large red buttons, pulling emergency releases, or stepping off high places?",
      a: [("Yes, occasionally. It's common, it's called the call of the void, and I've never once acted on it.", 3),
          ("Never. Not once. I have never had an intrusive thought in my life.", 1),
          ("Constantly. It's the main thing I think about. Which button are we discussing?", 0),
          ("Only about the ones with covers on them, which I assume is the point of the cover.", 2)]),

    Q(form: "SF-86-Δ · SECTION 22", preamble: "Honesty here is scored more favourably than you expect.",
      q: "When did you most recently lie to a person in a position of authority over you, and what was it about?",
      a: [("Recently, about something small. I said I'd read a procedure update that I'd skimmed. I went back and read it properly afterwards.", 3),
          ("I've never lied to anyone in authority. Not once, in my entire life, about anything.", 0),
          ("Right now. One of my previous answers was not strictly true and I'd like to amend it.", 2),
          ("I don't recognise the premise. Authority is a story we agree to tell each other.", 0)]),

    Q(form: "PSYCH EVAL · ITEM 18", preamble: "Scenario item. Read carefully.",
      q: "You are off duty, walking through a scrapyard, and you find a heavy metal cylinder, warm to the touch, stamped with a three-bladed symbol. Two teenagers are already taking photographs of it. What do you do?",
      a: [("Move everyone back, keep them back, call it in, and stay upwind at distance until someone with a meter arrives.", 3),
          ("Photograph the markings from a distance, then call it in. The serial number will tell them what they're dealing with.", 2),
          ("Take it somewhere safe myself. I'm trained; leaving it there is worse.", 0),
          ("Post it first. The public has a right to know, and the engagement would be enormous.", 0)]),

    Q(form: "PSYCH EVAL · ITEM 19", preamble: "One word. The panel will interpret it however it chooses.",
      q: "Describe your relationship with your mother in a single word.",
      a: [("Complicated.", 2), ("Good.", 2), ("Classified.", 3), ("[The subject does not answer. The silence runs to eleven seconds.]", 1)]),

    Q(form: "PSYCH EVAL · ITEM 21", preamble: "Instrument-trust item.",
      q: "Your dosimeter alarms. A colleague with nineteen years in the job glances at it and says 'that one's been faulty for weeks, ignore it.'",
      a: [("I leave the area and verify with a second instrument. If it's faulty I've lost four minutes. If it isn't, I've lost nothing at all.", 3),
          ("I ask him to prove it with his own meter, right now, standing where I'm standing.", 2),
          ("Nineteen years is nineteen years. I keep working and flag it at the debrief.", 0),
          ("I turn it off. The noise is the problem, not the radiation.", 0)]),

    Q(form: "SENSORY PROFILE · ITEM 4", preamble: "There is a correct answer to this question. We will not be telling you what it is, or why.",
      q: "Which of the following sounds do you find most settling?",
      a: [("The hiss of a demand valve. Steady. Means the seal is good and the air is coming.", 3),
          ("Complete silence.", 1),
          ("Wind chimes.", 1),
          ("Screaming. Distant, ideally. But present.", 0)]),

    Q(form: "PSYCH EVAL · ITEM 24", preamble: "Claustrophobia item. Be truthful; this is a disqualifier we can work around and a surprise we cannot.",
      q: "Rate your comfort working in a confined space, in the dark, wearing twenty-five kilograms of equipment, unable to scratch your own face, for forty minutes.",
      a: [("Comfortable. I've trained for it specifically and I know what my own breathing sounds like when it starts to go wrong.", 3),
          ("Manageable. I don't enjoy it, but enjoyment isn't the requirement.", 2),
          ("I would rather not discuss confined dark spaces, or my childhood, or the connection between them.", 1),
          ("I am in one right now. This room has no windows and you have not offered me water.", 0)]),

    Q(form: "DS-160 · PART 9", preamble: "A genuine item. It has been on the form since the 1950s and has survived every attempt to remove it.",
      q: "Have you ever been a member of, or in any way affiliated with, the Communist Party or any other totalitarian party?",
      a: [("No.", 3),
          ("No. I'd gently observe that a totalitarian party that recruits by asking politely on a form is not much of a totalitarian party.", 3),
          ("My university debating society was run along lines that several members described in those terms.", 1),
          ("Not yet. I like to keep my options open.", 0)]),

    Q(form: "PSYCH EVAL · ITEM 27", preamble: "Integrity item.",
      q: "If it were certain that nobody would ever find out, would you take a souvenir from an incident site?",
      a: [("No. The certainty of not being caught is not the part that stops me.", 3),
          ("Everyone would find out eventually. It would set off a portal monitor at an airport in nine years and ruin a stranger's afternoon.", 2),
          ("Photographs only, and only once the scene is released.", 1),
          ("Something small. Nobody misses something small.", 0)]),

    Q(form: "SF-86-Δ · SECTION 26", preamble: "Financial item. Debt is the oldest lever there is.",
      q: "Is there any debt, obligation, habit, or private arrangement in your life that a stranger could use to make you do something you would not otherwise do?",
      a: [("Nothing I haven't already declared in writing. That's the entire point of declaring it.", 3),
          ("Yes, and I'd rather tell you about it now than have you find it in week six.", 3),
          ("No. Nothing. My life is completely free of leverage of any kind.", 1),
          ("Several. But they all cancel each other out.", 0)]),

    Q(form: "PSYCH EVAL · ITEM 31", preamble: "Final scenario item.",
      q: "Mid-entry, your partner removes their facepiece in a contaminated atmosphere and tells you they 'just need a second'. They outrank you.",
      a: [("I get the mask back on and I get them out, and I accept whatever that costs me afterwards. Rank doesn't survive a sealed facepiece.", 3),
          ("I call command immediately and request an order from someone above both of us.", 2),
          ("I give them the second. They've been doing this longer than I have.", 0),
          ("I remove mine too. We're in it together or we're not.", 0)]),

    Q(form: "DS-160 · FINAL", preamble: "Last item. It is not a real visa question. We added it ourselves.",
      q: "Do you sleep with your socks on?",
      a: [("No.", 1), ("Yes.", 1), ("Is this being recorded?", 2), ("I don't sleep. Not really. Not in the way you mean.", 0)]),
]

let remarks = ["Noted.",
               "The polygraph needle twitches once and settles.",
               "The interviewer writes for an uncomfortably long time.",
               "A second interviewer enters, reads your answer over the first one's shoulder, and leaves without speaking.",
               "'Interesting.'",
               "Pen clicks. Silence. The clock on the wall is nine minutes slow.",
               "The air conditioning stops for no reason and does not start again.",
               "'Please keep your hands on the table where we can see them.'",
               "Somewhere behind the mirror, a printer starts.",
               "'We'll come back to that one.'",
               "The interviewer underlines something three times.",
               "'That's the answer most people give.' She does not say whether that's good."]

final class ScreeningScene: Scene {
    var idx = 0
    var score = 0
    var opts = OptionList([])
    var picked = Set<Int>()
    var remark = ""
    var t = 0.0
    var typed = 0.0
    var guide = GuideOverlay()

    init() { load(); Audio.shared.reset(); Audio.shared.hum = 0.4 }

    var cur: Q { questions[idx] }
    private var fullLen: Double { Double(cur.preamble.count + cur.q.count) }

    private func load() {
        var items = cur.a.map { $0.0 }
        if cur.multi { items.append("▶ SUBMIT THESE ANSWERS") }
        opts = OptionList(items, numberKeys: !cur.multi)
        picked.removeAll()
        typed = 0
    }

    func update(_ dt: Double) {
        t += dt
        let before = Int(typed)
        typed += dt * 260
        if Int(typed) != before && typed < fullLen && Int(typed) % 5 == 0 { Audio.shared.tick() }
    }

    func draw(_ g: G) {
        header(g, "SECURITY CLEARANCE & PSYCHOLOGICAL SCREENING", "ITEM \(idx + 1) OF \(questions.count)")
        g.panel(R(50, 100, 1180, 560), title: "INTERVIEW TERMINAL")
        // form stamp
        let fw = CGFloat(cur.form.count) * G.charW(11, true) + 20
        g.fill(R(1230 - fw, 112, fw, 20), Pal.amberDim)
        g.text(cur.form, 1240 - fw, 115, 11, Pal.black, bold: true)

        var y: CGFloat = 126
        let pshown = String(cur.preamble.prefix(Int(typed)))
        y += g.para(pshown, 74, y, w: 1050, size: 13, color: Pal.greenDim, lineH: 18) + 14
        if typed > Double(cur.preamble.count) {
            let qshown = String(cur.q.prefix(Int(typed) - cur.preamble.count))
            let caret = typed < fullLen && Int(t * 3) % 2 == 0 ? "█" : ""
            y += g.para(qshown + caret, 74, y, w: 1100, size: 19, color: Pal.amber, lineH: 26, bold: true) + 18
        }
        if typed >= fullLen {
            if cur.multi { g.text("SELECT ALL THAT APPLY, THEN SUBMIT", 74, y, 11, Pal.cyan, bold: true); y += 20 }
            opts.draw(g, x: 70, y: y, w: 1140, size: 14, gap: 6)
            if cur.multi {
                for (i, r) in opts.rects.enumerated() where i < cur.a.count {
                    g.text(picked.contains(i) ? "■" : "□", r.minX - 16, r.minY + 5, 14, picked.contains(i) ? Pal.cyan : Pal.greenDim, bold: true)
                }
            }
        }
        g.text(remark, 74, 672, 13, Pal.greenDim)
        g.bar(R(50, 700, 1180, 8), Double(idx) / Double(questions.count), Pal.green)
        g.para("Your answers are compared against your polygraph, your financial disclosures, your social media, your travel records, and a questionnaire three of your neighbours completed without telling you. Answer naturally.",
               50, 718, w: 1180, size: 12, color: Pal.greenDim, lineH: 16)
        guide.draw(g)
        footer(g, cur.multi ? "[↑↓] move   [ENTER] toggle / submit   [ESC] abort" : "[↑↓] select   [ENTER] answer   [1-4] quick answer   [ESC] abort")
    }

    func keyDown(_ k: String) {
        if guide.key(k) { return }
        if k == "esc" { Game.shared.go(TitleScene()); return }
        if typed < fullLen { if k == "enter" || k == "space" { typed = 1e9 }; return }
        if let i = opts.key(k) { choose(i) }
    }
    func mouseMoved(_ p: CGPoint) { opts.hover(p); guide.mouseMoved(p) }
    func mouseDown(_ p: CGPoint) {
        if typed < fullLen { typed = 1e9; return }
        if let i = opts.click(p) { choose(i) }
    }

    private func choose(_ i: Int) {
        if cur.multi {
            if i == opts.items.count - 1 {
                if picked.isEmpty { Audio.shared.deny(); remark = "Select at least one. 'Nowhere' is an option and is itself an answer."; return }
                for p in picked { score += cur.a[p].1 }
                // honesty bonus: declaring a lot of travel is better than declaring none
                if picked.count >= 3 { score += 2 }
                advance(picked.first ?? 0)
            } else {
                if picked.contains(i) { picked.remove(i) } else { picked.insert(i) }
                Audio.shared.blip(1200, 0.03)
            }
            return
        }
        score += cur.a[i].1
        advance(i)
    }

    private func advance(_ i: Int) {
        remark = remarks[(idx * 7 + i * 3) % remarks.count]
        idx += 1
        if idx >= questions.count {
            var maxS = 0
            for q in questions {
                if q.multi { maxS += (q.a.map { $0.1 }.sorted().suffix(3).reduce(0, +)) + 2 }
                else { maxS += q.a.map { $0.1 }.max() ?? 0 }
            }
            var s = Game.shared.state
            s.screened = true
            s.score = Int((Double(score) / Double(maxS) * 100).rounded())
            s.division = s.score >= 70 ? .nuclear : .chembio
            s.save()
            Game.shared.state = s
            Game.shared.go(ClearanceScene())
        } else { load() }
    }
}

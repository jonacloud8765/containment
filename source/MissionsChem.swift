// CONTAINMENT — Chemical & Biological track (CONFIDENTIAL clearance).
// Simplified, respectful reconstructions of public historical events plus composite accidents.

import AppKit

private let entry = Area(r: R(0, 500, 220, 300), name: "ENTRY CONTROL / DECON LINE", floor: rgba(0.13, 0.15, 0.13))
private let border = [Wall(r: R(0, 0, 2000, 20), shield: 1), Wall(r: R(0, 1280, 2000, 20), shield: 1)]

let chemMissions: [MissionDef] = [
    // ------------------------------------------------------------------ 5
    MissionDef(
        id: "C1", division: .chembio, year: "1991", op: "OPERATION SEALED ROOM", title: "Gulf War Scud Alert",
        location: "Residential street, Tel Aviv area, Israel", inspired: "Inspired by the 1991 Iraqi Scud attacks on Israel",
        window: 30, realSecs: 330, doseLimit: 0, windDeg: 10, windSpeed: 2, variants: 1,
        threat: { _ in .military },
        briefing: { _ in [
            "## 02:05 LOCAL // HOME FRONT COMMAND // BALLISTIC MISSILE WARNING",
            "!! SIRENS. Ballistic missile launch detected from western Iraq. Impact predicted: coastal plain.",
            ">> ...impact in a residential street... building damaged... reports of a strange smell...",
            "-- Resident: 'I smelled garlic! I injected my atropine, my heart is pounding out of my chest!'",
            "## INTEL: the launching state has used nerve and blister agents on civilians before. A chemical warhead is possible.",
            "## Public instruction: sealed room, gas mask on, atropine ONLY with nerve-agent signs.",
            "!! OPERATIONAL LIMIT: 30 MIN // FULL CHEMICAL PROTECTION UNTIL THE WARHEAD IS CLEARED",
            "## TASKS: confirm conventional or chemical warhead, sample crater / fragments / air, clear the shelters.",
        ] },
        build: { _ in
            var m = FieldMap()
            m.ground = rgba(0.11, 0.11, 0.10); m.dark = 0.5
            m.areas = [entry,
                       Area(r: R(220, 450, 1560, 400), name: "STREET (IMPACT SITE)", floor: rgba(0.13, 0.13, 0.12)),
                       Area(r: R(300, 60, 700, 380), name: "APARTMENT BLOCK (DAMAGED)", floor: rgba(0.16, 0.14, 0.12)),
                       Area(r: R(1100, 60, 620, 380), name: "SEALED-ROOM SHELTER, APT 3", floor: rgba(0.15, 0.15, 0.17)),
                       Area(r: R(1150, 860, 620, 400), name: "IMPACT CRATER", floor: rgba(0.17, 0.12, 0.08))]
            m.walls = room(R(300, 60, 700, 380), doors: [("s", 300, 120)]) + room(R(1100, 60, 620, 380), doors: [("s", 120, 100)]) + border
                + [Wall(r: R(500, 900, 300, 40)), Wall(r: R(900, 1100, 40, 160))]
            m.gas = [Gas(r: R(1200, 880, 520, 360), o2: 20.6, co: 70, voc: 14, label: "smoke from crater")]
            m.plumes = [Plume(p: P(1450, 1050), q: 1, spread: 80, length: 500, agent: "SMOKE", color: Pal.grey.a(0.18))]
            m.samples = [SamplePt(p: P(1450, 1060), label: "Crater soil", kind: .soil, contents: ["HE"]),
                         SamplePt(p: P(1300, 950), label: "Warhead fragment wipe", kind: .wipe, contents: ["HE"]),
                         SamplePt(p: P(1820, 760), label: "Downwind air canister", kind: .air, contents: ["CLEAN"]),
                         SamplePt(p: P(1420, 260), label: "Shelter air (control)", kind: .air, contents: ["CLEAN"])]
            m.victims = [
                Victim(p: P(1250, 200), name: "Man in sealed room",
                       signs: "Hot, dry, flushed skin. Wide pupils. Racing pulse. Confused and agitated. An empty atropine autoinjector beside him. Room detectors read clean.",
                       options: ["Stop antidotes: cool him, monitor, supportive care (atropine toxicity)", "Give a second DuoDote",
                                 "Tag RED for nerve-agent poisoning + midazolam", "Tag GREEN: panic attack"],
                       best: [0], why: "Hot, dry, flushed and confused with wide pupils is atropine toxicity, with no exposure behind it. More atropine would be dangerous. In 1991 many people self-injected without being exposed."),
                Victim(p: P(1560, 330), name: "Child in a gas mask",
                       signs: "Struggling, face red, mask collapsing against her face with each breath. The filter's sealing cap is still on.",
                       options: ["Remove the filter's sealing cap at once and recheck the seal (shelter air reads clean)", "Tape the mask edges tighter",
                                 "Give atropine", "Wait for the all-clear"],
                       best: [0], why: "With the filter sealed she can't breathe. Suffocation from badly fitted or capped masks caused deaths during the 1991 alerts."),
                Victim(p: P(700, 620), name: "Elderly man on the street",
                       signs: "Crushing chest pain and sweating after the blast, terrified. Normal pupils, no drooling or runny nose.",
                       options: ["Urgent transport: suspected heart attack (stress), no agent signs", "DuoDote", "Tag GREEN", "Decon shower first"],
                       best: [0], why: "Normal pupils and no secretions argue against nerve agent. Stress-related heart attacks were a real cause of death during the alerts.", litter: true),
            ]
            m.clues = [Clue(p: P(160, 460), title: "CIVIL DEFENCE NOTICE",
                            text: "On the siren: enter the sealed room, put on the mask, REMOVE THE FILTER CAP. Inject atropine ONLY with signs of nerve-agent poisoning: pinpoint pupils, drooling, runny nose, chest tightness, twitching."),
                       Clue(p: P(1360, 1000), title: "WARHEAD FRAGMENT",
                            text: "Twisted casing from an extended-range Scud. Charred, with a strong smell of burnt explosive. No oily droplets, no liquid residue, M9 paper unchanged."),
                       Clue(p: P(620, 520), title: "MILITARY LIAISON",
                            text: "Launch tracked from western Iraq. A state ballistic-missile attack during the Gulf War, so the warhead type decides everything we do next.")]
            m.surveys = [Survey(p: P(1250, 820), name: "Crater rim"), Survey(p: P(1300, 400), name: "Shelter door"), Survey(p: P(800, 600), name: "Street centre")]
            m.props = [(R(560, 520, 140, 60), rgba(0.25, 0.25, 0.30), "CAR"), (R(1000, 560, 140, 60), rgba(0.30, 0.20, 0.18), "CAR"),
                       (R(1380, 990, 160, 80), rgba(0.10, 0.08, 0.06), "CRATER")]
            return m
        },
        candidates: ["GB", "VX", "HD", "OPPEST", "HE", "CLEAN"], multiID: false,
        protocols: chemProtocols, bestProtocol: { _ in [5] }, decon: { _ in .none }, required: 3,
        history: { _ in "From January to February 1991 Iraq fired about 40 extended-range Scud missiles at Israel. Every warhead was conventional. Fear of nerve agents meant gas masks and sealed rooms for the whole population. Direct blast deaths were few. More harm came from stress-related heart attacks, suffocation in badly used masks, and atropine injected without exposure. A state military attack." },
        ambientWind: 0.2, ambientRumble: 0.0, siren: true, suggestedSensor: .pid,
        alertLoc: "RESIDENTIAL STREET — BALLISTIC MISSILE IMPACT",
        alertDispatch: "MISSILE IMPACT IN A CIVILIAN AREA. CHEMICAL WARHEAD NOT RULED OUT.",
        litters: 1),

    // ------------------------------------------------------------------ 6
    MissionDef(
        id: "C2", division: .chembio, year: "1995", op: "OPERATION RUSH HOUR", title: "Tokyo Subway Release",
        location: "Subway platform and train car, central Tokyo", inspired: "Inspired by the 1995 Tokyo subway sarin attack",
        window: 20, realSecs: 330, doseLimit: 0, windDeg: 180, windSpeed: 1.5, variants: 1,
        threat: { _ in .terrorism },
        briefing: { _ in [
            "## 08:20 LOCAL // METRO FIRE DEPARTMENT // MASS CASUALTY, TRANSIT NETWORK",
            "!! Mass-casualty calls from several stations on several lines AT ONCE.",
            "-- Commuter: 'Everything went dark, like the lights dimmed. My nose is running, I can't breathe.'",
            "-- Station staff: 'Packages wrapped in newspaper, leaking an oily liquid on the train floor.'",
            ">> ...hospital reports nurses falling ill after handling patients' clothing...",
            "## TELEMETRY: tunnel draft pushes air WEST along the platform. No visible cloud.",
            "!! OPERATIONAL LIMIT: 20 MIN // ACUTE VAPOR HAZARD // VAPOR-PROTECTIVE ENSEMBLE ADVISED",
            "## TASKS: collect the liquid, triage the casualties, get vapor and evidence samples, confirm by GC-MS.",
        ] },
        build: { _ in
            var m = FieldMap()
            m.ground = rgba(0.12, 0.12, 0.13); m.dark = 0.15
            m.areas = [entry,
                       Area(r: R(220, 420, 640, 460), name: "CONCOURSE", floor: rgba(0.15, 0.15, 0.15)),
                       Area(r: R(860, 200, 1100, 360), name: "PLATFORM 2", floor: rgba(0.17, 0.16, 0.13)),
                       Area(r: R(900, 600, 900, 240), name: "TRAIN CAR 3", floor: rgba(0.20, 0.20, 0.22)),
                       Area(r: R(860, 900, 700, 340), name: "STAIRWELL / EXIT B", floor: rgba(0.13, 0.13, 0.14))]
            m.walls = room(R(900, 600, 900, 240), t: 14, doors: [("n", 120, 90), ("n", 450, 90), ("n", 760, 90)]) + border
                + [Wall(r: R(860, 860, 1100, 30)), Wall(r: R(860, 180, 1100, 24)), Wall(r: R(1960, 180, 24, 720))]
            m.plumes = [Plume(p: P(1350, 710), q: 30, spread: 60, length: 650, agent: "GB")]
            m.puddles = [Puddle(p: P(1350, 712), r: 42, agent: "GB", level: 2.0, color: rgba(0.75, 0.70, 0.45, 0.35)),
                         Puddle(p: P(1520, 700), r: 26, agent: "GB", level: 1.2, color: rgba(0.75, 0.70, 0.45, 0.30))]
            m.gas = [Gas(r: R(914, 614, 872, 212), voc: 4, label: "train car")]
            m.samples = [SamplePt(p: P(1355, 690), label: "Liquid from punctured package", kind: .vial, contents: ["GB"], secs: 5),
                         SamplePt(p: P(1520, 720), label: "Floor puddle swab", kind: .swab, contents: ["GB"]),
                         SamplePt(p: P(1100, 400), label: "Platform air canister", kind: .air, contents: ["GB"]),
                         SamplePt(p: P(640, 600), label: "Victim's coat (evidence bag)", kind: .evidence, contents: ["GB"])]
            m.victims = [
                Victim(p: P(1250, 480), name: "Station attendant",
                       signs: "Carried the leaking packages off the train. Pinpoint pupils, heavy drooling, twitching, laboured breathing, now seizing.",
                       options: ["Tag RED: DuoDote ×3 + midazolam, airway support, decon", "Tag GREEN: walk to decon",
                                 "Supportive care only, no antidote", "Tag BLACK (expectant)"],
                       best: [0], why: "Severe nerve-agent poisoning. Early atropine and pralidoxime, midazolam for the seizures, and airway support are what save lives.", litter: true),
                Victim(p: P(960, 330), name: "Commuter",
                       signs: "Dim vision, runny nose, tight chest, but walking and talking.",
                       options: ["Tag YELLOW: one DuoDote, decon, observe", "Tag RED + three DuoDote", "Tag GREEN: no treatment", "Midazolam only"],
                       best: [0], why: "Moderate signs with chest tightness: one autoinjector, then reassess. Atropine is titrated until secretions dry.", litter: true),
                Victim(p: P(600, 720), name: "Office worker",
                       signs: "Eye pain and dim vision only. Pinpoint pupils, breathing normal.",
                       options: ["Tag GREEN: decon, no systemic atropine (miosis alone), eye care", "DuoDote now", "Tag RED", "Send home without decon"],
                       best: [0], why: "Miosis alone doesn't need intramuscular atropine, and the injection won't reverse it. She still needs decon: in 1995 off-gassing clothes sickened hospital staff."),
            ]
            m.clues = [Clue(p: P(300, 470), title: "STATION LOG",
                            text: "08:00 rush hour. Passengers collapsing on several lines within minutes of each other. Several plastic bags wrapped in newspaper, leaking liquid. Several lines hit at once suggests a coordinated act."),
                       Clue(p: P(1050, 660), title: "WITNESS",
                            text: "'A man in a surgical mask jabbed the packages with the tip of his umbrella and got off at the next stop.'"),
                       Clue(p: P(160, 620), title: "HOSPITAL RADIO",
                            text: "Nurses getting sick from patients' clothing. Request decon and clothing removal BEFORE transport.")]
            m.surveys = [Survey(p: P(1000, 520), name: "Car door 1"), Survey(p: P(1700, 400), name: "Platform west end"), Survey(p: P(700, 520), name: "Concourse")]
            m.props = [(R(1300, 680, 100, 40), rgba(0.55, 0.50, 0.35), "PACKAGE")]
            return m
        },
        candidates: ["GB", "VX", "HD", "OPPEST", "NIC", "CL2", "CLEAN"], multiID: false,
        protocols: chemProtocols, bestProtocol: { _ in [0] }, decon: { _ in .cwaNerve }, required: 3,
        history: { _ in "On 20 March 1995 members of the Aum Shinrikyo cult released impure sarin on five Tokyo subway trains in rush hour. More than a dozen people died and thousands went to hospital, many of them frightened but unharmed. Hospital staff were sickened by off-gassing from victims' clothing, and that's why decon before transport is now standard. A deliberate terrorist attack." },
        ambientWind: 0.15, ambientRumble: 0.2, siren: false, suggestedSensor: .pid,
        alertLoc: "UNDERGROUND STATION, PLATFORM 2 AND TRAIN CAR 3",
        alertDispatch: "DOZENS COLLAPSING ON SEVERAL LINES AT ONCE. NO FIRE, NO BLAST, NO VISIBLE CLOUD.",
        litters: 2, confinedDecon: true),

    // ------------------------------------------------------------------ 7
    MissionDef(
        id: "C3", division: .chembio, year: "2001", op: "OPERATION WHITE POWDER", title: "Postal & Office Spores",
        location: "Mail processing centre and government office suite", inspired: "Inspired by the 2001 US anthrax letters",
        window: 60, realSecs: 420, doseLimit: 0, windDeg: 0, windSpeed: 0.3, variants: 1,
        threat: { _ in .terrorism },
        briefing: { _ in [
            "## 09:10 LOCAL // FEDERAL POLICE / PUBLIC HEALTH JOINT OPERATIONS",
            "-- Staffer: 'The envelope was taped shut. Fine powder puffed out when I opened it.'",
            "-- Postal supervisor: 'A sorting machine jammed two days ago. The crew blew it clean with compressed air.'",
            ">> ...one employee hospitalized with 'flu' that's getting worse fast...",
            "!! Several other white-powder calls today. Most will be hoaxes. Some may not be.",
            "## Biological aerosols are silent: no smell, no immediate symptoms. Incubation is days.",
            "!! OPERATIONAL LIMIT: 60 MIN // CHANGE OUTER GLOVES BETWEEN SAMPLES [G] // NO DRY BRUSHING",
            "## TASKS: sample every powder site separately, keep the chain of custody, confirm by PCR / culture.",
        ] },
        build: { _ in
            var m = FieldMap()
            m.ground = rgba(0.12, 0.12, 0.12); m.dark = 0.1
            m.areas = [entry,
                       Area(r: R(220, 60, 1000, 640), name: "MAIL SORTING FLOOR", floor: rgba(0.15, 0.15, 0.15)),
                       Area(r: R(1300, 60, 660, 640), name: "GOVERNMENT OFFICE SUITE", floor: rgba(0.15, 0.13, 0.12)),
                       Area(r: R(220, 800, 520, 440), name: "BREAK ROOM", floor: rgba(0.16, 0.15, 0.13)),
                       Area(r: R(820, 820, 520, 400), name: "HVAC PLANT ROOM", floor: rgba(0.12, 0.13, 0.14))]
            m.walls = room(R(220, 60, 1000, 640), doors: [("s", 60, 120), ("e", 400, 120)]) + room(R(1300, 60, 660, 640), doors: [("w", 400, 120), ("s", 80, 120)])
                + room(R(220, 800, 520, 440), doors: [("n", 300, 110)]) + room(R(820, 820, 520, 400), doors: [("n", 200, 110)]) + border
            m.powders = [Powder(p: P(700, 300), r: 80, agent: "BA", level: 2.0), Powder(p: P(1600, 300), r: 45, agent: "BA", level: 3.0),
                         Powder(p: P(1060, 1010), r: 55, agent: "BA", level: 1.0), Powder(p: P(460, 1010), r: 38, agent: "HOAX_STARCH", level: 1.0),
                         Powder(p: P(1760, 560), r: 32, agent: "HOAX_SODA", level: 1.0)]
            m.samples = [SamplePt(p: P(1610, 315), label: "Letter A: office (taped envelope)", kind: .evidence, contents: ["BA"]),
                         SamplePt(p: P(720, 330), label: "Sorting machine swab", kind: .swab, contents: ["BA"]),
                         SamplePt(p: P(1065, 1015), label: "HVAC filter wipe", kind: .wipe, contents: ["BA"]),
                         SamplePt(p: P(470, 1015), label: "Break-room powder", kind: .swab, contents: ["HOAX_STARCH"]),
                         SamplePt(p: P(1765, 565), label: "Reception desk powder", kind: .swab, contents: ["HOAX_SODA"])]
            m.victims = [
                Victim(p: P(420, 420), name: "Postal worker",
                       signs: "Fever, cough, aches and chest discomfort, four days after the machine jam. 'It's just flu, right?'",
                       options: ["Urgent hospital evaluation for inhalation anthrax; IV antibiotics; no isolation needed", "Send home with flu advice",
                                 "Isolate as highly contagious", "Decon shower only"],
                       best: [0], why: "Inhalation anthrax starts out looking like flu, and in 2001 postal workers were among those who died. It doesn't spread person to person.", litter: true),
                Victim(p: P(1480, 520), name: "Office staffer",
                       signs: "Opened the letter. Powder on her sleeves. No symptoms.",
                       options: ["Remove clothing gently, bag as evidence, soap-and-water shower, start PEP pending results",
                                 "Brush the powder off and return to work", "Blow the powder off with compressed air", "Wait for lab results before doing anything"],
                       best: [0], why: "Remove clothing gently, shower, and start prophylaxis early. Never brush or blow powder: that puts spores back in the air."),
            ]
            m.clues = [Clue(p: P(1700, 220), title: "LETTER (PHOTOCOPY)",
                            text: "A short threatening note in block capitals. Envelope taped at every seam, no return address. A deliberate mailing."),
                       Clue(p: P(330, 140), title: "MAINTENANCE LOG",
                            text: "Sorter #4 jammed 13:00 two days ago. Cleared and blown out with compressed air. Area not ventilated afterward."),
                       Clue(p: P(160, 460), title: "CDC ALERT",
                            text: "Hand-held immunoassays are screening tools only. Confirmation requires PCR and culture at a Laboratory Response Network lab. Keep every sample separate.")]
            m.surveys = [Survey(p: P(600, 520), name: "Sorting floor"), Survey(p: P(1500, 400), name: "Office suite"), Survey(p: P(1000, 900), name: "HVAC intake")]
            m.props = [(R(560, 230, 280, 120), rgba(0.30, 0.32, 0.34), "SORTER #4"), (R(1540, 260, 120, 60), rgba(0.40, 0.30, 0.20), "DESK"),
                       (R(980, 960, 160, 100), rgba(0.25, 0.28, 0.30), "AIR HANDLER")]
            return m
        },
        candidates: ["BA", "BT", "HOAX_STARCH", "HOAX_TALC", "HOAX_SODA", "CLEAN"], multiID: false,
        protocols: chemProtocols, bestProtocol: { _ in [4] }, decon: { _ in .bioSpore }, required: 4,
        history: { _ in "In autumn 2001, letters containing Bacillus anthracis spores were mailed to news media and two US Senate offices. Five people died, including two postal workers, and 17 more fell ill. Mail-sorting machines pushed spores through envelope seams and contaminated whole facilities. Thousands of people took antibiotic prophylaxis. Hundreds of hoax powder letters followed. A deliberate act of bioterrorism." },
        ambientWind: 0.0, ambientRumble: 0.15, siren: false, suggestedSensor: .pid,
        alertLoc: "MAIL PROCESSING CENTRE AND GOVERNMENT OFFICE SUITE",
        alertDispatch: "WHITE POWDER RELEASED FROM AN OPENED ENVELOPE. ONE EMPLOYEE HOSPITALISED.",
        litters: 1),

    // ------------------------------------------------------------------ 8
    MissionDef(
        id: "C4", division: .chembio, year: "PRESENT", op: "OPERATION PLACARD", title: "Rail Yard / Refinery Release",
        location: "Rail siding beside a chemical plant", inspired: "Composite of real derailments and refinery releases",
        window: 30, realSecs: 330, doseLimit: 0, windDeg: 60, windSpeed: 3, variants: 3,
        threat: { v in [Threat.accident, .accident, .terrorism][v] },
        briefing: { v in [
            "## 05:40 LOCAL // COUNTY HAZMAT // 911 CENTRE",
            ">> ...tank car on its side at the plant siding... cloud drifting toward the ditch...",
            v == 1 ? "-- Driver: 'Red diamond on the car. Smells like gasoline. Liquid running into the ditch.'"
                   : "-- Driver: 'White diamond with a skull on it. There's a yellow-green haze lying in the ditch.'",
            "-- Plant guard: 'Two workers down by the siding. Coughing, dizzy.'",
            "## Read the placard before you trust anyone's story. Check the US DOT ERG guide.",
            "## TELEMETRY: wind 3 m/s toward the SE. Low ground lies downwind. Heavy gases pool.",
            "!! OPERATIONAL LIMIT: 30 MIN // CHOOSE THE 5-GAS METER'S FIFTH SENSOR TO MATCH THE PRODUCT",
            "## Accident or sabotage? Track switch, valve and fence will tell you.",
        ] },
        build: { v in
            var m = FieldMap()
            m.ground = rgba(0.11, 0.11, 0.09); m.dark = 0.3
            let cl = v != 1
            let ag = cl ? "CL2" : "BENZENE"
            m.areas = [entry,
                       Area(r: R(220, 450, 1560, 400), name: "RAIL SIDING", floor: rgba(0.13, 0.12, 0.10)),
                       Area(r: R(300, 60, 520, 360), name: "CONTROL BUILDING", floor: rgba(0.15, 0.15, 0.15)),
                       Area(r: R(1400, 60, 420, 320), name: "PUMP HOUSE", floor: rgba(0.13, 0.13, 0.14)),
                       Area(r: R(900, 900, 820, 260), name: "DRAINAGE DITCH (LOW GROUND)", floor: rgba(0.08, 0.10, 0.07))]
            m.walls = room(R(300, 60, 520, 360), doors: [("s", 200, 110)]) + room(R(1400, 60, 420, 320), doors: [("s", 150, 110)]) + border
            m.plumes = [Plume(p: P(1300, 620), q: cl ? 600 : 9000, spread: 50, length: 900, agent: ag,
                              color: cl ? rgba(0.75, 0.85, 0.25, 0.22) : nil)]
            m.gas = [cl ? Gas(r: R(900, 900, 820, 260), o2: 19.0, cl2: 300, label: "chlorine pooled in ditch")
                        : Gas(r: R(900, 900, 820, 260), o2: 19.8, lel: 45, voc: 5400, label: "benzene vapor in ditch")]
            if !cl { m.puddles = [Puddle(p: P(1300, 700), r: 70, agent: "BENZENE", level: 1.0, color: rgba(0.55, 0.45, 0.25, 0.35))] }
            m.samples = [SamplePt(p: P(1290, 600), label: "Valve residue swab", kind: .swab, contents: [ag]),
                         SamplePt(p: P(1100, 990), label: "Ditch air canister", kind: .air, contents: [ag]),
                         SamplePt(p: P(1360, 770), label: "Soil at the spill", kind: .soil, contents: [ag]),
                         SamplePt(p: P(520, 240), label: "Control-room air (control)", kind: .air, contents: ["CLEAN"])]
            m.victims = [cl ? Victim(p: P(1000, 760), name: "Rail worker",
                                     signs: "Coughing, wheezing, burning eyes, came scrambling up out of the ditch.",
                                     options: ["Move uphill and upwind to fresh air, oxygen, flush eyes, observe for delayed pulmonary edema",
                                               "DuoDote", "Rinse with bleach solution", "Tag GREEN: the cough will pass"],
                                     best: [0], why: "Chlorine damages the airways, and fluid in the lungs can appear hours later. Fresh air, oxygen and observation. Never give nerve-agent antidotes for an irritant gas.", litter: true)
                            : Victim(p: P(1000, 760), name: "Refinery operator",
                                     signs: "Dizzy, headache, slurred speech. Clothes soaked with a sweet, fuel-smelling liquid.",
                                     options: ["Remove soaked clothing, soap-and-water wash, fresh air, supportive care; no ignition sources",
                                               "DuoDote", "Scrub with STB slurry", "Tag GREEN"],
                                     best: [0], why: "Benzene depresses the brain and soaks through skin. Strip, wash with surfactant, get fresh air, and keep ignition sources away.", litter: true),
                         Victim(p: P(640, 520), name: "Plant guard",
                                signs: "Anxious, mild throat irritation, ran out early.",
                                options: ["Tag GREEN: fresh air, rinse eyes, observe, register", "Tag RED", "DuoDote", "Send back inside"],
                                best: [0], why: "Minor and walking. Register and observe.")]
            let placard = cl ? "White diamond with skull and crossbones, '2' at the bottom: 2.3 POISON GAS. Orange panel: UN 1017 (CHLORINE). ERG Guide 124: toxic and oxidizing gas, heavier than air."
                             : "Red diamond with a flame, '3' at the bottom: FLAMMABLE LIQUID. Orange panel: UN 1114 (BENZENE). ERG Guide 130: flammable, vapors travel to ignition sources."
            let valve = ["The shell was punctured in the derailment. Valves closed, seals intact.",
                         "Corrosion pitting and a fatigue crack across the valve body. Replacement deferred 14 months.",
                         "Security seal cut cleanly. Fresh wrench marks on the valve bonnet. Padlock missing."][v]
            let sw = ["Track switch left lined toward the occupied siding: a human-error derailment.",
                      "Maintenance tag: 'valve body thinning, replace at next turnaround'. The turnaround was postponed.",
                      "Switch normal. Perimeter fence cut near the siding; boot prints lead to the car."][v]
            m.clues = [Clue(p: P(1180, 700), title: "PLACARD", text: placard),
                       Clue(p: P(1340, 560), title: "VALVE INSPECTION", text: valve),
                       Clue(p: P(720, 720), title: v == 1 ? "MAINTENANCE TAG" : "TRACK SWITCH", text: sw)]
            m.surveys = [Survey(p: P(1100, 560), name: "Upwind of car"), Survey(p: P(1300, 880), name: "Ditch edge"), Survey(p: P(600, 480), name: "Control door")]
            m.props = [(R(1100, 560, 360, 110), cl ? rgba(0.80, 0.80, 0.78) : rgba(0.15, 0.15, 0.15), cl ? "TANK CAR // 1017" : "TANK CAR // 1114")]
            return m
        },
        candidates: ["CL2", "BENZENE", "GB", "HD", "NIC", "CLEAN"], multiID: false,
        protocols: chemProtocols, bestProtocol: { v in v == 1 ? [1] : [2] }, decon: { v in v == 1 ? .hydrocarbon : .toxicGas }, required: 3,
        history: { v in [
            "Chlorine tank-car derailments, such as Graniteville, South Carolina in 2005, where a misaligned switch caused a release that killed nine people, show how a single human error can turn a rail siding into a toxic-gas disaster. Placards and the ERG are a responder's first and best identification tool. An accident.",
            "Refinery and terminal releases of benzene and other hydrocarbons are usually traced to corrosion and deferred maintenance. The main dangers are fire and explosion as much as toxicity, so the LEL reading drives every move. An accident.",
            "Deliberate attacks on hazmat rail cars are rare, but security seals, fencing and tamper evidence exist because the consequences could be catastrophic. Cut seals and tool marks mark sabotage, and that makes it a crime scene and a terrorism investigation.",
        ][v] },
        ambientWind: 0.4, ambientRumble: 0.1, siren: false, suggestedSensor: .pid,
        alertLoc: "RAIL SIDING BESIDE A CHEMICAL PLANT",
        alertDispatch: "TANK CAR ON ITS SIDE, PRODUCT RELEASING, TWO WORKERS DOWN.",
        litters: 1),

    // ------------------------------------------------------------------ 9
    MissionDef(
        id: "C5", division: .chembio, year: "PRESENT", op: "OPERATION VAPOR TRAIL", title: "The Nicotine Level",
        location: "E-liquid bottling warehouse, light-industrial park", inspired: "Composite of real liquid-nicotine poisonings",
        window: 45, realSecs: 360, doseLimit: 0, windDeg: 0, windSpeed: 1, variants: 1,
        threat: { _ in .accident },
        briefing: { _ in [
            "## 14:05 LOCAL // REGIONAL HAZMAT // 911 CENTRE",
            "-- Caller (neighbor): 'NERVE GAS! Everyone in the warehouse is throwing up and shaking!'",
            "-- Paramedic: 'Drooling, sweating, vomiting, tremors. That's cholinergic, right? Want DuoDote for everyone?'",
            ">> ...agricultural supply store next door stocks organophosphate pesticides...",
            "## The building bottles vape e-liquid. Forklift incident reported minutes before the calls.",
            "## Symptoms overlap. Watch the pulse, blood pressure and pupils. Let the lab decide.",
            "!! OPERATIONAL LIMIT: 45 MIN // LIQUID CONTACT HAZARD // DON'T STEP IN SPILLS",
            "## TASKS: sample the spill and the neighbor's stock, triage, find out what this really is.",
        ] },
        build: { _ in
            var m = FieldMap()
            m.ground = rgba(0.12, 0.12, 0.11); m.dark = 0.1
            m.areas = [entry,
                       Area(r: R(220, 60, 1100, 720), name: "WAREHOUSE FLOOR / BOTTLING LINE", floor: rgba(0.16, 0.16, 0.15)),
                       Area(r: R(1400, 60, 560, 520), name: "AG-SUPPLY STORE (NEXT DOOR)", floor: rgba(0.14, 0.15, 0.12)),
                       Area(r: R(220, 860, 520, 380), name: "OFFICE", floor: rgba(0.15, 0.14, 0.13)),
                       Area(r: R(820, 860, 1140, 380), name: "PARKING LOT", floor: rgba(0.11, 0.11, 0.11))]
            m.walls = room(R(220, 60, 1100, 720), doors: [("w", 450, 110), ("s", 500, 120)]) + room(R(1400, 60, 560, 520), doors: [("s", 200, 110)])
                + room(R(220, 860, 520, 380), doors: [("n", 300, 110)]) + border
            m.puddles = [Puddle(p: P(900, 400), r: 90, agent: "NIC", level: 3.0, color: rgba(0.85, 0.80, 0.55, 0.30)),
                         Puddle(p: P(1010, 480), r: 40, agent: "NIC", level: 1.5, color: rgba(0.85, 0.80, 0.55, 0.25)),
                         Puddle(p: P(790, 530), r: 30, agent: "NIC", level: 1.2, color: rgba(0.85, 0.80, 0.55, 0.25))]
            m.plumes = [Plume(p: P(900, 400), q: 6, spread: 70, length: 300, agent: "NIC")]
            m.samples = [SamplePt(p: P(900, 380), label: "Drum spill liquid", kind: .vial, contents: ["NIC"], secs: 5),
                         SamplePt(p: P(780, 545), label: "Forklift tyre swab", kind: .swab, contents: ["NIC"]),
                         SamplePt(p: P(500, 1000), label: "Worker glove (evidence bag)", kind: .evidence, contents: ["NIC"]),
                         SamplePt(p: P(1650, 300), label: "Ag-store shelf wipe (control)", kind: .wipe, contents: ["CLEAN"])]
            m.victims = [
                Victim(p: P(680, 440), name: "Forklift operator",
                       signs: "Soaked in liquid from the punctured drum. Vomiting, drooling, sweating, tremor. Pulse 128, blood pressure HIGH. Pupils normal to slightly wide.",
                       options: ["Remove soaked clothing, wash skin with soap and water, airway and oxygen; NO oxime",
                                 "DuoDote ×3: it's a nerve agent", "Tag GREEN: food poisoning", "Rinse with 0.5% bleach"],
                       best: [0], why: "A fast pulse, high blood pressure and normal pupils point away from nerve agent and toward nicotine. Washing the liquid off is the most important step, because the skin is still absorbing it."),
                Victim(p: P(1120, 620), name: "Line worker (collapsed)",
                       signs: "Collapsed 40 minutes in. Pulse 44, low blood pressure, weak, shallow breathing.",
                       options: ["Tag RED: airway/ventilation support; atropine for symptomatic slow pulse only; NO oxime",
                                 "Pralidoxime", "Tag GREEN", "Scrub with STB slurry"],
                       best: [0], why: "This is the late, severe phase of nicotine poisoning. Support breathing and circulation. Atropine can treat the slow pulse, but pralidoxime does nothing here because cholinesterase isn't inhibited.", litter: true),
                Victim(p: P(450, 960), name: "Office clerk",
                       signs: "Noticed a 'peppery' smell, mild headache and nausea. No skin contact.",
                       options: ["Tag GREEN: fresh air, check skin, wash hands and face, observe", "DuoDote", "Tag RED", "Midazolam"],
                       best: [0], why: "Minor. Low-volatility nicotine is mostly a skin-contact hazard, not a vapor hazard."),
            ]
            m.clues = [Clue(p: P(160, 460), title: "911 TRANSCRIPT",
                            text: "'Nerve gas! Everyone is throwing up and shaking!' The caller is the ag-store manager next door. He hasn't been inside the warehouse."),
                       Clue(p: P(960, 320), title: "DRUM LABEL",
                            text: "UN1654 NICOTINE, class 6.1 (TOXIC). 'Nicotine USP 99%': concentrate for e-liquid mixing. Punctured low on the side by a forklift tine."),
                       Clue(p: P(1520, 480), title: "AG-STORE STOCK",
                            text: "Organophosphate pesticide stock sealed, still shrink-wrapped on the pallet. No leaks. No odor."),
                       Clue(p: P(560, 200), title: "SAFETY DATA SHEET",
                            text: "Nicotine: fatal in contact with skin. Rapidly absorbed. Wear chemical-resistant gloves and suit. Not a cholinesterase inhibitor.")]
            m.surveys = [Survey(p: P(700, 300), name: "Bottling line"), Survey(p: P(1600, 420), name: "Ag-store aisle"), Survey(p: P(1100, 1000), name: "Parking lot")]
            m.props = [(R(860, 340, 70, 70), rgba(0.25, 0.35, 0.55), "DRUM"), (R(720, 500, 110, 60), rgba(0.85, 0.60, 0.10), "FORKLIFT"),
                       (R(400, 150, 360, 50), rgba(0.30, 0.30, 0.32), "BOTTLING LINE"), (R(1500, 150, 300, 60), rgba(0.30, 0.35, 0.25), "OP PESTICIDE PALLET")]
            return m
        },
        candidates: ["NIC", "GB", "OPPEST", "VX", "BENZENE", "CLEAN"], multiID: false,
        protocols: chemProtocols, bestProtocol: { _ in [1] }, decon: { _ in .nicotine }, required: 3,
        history: { _ in "Concentrated liquid nicotine, sold for mixing vape e-liquids, has caused serious poisonings and deaths, including a toddler in 2014 that prompted US child-resistant packaging laws for liquid nicotine. Workers handling tobacco or nicotine get a milder occupational form, green tobacco sickness. Early signs look cholinergic, but nicotine doesn't inhibit cholinesterase, so oximes don't help. An industrial accident." },
        ambientWind: 0.1, ambientRumble: 0.15, siren: false, suggestedSensor: .pid,
        alertLoc: "LIGHT-INDUSTRIAL PARK, BOTTLING WAREHOUSE",
        alertDispatch: "CALLER SCREAMING NERVE GAS. EVERYONE INSIDE VOMITING AND SHAKING.",
        litters: 1),
]

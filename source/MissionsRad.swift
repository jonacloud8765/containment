// CONTAINMENT — Nuclear & Radiological track (TOP SECRET clearance).
// Scenarios are respectful, simplified reconstructions of public historical events for training play.

import AppKit

private let entry = Area(r: R(0, 500, 220, 300), name: "ENTRY CONTROL / DECON LINE", floor: rgba(0.13, 0.15, 0.13), rate: 0.2)

private func radVictimOptions(_ o: [String]) -> [String] { o }

let radMissions: [MissionDef] = [
    // ------------------------------------------------------------------ 1
    MissionDef(
        id: "R1", division: .nuclear, year: "1986", op: "OPERATION GRAPHITE", title: "Pripyat Exclusion Zone",
        location: "Reactor Unit 4 yard, Pripyat, Ukrainian SSR", inspired: "Inspired by the Chernobyl disaster",
        window: 20, realSecs: 330, doseLimit: 100, windDeg: 225, windSpeed: 4, variants: 1,
        threat: { _ in .accident },
        briefing: { _ in [
            "## 02:10 LOCAL // CHANNEL 4 // NUCLEAR SITE EMERGENCY DECLARED",
            ">> ...two explosions at the reactor building... the roof is gone... fire on the turbine hall...",
            "-- Fire crew: 'Black chunks all over the yard. Hot. My throat tastes like metal.'",
            "-- Operator: 'Core instrumentation offline. We don't know what is left of the reactor.'",
            "!! Area dose-rate instruments issued to first crews pegged at their top range.",
            "## TELEMETRY: surface wind carrying the plume NW. Smoke and ash over the yard.",
            "## SOURCE TERM: unknown. Possible core breach and graphite fire.",
            "!! OPERATIONAL LIMIT: 20 MIN ENTRY WINDOW // TURN-BACK DOSE 100 mSv (EPA PAG 10 rem: protecting critical infrastructure)",
            "## TASKS: map dose rates, collect fallout / fuel-fragment / air samples, triage casualties.",
            "## Unknown: sabotage? Military strike? Operator error? Assess before you deploy.",
        ] },
        build: { _ in
            var m = FieldMap()
            m.ground = rgba(0.09, 0.09, 0.085); m.ash = true; m.dark = 0.45
            m.areas = [entry,
                       Area(r: R(220, 500, 500, 300), name: "ACCESS ROAD", floor: rgba(0.12, 0.12, 0.11), rate: 4_000),
                       Area(r: R(220, 100, 500, 400), name: "TURBINE HALL", floor: rgba(0.14, 0.13, 0.12), rate: 1_800),
                       Area(r: R(220, 800, 500, 440), name: "CABLE ROOM / FLOODED BASEMENT", floor: rgba(0.08, 0.10, 0.12), rate: 6_000),
                       Area(r: R(720, 100, 800, 1140), name: "UNIT 4 YARD: DEBRIS FIELD", floor: rgba(0.13, 0.11, 0.09), rate: 22_000),
                       Area(r: R(1520, 60, 480, 1180), name: "REACTOR BUILDING (NO ENTRY)", floor: rgba(0.20, 0.08, 0.05), rate: 0)]
            m.walls = room(R(220, 100, 500, 400), t: 18, shield: 0.08, doors: [("s", 180, 110), ("e", 260, 100)])
                + room(R(220, 800, 500, 440), t: 18, shield: 0.06, doors: [("n", 300, 110)])
                + [Wall(r: R(1520, 60, 60, 1180), shield: 0.004),
                   Wall(r: R(960, 430, 40, 240), shield: 0.10), Wall(r: R(1150, 780, 220, 40), shield: 0.10),
                   Wall(r: R(1260, 220, 40, 210), shield: 0.10), Wall(r: R(860, 900, 160, 36), shield: 0.12),
                   Wall(r: R(0, 0, 2000, 20), shield: 1), Wall(r: R(0, 1280, 2000, 20), shield: 1)]
            m.rad = [RadSrc(p: P(1760, 650), rate: 5e8, band: 1, name: "BREACHED CORE"),
                     RadSrc(p: P(900, 330), rate: 2.0e6, band: 1, name: "graphite block"),
                     RadSrc(p: P(1100, 600), rate: 3.0e6, band: 1, name: "graphite block"),
                     RadSrc(p: P(1320, 960), rate: 2.5e6, band: 1, name: "fuel fragment"),
                     RadSrc(p: P(1000, 1080), rate: 1.5e6, band: 1, name: "graphite block"),
                     RadSrc(p: P(1420, 430), rate: 4.0e6, band: 1, name: "fuel fragment")]
            m.contam = [Contam(p: P(900, 520), r: 120, cpm: 60_000), Contam(p: P(1200, 400), r: 160, cpm: 90_000),
                        Contam(p: P(1150, 1000), r: 150, cpm: 70_000), Contam(p: P(600, 650), r: 90, cpm: 15_000),
                        Contam(p: P(450, 1050), r: 140, cpm: 30_000)]
            m.gas = [Gas(r: R(238, 818, 464, 404), o2: 17.6, co: 380, voc: 6, label: "smoke-logged basement"),
                     Gas(r: R(1380, 480, 140, 340), o2: 20.4, co: 160, label: "fire front")]
            m.samples = [SamplePt(p: P(1050, 300), label: "Fallout ash swab (yard)", kind: .swab, contents: ["CS137", "CS134", "I131"]),
                         SamplePt(p: P(1360, 700), label: "Fuel-fragment smear", kind: .wipe, contents: ["ZR95", "RU103", "CS137", "CS134"], secs: 5),
                         SamplePt(p: P(820, 1180), label: "Air filter cassette (downwind fence)", kind: .air, contents: ["I131", "CS137"]),
                         SamplePt(p: P(450, 1160), label: "Basement water", kind: .vial, contents: ["CS137", "CS134"]),
                         SamplePt(p: P(600, 170), label: "Roof-drain sediment", kind: .soil, contents: ["CS137", "CS134", "I131", "RU103"])]
            m.victims = [
                Victim(p: P(860, 800), name: "Firefighter at hydrant",
                       signs: "Vomiting began within an hour of arrival. Reddened skin on face and hands. Dizzy, insists on going back to the hose line.",
                       options: ["Tag RED: suspected acute radiation syndrome. Evacuate now; medical care before full decon",
                                 "Give KI tablet and return him to the hose line", "Complete full decon first, then transport",
                                 "Tag GREEN: dehydration, rest in place"],
                       best: [0], why: "Vomiting soon after exposure signals a high dose. Life-threatening needs come before radiological decon; removing outer gear protects the rescuers. KI only protects the thyroid from radioiodine.", litter: true),
                Victim(p: P(420, 300), name: "Plant operator",
                       signs: "Walked out of the control area. No vomiting yet. Personal dosimeter off-scale. Asking to go back for colleagues.",
                       options: ["Remove from service. Log dosimeter, send to medical monitoring and dose reconstruction",
                                 "Clear to return: no symptoms means low dose", "Give Prussian blue now", "Tag BLACK (expectant)"],
                       best: [0], why: "No early symptoms doesn't rule out a significant dose. Remove him from service, reconstruct the dose, and follow his blood counts."),
            ]
            m.clues = [Clue(p: P(520, 430), title: "SHIFT LOG FRAGMENT",
                            text: "01:23: turbine rundown test in progress... sudden power surge... two explosions. Roof destroyed. Graphite and fuel debris on the yard. Fire on the turbine-hall roof. No evidence of intruders or weapons."),
                       Clue(p: P(300, 720), title: "DOSIMETRIST NOTE",
                            text: "The low-range meters we had pegged everywhere outside. Your modern ion chamber reads to 10 Sv/h. Read it in mSv/h, keep concrete between you and the debris, and don't linger."),
                       Clue(p: P(690, 610), title: "WIND TELEMETRY",
                            text: "Surface wind carrying the plume NW, away from the yard. Fallout heaviest downwind. Radioiodine is in the plume: the public will need KI and sheltering or evacuation.")]
            m.surveys = [Survey(p: P(780, 540), name: "Yard edge"), Survey(p: P(1220, 560), name: "Debris field centre"),
                         Survey(p: P(500, 940), name: "Basement stair")]
            m.props = [(R(300, 560, 130, 56), Pal.suitRed, "FIRE ENGINE"), (R(1590, 520, 300, 260), rgba(0.35, 0.12, 0.05), "UNIT 4 // BREACH")]
            return m
        },
        candidates: ["CS137", "CS134", "I131", "RU103", "ZR95", "CO60", "IR192", "K40", "NONE"], multiID: true,
        protocols: radProtocols, bestProtocol: { _ in [0] }, decon: { _ in .radParticulate }, required: 3,
        history: { _ in "On 26 April 1986 a safety test on Chernobyl Unit 4 ended in a power excursion and explosions that destroyed the reactor and started a graphite fire that burned for about ten days. Two workers died that night, and 28 firefighters and staff died of acute radiation syndrome within months. Radioiodine in milk caused the clearest long-term harm: childhood thyroid cancers, which prompt KI and food restrictions could have reduced. Cause: reactor design flaws combined with operating errors. An accident, not an attack." },
        ambientWind: 0.35, ambientRumble: 0.25, siren: false, suggestedSensor: .pid,
        alertLoc: "POWER STATION — REACTOR BUILDING AND TURBINE HALL",
        alertDispatch: "EXPLOSION AND FIRE AT A NUCLEAR SITE. CREWS ON SCENE REPORTING ILLNESS.",
        litters: 1),

    // ------------------------------------------------------------------ 2
    MissionDef(
        id: "R2", division: .nuclear, year: "1987", op: "OPERATION BLUE GLOW", title: "Goiânia Orphaned Source",
        location: "Scrapyard and homes, Goiânia, Brazil", inspired: "Inspired by the Goiânia accident",
        window: 60, realSecs: 420, doseLimit: 50, windDeg: 0, windSpeed: 1, variants: 1,
        threat: { _ in .accident },
        briefing: { _ in [
            "## 21:40 LOCAL // HEALTH SURVEILLANCE NET // CLUSTER ALERT",
            "-- Clinic: 'Several patients with burns that look like nothing we have seen. Nausea, hair loss.'",
            "-- Resident: 'My cousin had a powder that glowed blue at night. The children rubbed it on their skin.'",
            ">> ...a woman brought a bag of metal parts to the health office... physicist confirms high readings...",
            "## SUSPECTED SOURCE: medical radiotherapy head removed from an abandoned clinic.",
            "## TELEMETRY: calm night air, 1 m/s. Contamination spread by hands, shoes, pets and buses.",
            "!! OPERATIONAL LIMIT: 60 MIN WINDOW // TURN-BACK DOSE 50 mSv (EPA PAG 5 rem)",
            "## TASKS: map contamination, shield the remnant source, sample homes and yard, triage residents.",
            "## Theft for scrap? Deliberate poisoning? Accident? Decide what you think this is.",
        ] },
        build: { _ in
            var m = FieldMap()
            m.ground = rgba(0.10, 0.10, 0.09); m.dark = 0.65
            m.areas = [entry,
                       Area(r: R(220, 500, 1600, 300), name: "RUA 57 (STREET)", floor: rgba(0.13, 0.13, 0.12), rate: 2),
                       Area(r: R(1100, 80, 760, 420), name: "SCRAPYARD", floor: rgba(0.14, 0.12, 0.09), rate: 40),
                       Area(r: R(300, 80, 520, 420), name: "HOUSE A", floor: rgba(0.16, 0.13, 0.10), rate: 15),
                       Area(r: R(300, 800, 620, 440), name: "HOUSE B", floor: rgba(0.15, 0.13, 0.11), rate: 8),
                       Area(r: R(1100, 800, 760, 440), name: "VACANT LOT (CONTROL)", floor: rgba(0.10, 0.12, 0.09), rate: 0.15)]
            m.walls = room(R(300, 80, 520, 420), doors: [("s", 220, 100)]) + room(R(300, 800, 620, 440), doors: [("n", 250, 100)])
                + room(R(1100, 80, 760, 420), shield: 0.5, doors: [("s", 120, 140)])
                + room(R(1560, 160, 220, 200), shield: 0.35, doors: [("w", 120, 70)])
                + [Wall(r: R(0, 0, 2000, 20), shield: 1), Wall(r: R(0, 1280, 2000, 20), shield: 1)]
            m.rad = [RadSrc(p: P(1680, 250), rate: 1.0e6, band: 1, name: "SOURCE CAPSULE REMNANT"),
                     RadSrc(p: P(520, 250), rate: 2.0e4, band: 1, name: "powder on kitchen table"),
                     RadSrc(p: P(640, 1050), rate: 6.0e3, band: 1, name: "powder residue")]
            m.contam = [Contam(p: P(520, 260), r: 90, cpm: 200_000, glow: true), Contam(p: P(1400, 330), r: 140, cpm: 80_000, glow: true),
                        Contam(p: P(1000, 650), r: 70, cpm: 25_000, glow: true), Contam(p: P(640, 1050), r: 110, cpm: 60_000, glow: true),
                        Contam(p: P(1650, 260), r: 70, cpm: 900_000, glow: true), Contam(p: P(780, 620), r: 50, cpm: 9_000, glow: true)]
            m.samples = [SamplePt(p: P(1380, 360), label: "Scrapyard soil (near shed)", kind: .soil, contents: ["CS137"]),
                         SamplePt(p: P(540, 300), label: "Kitchen table wipe (House A)", kind: .wipe, contents: ["CS137"]),
                         SamplePt(p: P(1010, 690), label: "Street drain water", kind: .vial, contents: ["CS137"]),
                         SamplePt(p: P(600, 1000), label: "House B floor wipe", kind: .wipe, contents: ["CS137"]),
                         SamplePt(p: P(1520, 1100), label: "Vacant lot soil (control)", kind: .soil, contents: ["K40"])]
            m.victims = [
                Victim(p: P(420, 200), name: "Resident, House A",
                       signs: "Handled the glowing powder days ago and rubbed some on her skin. Nausea, vomiting, burns on the hands. Frisker off-scale on her hands.",
                       options: ["Remove outer clothing, survey, wash with soap and lukewarm water; urgent referral for Prussian blue and ARS care",
                                 "Give potassium iodide tablets", "Scrub skin hard with a stiff brush and hot water", "Tag GREEN: food poisoning"],
                       best: [0], why: "Prussian blue speeds caesium elimination; it was used in Goiânia. KI does nothing for caesium. Hard scrubbing and hot water push contamination through damaged skin.", litter: true),
                Victim(p: P(900, 560), name: "Worried neighbor",
                       signs: "No symptoms. Frisker shows light contamination on shoes only.",
                       options: ["Survey, remove shoes, shower, register for follow-up; reassure", "Prussian blue for the whole street",
                                 "Send home without a survey", "Isolate as contagious"],
                       best: [0], why: "Contaminated people aren't contagious. Clean them, register them, reassure them. Stigma did real harm in Goiânia."),
            ]
            m.clues = [Clue(p: P(1250, 620), title: "SCRAP DEALER STATEMENT",
                            text: "Two men sold me a heavy metal cylinder from the old clinic. We broke it open. The powder glowed blue in the dark, so people took pinches home to show family. Nobody knew it was dangerous."),
                       Clue(p: P(160, 470), title: "CLINIC RECORD",
                            text: "Radiotherapy institute relocated. A teletherapy unit was left in the abandoned building. The source head is now missing. No sign of a threat, demand or claim of responsibility."),
                       Clue(p: P(820, 740), title: "HEALTH OFFICE NOTE",
                            text: "A resident carried part of the device here by bus because she suspected it was making her family sick. Her suspicion is what started the response.")]
            m.surveys = [Survey(p: P(700, 650), name: "Street centre"), Survey(p: P(1300, 460), name: "Scrapyard gate"),
                         Survey(p: P(450, 420), name: "House A doorway")]
            m.tasks = [FieldTask(p: P(1620, 330), name: "Shield the capsule remnant",
                                 text: "Drape a lead shielding blanket over the remnant to cut the dose rate for everyone who follows.", secs: 6, effect: "shield0")]
            m.props = [(R(1180, 140, 160, 90), rgba(0.30, 0.25, 0.18), "SCRAP PILE"), (R(1420, 620, 120, 60), rgba(0.20, 0.28, 0.35), "BUS STOP")]
            return m
        },
        candidates: ["CS137", "CS134", "CO60", "IR192", "AM241", "K40", "RA226", "NONE"], multiID: true,
        protocols: radProtocols, bestProtocol: { _ in [1] }, decon: { _ in .radParticulate }, required: 3,
        history: { _ in "In September 1987 scavengers removed a caesium-137 teletherapy source from an abandoned clinic in Goiânia, Brazil. The glowing caesium chloride powder was passed among families and neighbors. Four people died, about 250 were found contaminated, and houses had to be demolished. Prussian blue was used to speed elimination of internal caesium. An accident of neglect and ignorance, not an attack, and still the core training case for orphaned sources." },
        ambientWind: 0.1, ambientRumble: 0.0, siren: false, suggestedSensor: .pid,
        alertLoc: "RESIDENTIAL STREET AND ADJACENT SCRAPYARD",
        alertDispatch: "CLINIC REPORTING A CLUSTER OF UNEXPLAINED BURNS AND VOMITING ACROSS ONE STREET.",
        litters: 1),

    // ------------------------------------------------------------------ 3
    MissionDef(
        id: "R3", division: .nuclear, year: "1999", op: "OPERATION BLUE FLASH", title: "Tokaimura Criticality",
        location: "Uranium conversion facility, Tokai, Ibaraki, Japan", inspired: "Inspired by the Tokaimura criticality accident",
        window: 25, realSecs: 330, doseLimit: 100, windDeg: 90, windSpeed: 2, variants: 1,
        threat: { _ in .accident },
        briefing: { _ in [
            "## 10:35 LOCAL // REGIONAL EOC // FUEL FACILITY EMERGENCY",
            "-- Worker: 'I saw a blue flash at the tank. Then I was sick on the floor.'",
            "!! Gamma area alarms tripped. Boundary NEUTRON monitors still reading. It hasn't stopped.",
            ">> ...three workers to hospital... vomiting... one unconscious briefly...",
            "## HYPOTHESIS: self-sustaining fission chain reaction (criticality) in process solution.",
            "## Neutrons go through PPE. Distance, concrete and water are your shielding.",
            "!! OPERATIONAL LIMIT: 25 MIN // TURN-BACK DOSE 100 mSv (EPA PAG 10 rem: preventing a continuing release)",
            "## TASKS: drain the tank cooling jacket, inject boric acid, collect blood / salt / soil samples.",
            "## Sabotage? Equipment failure? Procedural shortcut? Assess.",
        ] },
        build: { _ in
            var m = FieldMap()
            m.ground = rgba(0.10, 0.11, 0.11); m.dark = 0.2
            m.areas = [entry,
                       Area(r: R(220, 500, 480, 300), name: "SITE ROAD", floor: rgba(0.13, 0.13, 0.13), rate: 50),
                       Area(r: R(250, 80, 420, 380), name: "OFFICE / CANTEEN", floor: rgba(0.15, 0.15, 0.14), rate: 30),
                       Area(r: R(250, 840, 380, 360), name: "WORKER CLINIC TENT", floor: rgba(0.12, 0.15, 0.13), rate: 5),
                       Area(r: R(700, 150, 1000, 900), name: "CONVERSION BUILDING", floor: rgba(0.16, 0.16, 0.15), rate: 200),
                       Area(r: R(1200, 340, 320, 360), name: "PRECIPITATION TANK ROOM", floor: rgba(0.18, 0.15, 0.12), rate: 0)]
            m.walls = room(R(250, 80, 420, 380), doors: [("s", 160, 100)]) + room(R(250, 840, 380, 360), shield: 0.9, doors: [("n", 140, 100)])
                + room(R(700, 150, 1000, 900), t: 20, shield: 0.15, doors: [("w", 330, 120), ("s", 600, 120)])
                + room(R(1200, 340, 320, 360), t: 24, shield: 0.10, doors: [("w", 140, 80)])
                + [Wall(r: R(0, 0, 2000, 20), shield: 1), Wall(r: R(0, 1280, 2000, 20), shield: 1)]
            m.rad = [RadSrc(p: P(1380, 520), rate: 3.0e6, band: 2, neutron: 7.0e6, name: "PRECIPITATION TANK")]
            m.contam = [Contam(p: P(1300, 600), r: 80, cpm: 4_000)]
            m.tasks = [FieldTask(p: P(1150, 760), name: "Drain the cooling-water jacket",
                                 text: "Break the cooling-water line. Water in the jacket reflects neutrons back into the solution; draining it should drop the reaction rate.", secs: 8, effect: "drain"),
                       FieldTask(p: P(1560, 300), name: "Inject boric acid",
                                 text: "Inject boric acid into the tank. Boron absorbs neutrons and makes sure the reaction stays shut down.", secs: 6, effect: "boron")]
            m.samples = [SamplePt(p: P(420, 1030), label: "Worker blood sample", kind: .bio, contents: ["NA24"], secs: 3),
                         SamplePt(p: P(450, 180), label: "Canteen table salt", kind: .soil, contents: ["NA24"]),
                         SamplePt(p: P(1790, 980), label: "Soil at building wall", kind: .soil, contents: ["NA24", "K40"]),
                         SamplePt(p: P(820, 980), label: "Loading-door smear", kind: .wipe, contents: ["NONE"])]
            m.victims = [
                Victim(p: P(330, 960), name: "Worker A (at the tank)",
                       signs: "Saw a blue flash, vomited within minutes, lost consciousness briefly. Not externally contaminated.",
                       options: ["Tag RED: severe neutron/gamma exposure. Urgent transfer to a specialist radiation hospital; blood for Na-24 dosimetry",
                                 "Prussian blue", "Potassium iodide", "Decon shower, then send home"],
                       best: [0], why: "Vomiting within minutes means a very high dose. Na-24 in the blood measures the neutron dose. This is an irradiation, not contamination, so decon isn't the priority.", litter: true),
                Victim(p: P(540, 1100), name: "Worker C (next room)",
                       signs: "Nausea after about an hour, alert and talking.",
                       options: ["Tag YELLOW: Na-24 blood dosimetry, ARS monitoring, transfer", "Tag GREEN: send home", "DTPA chelation", "Hard skin scrub"],
                       best: [0], why: "A delayed, milder onset still calls for dosimetry and blood-count monitoring. DTPA is for transuranics, not neutron exposure."),
            ]
            m.clues = [Clue(p: P(560, 400), title: "PROCEDURE NOTE",
                            text: "To speed up the batch, enriched uranyl nitrate was poured by hand from steel buckets into a precipitation tank instead of the approved dissolution column. The tank's shape and water jacket were never meant to hold that much."),
                       Clue(p: P(840, 560), title: "NEUTRON MONITOR LOG",
                            text: "Boundary neutron monitor still elevated hours after the flash. The reaction is continuing on and off. No intrusion alarms; badge records show only shift staff."),
                       Clue(p: P(150, 470), title: "EVACUATION ORDER",
                            text: "Residents within 350 m evacuated. Shelter indoors within 10 km. Table salt and coins from nearby homes are being collected for neutron dose estimates.")]
            m.surveys = [Survey(p: P(760, 640), name: "Building entrance"), Survey(p: P(1100, 900), name: "Tank room exterior"),
                         Survey(p: P(1660, 720), name: "Boundary wall")]
            m.props = [(R(1300, 460, 160, 120), rgba(0.30, 0.32, 0.36), "TANK"), (R(300, 900, 90, 40), Pal.white, "COT"), (R(470, 1060, 90, 40), Pal.white, "COT")]
            return m
        },
        candidates: ["NA24", "CO60", "CS137", "I131", "K40", "IR192", "TC99M", "NONE"], multiID: true,
        protocols: radProtocols, bestProtocol: { _ in [3] }, decon: { _ in .radParticulate }, required: 3,
        history: { _ in "On 30 September 1999 at the JCO fuel-conversion plant in Tokai, Japan, workers poured enriched uranyl nitrate by hand into a precipitation tank. That started a criticality that kept going for about 20 hours, until crews drained the cooling-water jacket and added boric acid. Two of the three workers died. Na-24 measured in their blood, and in salt from nearby homes, was used to reconstruct the neutron doses. A procedural shortcut, not sabotage." },
        ambientWind: 0.15, ambientRumble: 0.1, siren: false, suggestedSensor: .pid,
        alertLoc: "FUEL PROCESSING FACILITY — CONVERSION BUILDING",
        alertDispatch: "AREA RADIATION ALARMS AT AN INDUSTRIAL SITE. THREE WORKERS DOWN.",
        litters: 1),

    // ------------------------------------------------------------------ 4
    MissionDef(
        id: "R4", division: .nuclear, year: "PRESENT", op: "OPERATION MANIFEST", title: "Port Radiological Alert",
        location: "Container terminal, berth 7", inspired: "Composite of real port-security procedures",
        window: 45, realSecs: 360, doseLimit: 50, windDeg: 180, windSpeed: 6, variants: 3,
        threat: { v in [Threat.benign, .criminal, .terrorism][v] },
        briefing: { v in [
            "## 04:12 LOCAL // PORT SECURITY OPERATIONS CENTRE",
            "!! Radiation portal monitor GAMMA alarm, lane 3, container MSKU-7Δ. Neutron channel: normal.",
            ">> ...truck stopped at the secondary inspection area... driver cooperative... cargo seal intact...",
            ["-- Customs: 'Declared as glazed ceramic tiles. We flag these every week.'",
             "-- Customs: 'Declared as pipeline inspection equipment. No radioactive-material papers.'",
             "-- Customs: 'Declared as industrial pumps. Shipper address doesn't exist. Booking paid in cash.'"][v],
            "## Most portal alarms are innocent: ceramics, fertilizer, granite, medical patients.",
            "## A shielded source or a dispersal device needs a very different response.",
            "!! OPERATIONAL LIMIT: 45 MIN // TURN-BACK DOSE 50 mSv",
            "## TASKS: take in-situ spectra, read the paperwork, check the interior, decide the response.",
        ] },
        build: { v in
            var m = FieldMap()
            m.ground = rgba(0.10, 0.11, 0.12); m.dark = 0.35
            m.areas = [entry,
                       Area(r: R(220, 500, 520, 300), name: "SECONDARY INSPECTION LANE", floor: rgba(0.13, 0.14, 0.15), rate: 0.1),
                       Area(r: R(740, 60, 1240, 1180), name: "CONTAINER STACKS", floor: rgba(0.12, 0.12, 0.13), rate: 0.08)]
            var walls: [Wall] = [Wall(r: R(0, 0, 2000, 20), shield: 1), Wall(r: R(0, 1280, 2000, 20), shield: 1)]
            for (i, y) in [100, 300, 860, 1060].enumerated() {
                walls.append(Wall(r: R(800, CGFloat(y), 520, 110), shield: 0.4))
                walls.append(Wall(r: R(1400 - CGFloat(i % 2) * 40, CGFloat(y), 540, 110), shield: 0.4))
            }
            // the flagged container (open doors at the east end)
            walls += [Wall(r: R(1380, 560, 280, 14), shield: 0.6), Wall(r: R(1380, 666, 280, 14), shield: 0.6),
                      Wall(r: R(1380, 560, 14, 120), shield: 0.6)]
            m.walls = walls
            switch v {
            case 0: m.rad = [RadSrc(p: P(1440, 600), rate: 5, band: 2), RadSrc(p: P(1520, 640), rate: 5, band: 2), RadSrc(p: P(1600, 610), rate: 5, band: 2)]
            case 1: m.rad = [RadSrc(p: P(1500, 620), rate: 120, band: 1, name: "radiography camera")]
            default: m.rad = [RadSrc(p: P(1480, 620), rate: 350, band: 1, name: "shielded source")]
            }
            let spec = [["K40", "RA226"], ["IR192"], ["CS137"]][v]
            m.samples = [SamplePt(p: P(1500, 530), label: "In-situ spectrum: container north wall", kind: .spectrum, contents: spec, secs: 6),
                         SamplePt(p: P(1700, 620), label: "In-situ spectrum: container doors", kind: .spectrum, contents: spec, secs: 6),
                         SamplePt(p: P(1440, 640), label: "Package surface wipe", kind: .wipe, contents: ["NONE"])]
            let inside = ["Pallets of glazed ceramic floor tiles, shrink-wrapped. Nothing else.",
                          "A yellow steel radiography camera with a torn trefoil label. No transport-index label, no Type B package papers (UN2916). Its lock is engaged.",
                          "A lead shielding 'pig' taped to a sealed plastic box with a battery pack and wires. DO NOT TOUCH. Back out, keep the perimeter, call the render-safe team."][v]
            let manifest = ["Bill of lading: 18 t glazed ceramic tiles. Consignee is a long-standing flooring importer.",
                            "Bill of lading: 'pipeline inspection equipment'. The shipper holds a radiography licence abroad but declared no radioactive material.",
                            "Bill of lading: 'industrial pumps, 2 units'. Shipper address is a vacant lot. Booking paid in cash 48 h before sailing."][v]
            m.clues = [Clue(p: P(450, 640), title: "PORTAL MONITOR PRINTOUT",
                            text: "Gamma alarm, sum of energy windows elevated. Neutron channel at background, so special nuclear material is unlikely. Spectroscopy is needed to identify the isotope."),
                       Clue(p: P(1340, 720), title: "BILL OF LADING", text: manifest),
                       Clue(p: P(1560, 620), title: "CONTAINER INTERIOR", text: inside)]
            m.victims = [Victim(p: P(600, 560), name: "Crane operator",
                                signs: "Worked about 2 h near the container. No symptoms. Anxious.",
                                options: ["Estimate the dose from time and distance (very low), survey, reassure, log", "Prussian blue",
                                          "Potassium iodide", "Admit for acute radiation syndrome"],
                                best: [0], why: "Dose from a shielded or NORM source at working distance is tiny. Reassure with data, not drugs.")]
            m.surveys = [Survey(p: P(1360, 520), name: "Container contact"), Survey(p: P(1180, 620), name: "5 m from container"),
                         Survey(p: P(900, 760), name: "Stack corridor")]
            m.props = [(R(300, 590, 200, 70), rgba(0.25, 0.30, 0.35), "TRUCK CAB"), (R(1394, 574, 266, 92), rgba(0.30, 0.18, 0.12), "MSKU-7Δ")]
            return m
        },
        candidates: ["K40", "RA226", "IR192", "CS137", "CO60", "AM241", "TC99M", "NONE"], multiID: true,
        protocols: radProtocols, bestProtocol: { v in [[6], [5], [4]][v] }, decon: { _ in .radParticulate }, required: 2,
        history: { v in [
            "Radiation portal monitors routinely alarm on naturally occurring radioactive material: ceramics, granite, potash fertilizer, even bananas. Spectroscopy that sorts out these innocent alarms quickly is most of the real job. This one was a false alarm.",
            "Lost, stolen and undeclared industrial radiography sources are a recurring real problem, and some have badly burned people who picked them up. Labels, package types and shipping papers exist so responders know what they're facing. A regulatory breach, not an attack.",
            "There's still no confirmed case of a dirty bomb being set off. Agencies plan for one anyway. Most of the harm would come from fear, disruption and cleanup cost rather than dose, so a calm perimeter and the render-safe team matter most. A deliberate device.",
        ][v] },
        ambientWind: 0.45, ambientRumble: 0.05, siren: false, suggestedSensor: .pid,
        alertLoc: "CONTAINER TERMINAL, BERTH 7",
        alertDispatch: "RADIATION PORTAL MONITOR ALARM ON AN INBOUND CONTAINER."),
]

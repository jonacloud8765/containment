// CONTAINMENT — additional present-day callouts: an unconventional attack in a shopping centre
// (three variants, one of which is nothing at all) and an arena biological release.

import AppKit

private let entry = Area(r: R(0, 500, 220, 300), name: "ENTRY CONTROL / DECON LINE", floor: rgba(0.13, 0.15, 0.13))
private let border = [Wall(r: R(0, 0, 2000, 20), shield: 1), Wall(r: R(0, 1280, 2000, 20), shield: 1)]

let extraChemMissions: [MissionDef] = [

    // ------------------------------------------------------------------ C6
    MissionDef(
        id: "C6", division: .chembio, year: "PRESENT", op: "OPERATION ATRIUM", title: "Shopping Centre Release",
        location: "Food court and service corridor, regional shopping centre",
        inspired: "Composite: opioid aerosol incidents, confined-space releases, and mass psychogenic illness",
        window: 25, realSecs: 330, doseLimit: 0, windDeg: 270, windSpeed: 0.4, variants: 3,
        threat: { v in [Threat.terrorism, .criminal, .benign][v] },
        briefing: { v in [
            "## 16:48 LOCAL // POLICE / FIRE JOINT CHANNEL // SHOPPING CENTRE, FOOD COURT LEVEL",
            ">> ...people collapsing near the fountain... security says dozens... the place is in a stampede...",
            [
             "-- Security: 'Two men left a sports bag by the air handler and walked out. Bag's still there, it's hissing.'",
             "-- Security: 'There's a bag by the air handler. Looks like a drug kit — bottles, a mask, tubing.'",
             "-- Security: 'There's a bag by the air handler. We don't know whose it is. Nobody will go near it.'",
            ][v],
            "-- Paramedic: 'Several are barely breathing. Pinpoint pupils. Others are hyperventilating and fine.'",
            "!! NOT EVERYONE WHO LOOKS AFFECTED IS POISONED. Crowd panic looks like a chemical event.",
            "## TELEMETRY: enclosed atrium, weak air movement W, recirculating HVAC. A confined space with 400 people in it.",
            "!! OPERATIONAL LIMIT: 25 MIN // CONFINED SPACE — DECON INSIDE, PORTABLE SPRAYER",
            "## TASKS: locate the source, sample it, triage by signs not by noise, carry the non-ambulatory out.",
            "## Attack? Criminal stupidity? Nothing at all? Decide what you are looking at.",
        ] },
        build: { v in
            var m = FieldMap()
            m.ground = rgba(0.13, 0.13, 0.14); m.dark = 0.12
            m.areas = [entry,
                       Area(r: R(220, 420, 1080, 460), name: "FOOD COURT ATRIUM", floor: rgba(0.17, 0.16, 0.15)),
                       Area(r: R(300, 60, 900, 360), name: "RETAIL CONCOURSE", floor: rgba(0.16, 0.16, 0.17)),
                       Area(r: R(1340, 300, 620, 640), name: "SERVICE CORRIDOR / PLANT", floor: rgba(0.11, 0.12, 0.13)),
                       Area(r: R(300, 920, 900, 330), name: "EXIT ROUTE / CAR PARK DOORS", floor: rgba(0.12, 0.12, 0.12))]
            m.walls = room(R(300, 60, 900, 360), doors: [("s", 380, 160)])
                + room(R(1340, 300, 620, 640), t: 18, doors: [("w", 240, 120)])
                + [Wall(r: R(300, 900, 380, 24)), Wall(r: R(820, 900, 380, 24)),
                   Wall(r: R(1300, 420, 24, 460))] + border
            let srcAgent = ["FENT", "FENT", "CLEAN"][v]
            if v < 2 {
                m.plumes = [Plume(p: P(1500, 620), q: 2.4, spread: 90, length: 1100, agent: "FENT")]
                m.powders = [Powder(p: P(1500, 620), r: 60, agent: "FENT", level: v == 0 ? 2.2 : 1.2)]
            } else {
                m.powders = [Powder(p: P(1500, 620), r: 45, agent: "HOAX_SUGAR", level: 1.0)]
            }
            m.gas = [Gas(r: R(1358, 318, 584, 604), o2: 20.5, voc: v < 2 ? 12 : 2, label: "plant room")]
            let bagText = [
                "A sports bag against the fresh-air intake. Inside: a compressed-air cylinder, a nebuliser head, tubing taped into the duct, and a sealed jar of off-white powder. Deliberate, and built to use the building's own ventilation.",
                "A sports bag against the fresh-air intake. Inside: a nebuliser, bottles, a respirator mask, and a jar of off-white powder. Receipts, a burner phone and a tally of cash. This is a drug-production kit stashed in a plant room, and the nebuliser vented into the duct by accident.",
                "A sports bag against the fresh-air intake. Inside: gym kit, a protein shaker leaking white powder, a wet towel and a padlock key. It has been there since this morning. It is someone's gym bag.",
            ][v]
            m.samples = [SamplePt(p: P(1500, 600), label: "Powder from the bag", kind: .evidence, contents: [srcAgent == "CLEAN" ? "HOAX_SUGAR" : "FENT"], secs: 5),
                         SamplePt(p: P(1430, 700), label: "Duct intake wipe", kind: .wipe, contents: [v < 2 ? "FENT" : "CLEAN"]),
                         SamplePt(p: P(700, 640), label: "Food court air canister", kind: .air, contents: [v < 2 ? "FENT" : "CLEAN"]),
                         SamplePt(p: P(640, 220), label: "Concourse air (control)", kind: .air, contents: ["CLEAN"])]
            var vics: [Victim] = [
                Victim(p: P(860, 600), name: "Man by the fountain",
                       signs: v < 2
                        ? "Barely breathing, six a minute and shallow. Pinpoint pupils. Limp. Skin DRY — no drooling, no runny nose, no sweating, no twitching."
                        : "Collapsed in the crush. Breathing fine. Pupils normal. Grazed scalp and a twisted ankle. Frightened.",
                       options: ["Naloxone + assisted ventilation and airway support (opioid picture)",
                                 "DuoDote ×3 — nerve agent",
                                 "Atropine alone",
                                 "Trauma care and reassurance; no antidote"],
                       best: v < 2 ? [0] : [3],
                       why: v < 2
                        ? "Pinpoint pupils with a DRY casualty is opioid, not nerve agent. Nerve agent floods the body with secretions — SLUDGE. Naloxone and ventilation. Atropine and oximes do nothing for an opioid."
                        : "No agent, no toxidrome. This is crush injury and fear. Giving antidotes to uninjured people is how a false alarm turns into a casualty list.",
                       litter: true),
                Victim(p: P(520, 760), name: "Teenager, hyperventilating",
                       signs: "Breathing very fast, tingling hands, dizzy, terrified. Pupils normal. Oxygen saturation 99%. Says everyone around her was 'gassed'.",
                       options: ["Move her to clean air, coach her breathing, observe. No antidote",
                                 "DuoDote",
                                 "Naloxone",
                                 "Tag RED and intubate"],
                       best: [0],
                       why: "Normal pupils, perfect saturation, fast breathing: this is hyperventilation from fear, and it is genuinely common in mass-casualty incidents. Treat the fear. An unnecessary autoinjector would make her a real patient."),
                Victim(p: P(1080, 500), name: "Security guard",
                       signs: v < 2
                        ? "Went to the plant room twice. Drowsy, slurred, pupils small, breathing slow but adequate. No secretions."
                        : "Drowsy and slurred. Smells strongly of alcohol. Pupils normal. Breathing fine.",
                       options: [v < 2 ? "Naloxone, oxygen, monitor for re-sedation" : "Supportive care, monitor, no antidote",
                                 "DuoDote ×3",
                                 "Tag GREEN, send home",
                                 "Midazolam"],
                       best: [0],
                       why: v < 2
                        ? "Opioid exposure from going back into the source room. Naloxone wears off faster than many opioids, so he can re-sedate: he gets monitored, not discharged."
                        : "Nothing chemical. Pupils and breathing are normal. He is drunk on shift, which is a disciplinary problem, not a toxicological one."),
            ]
            if v < 2 {
                vics.append(Victim(p: P(1180, 760), name: "Cleaner, collapsed in the corridor",
                                   signs: "Unresponsive, breathing three a minute, pinpoint pupils, lips blue. Dry skin.",
                                   options: ["Naloxone now, ventilate, litter carry to the decon line",
                                             "Full decon first, then treat", "DuoDote ×3", "Tag BLACK"],
                                   best: [0],
                                   why: "Life before decon. She is minutes from respiratory arrest; naloxone and ventilation come first, and she travels on a litter because she cannot walk.",
                                   litter: true))
            }
            m.victims = vics
            m.clues = [Clue(p: P(1480, 560), title: "THE BAG", text: bagText),
                       Clue(p: P(760, 500), title: "CCTV REVIEW",
                            text: [
                             "Two men enter the plant corridor at 16:31 carrying the bag, leave at 16:34 without it, and walk straight out to the car park. Faces covered. They never return.",
                             "One man enters at 15:50 with the bag and does not come out. He is one of the casualties. The bag was hidden, not planted.",
                             "A member of gym staff drops the bag in the corridor at 07:12 and forgets it. Nobody else goes near it all day.",
                            ][v]),
                       Clue(p: P(420, 560), title: "TRIAGE OFFICER",
                            text: "Dozens presenting, four genuinely critical. The rest have normal pupils and normal saturations. Sort by signs, not by volume: the loudest casualties are rarely the sickest.")]
            m.surveys = [Survey(p: P(760, 620), name: "Food court centre"), Survey(p: P(1400, 620), name: "Plant room door"),
                         Survey(p: P(600, 1000), name: "Exit route")]
            m.props = [(R(640, 540, 180, 90), rgba(0.20, 0.30, 0.38), "FOUNTAIN"),
                       (R(1420, 560, 150, 120), rgba(0.26, 0.28, 0.30), "AIR HANDLER"),
                       (R(1470, 600, 60, 40), rgba(0.35, 0.22, 0.12), "BAG"),
                       (R(400, 140, 300, 70), rgba(0.22, 0.24, 0.26), "RETAIL UNITS")]
            return m
        },
        candidates: ["FENT", "GB", "NIC", "OPPEST", "HOAX_SUGAR", "CL2", "CLEAN"], multiID: false,
        protocols: chemProtocols + ["Opioid protocol: naloxone + ventilation, no oxime; secure the source room"],
        bestProtocol: { v in v == 2 ? [5] : [6] },
        decon: { v in v == 2 ? .none : .opioid }, required: 3,
        history: { v in [
            "Aerosolised opioids have been used against people in an enclosed space once in the modern record: the 2002 Moscow theatre siege, where a fentanyl-derivative aerosol pumped through the ventilation killed around 130 hostages — most of them because nobody told the arriving medics what the agent was, and naloxone arrived too late. The lesson is not the chemistry; it is that responders who are told what they are facing can treat it.",
            "Clandestine drug production in service spaces is routine, and responders find fentanyl in bags, vehicles and storage units regularly. Occupational-health research has repeatedly shown that brief skin contact is NOT a serious risk to a responder in PPE — airborne powder is. The panic around responder fentanyl exposure has itself delayed care for real overdose patients.",
            "Mass psychogenic illness is a documented, ordinary phenomenon: a smell, a rumour and a crowd produce dozens of genuinely unwell-feeling people with no exposure at all. It has closed schools, malls and transit systems. Responders who treat the panic as poisoning create casualties out of bystanders.",
        ][v] },
        ambientWind: 0.05, ambientRumble: 0.3, siren: false, suggestedSensor: .pid,
        alertLoc: "REGIONAL SHOPPING CENTRE — FOOD COURT LEVEL",
        alertDispatch: "MASS COLLAPSE IN AN ENCLOSED PUBLIC SPACE. CROWD CRUSH IN PROGRESS.",
        litters: 2, confinedDecon: true),

    // ------------------------------------------------------------------ C7
    MissionDef(
        id: "C7", division: .chembio, year: "PRESENT", op: "OPERATION TURNSTILE", title: "Arena Aerosol Alarm",
        location: "Indoor arena concourse and roof plant, 14,000 seated",
        inspired: "Composite: biodetection false alarms, agro-aerosol misuse, and real bioterror response doctrine",
        window: 55, realSecs: 400, doseLimit: 0, windDeg: 135, windSpeed: 1.2, variants: 2,
        threat: { v in [Threat.terrorism, .benign][v] },
        briefing: { v in [
            "## 19:20 LOCAL // VENUE SECURITY / PUBLIC HEALTH JOINT CHANNEL",
            "!! Environmental biodetector on the arena concourse has gone to ALARM on a bacterial channel.",
            ">> ...fourteen thousand people inside... doors still open... nobody is sick...",
            [
             "-- Roof crew: 'There's a drone on the roof plant. It's got a tank and a spray boom bolted to it.'",
             "-- Roof crew: 'There's an agricultural drone on the roof. Groundskeeping says it's theirs.'",
            ][v],
            "## Biological aerosols are silent. No smell, no symptoms tonight. Incubation is days.",
            "## Biodetectors alarm on harmless relatives constantly. That is why they are a trigger, not a diagnosis.",
            "!! OPERATIONAL WINDOW: 55 MIN // LOWER ACUITY // CHANGE OUTER GLOVES BETWEEN SAMPLES [G]",
            "## TASKS: sample the device and the concourse separately, keep chain of custody, confirm by PCR and culture.",
            "## Get this wrong in either direction and you either evacuate 14,000 people for nothing, or you don't.",
        ] },
        build: { v in
            var m = FieldMap()
            m.ground = rgba(0.12, 0.12, 0.13); m.dark = 0.18
            m.areas = [entry,
                       Area(r: R(220, 460, 1000, 420), name: "CONCOURSE (DETECTOR ALARM)", floor: rgba(0.16, 0.15, 0.14)),
                       Area(r: R(300, 60, 820, 380), name: "SEATING BOWL ENTRANCE", floor: rgba(0.14, 0.16, 0.14)),
                       Area(r: R(1300, 120, 660, 520), name: "ROOF PLANT / INTAKE DECK", floor: rgba(0.11, 0.12, 0.13)),
                       Area(r: R(1300, 700, 660, 540), name: "LOADING DOCK", floor: rgba(0.12, 0.12, 0.12))]
            m.walls = room(R(300, 60, 820, 380), doors: [("s", 340, 160)])
                + room(R(1300, 120, 660, 520), t: 18, doors: [("w", 220, 120), ("s", 300, 120)])
                + [Wall(r: R(1240, 440, 24, 440))] + border
            let bug = v == 0 ? "BA" : "BT"
            m.powders = [Powder(p: P(1620, 380), r: 55, agent: bug, level: 1.6),
                         Powder(p: P(700, 640), r: 90, agent: bug, level: 0.5)]
            m.samples = [SamplePt(p: P(1620, 360), label: "Drone tank residue", kind: .evidence, contents: [bug], secs: 5),
                         SamplePt(p: P(1520, 300), label: "Spray boom swab", kind: .swab, contents: [bug]),
                         SamplePt(p: P(700, 660), label: "Concourse surface wipe", kind: .wipe, contents: [bug]),
                         SamplePt(p: P(840, 520), label: "Concourse air canister", kind: .air, contents: [bug]),
                         SamplePt(p: P(560, 220), label: "Seating bowl wipe (control)", kind: .wipe, contents: ["CLEAN"])]
            m.victims = [
                Victim(p: P(620, 560), name: "Concourse steward",
                       signs: "No symptoms. Was standing under the intake for most of the evening. Wants to know if he is going to die.",
                       options: ["Register him, gentle clothing removal and shower, start prophylaxis pending lab confirmation; tell him the truth about the timeline",
                                 "Send him home, it's probably a false alarm",
                                 "Isolate him as contagious",
                                 "Start antibiotics for the whole arena immediately"],
                       best: [0],
                       why: "Exposed-but-well people get registered, showered and started on prophylaxis that can be stopped if the lab clears it. Anthrax does not spread person to person, and mass-dosing 14,000 people before you have a result is its own harm."),
                Victim(p: P(960, 720), name: "Collapsed spectator",
                       signs: "Crushed against a barrier in the exit surge. Unconscious, breathing, obvious chest injury. Nothing to do with any agent.",
                       options: ["Trauma care and litter carry out now — this is a crush injury, not an exposure",
                                 "Full decon shower before touching her",
                                 "Anthrax prophylaxis first",
                                 "Leave her for the ambulance crews outside"],
                       best: [0],
                       why: "The evacuation hurt her, not the agent. Life before decon: she is carried out and treated. In real incidents the response itself causes a significant share of the injuries.",
                       litter: true),
                Victim(p: P(1500, 900), name: "Groundskeeper",
                       signs: "No symptoms. Agitated. Says the drone is his and he has the paperwork for what is in the tank.",
                       options: ["Take the statement, bag his clothing as evidence, register and shower him, and get the product label to the lab",
                                 "Arrest him and stop talking to him",
                                 "Release him; he explained it",
                                 "Start him on antibiotics and isolate him"],
                       best: [0],
                       why: "His paperwork is a lab lead, not a verdict. Register and decontaminate him either way, and let PCR decide whether his tank held a biopesticide or something else."),
            ]
            m.clues = [Clue(p: P(1560, 460), title: "THE DRONE",
                            text: [
                             "An agricultural spray drone, serial plate ground off, tank half empty, boom angled into the fresh-air intake. Flight battery still warm. No licence markings, no operator ID.",
                             "An agricultural spray drone with a groundskeeping asset tag and a pesticide label zip-tied to the frame: a Bacillus thuringiensis biopesticide, used on the pitch. It was parked on the roof to charge, upwind of the intake.",
                            ][v]),
                       Clue(p: P(480, 620), title: "BIODETECTOR PRINTOUT",
                            text: "Bacterial channel alarm, Bacillus-group signature. The unit cannot tell Bacillus anthracis from its harmless relatives. It is a trigger to sample, nothing more. Confirmation is PCR and culture at the reference laboratory."),
                       Clue(p: P(900, 420), title: "PUBLIC HEALTH LIAISON",
                            text: "No illness reported anywhere tonight, and we would not expect any for days. Decisions tonight are about prophylaxis and evidence, not treatment. Do not let anyone announce an agent before the laboratory has one."),
                       Clue(p: P(1420, 1050), title: "VENUE LOG",
                            text: [
                             "Roof access door forced at 17:40. No contractor booked. Camera on that stairwell was taped over.",
                             "Roof access booked to groundskeeping 17:30–19:00 for 'pitch treatment equipment charging'. Signed in, signed out.",
                            ][v])]
            m.surveys = [Survey(p: P(700, 560), name: "Concourse, under intake"), Survey(p: P(1560, 300), name: "Roof plant deck"),
                         Survey(p: P(520, 240), name: "Bowl entrance")]
            m.props = [(R(1560, 320, 130, 90), rgba(0.28, 0.30, 0.32), "DRONE"),
                       (R(1380, 200, 150, 110), rgba(0.24, 0.26, 0.28), "AIR INTAKE"),
                       (R(420, 520, 260, 70), rgba(0.22, 0.22, 0.24), "CONCESSIONS")]
            return m
        },
        candidates: ["BA", "BT", "HOAX_STARCH", "HOAX_SUGAR", "HOAX_TALC", "CLEAN"], multiID: false,
        protocols: chemProtocols + ["Stand down the biological response: harmless organism, no prophylaxis, release the venue"],
        bestProtocol: { v in v == 0 ? [4] : [6] },
        decon: { v in v == 0 ? .bioSpore : .none }, required: 3,
        history: { v in [
            "Environmental biodetection systems — the US BioWatch programme is the best-documented — have produced many alarms and no confirmed attacks. Every one had to be worked exactly like this: sample, chain of custody, PCR and culture at a reference laboratory, with prophylaxis started on the exposed and stopped if the lab clears them. Anthrax does not spread person to person, so isolation is never the answer.",
            "Bacillus thuringiensis is a commercial biopesticide sprayed on crops, sports pitches and parks worldwide. It is a close enough relative of Bacillus anthracis to set off hand-held immunoassays and field biodetectors, and it is one of the most common causes of biological false alarms. The confirmatory PCR targets — the pXO1 and pXO2 virulence plasmids — are what separate the two.",
        ][v] },
        ambientWind: 0.08, ambientRumble: 0.2, siren: false, suggestedSensor: .pid,
        alertLoc: "INDOOR ARENA — CONCOURSE AND ROOF PLANT",
        alertDispatch: "ENVIRONMENTAL BIODETECTOR IN ALARM WITH 14,000 PEOPLE INSIDE. NOBODY IS ILL.",
        litters: 1),
]

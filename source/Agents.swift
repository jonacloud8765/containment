// CONTAINMENT — CBRN Field Reference Guide.
// Content is limited to public, defensive responder knowledge: how each hazard shows up on
// detectors and in patients, the medical countermeasure, and decontamination. Gamma energies
// and half-lives are standard nuclear-data values. Sources: CDC/CHEMM/REMM, US DOT ERG,
// NIOSH, EPA PAG Manual (2017), FDA labels (Seizalam 2018, Cyfendus 2023, Radiogardase).

import Foundation

enum AgentKind { case isotope, chemical, biological, none }

enum DeconClass {
    case radParticulate, cwaNerve, bioSpore, toxicGas, hydrocarbon, nicotine, opioid, none
}

struct Agent {
    let id: String
    let name: String
    let kind: AgentKind
    let category: String
    var gammaKeV: [Double] = []
    var halfLifeH: Double = 0
    var halfLifeText = ""
    var m8 = "—", ims = "—", enzyme = "—", pH = "—", alkaloid = "—", tube = "—", gcms = "—"
    var ap4c = "—"            // flame spectrophotometry: which element bands light up
    var fent = "—"            // lateral-flow fentanyl immunoassay
    var hha = "—", gram = "—", spore = "—", iodine = "—", pcr = "—", culture = "—"
    /// AP4C element channels this agent lights: P, S, As, HNO.
    var bands: Set<Int> = []
    var signs = ""
    var treat = ""
    var decon = ""
}

/// AP4C channel names, in display order.
let ap4cBands = ["P", "S", "As", "HNO"]
let ap4cMeaning = ["phosphorus — nerve agent or organophosphate",
                   "sulfur — mustard / sulfur compounds",
                   "arsenic — lewisite / arsenicals",
                   "nitrogen — nitrogen compounds, some propellants"]

let agents: [String: Agent] = {
    var a: [Agent] = []
    // ---------- Radionuclides ----------
    a.append(Agent(id: "CS137", name: "Cs-137 (Caesium-137)", kind: .isotope, category: "Fission product; sealed medical/industrial sources",
                   gammaKeV: [661.7], halfLifeH: 263_500, halfLifeText: "30.1 y",
                   signs: "Internal contamination is silent at first. High external dose: nausea and vomiting (earlier onset means higher dose), skin burns, later marrow suppression (ARS).",
                   treat: "Prussian blue (Radiogardase) binds caesium in the gut and speeds its elimination. Life-threatening injuries take priority over decontamination.",
                   decon: "Remove outer clothing (removes most contamination), survey, wash with lukewarm water and soap. No chemical neutralizer exists for radioactivity."))
    a.append(Agent(id: "CS134", name: "Cs-134 (Caesium-134)", kind: .isotope, category: "Reactor activation product (fingerprint of reactor fuel)",
                   gammaKeV: [604.7, 795.9], halfLifeH: 18_090, halfLifeText: "2.06 y",
                   signs: "As Cs-137. A Cs-134/Cs-137 ratio points to reactor fuel rather than a sealed source.",
                   treat: "Prussian blue, as Cs-137.", decon: "As Cs-137."))
    a.append(Agent(id: "I131", name: "I-131 (Iodine-131)", kind: .isotope, category: "Volatile fission product",
                   gammaKeV: [364.5, 637.0], halfLifeH: 192.5, halfLifeText: "8.02 d",
                   signs: "Concentrates in the thyroid; children are most at risk.",
                   treat: "Potassium iodide (KI) blocks thyroid uptake. It works best just before or within hours of exposure, and only for radioiodine.",
                   decon: "Particulate and vapor: respiratory protection, then remove clothing and wash."))
    a.append(Agent(id: "RU103", name: "Ru-103 (Ruthenium-103)", kind: .isotope, category: "Fission product (reactor fire release)",
                   gammaKeV: [497.1], halfLifeH: 942, halfLifeText: "39.3 d",
                   signs: "Found in fuel-fragment fallout.", treat: "Contamination control.", decon: "As other particulates."))
    a.append(Agent(id: "ZR95", name: "Zr-95 (Zirconium-95)", kind: .isotope, category: "Refractory fission product (fuel particles)",
                   gammaKeV: [724.2, 756.7], halfLifeH: 1_536, halfLifeText: "64.0 d",
                   signs: "Marks dispersed fuel particles ('hot particles').", treat: "Contamination control.", decon: "As other particulates."))
    a.append(Agent(id: "CO60", name: "Co-60 (Cobalt-60)", kind: .isotope, category: "Industrial sterilizer / teletherapy / radiography",
                   gammaKeV: [1173.2, 1332.5], halfLifeH: 46_170, halfLifeText: "5.27 y",
                   signs: "Very penetrating gamma. Wearable PPE gives almost no protection.", treat: "Time, distance, shielding. ARS care.",
                   decon: "Usually a sealed source (no contamination) unless breached."))
    a.append(Agent(id: "IR192", name: "Ir-192 (Iridium-192)", kind: .isotope, category: "Industrial radiography camera source",
                   gammaKeV: [316.5, 468.1, 308.5], halfLifeH: 1_772, halfLifeText: "73.8 d",
                   signs: "Lost or undeclared radiography sources cause localized hand and skin burns.", treat: "Secure the source; regulator notification.",
                   decon: "Sealed source: survey only."))
    a.append(Agent(id: "AM241", name: "Am-241 (Americium-241)", kind: .isotope, category: "Smoke detectors / well-logging (alpha emitter)",
                   gammaKeV: [59.5], halfLifeH: 3_790_000, halfLifeText: "432 y",
                   signs: "Mainly an internal (inhaled) hazard.", treat: "Ca-DTPA / Zn-DTPA chelation for internal contamination.",
                   decon: "Alpha: survey with an alpha probe; wipe and contain."))
    a.append(Agent(id: "K40", name: "K-40 (Potassium-40)", kind: .isotope, category: "NORM: potash fertilizer, granite, ceramics, bananas",
                   gammaKeV: [1460.8], halfLifeH: 1.1e13, halfLifeText: "1.25 billion y",
                   signs: "A common cause of radiation-portal nuisance alarms.", treat: "None needed.", decon: "None needed."))
    a.append(Agent(id: "RA226", name: "Ra-226 series (Pb-214 / Bi-214)", kind: .isotope, category: "NORM: ceramics, zircon glazes, old luminous dials",
                   gammaKeV: [351.9, 609.3, 1764.5], halfLifeH: 14_000_000, halfLifeText: "1600 y (progeny lines)",
                   signs: "Glazed tiles and granite routinely trip portal monitors.", treat: "None needed at NORM levels.", decon: "None needed."))
    a.append(Agent(id: "TC99M", name: "Tc-99m (Technetium-99m)", kind: .isotope, category: "Medical imaging isotope",
                   gammaKeV: [140.5], halfLifeH: 6.01, halfLifeText: "6.01 h",
                   signs: "Recent nuclear-medicine patients and generator shipments.", treat: "None needed.", decon: "Decays away in days."))
    a.append(Agent(id: "NA24", name: "Na-24 (Sodium-24)", kind: .isotope, category: "Neutron activation of sodium (criticality indicator)",
                   gammaKeV: [1368.6, 2754.0], halfLifeH: 14.96, halfLifeText: "15.0 h",
                   signs: "Na-24 in blood or table salt proves neutron exposure, and its activity is used to estimate neutron dose.",
                   treat: "Neutron-exposure medical track: dose reconstruction, ARS care (filgrastim is FDA-approved for H-ARS).",
                   decon: "Activation is inside the body or material. It is not removable contamination."))
    a.append(Agent(id: "NONE", name: "No radionuclide above background", kind: .none, category: "Clean / background only",
                   signs: "", treat: "", decon: ""))

    // ---------- Chemicals ----------
    a.append(Agent(id: "GB", name: "GB (Sarin)", kind: .chemical, category: "Nerve agent, G-series (cholinesterase inhibitor). Volatile, non-persistent",
                   m8: "Yellow-gold", ims: "G-mode alarm", enzyme: "INHIBITED (no blue)", pH: "Mildly acidic (hydrolysis products)",
                   alkaloid: "Negative", tube: "Phosphoric-ester tube: positive", gcms: "Library match: GB (sarin) + degradation products",
                   ap4c: "P band STRONG · S none · As none", fent: "Negative", bands: [0],
                   signs: "Pinpoint pupils, dim vision, runny nose, drooling, chest tightness, sweating, twitching, vomiting, seizures, breathing failure. Vapor acts in seconds to minutes.",
                   treat: "Atropine for secretions and bronchospasm (titrate to dry secretions, not to pupil size), pralidoxime (2-PAM) early, midazolam for seizures, airway support. Miosis alone does not need systemic atropine.",
                   decon: "Disrobe, then soap and water (RSDL for skin spots). 5% hypochlorite on PPE, STB slurry on equipment. Off-gassing clothing can poison hospital staff."))
    a.append(Agent(id: "VX", name: "VX", kind: .chemical, category: "Nerve agent, V-series. Oily, persistent, skin hazard",
                   m8: "Dark green", ims: "V/G-mode alarm", enzyme: "INHIBITED (no blue)", pH: "Near neutral", alkaloid: "Negative",
                   tube: "Phosphoric-ester tube: positive", gcms: "Library match: VX",
                   ap4c: "P band STRONG · S present (V-series thiol) · As none", fent: "Negative", bands: [0, 1],
                   signs: "As GB, but onset after skin contact can be delayed by hours.", treat: "As GB.", decon: "As GB, with priority on liquid removal."))
    a.append(Agent(id: "HD", name: "HD (Sulfur mustard)", kind: .chemical, category: "Vesicant (blister agent). Persistent",
                   m8: "Red / pink", ims: "H-mode alarm", enzyme: "Normal (blue)", pH: "Near neutral", alkaloid: "Negative",
                   tube: "Thioether tube: positive", gcms: "Library match: bis(2-chloroethyl) sulfide",
                   ap4c: "S band STRONG · P none · As none", fent: "Negative", bands: [1],
                   signs: "Often no symptoms at first. Eye pain, skin redness and blisters 2–24 h later.",
                   treat: "No antidote. Decontaminating within minutes is the only way to limit injury. Supportive burn care.",
                   decon: "Immediate removal. Hypochlorite on equipment."))
    a.append(Agent(id: "OPPEST", name: "Organophosphate pesticide", kind: .chemical, category: "Agricultural cholinesterase inhibitor (e.g. parathion class)",
                   m8: "Variable (may react)", ims: "Possible G-mode interference", enzyme: "INHIBITED (no blue)", pH: "Near neutral",
                   alkaloid: "Negative", tube: "Phosphoric-ester tube: positive", gcms: "Library match: organophosphate pesticide",
                   ap4c: "P band STRONG — indistinguishable from nerve agent", fent: "Negative", bands: [0],
                   signs: "Same cholinergic crisis as nerve agents, usually slower.", treat: "Atropine plus oxime, as nerve agents.",
                   decon: "Soap and water. Enzyme tickets and IMS cannot tell it from nerve agent; GC-MS can."))
    a.append(Agent(id: "NIC", name: "Nicotine (concentrated liquid)", kind: .chemical, category: "Alkaloid, nicotinic receptor agonist. E-liquid concentrate (UN1654, class 6.1)",
                   m8: "No agent-specific color", ims: "No G/H library alarm", enzyme: "NORMAL (blue): not a cholinesterase inhibitor",
                   pH: "Alkaline (≈ pH 9–10)", alkaloid: "POSITIVE: orange-red precipitate (Dragendorff)", tube: "—",
                   gcms: "Library match: nicotine (pyridine alkaloid)",
                   ap4c: "HNO band only — no P, no S. NOT a nerve agent", fent: "Negative", bands: [3],
                   signs: "Early: nausea, vomiting, drooling, sweating, pallor, FAST pulse, HIGH blood pressure, tremor, agitation. Late or severe: slow pulse, low blood pressure, weakness, seizures, breathing failure. Rapidly absorbed through skin from concentrated liquid.",
                   treat: "Remove soaked clothing, wash skin with soap and water, supportive care (airway, oxygen, ventilation), benzodiazepines for seizures. Atropine only for symptomatic slow pulse or heavy secretions. Pralidoxime is NOT indicated.",
                   decon: "Soap and water: nicotine is water-soluble. Bleach is not indicated."))
    a.append(Agent(id: "CL2", name: "Chlorine (Cl2)", kind: .chemical, category: "Toxic inhalation hazard gas. UN1017, class 2.3, ERG Guide 124",
                   m8: "No reaction", ims: "No G/H alarm", enzyme: "Normal (blue)", pH: "Strongly acidic on a wetted strip (≈ pH 2)",
                   alkaloid: "Negative", tube: "Chlorine tube: POSITIVE", gcms: "N/A: inorganic gas (use tube / Cl2 sensor)",
                   ap4c: "No element band (inorganic gas)", fent: "Negative", bands: [],
                   signs: "Yellow-green, heavier than air, bleach odor. Eye and throat burning, cough, wheeze. Lung fluid can appear up to 24 h later.",
                   treat: "Move uphill and upwind to fresh air. Oxygen, bronchodilators, flush eyes and skin with water, observe for delayed pulmonary edema.",
                   decon: "Fresh air and water rinse. Never hypochlorite: it adds chlorine."))
    a.append(Agent(id: "BENZENE", name: "Benzene", kind: .chemical, category: "Flammable aromatic hydrocarbon. UN1114, class 3, ERG Guide 130",
                   m8: "Possible false darkening (hydrocarbon interferent)", ims: "No G/H alarm", enzyme: "Normal (blue)", pH: "Neutral",
                   alkaloid: "Negative", tube: "Benzene tube: POSITIVE", gcms: "Library match: benzene",
                   ap4c: "No element band — hydrocarbon", fent: "Negative", bands: [],
                   signs: "Sweet aromatic odor, dizziness, headache, drowsiness, confusion. Long-term carcinogen. Watch the LEL.",
                   treat: "Fresh air, remove clothing, wash with soap and water, supportive care.",
                   decon: "Surfactant soap and water, contain the runoff. Never oxidizers (STB / hypochlorite) on fuels: risk of reaction or fire."))
    a.append(Agent(id: "HE", name: "Conventional explosive residue", kind: .chemical, category: "Nitroaromatic high explosive. No chemical agent",
                   m8: "No reaction", ims: "No G/H alarm (explosives mode: positive)", enzyme: "Normal (blue)", pH: "Neutral",
                   alkaloid: "Negative", tube: "—", gcms: "Library match: TNT (trinitrotoluene)",
                   ap4c: "HNO band (nitroaromatic residue)", fent: "Negative", bands: [3],
                   signs: "Blast and fragment injuries, dust, panic.",
                   treat: "Trauma care. No antidotes without nerve-agent signs. Atropine toxicity looks like: hot, dry, flushed skin, wide pupils, fast pulse, confusion.",
                   decon: "Soap and water."))
    a.append(Agent(id: "FENT", name: "Fentanyl / analogue powder", kind: .chemical, category: "Synthetic opioid. Incapacitant and overdose hazard (UN2811, class 6.1)",
                   m8: "No reaction", ims: "No G/H alarm (narcotics mode: positive)", enzyme: "NORMAL (blue): not a cholinesterase inhibitor",
                   pH: "Near neutral", alkaloid: "POSITIVE (opioid alkaloid)", tube: "—",
                   gcms: "Library match: fentanyl + analogue (acetyl / carfentanil family)",
                   ap4c: "No P, no S, no As. HNO band weak", fent: "POSITIVE — strong test line (screening only)",
                   bands: [3],
                   signs: "Pinpoint pupils, slow shallow breathing then apnoea, drowsiness, limpness. DRY: no drooling, no streaming nose, no sweating, no twitching — that is what separates it from nerve agent.",
                   treat: "Naloxone, repeated as needed, plus airway support and ventilation. Atropine and pralidoxime do NOTHING for opioids. Responder risk from incidental skin contact is low; airborne powder is the real concern.",
                   decon: "Avoid raising dust. Gross removal, then soap and water. Bleach is not needed."))
    a.append(Agent(id: "HOAX_SUGAR", name: "Hoax powder: powdered sugar", kind: .none, category: "Hoax",
                   pH: "Neutral", ap4c: "No element bands", fent: "Negative", hha: "Negative",
                   gram: "No bacteria; crystalline", spore: "None", iodine: "Negative",
                   pcr: "All targets NOT detected", culture: "No growth",
                   signs: "None.", treat: "Reassurance.", decon: "Soap and water."))
    a.append(Agent(id: "CLEAN", name: "No agent detected", kind: .none, category: "Clean control / negative",
                   m8: "No reaction", ims: "No alarm", enzyme: "Normal (blue)", pH: "Neutral", alkaloid: "Negative", tube: "Negative",
                   gcms: "No significant peaks above blank", ap4c: "No element bands", fent: "Negative", hha: "Negative", gram: "No organisms", spore: "None", iodine: "Negative",
                   pcr: "All targets NOT detected", culture: "No growth"))

    // ---------- Biological ----------
    a.append(Agent(id: "BA", name: "Bacillus anthracis spores", kind: .biological, category: "Bacterial spore-former (anthrax)",
                   pH: "Neutral", ap4c: "No element bands", fent: "Negative",
                   hha: "POSITIVE (screen only: confirm by PCR/culture)",
                   gram: "Large Gram-positive rods in chains ('boxcars')", spore: "Oval, non-swelling spores",
                   iodine: "Negative", pcr: "pXO1 target DETECTED · pXO2 target DETECTED · chromosomal DETECTED",
                   culture: "Non-hemolytic, grey 'ground-glass' colonies; non-motile",
                   signs: "Inhalation: flu-like illness 1–7+ days after exposure, then sudden severe breathing difficulty. Skin: painless black eschar. Not spread person to person.",
                   treat: "Post-exposure prophylaxis: ciprofloxacin or doxycycline for 60 days plus anthrax vaccine (Cyfendus approved for PEP in 2023). Antitoxins for illness.",
                   decon: "No dry brushing or compressed air (re-aerosolizes). People: soap-and-water shower. Surfaces: 0.5% hypochlorite with contact time."))
    a.append(Agent(id: "BT", name: "Bacillus thuringiensis (biopesticide)", kind: .biological, category: "Near-relative, B. cereus group. Harmless to people",
                   pH: "Neutral", ap4c: "No element bands", fent: "Negative",
                   hha: "May cross-react (false positive)", gram: "Gram-positive rods", spore: "Spores + parasporal crystals",
                   iodine: "Negative", pcr: "pXO1 NOT detected · pXO2 NOT detected · B. cereus-group chromosomal DETECTED",
                   culture: "Beta-hemolytic, motile",
                   signs: "None.", treat: "None.", decon: "Soap and water."))
    a.append(Agent(id: "HOAX_STARCH", name: "Hoax powder: flour / cornstarch", kind: .none, category: "Hoax",
                   pH: "Neutral", ap4c: "No element bands", fent: "Negative",
                   hha: "Negative", gram: "No bacteria; plant starch granules", spore: "None",
                   iodine: "BLUE-BLACK (starch positive)", pcr: "All targets NOT detected", culture: "No significant growth",
                   signs: "None. Psychological stress is real.", treat: "Reassurance.", decon: "Soap and water."))
    a.append(Agent(id: "HOAX_TALC", name: "Hoax powder: talc", kind: .none, category: "Hoax",
                   pH: "Neutral", ap4c: "No element bands", fent: "Negative",
                   hha: "Negative", gram: "No bacteria; flat plate-like crystals", spore: "None",
                   iodine: "Negative", pcr: "All targets NOT detected", culture: "No growth",
                   signs: "None.", treat: "Reassurance.", decon: "Soap and water."))
    a.append(Agent(id: "HOAX_SODA", name: "Hoax powder: baking soda", kind: .none, category: "Hoax",
                   pH: "Mildly alkaline (≈ pH 8.3); fizzes with acid", ap4c: "No element bands", fent: "Negative",
                   hha: "Negative", gram: "No bacteria; crystalline",
                   spore: "None", iodine: "Negative", pcr: "All targets NOT detected", culture: "No growth",
                   signs: "None.", treat: "Reassurance.", decon: "Soap and water."))
    var d: [String: Agent] = [:]
    for x in a { d[x.id] = x }
    return d
}()

func agent(_ id: String) -> Agent { agents[id] ?? agents["CLEAN"]! }

// MARK: - Decontamination doctrine (per hazard class)

let suitSolutions = ["Low-pressure water rinse only", "Soap & water / detergent scrub", "0.5% hypochlorite (1:10 household bleach)",
                     "5% hypochlorite solution", "STB slurry (super tropical bleach)", "RSDL lotion", "Skip this station"]
let equipSolutions = ["Soap & water / detergent", "0.5% hypochlorite + 10 min contact time", "5% hypochlorite",
                      "STB slurry (super tropical bleach)", "HEPA vacuum + tacky wipes / strippable coating", "Skip this station"]
let verifyMethods = ["Frisker survey (GM pancake probe, ~1 cm, ~5 cm/s)", "IMS chemical-agent detector sniff",
                     "Surface swab → culture / PCR", "5-gas meter + PID off-gas check", "Visual inspection only"]

struct DeconRule {
    let suitBest: Set<Int>, suitOK: Set<Int>
    let equipBest: Set<Int>, equipOK: Set<Int>
    let verify: Set<Int>
    let why: String
}

func deconRule(_ c: DeconClass) -> DeconRule {
    switch c {
    case .radParticulate:
        return DeconRule(suitBest: [1], suitOK: [0], equipBest: [4], equipOK: [0], verify: [0],
                         why: "Radioactivity can't be neutralized, only removed and contained. Bleach and STB add mixed hazardous waste and do nothing to the activity.")
    case .cwaNerve:
        return DeconRule(suitBest: [3], suitOK: [1, 2], equipBest: [3], equipOK: [2], verify: [1],
                         why: "Hypochlorite oxidizes nerve agent. STB slurry is for vehicles, tools and terrain: too corrosive for suit seams and visors, and never on skin. RSDL is a skin product.")
    case .bioSpore:
        return DeconRule(suitBest: [2], suitOK: [1], equipBest: [1], equipOK: [3], verify: [2],
                         why: "Spores need a sporicide with contact time. Dilute (0.5%) hypochlorite is the standard; never dry-brush or blow powder.")
    case .toxicGas:
        return DeconRule(suitBest: [1], suitOK: [0], equipBest: [0], equipOK: [], verify: [3],
                         why: "Chlorine gas mostly leaves with fresh air. Hypochlorite products release more chlorine, so water and detergent only.")
    case .hydrocarbon:
        return DeconRule(suitBest: [1], suitOK: [], equipBest: [0], equipOK: [4], verify: [3],
                         why: "Hydrocarbons need surfactant. Oxidizers like STB or hypochlorite on fuel can react or ignite.")
    case .opioid:
        return DeconRule(suitBest: [1], suitOK: [0], equipBest: [4], equipOK: [0], verify: [3],
                         why: "Opioid powder is a dust problem. Gross removal and soap and water, HEPA vacuum on equipment, and nothing that raises the powder again. Hypochlorite adds nothing.")
    case .nicotine:
        return DeconRule(suitBest: [1], suitOK: [0], equipBest: [0], equipOK: [], verify: [3, 2],
                         why: "Nicotine is water-soluble and soaks through skin. Thorough soap-and-water washing is the treatment. Bleach adds hazard and gains nothing.")
    case .none:
        return DeconRule(suitBest: [1], suitOK: [0, 3], equipBest: [0], equipOK: [], verify: [1, 3],
                         why: "No agent confirmed, so routine soap and water. Precautionary hypochlorite isn't wrong, just unnecessary once the lab has cleared it.")
    }
}

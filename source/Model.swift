// CONTAINMENT — persistent state, divisions, threat classes and protective equipment.
// Protection values follow public responder guidance:
//  • Respiratory: OSHA 29 CFR 1910.134 assigned protection factors (SCBA pressure-demand 10,000;
//    tight-fitting full-face PAPR 1,000; full-face APR 50).
//  • Air-purifying respirators (APR/PAPR) may not be used in IDLH, unknown, or O2-deficient (<19.5%)
//    atmospheres, and particulate/CBRN canisters do not remove carbon monoxide.
//  • Wearable radiation PPE stops contamination and beta, but gives little protection against
//    penetrating gamma and almost none against fast neutrons: time, distance and shielding do that.

import AppKit

enum Division: String, Codable {
    case nuclear, chembio
    var clearance: String { self == .nuclear ? "TOP SECRET" : "CONFIDENTIAL" }
    var title: String { self == .nuclear ? "NUCLEAR & RADIOLOGICAL DIVISION" : "CHEMICAL & BIOLOGICAL DIVISION" }
    var rating: String { self == .nuclear ? "RAD-TECH / LEVEL-A (SHIELDED)" : "HAZMAT-SPEC / LEVEL-A & LEVEL-B" }
}

enum Threat: Int, CaseIterable, Codable {
    case terrorism, military, accident, criminal, benign
    var label: String {
        switch self {
        case .terrorism: return "TERRORISM / DELIBERATE RELEASE"
        case .military:  return "MILITARY / STATE ATTACK"
        case .accident:  return "INDUSTRIAL / CIVILIAN ACCIDENT"
        case .criminal:  return "CRIMINAL OR REGULATORY BREACH (NO ATTACK)"
        case .benign:    return "FALSE ALARM / NATURALLY OCCURRING"
        }
    }
}

struct GameState: Codable {
    var screened = false
    var score = 0
    var division: Division = .chembio
    var completed: [String: String] = [:]     // mission id → best grade
    var replayUnlocked = false
    var allowCrossTrack = false
    var trained = false                        // academy passed: you are on a team
    var trainScore = 0

    static let key = "containment.save.v2"
    static func load() -> GameState {
        guard let d = UserDefaults.standard.data(forKey: key),
              let s = try? JSONDecoder().decode(GameState.self, from: d) else { return GameState() }
        return s
    }
    func save() {
        if let d = try? JSONEncoder().encode(self) { UserDefaults.standard.set(d, forKey: GameState.key) }
    }
}

// MARK: - Respiratory protection

enum Resp: String {
    case scba, papr, apr
    var name: String {
        switch self {
        case .scba: return "SCBA (pressure-demand, open-circuit)"
        case .papr: return "CBRN PAPR (tight-fitting full facepiece)"
        case .apr:  return "CBRN full-face APR (gas mask + canister)"
        }
    }
    var short: String { self == .scba ? "SCBA" : (self == .papr ? "PAPR" : "APR") }
    /// OSHA assigned protection factor.
    var apf: Double { self == .scba ? 10_000 : (self == .papr ? 1_000 : 50) }
    var airPurifying: Bool { self != .scba }
}

struct Cylinder {
    let name: String
    let liters: Double       // free air at rated pressure (NIOSH rating basis = 40 L/min)
    let psi: Double
    let exertion: Double     // weight penalty on breathing rate
}

let cylinders: [Cylinder] = [
    Cylinder(name: "30-min rated, 4500 psi composite (light)", liters: 1200, psi: 4500, exertion: 1.00),
    Cylinder(name: "45-min rated, 4500 psi composite", liters: 1800, psi: 4500, exertion: 1.06),
    Cylinder(name: "60-min rated, 4500 psi composite (heavy)", liters: 2400, psi: 4500, exertion: 1.13),
]

struct Canister {
    let name: String
    let lifeMin: Double      // nominal service life at low challenge concentration (sim minutes)
}
let canisters: [Canister] = [
    Canister(name: "NIOSH CBRN canister (gas/vapor + P100)", lifeMin: 120),
    Canister(name: "P100 particulate filter only", lifeMin: 240),
]

/// The fifth, swappable sensor on the 5-gas meter (the other four are O2, LEL, CO, H2S).
enum Sensor5: Int, CaseIterable {
    case pid, cl2, nh3, hcn
    var name: String {
        switch self {
        case .pid: return "PID 10.6 eV (VOCs, ppm isobutylene-eq.)"
        case .cl2: return "Cl2 electrochemical (ppm)"
        case .nh3: return "NH3 electrochemical (ppm)"
        case .hcn: return "HCN electrochemical (ppm)"
        }
    }
    var tag: String { ["VOC", "Cl2", "NH3", "HCN"][rawValue] }
    var alarm: Double { [50, 0.5, 25, 4.7][rawValue] }
}

// MARK: - Suits

struct Suit {
    let id: String
    let name: String
    let level: String
    let division: Division
    let resp: [Resp]              // allowed respirators (first = default)
    let desc: String
    let vapor: Double             // skin vapor protection 0..1
    let liquid: Double            // liquid splash / permeation 0..1
    let particulate: Double       // powders, spores, radioactive particulate 0..1
    let beta: Double
    let gammaLow: Double          // < ~200 keV photons
    let gammaMid: Double          // ~ 300–800 keV (Cs-137, Ir-192)
    let gammaHigh: Double         // > 1 MeV (Co-60, Na-24)
    let neutron: Double
    let mobility: Double
    let airMult: Double
    let heat: Double
    let color: NSColor
    let trim: NSColor
    let encapsulated: Bool
}

let allSuits: [Suit] = [
    Suit(id: "RT-A1", name: "RAD-TECH A1 // Encapsulated", level: "LEVEL A", division: .nuclear, resp: [.scba],
         desc: "Gas-tight encapsulating suit, SCBA worn inside. Full contamination control and high beta stopping, but like all wearable PPE it barely attenuates penetrating gamma. Your real shielding is time, distance and concrete.",
         vapor: 0.999, liquid: 0.999, particulate: 0.999, beta: 0.55, gammaLow: 0.04, gammaMid: 0.01, gammaHigh: 0.005, neutron: 0,
         mobility: 0.80, airMult: 1.15, heat: 1.35, color: Pal.suitYel, trim: Pal.suitGrey, encapsulated: true),
    Suit(id: "RT-A2", name: "RAD-TECH A2 // Shielded", level: "LEVEL A (SHIELDED)", division: .nuclear, resp: [.scba],
         desc: "Encapsulated suit with tungsten-polymer panels over torso and pelvis (bone-marrow priority) and a borated liner. Strong vs beta and low-energy photons (Am-241, Tc-99m); only modest vs Cs-137 and Co-60 gamma; near zero vs fast neutrons. Weight drives heart rate and air burn.",
         vapor: 0.999, liquid: 0.999, particulate: 0.999, beta: 0.97, gammaLow: 0.55, gammaMid: 0.12, gammaHigh: 0.05, neutron: 0.04,
         mobility: 0.60, airMult: 1.38, heat: 1.7, color: Pal.suitRed, trim: Pal.suitGrey, encapsulated: true),
    Suit(id: "RT-C", name: "RAD-TECH C // Anti-C + CBRN APR", level: "LEVEL C", division: .nuclear, resp: [.apr, .papr],
         desc: "Double anti-contamination coveralls, taped gloves and booties, CBRN full-face respirator. The standard dress for known particulate contamination in breathable air. Light, cool, long stay time. Not permitted in IDLH, oxygen-deficient (<19.5%) or unknown atmospheres, and canisters do not stop CO.",
         vapor: 0.10, liquid: 0.60, particulate: 0.98, beta: 0.25, gammaLow: 0, gammaMid: 0, gammaHigh: 0, neutron: 0,
         mobility: 0.98, airMult: 1.0, heat: 0.7, color: rgba(0.90, 0.92, 0.95), trim: Pal.suitYel, encapsulated: false),

    Suit(id: "HS-A", name: "HAZMAT-SPEC A // Vapor-Protective", level: "LEVEL A", division: .chembio, resp: [.scba],
         desc: "Vapor-protective encapsulating ensemble (NFPA 1990, which absorbed the old NFPA 1991 in 2022), SCBA inside. Required for unknown or skin-absorbable vapors at high concentration such as nerve agents. Hot, slow, high air burn.",
         vapor: 0.999, liquid: 0.999, particulate: 0.999, beta: 0.3, gammaLow: 0, gammaMid: 0, gammaHigh: 0, neutron: 0,
         mobility: 0.74, airMult: 1.22, heat: 1.5, color: Pal.suitYel, trim: Pal.suitRed, encapsulated: true),
    Suit(id: "HS-B", name: "HAZMAT-SPEC B // Splash + SCBA", level: "LEVEL B", division: .chembio, resp: [.scba],
         desc: "Liquid-splash-protective suit with SCBA worn outside. Highest respiratory protection, but seams, hood and SCBA openings are not vapor-tight. Fine for spores and most industrial chemicals; marginal for skin-absorbing vapors.",
         vapor: 0.62, liquid: 0.93, particulate: 0.96, beta: 0.2, gammaLow: 0, gammaMid: 0, gammaHigh: 0, neutron: 0,
         mobility: 0.88, airMult: 1.05, heat: 1.1, color: Pal.suitRed, trim: Pal.suitYel, encapsulated: false),
    Suit(id: "HS-C", name: "HAZMAT-SPEC C // CBRN PAPR", level: "LEVEL C", division: .chembio, resp: [.papr, .apr],
         desc: "Chemical splash coverall with a CBRN PAPR (filtered blower air). Under OSHA definitions a PAPR plus splash suit is Level C. Long working time, cooler, but only for identified hazards below IDLH with O2 at or above 19.5%.",
         vapor: 0.55, liquid: 0.86, particulate: 0.97, beta: 0.2, gammaLow: 0, gammaMid: 0, gammaHigh: 0, neutron: 0,
         mobility: 0.95, airMult: 1.0, heat: 0.9, color: rgba(0.30, 0.62, 0.85), trim: Pal.suitYel, encapsulated: false),
    Suit(id: "MOPP4", name: "MOPP-4 // JSLIST + CBRN Mask", level: "MILITARY CW", division: .chembio, resp: [.apr],
         desc: "Military chemical-warfare ensemble: JSLIST overgarment with activated-carbon liner (adsorbs warfare-agent vapor), CBRN mask, butyl gloves and overboots. Good vs CW agents in open air; not built for high-concentration industrial chemicals or confined, oxygen-deficient spaces.",
         vapor: 0.90, liquid: 0.92, particulate: 0.95, beta: 0.2, gammaLow: 0, gammaMid: 0, gammaHigh: 0, neutron: 0,
         mobility: 0.90, airMult: 1.0, heat: 1.25, color: Pal.olive, trim: Pal.dark, encapsulated: false),
]

struct Loadout {
    var suit: Suit
    var resp: Resp
    var cylinder: Cylinder
    var canister: Canister
    var sensor5: Sensor5
}

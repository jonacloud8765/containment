// CONTAINMENT — mission data types, map builders and per-run state.
// World units: 40 px = 1 m. Dose rates are µSv/h at 1 m for point sources.

import AppKit

let PX_PER_M: CGFloat = 40

enum SampleKind: String {
    case swab = "SWAB", vial = "LIQUID VIAL", air = "AIR CANISTER", soil = "SOIL JAR", wipe = "WIPE",
         bio = "BIO SPECIMEN", spectrum = "IN-SITU SPECTRUM", evidence = "EVIDENCE BAG"
}

struct Wall { var r: CGRect; var shield: Double = 0.12 }           // gamma transmission through the wall
struct Area { var r: CGRect; var name: String; var floor: NSColor; var rate: Double = 0 } // ambient µSv/h
struct RadSrc { var p: CGPoint; var rate: Double; var band: Int; var neutron: Double = 0; var name = "" }
struct Contam { var p: CGPoint; var r: CGFloat; var cpm: Double; var glow = false }
struct Plume { var p: CGPoint; var q: Double; var spread: CGFloat; var length: CGFloat; var agent: String; var color: NSColor? = nil }
struct Gas {
    var r: CGRect
    var o2 = 20.9, lel = 0.0, co = 0.0, h2s = 0.0, voc = 0.0, cl2 = 0.0, nh3 = 0.0, hcn = 0.0
    var label = ""
}
struct Puddle { var p: CGPoint; var r: CGFloat; var agent: String; var level: Double; var color: NSColor }
struct Powder { var p: CGPoint; var r: CGFloat; var agent: String; var level: Double }
struct SamplePt { var p: CGPoint; var label: String; var kind: SampleKind; var contents: [String]; var secs: Double = 4; var taken = false }
struct Victim {
    var p: CGPoint; var name: String; var signs: String
    var options: [String]; var best: Set<Int>; var ok: Set<Int> = []; var why: String
    var choice: Int? = nil
    /// Non-ambulatory: needs two squad members and a litter to get out of the hot zone.
    var litter = false
    var rescued = false
}
struct Clue { var p: CGPoint; var title: String; var text: String; var read = false }
struct Survey { var p: CGPoint; var name: String; var logged = false; var log = "" }
struct FieldTask { var p: CGPoint; var name: String; var text: String; var secs: Double; var done = false; var effect: String }

struct FieldMap {
    var size = CGSize(width: 2000, height: 1300)
    var start = CGPoint(x: 130, y: 650)
    var exit = CGRect(x: 30, y: 560, width: 150, height: 180)
    var ground = rgba(0.10, 0.11, 0.10)
    var walls: [Wall] = []
    var areas: [Area] = []
    var rad: [RadSrc] = []
    var contam: [Contam] = []
    var plumes: [Plume] = []
    var gas: [Gas] = []
    var puddles: [Puddle] = []
    var powders: [Powder] = []
    var samples: [SamplePt] = []
    var victims: [Victim] = []
    var clues: [Clue] = []
    var surveys: [Survey] = []
    var tasks: [FieldTask] = []
    var ash = false
    var dark = 0.0
    var props: [(CGRect, NSColor, String)] = []   // decorative blocks with labels (vehicles, tanks, machines)
}

struct MissionDef {
    let id: String
    let division: Division
    let year: String
    let op: String
    let title: String
    let location: String
    let inspired: String
    let window: Double          // entry window, simulated minutes
    let realSecs: Double        // real seconds the window lasts
    let doseLimit: Double       // mSv turn-back (0 = not a radiological mission)
    let windDeg: Double         // direction the wind blows TOWARD (0 = east, 90 = south on screen)
    let windSpeed: Double       // m/s
    let variants: Int
    let threat: (Int) -> Threat
    let briefing: (Int) -> [String]
    let build: (Int) -> FieldMap
    let candidates: [String]
    let multiID: Bool
    let protocols: [String]
    let bestProtocol: (Int) -> Set<Int>
    let decon: (Int) -> DeconClass
    let required: Int
    let history: (Int) -> String
    let ambientWind: Double
    let ambientRumble: Double
    let siren: Bool
    let suggestedSensor: Sensor5
    /// Shown on the red-alert callout: present-day framing, giving away nothing about the agent.
    var alertLoc = "LOCATION PENDING"
    var alertDispatch = "MULTIPLE CALLERS — PERSONS DOWN, CAUSE UNKNOWN"
    /// Casualties that cannot walk out and must be carried on a stretcher by two squad members.
    var litters = 0
    /// Decon happens inside the structure with a backpack sprayer: no room for the truck.
    var confinedDecon = false
}

// MARK: - Run state

/// `contents` is the true material sampled; `crossWith` is trace material carried over on dirty gloves.
struct Sample {
    let label: String; let kind: SampleKind; var contents: [String]; var crossWith: [String] = []
    var cross: Bool { !crossWith.isEmpty }
    var primary: String { contents.first ?? "CLEAN" }
}

struct FieldResult {
    var samples: [Sample] = []
    var airStart = 1.0, airLeft = 1.0         // litres (SCBA) or filter minutes (APR/PAPR)
    var lowAirAlarmHit = false
    var dose = 0.0, neutronDose = 0.0         // mSv
    var skinChem = 0.0, inhaledChem = 0.0     // exposure index (1.0 = symptomatic)
    var hypoxia = 0.0, coLoad = 0.0, heat = 0.0
    var suitContam = 0.0
    var victims: [Victim] = []
    var rescued = 0, litters = 0
    var squadDown = 0
    var surveysLogged = 0, surveysTotal = 0
    var cluesRead = 0, cluesTotal = 0
    var tasksDone = 0, tasksTotal = 0
    var simMinutes = 0.0
    var extracted = false
    var incidents: [String] = []
    var injectorsUsed = 0, needlessInjectors = 0
    var gloveChanges = 0
    var readings: [String] = []
}

struct LabResult {
    var lines: [(String, Bool, String)] = []   // sample label, correct, chosen/truth text
    var idScore = 0.0
    var threat: Threat = .accident
    var threatCorrect = false
    var protoChoice = 0
    var protocolCorrect = false
    var contamination = 0
    var labMinutes = 0.0
}

struct DeconResult { var score = 0.0; var errors: [String] = []; var notes: [String] = [] }

final class MissionRun {
    let def: MissionDef
    let variant: Int
    var loadout: Loadout?
    var initialThreat: Threat?
    var field = FieldResult()
    var lab: LabResult?
    var decon: DeconResult?
    init(_ d: MissionDef) { def = d; variant = Int.random(in: 0..<max(1, d.variants)) }
    init(_ d: MissionDef, variant v: Int) { def = d; variant = v }
    var timeScale: Double { def.window * 60 / def.realSecs }
    var wind: CGPoint {
        let r = def.windDeg * .pi / 180
        return CGPoint(x: cos(r), y: sin(r))
    }
}

// MARK: - Builders

func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x, y: y, width: w, height: h) }
func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

/// Rectangular room outline with door gaps. Door = (side n/s/e/w, offset from the side's start, width).
func room(_ r: CGRect, t: CGFloat = 16, shield: Double = 0.12, doors: [(Character, CGFloat, CGFloat)] = []) -> [Wall] {
    var out: [Wall] = []
    func seg(_ side: Character, _ length: CGFloat, _ make: (CGFloat, CGFloat) -> CGRect) {
        var cuts = doors.filter { $0.0 == side }.map { ($0.1, $0.1 + $0.2) }.sorted { $0.0 < $1.0 }
        cuts.append((length, length))
        var s: CGFloat = 0
        for c in cuts {
            if c.0 > s { out.append(Wall(r: make(s, c.0 - s), shield: shield)) }
            s = max(s, c.1)
        }
    }
    seg("n", r.width) { R(r.minX + $0, r.minY, $1, t) }
    seg("s", r.width) { R(r.minX + $0, r.maxY - t, $1, t) }
    seg("w", r.height) { R(r.minX, r.minY + $0, t, $1) }
    seg("e", r.height) { R(r.maxX - t, r.minY + $0, t, $1) }
    return out
}

let radProtocols = [
    "Potassium iodide (KI) for the public in the plume path + evacuate / shelter",
    "Prussian blue for internally contaminated people + contamination control",
    "Ca/Zn-DTPA chelation for internal americium / plutonium",
    "Neutron-exposure medical track: Na-24 dosimetry, whole-body count, ARS care",
    "Perimeter + render-safe team: treat as radiological dispersal device",
    "Regulatory hold: secure source, notify regulator, no public action",
    "Release shipment: naturally occurring material, no action",
]
let chemProtocols = [
    "Nerve-agent protocol: atropine + pralidoxime + midazolam, mass decon",
    "Supportive care + skin decon (soap & water), NO oxime",
    "Fresh air, oxygen, flush eyes; observe for delayed pulmonary edema",
    "Immediate decon + burn care; observe 24 h for delayed blistering",
    "Post-exposure prophylaxis: cipro/doxycycline 60 days + anthrax vaccine",
    "Trauma care only; stop unneeded antidotes; reassure the public",
]

var missionDefs: [MissionDef] { radMissions + chemAll }
var chemAll: [MissionDef] { chemMissions + extraChemMissions }
func missions(for d: Division) -> [MissionDef] { d == .nuclear ? radMissions : chemAll }

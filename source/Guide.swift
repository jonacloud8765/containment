// CONTAINMENT — CBRN Field Reference Guide (overlay + standalone scene) and doctrine pages.

import AppKit

let doctrine: [(String, String)] = [
    ("PPE LEVELS (OSHA 1910.120 App. B)",
     "LEVEL A: SCBA + fully encapsulating, vapor-tight suit. For unknown or skin-absorbable vapors at high concentration.\nLEVEL B: SCBA + non-encapsulating splash suit. Highest respiratory protection, less skin vapor protection.\nLEVEL C: Air-purifying respirator (APR or PAPR) + splash suit. Only when the contaminant is identified, measured below IDLH, and O2 is at least 19.5%.\nLEVEL D: Work uniform. No respiratory hazard.\nNFPA 1990 (2022) now combines the old NFPA 1991/1992/1994 ensemble standards."),
    ("RESPIRATORS & CBRN FILTERS",
     "Assigned protection factors (OSHA 1910.134): pressure-demand SCBA 10,000 · tight-fitting full-face PAPR 1,000 · full-face APR 50.\nCBRN canisters are NIOSH-approved for warfare agents and many toxic industrial chemicals, but they:\n• do NOT supply oxygen. Never use below 19.5% O2.\n• do NOT remove carbon monoxide.\n• are NOT for IDLH or unknown atmospheres.\n• have a finite service life that shortens at high concentration.\nRemove the filter's sealing cap before use. Check the seal every time."),
    ("5-GAS METER",
     "O2 · LEL · CO · H2S + a swappable fifth sensor (PID, Cl2, NH3, HCN).\nTypical alarm points: O2 low 19.5% / high 23.5% · LEL 10% · CO 35 ppm · H2S 10 ppm · Cl2 0.5 ppm · NH3 25 ppm · HCN 4.7 ppm.\nA 10.6 eV PID sees benzene, ammonia and most organic vapors, but NOT chlorine (ionization energy 11.5 eV).\nElectrochemical cells have cross-sensitivities: oxidizers such as chlorine can drive the H2S reading NEGATIVE.\nBump-test before every entry."),
    ("SCBA AIR MANAGEMENT",
     "Cylinder ratings (30/45/60 min) assume 40 L/min breathing. Real work in a suit often burns air far faster: heavy exertion and sprinting can double it.\nLow-air alarm sounds at 33% remaining (NFPA 1981, 2013 edition onward).\nPlan to EXIT BEFORE the alarm. Reserve air is for emergencies, not for work.\nHeat stress in encapsulated suits often limits entry time before air does."),
    ("RADIATION PROTECTION",
     "Time · Distance (inverse square: double the distance, quarter the dose rate) · Shielding (concrete, water, steel).\nEPA PAG Manual (2017) emergency-worker guidelines: 50 mSv (5 rem) all activities · 100 mSv (10 rem) protecting valuable property / critical infrastructure · 250 mSv (25 rem) lifesaving or protecting large populations.\nWearable PPE stops contamination and beta. It does little against high-energy gamma and almost nothing against fast neutrons.\nIrradiation is not contamination: an irradiated patient isn't radioactive. Life-threatening injuries come before decon."),
    ("NERVE-AGENT ANTIDOTES",
     "Autoinjectors: DuoDote / ATNAA (atropine + pralidoxime), AtroPen (atropine only), midazolam (Seizalam, FDA 2018; replaced diazepam for seizures).\nAtropine endpoint: dry secretions and easy breathing, NOT pupil size. Isolated miosis doesn't need systemic atropine.\nAtropine toxicity: hot, dry, flushed skin, wide pupils, racing pulse, confusion. In a suit it also blocks sweating, which worsens heat stress.\nPralidoxime only helps cholinesterase INHIBITORS (nerve agents, organophosphates). It is useless for nicotine."),
    ("DECONTAMINATION",
     "Disrobing removes most contamination (often cited as up to ~90%). US PRISM guidance: disrobe, dry decon, then wet decon for mass casualties.\nSTB (super tropical bleach: calcium hypochlorite + lime) is for equipment, vehicles and terrain only. Never on skin, and too harsh for suit seams.\n5% hypochlorite: PPE and equipment for chemical agents. 0.5% hypochlorite (1:10 household bleach): spores on surfaces. RSDL: skin spot decon for nerve and blister agents.\nNever mix bleach with acids or ammonia. Never put oxidizers on fuels. Radioactivity can't be neutralized, only removed and contained."),
    ("TRIAGE TAGS",
     "RED: immediate, life-threatening but salvageable.\nYELLOW: delayed, serious but stable.\nGREEN: minimal, walking wounded.\nBLACK: expectant or deceased.\nTreat the patient, not the panic. Many casualties in CBRN events are 'worried well' or harmed by the response itself."),
    ("PLACARDS & THE ERG",
     "DOT hazard classes: 1 explosives · 2 gases (2.3 poison gas) · 3 flammable liquids · 4 flammable solids · 5 oxidizers · 6 toxic & infectious (6.1 toxic) · 7 radioactive · 8 corrosive · 9 miscellaneous.\nThe 4-digit UN number on the orange panel or placard points to an orange-section guide in the Emergency Response Guidebook. Toxic-inhalation-hazard materials also have protective-action distances in the green section."),
]

struct GuideOverlay {
    var cat = 0
    var list = OptionList([], numberKeys: false)
    var open = false
    let cats = ["RADIONUCLIDES", "CHEMICALS", "BIOLOGICAL", "DOCTRINE"]

    private func ids(_ c: Int) -> [String] {
        let all = agents.values.sorted { $0.name < $1.name }
        switch c {
        case 0: return all.filter { $0.kind == .isotope }.map { $0.id }
        case 1: return all.filter { $0.kind == .chemical || $0.id == "CLEAN" }.map { $0.id }
        case 2: return all.filter { $0.kind == .biological || $0.id.hasPrefix("HOAX") }.map { $0.id }
        default: return []
        }
    }
    mutating func show(_ c: Int) { open = true; cat = c; rebuild() }
    mutating func rebuild() {
        list = OptionList(cat == 3 ? doctrine.map { $0.0 } : ids(cat).map { agent($0).name }, numberKeys: false)
    }
    /// Returns true when handled.
    mutating func key(_ k: String) -> Bool {
        guard open else { return false }
        switch k {
        case "esc", "f", "back": open = false
        case "left", "a": cat = (cat + 3) % 4; rebuild()
        case "right", "d", "tab": cat = (cat + 1) % 4; rebuild()
        default: _ = list.key(k)
        }
        return true
    }
    mutating func mouseMoved(_ p: CGPoint) { if open { list.hover(p) } }

    mutating func draw(_ g: G) {
        guard open else { return }
        g.fill(R(0, 0, W, H), Pal.black.a(0.82))
        g.panel(R(40, 70, 1200, 680), title: "CBRN FIELD REFERENCE GUIDE")
        var x: CGFloat = 60
        for (i, c) in cats.enumerated() {
            let w = CGFloat(c.count) * G.charW(14, true) + 24
            if i == cat { g.fill(R(x, 92, w, 26), Pal.amber) }
            g.text(c, x + 12, 97, 14, i == cat ? Pal.black : Pal.amber, bold: true)
            x += w + 8
        }
        list.draw(g, x: 60, y: 136, w: 400, size: 13, gap: 4)
        let dx: CGFloat = 490, dw: CGFloat = 720
        var y: CGFloat = 136
        if cat == 3 {
            let d = doctrine[min(list.sel, doctrine.count - 1)]
            g.text(d.0, dx, y, 17, Pal.amber, bold: true); y += 30
            g.para(d.1, dx, y, w: dw, size: 14, color: Pal.green, lineH: 20)
        } else {
            let idl = ids(cat)
            guard !idl.isEmpty else { return }
            let a = agent(idl[min(list.sel, idl.count - 1)])
            g.text(a.name, dx, y, 18, Pal.amber, bold: true); y += 26
            y += g.para(a.category, dx, y, w: dw, size: 13, color: Pal.greenDim) + 10
            func row(_ k: String, _ v: String) {
                guard v != "—" && !v.isEmpty else { return }
                g.text(k, dx, y, 13, Pal.amber, bold: true)
                y += g.para(v, dx + 170, y, w: dw - 170, size: 13, color: Pal.green) + 4
            }
            if a.kind == .isotope {
                row("GAMMA LINES", a.gammaKeV.map { f($0, 1) + " keV" }.joined(separator: " · "))
                row("HALF-LIFE", a.halfLifeText)
            }
            row("M8 PAPER", a.m8); row("IMS DETECTOR", a.ims); row("ENZYME TICKET", a.enzyme); row("pH", a.pH)
            row("ALKALOID TEST", a.alkaloid); row("COLOR TUBE", a.tube); row("GC-MS", a.gcms)
            row("IMMUNOASSAY", a.hha); row("GRAM STAIN", a.gram); row("SPORE STAIN", a.spore); row("IODINE", a.iodine)
            row("PCR", a.pcr); row("CULTURE", a.culture)
            y += 6
            row("SIGNS", a.signs); row("COUNTERMEASURE", a.treat); row("DECON", a.decon)
        }
        g.text("[←→/TAB] category   [↑↓] entry   [ESC/F] close", 60, 722, 12, Pal.greenDim)
    }
}

final class GuideScene: Scene {
    var guide = GuideOverlay()
    let back: () -> Scene
    init(back: @escaping () -> Scene) { self.back = back; guide.show(0) }
    func update(_ dt: Double) { if !guide.open { Game.shared.go(back()) } }
    func draw(_ g: G) { header(g, "FIELD REFERENCE"); guide.draw(g) }
    func keyDown(_ k: String) { _ = guide.key(k) }
    func mouseMoved(_ p: CGPoint) { guide.mouseMoved(p) }
}

// CONTAINMENT — engine core: fixed backbuffer renderer, input, drawing helpers, scene manager.
// Everything renders into one 1280x800 CGBitmapContext (≈4 MB) that is handed to a CALayer
// each frame, so memory stays flat regardless of window size or Retina scale.

import AppKit
import QuartzCore

let W: CGFloat = 1280
let H: CGFloat = 800

enum Align { case left, center, right }

func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}

enum Pal {
    static let bg       = rgba(0.020, 0.028, 0.024)
    static let panel    = rgba(0.030, 0.046, 0.036, 0.94)
    static let amber    = rgba(1.00, 0.70, 0.10)
    static let amberDim = rgba(0.55, 0.38, 0.06)
    static let green    = rgba(0.38, 1.00, 0.50)
    static let greenDim = rgba(0.15, 0.46, 0.22)
    static let red      = rgba(1.00, 0.24, 0.18)
    static let yellow   = rgba(1.00, 0.86, 0.12)
    static let cyan     = rgba(0.38, 0.86, 1.00)
    static let grey     = rgba(0.55, 0.58, 0.56)
    static let dark     = rgba(0.09, 0.11, 0.10)
    static let white    = rgba(0.92, 0.94, 0.90)
    static let black    = rgba(0, 0, 0)
    static let suitYel  = rgba(0.96, 0.78, 0.10)
    static let suitRed  = rgba(0.82, 0.16, 0.12)
    static let suitGrey = rgba(0.48, 0.52, 0.50)
    static let olive    = rgba(0.33, 0.38, 0.24)
}

extension NSColor { func a(_ v: CGFloat) -> NSColor { withAlphaComponent(v) } }

func clamp<T: Comparable>(_ v: T, _ lo: T, _ hi: T) -> T { min(max(v, lo), hi) }

extension CGPoint {
    static func + (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x - b.x, y: a.y - b.y) }
    static func * (a: CGPoint, s: CGFloat) -> CGPoint { CGPoint(x: a.x * s, y: a.y * s) }
    var len: CGFloat { (x * x + y * y).squareRoot() }
    func dist(_ o: CGPoint) -> CGFloat { (self - o).len }
}

/// Formats a number with a fixed number of decimals.
func f(_ v: Double, _ d: Int = 1) -> String { String(format: "%.\(d)f", v) }

// MARK: - Drawing

final class G {
    let ctx: CGContext
    init(_ c: CGContext) { ctx = c }

    private static var fonts: [Int: NSFont] = [:]
    private static var widths: [Int: CGFloat] = [:]

    static func font(_ size: CGFloat, _ bold: Bool) -> NSFont {
        let key = Int(size * 10) * 2 + (bold ? 1 : 0)
        if let f = fonts[key] { return f }
        let f = NSFont.monospacedSystemFont(ofSize: size, weight: bold ? .bold : .regular)
        fonts[key] = f
        return f
    }
    static func charW(_ size: CGFloat, _ bold: Bool = false) -> CGFloat {
        let key = Int(size * 10) * 2 + (bold ? 1 : 0)
        if let w = widths[key] { return w }
        let w = ("M" as NSString).size(withAttributes: [.font: font(size, bold)]).width
        widths[key] = w
        return w
    }

    func fill(_ r: CGRect, _ c: NSColor) { ctx.setFillColor(c.cgColor); ctx.fill(r) }
    func stroke(_ r: CGRect, _ c: NSColor, _ w: CGFloat = 1) {
        ctx.setStrokeColor(c.cgColor); ctx.setLineWidth(w); ctx.stroke(r.insetBy(dx: w / 2, dy: w / 2))
    }
    func line(_ a: CGPoint, _ b: CGPoint, _ c: NSColor, _ w: CGFloat = 1) {
        ctx.setStrokeColor(c.cgColor); ctx.setLineWidth(w)
        ctx.beginPath(); ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
    }
    func circle(_ p: CGPoint, _ r: CGFloat, _ c: NSColor) {
        ctx.setFillColor(c.cgColor); ctx.fillEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }
    func ring(_ p: CGPoint, _ r: CGFloat, _ c: NSColor, _ w: CGFloat = 1) {
        ctx.setStrokeColor(c.cgColor); ctx.setLineWidth(w)
        ctx.strokeEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }
    func poly(_ pts: [CGPoint], _ c: NSColor, fill: Bool = true, w: CGFloat = 1) {
        guard pts.count > 1 else { return }
        ctx.beginPath(); ctx.move(to: pts[0]); for p in pts.dropFirst() { ctx.addLine(to: p) }
        if fill { ctx.closePath(); ctx.setFillColor(c.cgColor); ctx.fillPath() }
        else { ctx.setStrokeColor(c.cgColor); ctx.setLineWidth(w); ctx.strokePath() }
    }
    func roundRect(_ r: CGRect, _ rad: CGFloat, _ c: NSColor, fill: Bool = true, w: CGFloat = 1) {
        let p = CGPath(roundedRect: r, cornerWidth: rad, cornerHeight: rad, transform: nil)
        ctx.addPath(p)
        if fill { ctx.setFillColor(c.cgColor); ctx.fillPath() }
        else { ctx.setStrokeColor(c.cgColor); ctx.setLineWidth(w); ctx.strokePath() }
    }

    @discardableResult
    func text(_ s: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 14, _ color: NSColor = Pal.green,
              bold: Bool = false, align: Align = .left) -> CGFloat {
        let w = CGFloat(s.count) * G.charW(size, bold)
        var px = x
        if align == .center { px = x - w / 2 } else if align == .right { px = x - w }
        (s as NSString).draw(at: CGPoint(x: px, y: y),
                             withAttributes: [.font: G.font(size, bold), .foregroundColor: color])
        return w
    }

    static func wrap(_ s: String, width: CGFloat, size: CGFloat) -> [String] {
        let maxC = max(8, Int(width / charW(size)))
        var out: [String] = []
        for para in s.components(separatedBy: "\n") {
            if para.isEmpty { out.append(""); continue }
            var cur = ""
            for word in para.split(separator: " ", omittingEmptySubsequences: false) {
                let wd = String(word)
                if cur.isEmpty { cur = wd }
                else if cur.count + 1 + wd.count <= maxC { cur += " " + wd }
                else { out.append(cur); cur = wd }
                while cur.count > maxC { out.append(String(cur.prefix(maxC))); cur = String(cur.dropFirst(maxC)) }
            }
            out.append(cur)
        }
        return out
    }

    /// Wrapped paragraph. Returns height used.
    @discardableResult
    func para(_ s: String, _ x: CGFloat, _ y: CGFloat, w: CGFloat, size: CGFloat = 14,
              color: NSColor = Pal.green, lineH: CGFloat? = nil, bold: Bool = false) -> CGFloat {
        let lh = lineH ?? size * 1.35
        let lines = G.wrap(s, width: w, size: size)
        for (i, l) in lines.enumerated() { text(l, x, y + CGFloat(i) * lh, size, color, bold: bold) }
        return CGFloat(lines.count) * lh
    }

    func panel(_ r: CGRect, title: String? = nil, color: NSColor = Pal.amber) {
        fill(r, Pal.panel)
        stroke(r, color.a(0.55), 1)
        let L: CGFloat = 12
        for (cx, cy, dx, dy) in [(r.minX, r.minY, 1.0, 1.0), (r.maxX, r.minY, -1.0, 1.0),
                                 (r.minX, r.maxY, 1.0, -1.0), (r.maxX, r.maxY, -1.0, -1.0)] {
            line(CGPoint(x: cx, y: cy), CGPoint(x: cx + L * dx, y: cy), color, 2.5)
            line(CGPoint(x: cx, y: cy), CGPoint(x: cx, y: cy + L * dy), color, 2.5)
        }
        if let t = title {
            let tw = CGFloat(t.count) * G.charW(12, true) + 16
            fill(CGRect(x: r.minX + 14, y: r.minY - 9, width: tw, height: 18), color)
            text(t, r.minX + 22, r.minY - 8, 12, Pal.black, bold: true)
        }
    }

    func bar(_ r: CGRect, _ frac: Double, _ c: NSColor, back: NSColor = Pal.dark) {
        fill(r, back)
        fill(CGRect(x: r.minX, y: r.minY, width: r.width * CGFloat(clamp(frac, 0, 1)), height: r.height), c)
        stroke(r, c.a(0.5), 1)
    }

    func hazardStripes(_ r: CGRect, _ c1: NSColor = Pal.yellow, _ c2: NSColor = Pal.black, step: CGFloat = 16) {
        ctx.saveGState(); ctx.clip(to: r)
        fill(r, c2)
        var x = r.minX - r.height
        while x < r.maxX {
            poly([CGPoint(x: x, y: r.maxY), CGPoint(x: x + step / 2, y: r.maxY),
                  CGPoint(x: x + step / 2 + r.height, y: r.minY), CGPoint(x: x + r.height, y: r.minY)], c1)
            x += step
        }
        ctx.restoreGState()
    }

    func save() { ctx.saveGState() }
    func restore() { ctx.restoreGState() }
    func alpha(_ a: CGFloat) { ctx.setAlpha(a) }
}

// MARK: - Reusable selectable option list (keyboard + mouse)

struct OptionList {
    var items: [String]
    var sel = 0
    var rects: [CGRect] = []
    var numberKeys = true

    init(_ items: [String], numberKeys: Bool = true) { self.items = items; self.numberKeys = numberKeys }

    mutating func key(_ k: String) -> Int? {
        guard !items.isEmpty else { return nil }
        switch k {
        case "up", "w": sel = (sel - 1 + items.count) % items.count; Audio.shared.blip(900, 0.02)
        case "down", "s": sel = (sel + 1) % items.count; Audio.shared.blip(900, 0.02)
        case "enter", "space": Audio.shared.blip(1300, 0.05); return sel
        default:
            if numberKeys, let n = Int(k), n >= 1, n <= items.count {
                sel = n - 1; Audio.shared.blip(1300, 0.05); return sel
            }
        }
        return nil
    }
    mutating func hover(_ p: CGPoint) { if let i = rects.firstIndex(where: { $0.contains(p) }) { sel = i } }
    mutating func click(_ p: CGPoint) -> Int? {
        if let i = rects.firstIndex(where: { $0.contains(p) }) { sel = i; Audio.shared.blip(1300, 0.05); return i }
        return nil
    }

    /// Draws items; returns total height.
    @discardableResult
    mutating func draw(_ g: G, x: CGFloat, y: CGFloat, w: CGFloat, size: CGFloat = 16,
                       color: NSColor = Pal.green, hi: NSColor = Pal.amber, gap: CGFloat = 8,
                       disabled: Set<Int> = []) -> CGFloat {
        rects.removeAll(keepingCapacity: true)
        var cy = y
        let lh = size * 1.3
        for (i, it) in items.enumerated() {
            let label = (numberKeys && items.count <= 9 ? "[\(i + 1)] " : "") + it
            let lines = G.wrap(label, width: w - 24, size: size)
            let r = CGRect(x: x, y: cy - 3, width: w, height: CGFloat(lines.count) * lh + 6)
            rects.append(r)
            let off = disabled.contains(i)
            if i == sel {
                g.fill(r, hi.a(0.16)); g.fill(CGRect(x: r.minX, y: r.minY, width: 4, height: r.height), hi)
            }
            for (j, l) in lines.enumerated() {
                g.text(l, x + 14, cy + CGFloat(j) * lh, size, off ? Pal.grey : (i == sel ? hi : color), bold: i == sel)
            }
            cy += r.height + gap
        }
        return cy - y
    }
}

// MARK: - Scenes

protocol Scene: AnyObject {
    func update(_ dt: Double)
    func draw(_ g: G)
    func keyDown(_ k: String)
    func keyUp(_ k: String)
    func mouseDown(_ p: CGPoint)
    func mouseMoved(_ p: CGPoint)
    func leave()
}
extension Scene {
    func keyUp(_ k: String) {}
    func mouseDown(_ p: CGPoint) {}
    func mouseMoved(_ p: CGPoint) {}
    func leave() {}
}

enum Input {
    static var held = Set<String>()
    static func down(_ k: String) -> Bool { held.contains(k) }
}

final class Game {
    static let shared = Game()
    private(set) var scene: Scene?
    var state = GameState.load()
    var time: Double = 0
    var fade: Double = 1
    var headless = false

    let ctx: CGContext
    private var overlay: CGImage?

    private init() {
        let cs = CGColorSpace(name: CGColorSpace.sRGB)!
        ctx = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0,
                        space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!
        ctx.translateBy(x: 0, y: H)
        ctx.scaleBy(x: 1, y: -1)
        ctx.interpolationQuality = .low
        overlay = Game.makeOverlay()
    }

    func go(_ s: Scene) {
        scene?.leave()
        Input.held.removeAll()
        scene = s
        fade = 1
    }

    func update(_ dt: Double) {
        time += dt
        scene?.update(dt)
        fade = max(0, fade - dt * 3)
    }

    /// Renders one frame into the backbuffer and returns it as an image.
    func render() -> CGImage? {
        let prev = NSGraphicsContext.current
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
        let g = G(ctx)
        g.fill(CGRect(x: 0, y: 0, width: W, height: H), Pal.bg)
        scene?.draw(g)
        if let o = overlay { ctx.draw(o, in: CGRect(x: 0, y: 0, width: W, height: H)) }
        if fade > 0 { g.fill(CGRect(x: 0, y: 0, width: W, height: H), Pal.black.a(CGFloat(fade))) }
        NSGraphicsContext.current = prev
        return ctx.makeImage()
    }

    func keyDown(_ k: String) {
        if k == "`" { Audio.shared.muted.toggle(); return }
        scene?.keyDown(k)
    }

    /// Scanlines + vignette, rendered once.
    private static func makeOverlay() -> CGImage? {
        let cs = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let c = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0,
                                space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else { return nil }
        c.setFillColor(rgba(0, 0, 0, 0.11).cgColor)
        var y: CGFloat = 0
        while y < H { c.fill(CGRect(x: 0, y: y, width: W, height: 1)); y += 3 }
        let grad = CGGradient(colorsSpace: cs, colors: [rgba(0, 0, 0, 0).cgColor, rgba(0, 0, 0, 0.55).cgColor] as CFArray,
                              locations: [0.55, 1.0])!
        c.drawRadialGradient(grad, startCenter: CGPoint(x: W / 2, y: H / 2), startRadius: 0,
                             endCenter: CGPoint(x: W / 2, y: H / 2), endRadius: W * 0.62, options: [.drawsAfterEndLocation])
        return c.makeImage()
    }
}

// MARK: - Window view

final class GameView: NSView {
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        let l = CALayer()
        l.contentsGravity = .resizeAspect
        l.backgroundColor = NSColor.black.cgColor
        l.magnificationFilter = .linear
        layer = l
        wantsLayer = true
    }
    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    func present(_ img: CGImage?) {
        CATransaction.begin(); CATransaction.setDisableActions(true)
        layer?.contents = img
        CATransaction.commit()
    }

    private func logical(_ e: NSEvent) -> CGPoint {
        let p = convert(e.locationInWindow, from: nil)
        let s = min(bounds.width / W, bounds.height / H)
        let ox = (bounds.width - W * s) / 2, oy = (bounds.height - H * s) / 2
        return CGPoint(x: (p.x - ox) / s, y: (p.y - oy) / s)
    }

    static func name(_ e: NSEvent) -> String {
        switch e.keyCode {
        case 126: return "up"
        case 125: return "down"
        case 123: return "left"
        case 124: return "right"
        case 36, 76: return "enter"
        case 53: return "esc"
        case 49: return "space"
        case 48: return "tab"
        case 51, 117: return "back"
        default: return (e.charactersIgnoringModifiers ?? "").lowercased()
        }
    }

    override func keyDown(with e: NSEvent) {
        if e.modifierFlags.contains(.command) { super.keyDown(with: e); return }
        let n = GameView.name(e)
        Input.held.insert(n)
        if !e.isARepeat || ["up", "down", "left", "right", "back"].contains(n) { Game.shared.keyDown(n) }
    }
    override func keyUp(with e: NSEvent) {
        let n = GameView.name(e)
        Input.held.remove(n)
        Game.shared.scene?.keyUp(n)
    }
    override func flagsChanged(with e: NSEvent) {
        if e.modifierFlags.contains(.shift) { Input.held.insert("shift") } else { Input.held.remove("shift") }
    }
    override func mouseDown(with e: NSEvent) { Game.shared.scene?.mouseDown(logical(e)) }
    override func mouseMoved(with e: NSEvent) { Game.shared.scene?.mouseMoved(logical(e)) }
}

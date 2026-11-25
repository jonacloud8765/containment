// CONTAINMENT — fully procedural audio. No sample files: one AVAudioSourceNode synthesizes
// Geiger clicks, SCBA demand-valve breathing, wind, heartbeat, alarms and UI/radio one-shots.

import AVFoundation
import os

final class Audio {
    static let shared = Audio()

    private let engine = AVAudioEngine()
    private var src: AVAudioSourceNode?
    private let sr = 44100.0
    private(set) var started = false
    var muted = false

    // Continuous parameters (written on main thread, read on render thread — plain scalars).
    var geigerCPS = 0.0        // detector clicks per second
    var breathRate = 0.0       // breaths per minute (0 = off)
    var breathGain = 0.5
    var wind = 0.0             // 0..1
    var rumble = 0.0           // 0..1 low industrial rumble / fire
    var hum = 0.0              // 0..1 lab equipment hum
    var radioStatic = 0.0      // 0..1 continuous radio hiss
    var heartBPM = 0.0
    var heartGain = 0.0
    var alarm = 0              // 0 none, 1 gas meter, 2 SCBA low-air bell, 3 dosimeter chirp, 4 siren, 5 PASS-style tone

    // Render-thread state.
    private var rng: UInt32 = 0x9E3779B9
    private var clickEnv = 0.0, clickSign = 1.0
    private var breathT = 0.0
    private var lpA = 0.0, lpB = 0.0, lpC = 0.0, lpD = 0.0, lpE = 0.0, lpF = 0.0
    private var alarmT = 0.0, phaseA = 0.0, phaseB = 0.0, heartT = 0.0, humPh = 0.0
    private var windMod = 0.0

    private struct Voice { var kind = 0; var freq = 0.0; var t = 1.0; var dur = 0.0; var gain = 0.0; var ph = 0.0 }
    private var voices = [Voice](repeating: Voice(), count: 16)
    private var queue: [Voice] = []
    private let lock: UnsafeMutablePointer<os_unfair_lock> = {
        let p = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1); p.initialize(to: os_unfair_lock()); return p
    }()

    func start() {
        guard !started else { return }
        let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 2)!
        let node = AVAudioSourceNode(format: fmt) { [unowned self] _, _, frames, abl -> OSStatus in
            self.render(Int(frames), UnsafeMutableAudioBufferListPointer(abl))
            return noErr
        }
        src = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: fmt)
        engine.mainMixerNode.outputVolume = 0.85
        do { try engine.start(); started = true } catch { print("CONTAINMENT: audio disabled (\(error))") }
    }

    /// Silence every continuous layer — called between scenes so nothing leaks across missions.
    func reset() {
        geigerCPS = 0; breathRate = 0; wind = 0; rumble = 0; hum = 0; radioStatic = 0
        heartBPM = 0; heartGain = 0; alarm = 0
    }

    // MARK: One-shots

    private func push(_ v: Voice) {
        guard started else { return }
        os_unfair_lock_lock(lock); if queue.count < 32 { queue.append(v) }; os_unfair_lock_unlock(lock)
    }
    func blip(_ freq: Double = 1000, _ dur: Double = 0.04, _ gain: Double = 0.12) { push(Voice(kind: 0, freq: freq, t: 0, dur: dur, gain: gain)) }
    func staticBurst(_ dur: Double = 0.25, _ gain: Double = 0.18) { push(Voice(kind: 1, freq: 0, t: 0, dur: dur, gain: gain)) }
    func squelch() { push(Voice(kind: 2, freq: 2400, t: 0, dur: 0.12, gain: 0.14)); staticBurst(0.18, 0.1) }
    func tick() { push(Voice(kind: 3, freq: 0, t: 0, dur: 0.012, gain: 0.08)) }
    func thud(_ gain: Double = 0.35) { push(Voice(kind: 4, freq: 55, t: 0, dur: 0.35, gain: gain)) }
    func spray(_ dur: Double = 1.4) { push(Voice(kind: 5, freq: 0, t: 0, dur: dur, gain: 0.16)) }
    func confirm() { push(Voice(kind: 6, freq: 700, t: 0, dur: 0.18, gain: 0.12)) }
    func deny() { push(Voice(kind: 7, freq: 220, t: 0, dur: 0.3, gain: 0.16)) }
    func stamp() { thud(0.5); staticBurst(0.06, 0.2) }

    // MARK: Render

    @inline(__always) private func noise() -> Double {
        rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5
        return Double(rng) / 2147483647.5 - 1.0
    }
    @inline(__always) private func coef(_ fc: Double) -> Double { 1 - exp(-2 * Double.pi * fc / sr) }

    private func render(_ n: Int, _ bufs: UnsafeMutableAudioBufferListPointer) {
        if os_unfair_lock_trylock(lock) {
            for q in queue { if let i = voices.firstIndex(where: { $0.t >= $0.dur }) { voices[i] = q } }
            queue.removeAll(keepingCapacity: true)
            os_unfair_lock_unlock(lock)
        }
        guard bufs.count >= 2, let l = bufs[0].mData?.assumingMemoryBound(to: Float.self),
              let r = bufs[1].mData?.assumingMemoryBound(to: Float.self) else { return }
        if muted { for i in 0..<n { l[i] = 0; r[i] = 0 }; return }

        let dt = 1.0 / sr
        let cHiss = coef(5200), cLow = coef(520), cWind = coef(380), cRum = coef(70), cStat = coef(3800)
        let gps = min(geigerCPS, 1500)
        let br = breathRate
        let period = br > 0 ? 60.0 / br : 1
        for i in 0..<n {
            var s = 0.0
            let nz = noise()

            // Geiger-Müller tube clicks (Poisson process).
            if gps > 0, (noise() * 0.5 + 0.5) < gps * dt { clickEnv = 1; clickSign = -clickSign }
            if clickEnv > 0.002 { s += clickEnv * (0.55 * nz + 0.45 * clickSign) * 0.42; clickEnv *= 0.86 }

            // SCBA: demand-valve inhale hiss, exhalation-valve whoosh.
            if br > 0 {
                breathT += dt; if breathT >= period { breathT -= period }
                let ph = breathT / period
                lpA += cHiss * (nz - lpA)
                lpB += cLow * (nz - lpB)
                if ph < 0.38 {
                    let e = pow(sin(Double.pi * ph / 0.38), 0.8)
                    s += (lpA - lpB * 0.6) * e * 0.30 * breathGain
                } else if ph < 0.80 {
                    let p2 = (ph - 0.38) / 0.42
                    let e = pow(sin(Double.pi * p2), 1.3) * (0.75 + 0.25 * sin(2 * Double.pi * 28 * breathT))
                    s += lpB * e * 0.75 * breathGain
                    if p2 < 0.01 { s += 0.10 * breathGain * nz }
                }
            }

            // Wind / rumble.
            if wind > 0 {
                windMod += dt * 0.31
                lpC += cWind * (nz - lpC)
                s += lpC * wind * (0.55 + 0.45 * sin(windMod * 2.1) * sin(windMod * 0.7)) * 0.9
            }
            if rumble > 0 { lpD += cRum * (nz - lpD); s += lpD * rumble * 2.2 }
            if hum > 0 {
                humPh += dt * 60
                s += (sin(2 * Double.pi * humPh) * 0.6 + sin(4 * Double.pi * humPh) * 0.3) * hum * 0.05
            }
            if radioStatic > 0 { lpE += cStat * (nz - lpE); s += (nz - lpE) * radioStatic * 0.10 }

            // Heartbeat (lub-dub).
            if heartBPM > 0 && heartGain > 0 {
                heartT += dt; let hp = 60 / heartBPM; if heartT >= hp { heartT -= hp }
                for off in [0.0, 0.16] {
                    let t = heartT - off
                    if t >= 0 && t < 0.12 { s += sin(2 * Double.pi * 48 * t) * exp(-t * 30) * heartGain * 0.5 }
                }
            }

            // Alarms.
            if alarm != 0 {
                alarmT += dt
                switch alarm {
                case 1: // multi-gas meter: alternating piercing tones
                    let cyc = alarmT.truncatingRemainder(dividingBy: 0.5)
                    if cyc < 0.2 || (cyc > 0.25 && cyc < 0.45) {
                        phaseA += (cyc < 0.25 ? 2900 : 2400) * dt
                        s += (phaseA.truncatingRemainder(dividingBy: 1) < 0.5 ? 1 : -1) * 0.05
                    }
                case 2: // SCBA low-air bell
                    let t = alarmT.truncatingRemainder(dividingBy: 0.22)
                    s += (sin(2 * Double.pi * 1850 * t) + 0.6 * sin(2 * Double.pi * 2930 * t)) * exp(-t * 18) * 0.09
                case 3: // electronic personal dosimeter chirp
                    let t = alarmT.truncatingRemainder(dividingBy: 0.35)
                    if t < 0.06 { s += sin(2 * Double.pi * 3300 * t) * 0.07 }
                case 4: // civil-defence wail siren
                    let fq = 420 + 330 * (0.5 - 0.5 * cos(alarmT * 2 * Double.pi / 9))
                    phaseA += fq * dt; phaseB += fq * 1.5 * dt
                    s += (sin(2 * Double.pi * phaseA) * 0.7 + sin(2 * Double.pi * phaseB) * 0.2) * 0.07
                default: // steady warning tone
                    phaseA += 1600 * dt
                    if alarmT.truncatingRemainder(dividingBy: 1.0) < 0.5 { s += sin(2 * Double.pi * phaseA) * 0.05 }
                }
            }

            // One-shot voices.
            for v in 0..<voices.count where voices[v].t < voices[v].dur {
                var vc = voices[v]
                let p = vc.t / vc.dur
                var x = 0.0
                switch vc.kind {
                case 0: vc.ph += vc.freq * dt; x = sin(2 * Double.pi * vc.ph) * (1 - p)
                case 1: lpF += coef(2600) * (nz - lpF); x = (nz * 0.6 + lpF) * (1 - p) * (0.6 + 0.4 * sin(vc.t * 90))
                case 2: vc.ph += (vc.freq * (1 - 0.7 * p)) * dt; x = sin(2 * Double.pi * vc.ph) * (1 - p)
                case 3: x = nz * (1 - p)
                case 4: vc.ph += vc.freq * (1 - 0.4 * p) * dt; x = sin(2 * Double.pi * vc.ph) * exp(-vc.t * 9)
                case 5: x = nz * min(1, vc.t * 8) * min(1, (vc.dur - vc.t) * 4) * 0.7
                case 6: vc.ph += (vc.freq + 700 * p) * dt; x = sin(2 * Double.pi * vc.ph) * (1 - p)
                default: vc.ph += vc.freq * dt; x = (vc.ph.truncatingRemainder(dividingBy: 1) < 0.5 ? 1 : -1) * (1 - p) * 0.6
                }
                s += x * vc.gain
                vc.t += dt
                voices[v] = vc
            }

            let o = Float(tanh(s * 1.4) * 0.8)
            l[i] = o; r[i] = o
        }
    }
}

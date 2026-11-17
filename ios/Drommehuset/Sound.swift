import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(os)
import os
#endif

// Synthesized sound effects and music (same sounds as the web version, made in code, no files).

private struct Voice {
    var active = false
    var bus = 0            // 0 = effects, 1 = music
    var wave = 0           // 0 sine, 1 square, 2 triangle, 3 saw, 4 noise
    var start: Int64 = 0   // absolute sample time
    var len: Int64 = 0     // samples until the voice stops
    var dur = 0.1          // seconds of the envelope ramp
    var attack = 0.0       // seconds of linear fade-in (0 = start at full volume)
    var vol = 0.1
    var f0 = 440.0, f1 = 0.0
    var phase = 0.0
    var rng: UInt32 = 22222
    var filt = Biquad()
    var useFilter = false
    var sustain = false    // jevn tone med vibrato (sangstemme)
    var tag = 0            // 1 = sangen (kan stoppes)
}

private struct Biquad {
    var b0 = 1.0, b1 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0

    // type: 0 lowpass, 1 highpass, 2 bandpass
    static func make(_ type: Int, _ freq: Double, _ q: Double, _ sr: Double) -> Biquad {
        var f = Biquad()
        let w = 2 * Double.pi * min(freq, sr * 0.45) / sr
        let cw = cos(w), alpha = sin(w) / (2 * q)
        var b0 = 0.0, b1 = 0.0, b2 = 0.0
        if type == 0 { b0 = (1 - cw) / 2; b1 = 1 - cw; b2 = (1 - cw) / 2 }
        else if type == 1 { b0 = (1 + cw) / 2; b1 = -(1 + cw); b2 = (1 + cw) / 2 }
        else { b0 = alpha; b1 = 0; b2 = -alpha }
        let a0 = 1 + alpha
        f.b0 = b0 / a0; f.b1 = b1 / a0; f.b2 = b2 / a0
        f.a1 = (-2 * cw) / a0; f.a2 = (1 - alpha) / a0
        return f
    }

    mutating func run(_ x: Double) -> Double {
        let y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1; x1 = x; y2 = y1; y1 = y
        return y
    }
}

private struct LoopSlot {
    var active = false
    var noise = false
    var gain = 0.0, target = 0.0, coef = 0.0
    var freqs = (0.0, 0.0)
    var phases = (0.0, 0.0)
    var filt1 = Biquad(), filt2 = Biquad()
    var rng: UInt32 = 12345
}

private final class Lock {
    #if canImport(os)
    private let p: UnsafeMutablePointer<os_unfair_lock>
    init() { p = .allocate(capacity: 1); p.initialize(to: os_unfair_lock()) }
    func lock() { os_unfair_lock_lock(p) }
    func unlock() { os_unfair_lock_unlock(p) }
    #else
    private let l = NSLock()
    func lock() { l.lock() }
    func unlock() { l.unlock() }
    #endif
}

final class Sound {
    static let shared = Sound()

    /// 0 = off, 1 = effects only, 2 = effects and music (same as state.snd)
    var level = 2 { didSet { levelChanged() } }
    /// Evening makes the music slower and lower, like the web version.
    var evening = false

    private let maxVoices = 96
    private let voices: UnsafeMutablePointer<Voice>
    private var loops = [LoopSlot](repeating: LoopSlot(), count: 6)
    private var loopNames = [String](repeating: "", count: 6)   // main thread only
    private let lock = Lock()
    private var sr = 44100.0
    private var clock: Int64 = 0
    private var master = 0.0, masterTarget = 1.2
    private var mus = 0.0, musTarget = 1.8
    private var env = 0.0
    private var seed: UInt32 = 987654
    private var started = false
    private var nextBeat = 0.0
    private var step = 0
    private var timer: Timer?
    #if canImport(AVFoundation)
    private var engine: AVAudioEngine?
    private var node: AVAudioSourceNode?
    #endif

    private init() {
        voices = .allocate(capacity: 96)
        voices.initialize(repeating: Voice(), count: 96)
    }

    // MARK: public API

    func sfx(_ n: String) {
        guard level > 0 else { return }
        start()
        switch n {
        case "click": tone(880, 0.06, 0, 0.05)
        case "coin": tone(988, 0.09, 1, 0.045); tone(1319, 0.3, 1, 0.045, 0.08)
        case "level": for (i, f) in [523.0, 659, 784, 1047, 1319].enumerated() { tone(f, 0.25, 2, 0.08, Double(i) * 0.09) }
        case "good": for (i, f) in [659.0, 784, 988, 1319].enumerated() { tone(f, 0.3, 0, 0.08, Double(i) * 0.07) }
        case "bad": tone(392, 0.25, 2, 0.1, 0, 330); tone(294, 0.45, 2, 0.1, 0.2, 220)
        case "step": noise(0.06, 0.05, 500)
        case "rustle": noise(0.18, 0.07, 3500, 2); noise(0.15, 0.05, 2500, 2, 0.15)
        case "meow": tone(620, 0.18, 3, 0.03, 0, 900); tone(900, 0.35, 3, 0.03, 0.16, 520)
        case "bark": for a in [0.0, 0.22] { tone(300, 0.12, 1, 0.05, a, 160); noise(0.1, 0.1, 900, 0, a) }
        case "squeak": tone(1400, 0.12, 0, 0.05, 0, 1900)
        case "splash": noise(0.6, 0.15, 1400)
        case "flush": noise(1.2, 0.12, 700); noise(0.8, 0.06, 2000, 2, 0.3)
        case "door": tone(110, 0.15, 0, 0.12, 0, 80); noise(0.08, 0.06, 600)
        case "giggle": for (i, a) in [0.0, 0.1, 0.2, 0.3].enumerated() { tone(900 + Double(i) * 60, 0.08, 0, 0.06, a, 1100) }
        case "ding": tone(1047, 0.6, 0, 0.08); tone(1568, 0.6, 0, 0.04, 0.02)
        case "buckle": noise(0.03, 0.25, 4000, 1); tone(1900, 0.04, 1, 0.05, 0.07); noise(0.03, 0.2, 3000, 1, 0.08)
        case "pop": tone(300, 0.08, 0, 0.08, 0, 700)
        default: break
        }
    }

    /// Looping sounds: "water", "sizzle", "engine", anything else = low hum.
    func loop(_ n: String, _ on: Bool) {
        if on && level > 0 { start() }
        guard started else { return }
        let idx = loopNames.firstIndex(of: n)
        if !on || level == 0 {
            guard let i = idx else { return }
            loopNames[i] = ""
            lock.lock()
            loops[i].target = 0
            loops[i].coef = 1 - exp(-1 / (0.15 * sr))
            lock.unlock()
            // the slot keeps fading and is switched off by the render loop once it is silent
            return
        }
        if idx != nil { return }
        lock.lock()
        var free = -1
        for i in 0..<loops.count where !loops[i].active && loopNames[i].isEmpty { free = i; break }
        if free < 0 {
            for i in 0..<loops.count where loopNames[i].isEmpty { free = i; break }
        }
        if free < 0 { lock.unlock(); return }
        var s = LoopSlot()
        s.active = true
        s.coef = 1 - exp(-1 / (0.2 * sr))
        if n == "water" || n == "sizzle" {
            s.noise = true
            s.filt1 = n == "water" ? Biquad.make(2, 1800, 1, sr) : Biquad.make(1, 3500, 0.8, sr)
            s.target = n == "sizzle" ? 0.05 : 0.07
        } else {
            let eng = n == "engine"
            s.freqs = eng ? (55, 57) : (82, 83.5)
            s.filt1 = Biquad.make(0, eng ? 300 : 420, 0.8, sr)
            s.filt2 = s.filt1
            s.target = 0.06
        }
        s.rng = UInt32(truncatingIfNeeded: free * 7919 + 17)
        loops[free] = s
        lock.unlock()
        loopNames[free] = n
    }

    func startMusic() { if level < 2 { level = 2 } else { start() } }
    func stopMusic() { if level > 1 { level = 1 } }

    // MARK: building voices

    private func now() -> Double {
        lock.lock(); let c = clock; lock.unlock()
        return Double(c) / sr
    }

    private func add(_ v: Voice) {
        lock.lock()
        for i in 0..<maxVoices where !voices[i].active {
            voices[i] = v
            voices[i].active = true
            break
        }
        lock.unlock()
    }

    /// Same as JS tone(f,d,type,vol,at,f2)
    private func tone(_ f: Double, _ d: Double, _ wave: Int, _ vol: Double, _ at: Double = 0, _ f2: Double = 0) {
        guard started else { return }
        var v = Voice()
        v.bus = 0; v.wave = wave; v.f0 = f; v.f1 = f2; v.dur = d; v.vol = vol; v.attack = 0.012
        v.start = Int64((now() + 0.01 + at) * sr)
        v.len = Int64((d + 0.05) * sr)
        add(v)
    }

    /// Same as JS noise(d,vol,freq,type,at); type 0 lowpass, 1 highpass, 2 bandpass
    private func noise(_ d: Double, _ vol: Double, _ freq: Double, _ type: Int = 0, _ at: Double = 0) {
        guard started else { return }
        var v = Voice()
        v.bus = 0; v.wave = 4; v.dur = d; v.vol = vol; v.attack = 0
        v.useFilter = true
        v.filt = Biquad.make(type, freq, type == 2 ? 1 : 0.8, sr)
        seed = seed &* 1664525 &+ 1013904223
        v.rng = seed | 1
        v.start = Int64((now() + 0.01 + at) * sr)
        v.len = Int64((d + 0.05) * sr)
        add(v)
    }

    private func note(_ f: Double, _ d: Double, _ wave: Int, _ vol: Double, _ at: Double) {
        var v = Voice()
        v.bus = 1; v.wave = wave; v.f0 = f; v.dur = d; v.vol = vol; v.attack = 0.04
        v.start = Int64(at * sr)
        v.len = Int64((d + 0.05) * sr)
        add(v)
    }

    // MARK: vuggesang («Bæ, bæ, lille lam», folkevise)

    /// (tekst, tone i halvtoner fra C, lengde i slag)
    static let songSyl: [[(String, Int, Double)]] = [
        [("Bæ,", 0, 1), ("bæ,", 0, 1), ("lil", 7, 0.5), ("le", 7, 0.5), ("lam,", 7, 1), ("har", 9, 0.5), ("du", 9, 0.5), ("no", 9, 0.5), ("e", 9, 0.5), ("ull?", 7, 2)],
        [("Ja,", 5, 1), ("ja,", 5, 1), ("kjæ", 4, 0.5), ("re", 4, 0.5), ("barn,", 4, 1), ("jeg", 2, 0.5), ("har", 2, 0.5), ("krop", 2, 0.5), ("pen", 2, 0.5), ("full.", 0, 2)],
        [("Søn", 7, 1), ("dags", 7, 0.5), ("klær", 7, 0.5), ("til", 5, 1), ("far", 5, 1), ("og", 4, 0.5), ("søn", 4, 0.5), ("dags", 4, 0.5), ("klær", 4, 0.5), ("til", 2, 1), ("mor,", 2, 1)],
        [("og", 7, 0.5), ("to", 7, 0.5), ("par", 7, 1), ("strøm", 5, 1), ("per", 5, 1), ("til", 4, 0.5), ("den", 4, 0.5), ("lil", 2, 0.5), ("le", 2, 0.5), ("bror.", 0, 2)],
    ]
    static let songLines = ["Bæ, bæ, lille lam, har du noe ull?", "Ja, ja, kjære barn, jeg har kroppen full.", "Søndagsklær til far og søndagsklær til mor,", "og to par strømper til den lille bror."]
    static let songBeat = 0.62
    static var songLength: Double { songSyl.reduce(0) { $0 + $1.reduce(0) { $0 + $1.2 } } * songBeat + 0.6 }
    /// Hvilken linje som synges etter t sekunder.
    static func songLine(_ t: Double) -> Int {
        var acc = 0.0
        for (i, l) in songSyl.enumerated() { acc += l.reduce(0) { $0 + $1.2 } * songBeat; if t < acc { return i } }
        return songSyl.count - 1
    }

    /// Spiller vuggesangen med en myk sangstemme og rolig akkompagnement.
    func song() {
        guard level > 0 else { return }
        start()
        stopSong()
        let c5 = 523.25, t0 = now() + 0.15
        var t = t0
        let bass: [[Int]] = [[0, 0], [5, 0], [0, 5], [7, 0]]
        for (li, line) in Sound.songSyl.enumerated() {
            let lineStart = t
            for (_, semi, beats) in line {
                let f = c5 * pow(2, Double(semi) / 12), d = beats * Sound.songBeat
                for (mul, vol, wave) in [(1.0, 0.085, 0), (2.0, 0.012, 2), (0.5, 0.02, 0)] {
                    var v = Voice()
                    v.bus = 0; v.wave = wave; v.f0 = f * mul; v.dur = d * 0.96; v.vol = vol; v.attack = 0.05; v.sustain = true; v.tag = 1
                    v.start = Int64(t * sr); v.len = Int64((d + 0.05) * sr)
                    add(v)
                }
                t += d
            }
            let half = (t - lineStart) / 2
            for (k, b) in bass[li].enumerated() {
                var v = Voice()
                v.bus = 0; v.wave = 2; v.f0 = 130.81 * pow(2, Double(b) / 12); v.dur = half; v.vol = 0.05; v.attack = 0.02; v.tag = 1
                v.start = Int64((lineStart + Double(k) * half) * sr); v.len = Int64((half + 0.05) * sr)
                add(v)
            }
        }
        lock.lock(); songUntil = t; lock.unlock()
    }

    func stopSong() {
        lock.lock()
        for i in 0..<maxVoices where voices[i].active && voices[i].tag == 1 { voices[i].active = false }
        songUntil = 0
        lock.unlock()
    }

    private var songUntil = 0.0

    // MARK: music (same chords and pentatonic melody as the web version)

    private static let CH: [[Double]] = [[261.63, 329.63, 392], [220, 261.63, 329.63], [174.61, 220, 261.63], [196, 246.94, 293.66]]
    private static let PENT: [Double] = [523.25, 587.33, 659.25, 783.99, 880, 1046.5]

    private func music() {
        guard started, level >= 2 else { nextBeat = 0; return }
        let bt = 0.68
        let t0 = now()
        if nextBeat == 0 || nextBeat < t0 { nextBeat = t0 + 0.1 }
        while nextBeat < t0 + 0.4 {
            let t = nextBeat, b = step % 16, ch = Sound.CH[(step >> 4) % 4], eve = evening
            if b % 4 == 0 && t >= songUntil {
                for f in ch { note(f / 2, bt * 4, 2, 0.022, t) }
                note(ch[0] / 4, bt * 1.8, 0, 0.05, t)
            }
            if b % 4 == 2 && t >= songUntil { note(ch[0] / 4 * ((b == 6 || b == 14) ? 1.5 : 1), bt * 1.5, 0, 0.035, t) }
            if t >= songUntil, Double.random(in: 0..<1) < (eve ? 0.35 : 0.55) {
                let f = Sound.PENT[Int.random(in: 0..<Sound.PENT.count)] * (eve ? 0.5 : 1)
                note(f, bt * 1.2, 0, 0.028, t + (Double.random(in: 0..<1) < 0.3 ? bt / 2 : 0))
            }
            step += 1
            nextBeat += bt * (eve ? 1.18 : 1)
        }
    }

    private func levelChanged() {
        lock.lock()
        masterTarget = level > 0 ? 1.2 : 0
        musTarget = level > 1 ? 1.8 : 0
        lock.unlock()
        if level < 1 { for n in loopNames where !n.isEmpty { loop(n, false) } }
        if level > 0 { start() }
    }

    // MARK: rendering (audio thread)

    private func render(_ out: UnsafeMutablePointer<Float>, _ frames: Int) {
        lock.lock()
        let kMaster = 1 - exp(-1 / (0.05 * sr)), kMus = 1 - exp(-1 / (0.4 * sr))
        let atk = 1 - exp(-1 / (0.003 * sr)), rel = 1 - exp(-1 / (0.25 * sr))
        let inv = 1 / sr
        for i in 0..<frames {
            let tnow = clock + Int64(i)
            var sfxSum = 0.0, musSum = 0.0
            for k in 0..<maxVoices where voices[k].active {
                let v = voices + k
                let age = tnow - v.pointee.start
                if age < 0 { continue }
                if age >= v.pointee.len { v.pointee.active = false; continue }
                let tau = Double(age) * inv
                let d = v.pointee.dur, a = v.pointee.attack, vol = v.pointee.vol
                var g: Double
                if v.pointee.sustain {
                    g = vol * min(1, tau / max(0.001, a)) * (tau > d - 0.09 ? max(0, (d - tau) / 0.09) : 1)
                } else if a > 0 && tau < a { g = vol * tau / a }
                else if tau < d { g = vol * pow(0.0001 / vol, (tau - a) / max(0.001, d - a)) }
                else { g = 0.0001 }
                var s: Double
                if v.pointee.wave == 4 {
                    var r = v.pointee.rng
                    r ^= r << 13; r ^= r >> 17; r ^= r << 5
                    v.pointee.rng = r
                    s = Double(r) / Double(UInt32.max) * 2 - 1
                } else {
                    var f = v.pointee.f0
                    if v.pointee.f1 > 0 { f = f * pow(v.pointee.f1 / f, min(1, tau / d)) }
                    if v.pointee.sustain { f *= 1 + 0.007 * sin(2 * Double.pi * 5.3 * tau) * min(1, tau / 0.25) }
                    let dt = f * inv
                    var p = v.pointee.phase + dt
                    if p >= 1 { p -= 1 }
                    v.pointee.phase = p
                    s = Sound.osc(v.pointee.wave, p, dt)
                }
                if v.pointee.useFilter { s = v.pointee.filt.run(s) }
                if v.pointee.bus == 0 { sfxSum += s * g } else { musSum += s * g }
            }
            for k in 0..<loops.count where loops[k].active {
                loops[k].gain += (loops[k].target - loops[k].gain) * loops[k].coef
                if loops[k].target == 0 && loops[k].gain < 0.0002 { loops[k].active = false; continue }
                var s: Double
                if loops[k].noise {
                    var r = loops[k].rng
                    r ^= r << 13; r ^= r >> 17; r ^= r << 5
                    loops[k].rng = r
                    s = loops[k].filt1.run(Double(r) / Double(UInt32.max) * 2 - 1)
                } else {
                    let d1 = loops[k].freqs.0 * inv, d2 = loops[k].freqs.1 * inv
                    var p1 = loops[k].phases.0 + d1; if p1 >= 1 { p1 -= 1 }
                    var p2 = loops[k].phases.1 + d2; if p2 >= 1 { p2 -= 1 }
                    loops[k].phases = (p1, p2)
                    s = loops[k].filt1.run(Sound.osc(3, p1, d1)) + loops[k].filt2.run(Sound.osc(3, p2, d2))
                }
                sfxSum += s * loops[k].gain
            }
            master += (masterTarget - master) * kMaster
            mus += (musTarget - mus) * kMus
            var x = (sfxSum * 1.9 + musSum * mus) * master
            // compressor like the web version (threshold -10 dB, ratio 4, with makeup gain)
            let ax = abs(x)
            env += (ax - env) * (ax > env ? atk : rel)
            let thr = 0.316
            if env > thr { x *= (thr * pow(env / thr, 0.25)) / env }
            x *= 1.6
            if x > 1 { x = 1 } else if x < -1 { x = -1 }
            out[i] = Float(x)
        }
        clock += Int64(frames)
        lock.unlock()
    }

    /// Band-limited oscillators (polyBLEP for square and saw, like the browser's).
    private static func osc(_ w: Int, _ p: Double, _ dt: Double) -> Double {
        switch w {
        case 0: return sin(2 * Double.pi * p)
        case 1:
            var s = p < 0.5 ? 1.0 : -1.0
            s += blep(p, dt)
            var q = p + 0.5; if q >= 1 { q -= 1 }
            s -= blep(q, dt)
            return s
        case 2: return 1 - 4 * abs(p - 0.5)
        default: return (2 * p - 1) - blep(p, dt)
        }
    }

    private static func blep(_ t: Double, _ dt: Double) -> Double {
        if dt <= 0 { return 0 }
        if t < dt { let x = t / dt; return x + x - x * x - 1 }
        if t > 1 - dt { let x = (t - 1) / dt; return x * x + x + x + 1 }
        return 0
    }

    // MARK: engine

    private func start() {
        if started { resumeIfNeeded(); return }
        #if canImport(AVFoundation)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        let eng = AVAudioEngine()
        let hw = eng.outputNode.outputFormat(forBus: 0).sampleRate
        sr = hw > 0 ? hw : 44100
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1) else { return }
        let src = AVAudioSourceNode(format: fmt) { [unowned self] _, _, frameCount, abl -> OSStatus in
            let list = UnsafeMutableAudioBufferListPointer(abl)
            let n = Int(frameCount)
            if let first = list.first, let data = first.mData {
                let out = data.assumingMemoryBound(to: Float.self)
                self.render(out, n)
                for b in 1..<max(1, list.count) {
                    if let d = list[b].mData { d.assumingMemoryBound(to: Float.self).update(from: out, count: n) }
                }
            }
            return noErr
        }
        eng.attach(src)
        eng.connect(src, to: eng.mainMixerNode, format: fmt)
        eng.mainMixerNode.outputVolume = 1
        do { try eng.start() } catch { return }
        engine = eng
        node = src
        started = true
        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] _ in
            self?.resumeIfNeeded()
        }
        nc.addObserver(forName: .AVAudioEngineConfigurationChange, object: eng, queue: .main) { [weak self] _ in
            self?.resumeIfNeeded()
        }
        #else
        started = true
        #endif
        let t = Timer(timeInterval: 0.12, repeats: true) { [weak self] _ in self?.music() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func resumeIfNeeded() {
        #if canImport(AVFoundation)
        guard let eng = engine, !eng.isRunning else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        try? eng.start()
        #endif
    }

    /// Call when the app goes to the background / comes back.
    func pause() {
        #if canImport(AVFoundation)
        engine?.pause()
        #endif
    }

    func resume() { if started { resumeIfNeeded() } }
}

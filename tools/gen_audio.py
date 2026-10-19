#!/usr/bin/env python3
"""Membangkitkan efek suara dan musik placeholder (CC0, disintesis dari nol).

Pakai:  python3 tools/gen_audio.py
Hasil:  assets/audio/*.wav  (mono, 16-bit, 22050 Hz)
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def save(name, samples, gain=0.8):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = min(1.0, gain / peak) if peak > gain else 1.0
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767)) for s in samples))


def n(seconds):
    return int(seconds * SR)


def env(i, total, attack=0.004, release=0.05):
    t = i / SR
    dur = total / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, max(0.0, (dur - t) / release)) if release > 0 else 1.0
    return a * r


def sine(freq, dur, amp=1.0, decay=0.0, attack=0.004, release=0.05):
    total = n(dur)
    return [amp * math.sin(2 * math.pi * freq * i / SR) * env(i, total, attack, release)
            * (math.exp(-decay * i / SR) if decay else 1.0) for i in range(total)]


def tri(freq, dur, amp=1.0, decay=0.0, attack=0.01, release=0.08):
    total = n(dur)
    out = []
    for i in range(total):
        ph = (freq * i / SR) % 1.0
        v = 4 * abs(ph - 0.5) - 1
        out.append(amp * v * env(i, total, attack, release) * (math.exp(-decay * i / SR) if decay else 1.0))
    return out


def noise(dur, amp=1.0, decay=8.0, smooth=1):
    raw = [random.uniform(-1, 1) for _ in range(n(dur) + smooth)]
    out = []
    for i in range(n(dur)):
        v = sum(raw[i:i + smooth]) / smooth
        out.append(amp * v * math.exp(-decay * i / SR))
    return out


def sweep(f0, f1, dur, amp=1.0, decay=0.0):
    total = n(dur)
    out = []
    phase = 0.0
    for i in range(total):
        f = f0 + (f1 - f0) * i / total
        phase += 2 * math.pi * f / SR
        out.append(amp * math.sin(phase) * env(i, total, 0.003, 0.03) * (math.exp(-decay * i / SR) if decay else 1.0))
    return out


def add(buf, start, samples):
    end = start + len(samples)
    if end > len(buf):
        buf.extend([0.0] * (end - len(buf)))
    for i, s in enumerate(samples):
        buf[start + i] += s


def concat(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def note(semitones_from_a4):
    return 440.0 * 2 ** (semitones_from_a4 / 12)


# ----------------------------------------------------------------- efek suara
random.seed(7)
save("hoe", [a + b for a, b in zip(noise(0.14, 0.9, 22, 6), sine(95, 0.14, 0.6, 18))])
save("water", sweep(900, 350, 0.28, 0.5, 5)[:n(0.28)])
save("plant", concat(sine(note(3), 0.07, 0.6, 20), sine(note(10), 0.1, 0.6, 14)))
save("harvest", concat(sine(note(3), 0.07, 0.6, 10), sine(note(7), 0.07, 0.6, 10), sine(note(12), 0.16, 0.6, 8)))
save("coin", concat(sine(note(14), 0.07, 0.6, 6), sine(note(19), 0.25, 0.6, 7)))
save("blip", sine(note(8), 0.045, 0.5, 20))
save("select", sine(note(12), 0.03, 0.4, 25))
save("error", tri(110, 0.16, 0.6, 5))
save("splash", noise(0.35, 0.9, 7, 10))
save("mine", [a + b for a, b in zip(noise(0.12, 0.9, 30, 2), sine(180, 0.12, 0.7, 26))])
save("cook", noise(0.5, 0.5, 2.5, 3))
save("door", sweep(320, 160, 0.16, 0.7, 6))


# ---------------------------------------------------------------------- musik
def render_track(name, bpm, root, scale, chords, bars, melody_density, lead, bass_gain, seed, lead_decay=0.0, octave=0):
    rng = random.Random(seed)
    beat = 60.0 / bpm
    total_beats = bars * 4
    buf = [0.0] * n(total_beats * beat)
    # akor: root akor dalam semitone dari root, ganti tiap 2 bar
    for bar in range(bars):
        ch = chords[(bar // 2) % len(chords)]
        t0 = n(bar * 4 * beat)
        for k, interval in enumerate([0, 7, 12, 7]):  # arpeggio per beat
            add(buf, t0 + n(k * beat), sine(note(root + ch + interval - 12 + octave), beat * 0.95, 0.18, 2.0, 0.01, 0.1))
        add(buf, t0, tri(note(root + ch - 24 + octave), beat * 2, bass_gain, 0.6, 0.02, 0.2))
        add(buf, t0 + n(2 * beat), tri(note(root + ch - 24 + octave), beat * 2, bass_gain, 0.6, 0.02, 0.2))
    # melodi: delapan-an dengan jeda acak, nada dari skala
    steps = total_beats * 2
    last = rng.randrange(len(scale))
    for s in range(steps):
        if rng.random() > melody_density:
            continue
        last = max(0, min(len(scale) * 2 - 1, last + rng.choice([-2, -1, -1, 0, 1, 1, 2])))
        degree = scale[last % len(scale)] + 12 * (last // len(scale))
        dur = beat * rng.choice([0.5, 0.5, 1.0])
        add(buf, n(s * beat * 0.5), lead(note(root + degree + octave), dur, lead_decay))
    # fade in/out kecil agar loop tidak klik
    f = n(0.03)
    for i in range(f):
        buf[i] *= i / f
        buf[-1 - i] *= i / f
    save(name, buf, 0.45)


def lead_soft(freq, dur, decay):
    return tri(freq, dur, 0.22, decay or 1.5, 0.02, 0.15)


def lead_bell(freq, dur, decay):
    a = sine(freq, dur + 0.3, 0.2, 5.0, 0.002, 0.2)
    b = sine(freq * 2.01, dur + 0.3, 0.07, 8.0, 0.002, 0.2)
    return [x + y for x, y in zip(a, b)]


PENTA = [0, 2, 4, 7, 9]          # pentatonik mayor
MINOR_PENTA = [0, 3, 5, 7, 10]
MAJOR = [0, 2, 4, 5, 7, 9, 11]

render_track("music_day", 96, -9, PENTA, [0, -3, -7, -5], 8, 0.7, lead_soft, 0.16, 11)          # C mayor-ish
render_track("music_night", 66, -12, MINOR_PENTA, [0, -2, -4, -2], 8, 0.4, lead_soft, 0.14, 23)
render_track("music_indoor", 108, -2, MAJOR, [0, 5, 7, 5], 8, 0.65, lead_bell, 0.12, 5, octave=12)
print("selesai:", sorted(os.listdir(OUT)))

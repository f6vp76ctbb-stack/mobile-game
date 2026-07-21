#!/usr/bin/env python3
"""Generates the background music loop (assets/audio/music.wav).

Self-made, license-free (CC0 / Eigenwerk): a calm lo-fi ambient loop built
from pure sine tones. Deliberately understated to avoid listening fatigue on
long sessions — a soft pad carries the harmony, a sparse arpeggio appears on
only some bars, and a quiet bass grounds it. The progression is longer (12
bars) so repeats are less obvious. Envelopes decay to zero at loop boundaries
so the loop point is click-free. Mono, 22050 Hz, 16-bit PCM.

Run from the repo root:  python3 scripts/gen_music.py
"""
import math
import struct
import wave

RATE = 22050
BPM = 68.0
BEAT = 60.0 / BPM
CHORD_BEATS = 4
# Calm progression in A minor: i - VI - III - VII, then a gentler variation.
CHORDS = [
    ("Am", [220.00, 261.63, 329.63], True),
    ("F", [174.61, 220.00, 261.63], False),
    ("C", [130.81, 164.81, 196.00, 261.63], True),
    ("G", [196.00, 246.94, 293.66], False),
    ("Am", [220.00, 261.63, 329.63], False),
    ("Dm", [146.83, 174.61, 220.00], True),
    ("F", [174.61, 220.00, 261.63], False),
    ("E", [164.81, 207.65, 246.94], True),
    ("Am", [220.00, 261.63, 329.63], True),
    ("F", [174.61, 220.00, 261.63], False),
    ("Dm", [146.83, 174.61, 220.00], False),
    ("E", [164.81, 207.65, 246.94], True),
]
CHORD_LEN = BEAT * CHORD_BEATS
TOTAL = CHORD_LEN * len(CHORDS)
N = int(TOTAL * RATE)

PAD_GAIN = 0.18
ARP_GAIN = 0.06
BASS_GAIN = 0.12


def pad_env(t, length):
    x = t / length
    return math.sin(math.pi * min(max(x, 0.0), 1.0)) ** 1.6


def pluck_env(t, length):
    if t < 0 or t >= length:
        return 0.0
    attack = 0.02
    if t < attack:
        return t / attack
    rel = (t - attack) / (length - attack)
    return math.exp(-3.5 * rel) * (1.0 - rel) ** 0.6


samples = [0.0] * N

for ci, (_, freqs, arp_on) in enumerate(CHORDS):
    start = ci * CHORD_LEN
    s0 = int(start * RATE)
    s1 = int((start + CHORD_LEN) * RATE)

    # Soft pad: chord tones with a quiet octave shimmer, swelling per bar.
    for k in range(s0, min(s1, N)):
        t = k / RATE - start
        env = pad_env(t, CHORD_LEN) * PAD_GAIN
        v = 0.0
        for f in freqs:
            v += math.sin(2 * math.pi * f * t)
            v += 0.22 * math.sin(2 * math.pi * f * 2 * t)
        samples[k] += env * v / (len(freqs) * 1.2)

    # Bass: root an octave down, one soft note per bar (less busy).
    root = freqs[0] / 2.0
    for k in range(s0, min(s1, N)):
        t = k / RATE - start
        env = pluck_env(t, CHORD_LEN) * BASS_GAIN
        samples[k] += env * math.sin(2 * math.pi * root * t)

    # Arpeggio only on flagged bars, as calm quarter notes (not eighths).
    if arp_on:
        tones = [f * 2 for f in freqs]
        for i in range(CHORD_BEATS):
            astart = start + i * BEAT
            a0 = int(astart * RATE)
            f = tones[i % len(tones)]
            for k in range(a0, min(int((astart + BEAT) * RATE), N)):
                t = k / RATE - astart
                env = pluck_env(t, BEAT) * ARP_GAIN
                samples[k] += env * math.sin(2 * math.pi * f * t)

# Normalize with generous headroom (quiet, non-fatiguing).
peak = max(abs(s) for s in samples) or 1.0
scale = 0.6 / peak
frames = bytearray()
for s in samples:
    v = int(max(-1.0, min(1.0, s * scale)) * 32767)
    frames += struct.pack("<h", v)

with wave.open("assets/audio/music.wav", "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(RATE)
    w.writeframes(bytes(frames))

print(f"music.wav: {TOTAL:.1f}s, {len(frames) / 1e6:.2f} MB")

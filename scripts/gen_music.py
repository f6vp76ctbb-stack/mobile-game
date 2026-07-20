#!/usr/bin/env python3
"""Generates the background music loop (assets/audio/music.wav).

Self-made, license-free (CC0 / Eigenwerk): a calm ambient loop built from
pure sine tones — soft pad chords (Am F C G), a gentle eighth-note arpeggio
and a quiet bass. Envelopes decay to zero at chord boundaries so the loop
point is click-free. Mono, 22050 Hz, 16-bit PCM (same format as the SFX).

Run from the repo root:  python3 scripts/gen_music.py
"""
import math
import struct
import wave

RATE = 22050
BPM = 75.0
BEAT = 60.0 / BPM                      # 0.8 s
CHORD_BEATS = 4                        # one bar per chord
CHORDS = [                             # frequencies (Hz): root, third, fifth
    ("Am", [220.00, 261.63, 329.63]),
    ("F", [174.61, 220.00, 261.63]),
    ("C", [130.81, 164.81, 196.00, 261.63]),
    ("G", [196.00, 246.94, 293.66]),
    ("Am", [220.00, 261.63, 329.63]),
    ("F", [174.61, 220.00, 261.63]),
    ("C", [130.81, 164.81, 196.00, 261.63]),
    ("Em", [164.81, 196.00, 246.94]),
]
CHORD_LEN = BEAT * CHORD_BEATS
TOTAL = CHORD_LEN * len(CHORDS)        # 25.6 s
N = int(TOTAL * RATE)

PAD_GAIN = 0.16
ARP_GAIN = 0.10
BASS_GAIN = 0.14


def pad_env(t, length):
    """Slow swell that starts and ends at zero within one chord."""
    x = t / length
    return math.sin(math.pi * min(max(x, 0.0), 1.0)) ** 1.5


def pluck_env(t, length):
    """Fast attack, exponential decay, hard-zero at the end."""
    if t < 0 or t >= length:
        return 0.0
    attack = 0.008
    if t < attack:
        return t / attack
    rel = (t - attack) / (length - attack)
    return math.exp(-4.5 * rel) * (1.0 - rel) ** 0.5


samples = [0.0] * N

for ci, (_, freqs) in enumerate(CHORDS):
    start = ci * CHORD_LEN
    s0 = int(start * RATE)
    s1 = int((start + CHORD_LEN) * RATE)

    # Pad: chord tones + soft octave shimmer, swelling per bar.
    for k in range(s0, min(s1, N)):
        t = k / RATE - start
        env = pad_env(t, CHORD_LEN) * PAD_GAIN
        v = 0.0
        for f in freqs:
            v += math.sin(2 * math.pi * f * t)
            v += 0.35 * math.sin(2 * math.pi * f * 2 * t)  # octave, quieter
        samples[k] += env * v / (len(freqs) * 1.35)

    # Bass: root an octave down, two half-notes per bar.
    root = freqs[0] / 2.0
    for half in range(2):
        hstart = start + half * (CHORD_LEN / 2)
        h0 = int(hstart * RATE)
        hlen = CHORD_LEN / 2
        for k in range(h0, min(int((hstart + hlen) * RATE), N)):
            t = k / RATE - hstart
            env = pluck_env(t, hlen) * BASS_GAIN
            samples[k] += env * math.sin(2 * math.pi * root * t)

    # Arpeggio: eighth notes cycling chord tones one octave up.
    eighth = BEAT / 2
    tones = [f * 2 for f in freqs]
    for i in range(CHORD_BEATS * 2):
        astart = start + i * eighth
        a0 = int(astart * RATE)
        f = tones[i % len(tones)]
        for k in range(a0, min(int((astart + eighth) * RATE), N)):
            t = k / RATE - astart
            env = pluck_env(t, eighth) * ARP_GAIN
            samples[k] += env * math.sin(2 * math.pi * f * t)

# Normalize with headroom, clip safety.
peak = max(abs(s) for s in samples) or 1.0
scale = 0.72 / peak
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

#!/usr/bin/env python3
"""Generate 8-bit-style WAV samples for omarchy-neonvolley."""
import math
import os
import random
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sfx")
SR = 22050


def write_wav(name, samples):
    path = os.path.join(OUT, name + ".wav")
    os.makedirs(OUT, exist_ok=True)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s)))) for s in samples)
        w.writeframes(frames)
    print(path)


def tone(freq, ms, vol=0.35, decay=True):
    n = int(SR * ms / 1000)
    out = []
    for i in range(n):
        t = i / SR
        env = (1 - i / n) if decay else 1
        out.append(math.sin(2 * math.pi * freq * t) * vol * env * 32767)
    return out


def noise(ms, vol=0.2):
    random.seed(42)
    n = int(SR * ms / 1000)
    return [(random.random() * 2 - 1) * vol * (1 - i / n) * 32767 for i in range(n)]


def chirp(f0, f1, ms, vol=0.3):
    n = int(SR * ms / 1000)
    out = []
    for i in range(n):
        t = i / max(1, n - 1)
        f = f0 + (f1 - f0) * t
        env = 1 - i / n
        out.append(math.sin(2 * math.pi * f * (i / SR)) * vol * env * 32767)
    return out


if __name__ == "__main__":
    write_wav("hit", tone(880, 40, 0.45) + tone(440, 30, 0.25))
    write_wav("bounce", tone(220, 35, 0.3) + noise(15, 0.08))
    write_wav("score", chirp(440, 880, 120, 0.35) + tone(880, 80, 0.25))
    write_wav("start", chirp(220, 660, 150, 0.32))
    write_wav("power", chirp(330, 990, 90, 0.42) + tone(990, 50, 0.35))
    write_wav("gameover", chirp(660, 220, 200, 0.28) + tone(220, 120, 0.22))

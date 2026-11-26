#!/usr/bin/env python3
"""Synthesize the finished game's sound effects.

    python3 tools/make_audio.py

Writes game/audio/sfx/*.wav, committed so CI never needs this script. Everything is made from plain waves
and noise here, seeded, so running it again gives the same sounds. Placeholders: anyone can replace a file
with one of the same name. Needs numpy. (The music is the 2014 BIDU songs: tools/make_bidu_music.py.)
"""
import pathlib
import wave

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "game/audio"
SR = 22050
RNG = np.random.default_rng(2016)


def t_axis(seconds):
    return np.arange(int(SR * seconds)) / SR


def env(n, attack=0.01, release=0.1, sustain=1.0):
    e = np.ones(n) * sustain
    a, r = max(1, int(attack * SR)), max(1, int(release * SR))
    e[:a] = np.linspace(0, sustain, a)
    e[-r:] *= np.linspace(1, 0, r)
    return e


def lowpass(x, cutoff):
    """One-pole low-pass, cutoff in Hz (array or number)."""
    cutoff = np.broadcast_to(np.asarray(cutoff, float), x.shape)
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    prev = 0.0
    for i in range(len(x)):
        prev = (1 - a[i]) * x[i] + a[i] * prev
        y[i] = prev
    return y


def osc(freq, seconds, shape="sine"):
    t = t_axis(seconds)
    freq = np.broadcast_to(np.asarray(freq, float), t.shape)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    if shape == "sine":
        return np.sin(phase)
    if shape == "square":
        return np.sign(np.sin(phase)) * 0.6
    if shape == "saw":
        return 2 * ((phase / (2 * np.pi)) % 1) - 1
    if shape == "tri":
        return 2 * np.abs(2 * ((phase / (2 * np.pi)) % 1) - 1) - 1
    raise ValueError(shape)


def normalize(x, peak=0.9):
    m = np.max(np.abs(x)) or 1
    return x / m * peak


def write_wav(path, x):
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def sfx(name, x):
    write_wav(OUT / "sfx" / f"{name}.wav", normalize(x))
    print(f"  sfx/{name}.wav {len(x) / SR:.2f} s")


# ------------------------------------------------------------------------------------------------ effects

def fart(seconds, base, wobble, seed, bright=900):
    rng = np.random.default_rng(seed)
    t = t_axis(seconds)
    n = len(t)
    f = base * (1 + 0.25 * np.sin(2 * np.pi * wobble * t) + 0.15 * rng.standard_normal(n).cumsum() / np.sqrt(n))
    f *= np.linspace(1.1, 0.8, n)
    buzz = osc(f, seconds, "saw") * 0.7 + osc(f * 0.5, seconds, "square") * 0.3
    flutter = 0.6 + 0.4 * (np.sin(2 * np.pi * (wobble * 2.3) * t) > 0)
    noise = rng.standard_normal(n) * 0.35
    x = lowpass(buzz * flutter + noise, bright) * env(n, 0.02, 0.12)
    return x


def boing(f0, f1, seconds):
    t = t_axis(seconds)
    f = f0 * (f1 / f0) ** (t / seconds)
    return osc(f, seconds, "sine") * env(len(t), 0.005, 0.08) * (1 + 0.3 * np.sin(2 * np.pi * 18 * t))


def blip(freqs, step, shape="square"):
    parts = [osc(f, step, shape) * env(int(step * SR), 0.003, step * 0.6) for f in freqs]
    return np.concatenate(parts)


def thud(seconds=0.25, f=90):
    t = t_axis(seconds)
    body = osc(f * np.exp(-t * 8), seconds) * np.exp(-t * 14)
    click = RNG.standard_normal(len(t)) * np.exp(-t * 60) * 0.5
    return body + click


def crack():
    t = t_axis(0.4)
    noise = RNG.standard_normal(len(t))
    return lowpass(noise, 2500) * np.exp(-t * 12) + thud(0.4, 70) * 0.6


def bray():
    """A donkey's hee-haw: alternating high and low voiced tones with a rough edge."""
    parts = []
    for i, (f, d) in enumerate([(620, 0.22), (300, 0.3), (640, 0.2), (290, 0.34)]):
        t = t_axis(d)
        ff = f * (1 + 0.05 * np.sin(2 * np.pi * 7 * t)) * (np.linspace(1.08, 0.95, len(t)) if i % 2 == 0 else 1)
        voice = osc(ff, d, "saw") * 0.6 + osc(ff * 2.02, d, "square") * 0.2
        voice += RNG.standard_normal(len(t)) * 0.15
        parts.append(lowpass(voice, 1800) * env(len(t), 0.02, 0.05))
    return np.concatenate(parts)


def gunshot():
    t = t_axis(0.5)
    noise = RNG.standard_normal(len(t))
    return lowpass(noise, np.linspace(6000, 400, len(t))) * np.exp(-t * 9)


def growl(seconds=0.9):
    t = t_axis(seconds)
    f = 70 + 20 * np.sin(2 * np.pi * 3 * t)
    x = osc(f, seconds, "saw") * (0.6 + 0.4 * np.sin(2 * np.pi * 23 * t))
    x += RNG.standard_normal(len(t)) * 0.4
    return lowpass(x, 700) * env(len(t), 0.08, 0.3)


def buzz(seconds=0.8, f=520):
    t = t_axis(seconds)
    x = osc(f * (1 + 0.03 * np.sin(2 * np.pi * 9 * t)), seconds, "saw")
    return lowpass(x, 3000) * env(len(t), 0.05, 0.2) * 0.6


def fanfare():
    notes = [523, 659, 784, 1047]
    x = blip(notes, 0.11, "square")
    tail = osc(1047, 0.4, "square") * env(int(0.4 * SR), 0.005, 0.35)
    return np.concatenate([x, tail])


def corn_fanfare():
    """'Make noise when getting all corn' (the 2014 sketch): a little fart trumpet tune."""
    parts = []
    for i, (f, d) in enumerate([(196, 0.12), (196, 0.12), (262, 0.12), (330, 0.32)]):
        parts.append(fart(d, f, 30 + i * 5, 50 + i, bright=1600))
    return np.concatenate(parts)


def chime():
    t = t_axis(0.9)
    x = sum(osc(f, 0.9) * np.exp(-t * k) for f, k in [(880, 3), (1320, 4), (1760, 6)])
    return x


def make_sfx():
    for i, (sec, base, wob) in enumerate([(0.45, 95, 9), (0.6, 80, 6), (0.35, 120, 14), (0.7, 70, 4)]):
        sfx(f"fart_{i + 1}", fart(sec, base, wob, i))
    sfx("super_fart", np.concatenate([fart(1.3, 60, 3, 9, 700), np.zeros(int(0.05 * SR))]))
    sfx("fart_fizzle", fart(0.25, 180, 20, 11, 500) * 0.5)
    sfx("jump", boing(220, 520, 0.22))
    sfx("double_jump", boing(380, 900, 0.22))
    sfx("land", thud(0.12, 120) * 0.6)
    sfx("corn", blip([880, 1320], 0.06))
    sfx("beans", blip([660, 990], 0.07, "tri"))
    sfx("hurt", bray())
    sfx("headbutt", thud(0.22, 140))
    sfx("bonk", np.concatenate([thud(0.15, 200), boing(300, 160, 0.25) * 0.6]))
    sfx("break", crack())
    sfx("splash", lowpass(RNG.standard_normal(int(0.5 * SR)), 1800) * np.exp(-t_axis(0.5) * 7))
    sfx("gunshot", gunshot())
    sfx("growl", growl())
    sfx("buzz", buzz())
    sfx("level_up", fanfare())
    sfx("all_corn", corn_fanfare())
    sfx("achievement", chime())
    sfx("click", blip([1200], 0.04))
    sfx("finish", np.concatenate([fanfare(), bray() * 0.7]))


def main():
    make_sfx()


if __name__ == "__main__":
    main()

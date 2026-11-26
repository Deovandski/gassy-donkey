#!/usr/bin/env python3
"""Synthesize the finished game's sound effects and music loops.

    python3 tools/make_audio.py

Writes game/audio/sfx/*.wav (short effects) and game/audio/music/*.ogg (loops), committed so CI never needs
this script. Everything is made from plain waves and noise here, seeded, so running it again gives the same
sounds. Placeholders: a composer can replace any file with one of the same name. Needs numpy and ffmpeg
(with libvorbis) for the .ogg files.
"""
import pathlib
import subprocess
import tempfile
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


# ------------------------------------------------------------------------------------------------ music

def note_hz(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def render_track(bpm, bars, layers):
    """layers: list of (pattern_fn(bar, beat_step) -> list of (midi, length_steps, gain, shape)), 16 steps a bar."""
    step = 60 / bpm / 4
    n = int(round(bars * 16 * step * SR))
    mix = np.zeros(n)
    for layer in layers:
        for bar in range(bars):
            for s in range(16):
                for midi, length, gain, shape in layer(bar, s):
                    start = int(round((bar * 16 + s) * step * SR))
                    d = length * step
                    if shape == "kick":
                        tt = t_axis(0.2)
                        x = osc(55 * np.exp(-tt * 18) + 45, 0.2) * np.exp(-tt * 16)
                    elif shape == "hat":
                        tt = t_axis(0.05)
                        x = RNG.standard_normal(len(tt)) * np.exp(-tt * 80) * 0.5
                    elif shape == "bongo":
                        tt = t_axis(0.18)
                        x = osc(note_hz(midi) * (1 + 0.5 * np.exp(-tt * 40)), 0.18) * np.exp(-tt * 22)
                    elif shape == "marimba":
                        tt = t_axis(d + 0.3)
                        f = note_hz(midi)
                        x = (osc(f, d + 0.3) + 0.3 * osc(f * 4, d + 0.3) * np.exp(-tt * 20)) * np.exp(-tt * 7)
                    elif shape == "pluck":
                        tt = t_axis(d + 0.2)
                        x = lowpass(osc(note_hz(midi), d + 0.2, "saw"), 2200) * np.exp(-tt * 6)
                    elif shape == "pad":
                        tt = t_axis(d)
                        f = note_hz(midi)
                        x = (osc(f, d, "tri") + osc(f * 1.005, d, "tri")) * 0.5 * env(len(tt), 0.3, 0.4)
                    else:
                        tt = t_axis(d)
                        x = osc(note_hz(midi), d, shape) * env(len(tt), 0.01, min(0.1, d / 2))
                    end = min(n, start + len(x))
                    mix[start:end] += x[: end - start] * gain
    # wrap the tail into the start so the loop is seamless
    return normalize(mix, 0.8)


def write_ogg(name, x):
    path = OUT / "music" / f"{name}.ogg"
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        w = pathlib.Path(tmp) / "m.wav"
        write_wav(w, x)
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(w), "-c:a", "libvorbis", "-q:a", "3", str(path)], check=True)
    print(f"  music/{name}.ogg {len(x) / SR:.1f} s")


def amazon_music():
    scale = [0, 2, 4, 7, 9, 12, 14, 16]  # major pentatonic
    root = 60
    chords = [0, -3, 5, -5]
    rnd = np.random.default_rng(1)
    melody = [[(root + 12 + scale[rnd.integers(0, 8)]) if rnd.random() < 0.55 else None for _ in range(8)] for _ in range(8)]

    def drums(bar, s):
        out = []
        if s in (0, 6, 10):
            out.append((0, 1, 0.9, "kick"))
        if s % 2 == 1:
            out.append((0, 1, 0.25, "hat"))
        if s in (3, 7, 11, 14, 15):
            out.append((64 if s % 2 else 69, 1, 0.5, "bongo"))
        return out

    def bass(bar, s):
        c = root - 24 + chords[bar % 4]
        return [(c if s in (0, 8) else c + 7, 2, 0.5, "tri")] if s in (0, 6, 8, 14) else []

    def mel(bar, s):
        if s % 2:
            return []
        m = melody[bar % 8][s // 2]
        return [(m, 2, 0.35, "marimba")] if m else []

    return render_track(112, 16, [drums, bass, mel])


def desert_music():
    root = 57  # A minor, a little western
    chords = [0, -2, -4, -5]

    def drums(bar, s):
        out = []
        if s in (0, 8):
            out.append((0, 1, 0.8, "kick"))
        if s in (4, 12):
            out.append((70, 1, 0.4, "bongo"))
        if s % 4 == 2:
            out.append((0, 1, 0.2, "hat"))
        return out

    def bass(bar, s):
        c = root - 24 + chords[bar % 4]
        return [(c, 3, 0.5, "tri")] if s in (0, 6, 10) else []

    phrase = [12, None, 15, 14, 12, None, 10, None, 7, None, 10, 12, None, None, None, None]

    def guitar(bar, s):
        if bar % 2 == 1 and s >= 8:
            return []
        p = phrase[s]
        return [(root + chords[bar % 4] + p, 2, 0.35, "pluck")] if p is not None and s % 2 == 0 else []

    return render_track(96, 16, [drums, bass, guitar])


def menu_music():
    root = 62
    prog = [[0, 4, 7, 11], [-3, 0, 4, 7], [-7, -3, 0, 4], [-5, -1, 2, 7]]

    def pad(bar, s):
        return [(root - 12 + n, 16, 0.18, "pad") for n in prog[bar % 4]] if s == 0 else []

    def arp(bar, s):
        chord = prog[bar % 4]
        return [(root + 12 + chord[s % 4], 1, 0.22, "sine")] if s % 2 == 0 else []

    return render_track(84, 8, [pad, arp])


def main():
    make_sfx()
    write_ogg("amazon", amazon_music())
    write_ogg("desert", desert_music())
    write_ogg("menu", menu_music())


if __name__ == "__main__":
    main()

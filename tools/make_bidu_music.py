#!/usr/bin/env python3
"""Turn the 2014 BIDU songs into the game's music loops and the website's listening copies.

    python3 tools/make_bidu_music.py

Reads legacy/2014-bidu-concept/BIDU songs/NN.aup (never changed) and writes:
- game/audio/music/bidu_NN.ogg: each song cut to loop seamlessly, and its loop start in game/data/music.json;
- public/audio/bidu/bidu-NN.mp3: each song as it was mixed, start to finish, for the history page.

How a loop is made, so it repeats without a bump:
1. Silence before the first note and after the last is trimmed.
2. The tempo is found from how the loudness changes (onsets, in six frequency bands) repeat.
3. Two points on the beat grid are picked: where the loop jumps from (in the last 40% of the song) and
   where it goes back to (in the first 40%), a whole number of bars apart, where the 2 bars after each
   sound most alike, beat by beat (pitch classes and loudness per band; the longest loop among the close
   matches). So the intro plays once and the rest repeats, in time with the beat.
4. The jump point is fine-tuned to the sample by comparing the waveforms within +-15 ms, the song is cut
   there, and its last 0.25 s is cross-faded (equal power) into the 0.25 s before the loop start.
5. The loop start goes into game/data/music.json ("loop_start", seconds); Audio.music() sets it on the
   stream, so playback jumps from the end of the file back to that point.
Needs numpy and ffmpeg (libvorbis, libmp3lame).
"""
import json
import pathlib
import subprocess
import sys
import tempfile

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from render_aup import render, write_wav  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
SONGS = ROOT / "legacy/2014-bidu-concept/BIDU songs"
GAME = ROOT / "game/audio/music"
SITE = ROOT / "public/audio/bidu"
MUSIC_JSON = ROOT / "game/data/music.json"
HOP = 256
FADE_S = 0.25


def trim(x: np.ndarray, rate: int, threshold=0.01) -> np.ndarray:
    m = np.abs(x).max(axis=1)
    loud = np.where(m > threshold)[0]
    start = max(0, loud[0] - int(0.01 * rate))
    end = min(len(x), loud[-1] + int(0.05 * rate))
    return x[start:end]


BANDS = [0, 150, 400, 1000, 2500, 6000, 22050]


def onsets(x: np.ndarray) -> np.ndarray:
    """Loudness rises per frequency band, one row per frame: rhythm and sound together."""
    mono = x.mean(axis=1)
    frames = len(mono) // HOP - 3
    win = np.hanning(HOP * 4)
    spec = np.abs(np.stack([np.fft.rfft(mono[i * HOP:i * HOP + HOP * 4] * win) for i in range(frames)]))
    freqs = np.fft.rfftfreq(HOP * 4, 1 / 44100)
    bands = np.stack([spec[:, (freqs >= a) & (freqs < b)].sum(axis=1) for a, b in zip(BANDS, BANDS[1:])], axis=1)
    log = np.log(bands + 1e-3)
    return np.maximum(0, np.diff(log, axis=0, prepend=log[:1]))


def beat_period(env: np.ndarray, fps: float) -> float:
    """Seconds per beat: the lag where the onsets repeat best, checked over 1 to 32 beats."""
    e = env.sum(axis=1)
    e = e - e.mean()
    ac = np.correlate(e, e, "full")[len(e) - 1:]
    ac = ac / ac[0]
    idx = np.arange(len(ac))

    def comb(bpm: float, beats) -> float:
        lag = fps * 60 / bpm
        return sum(float(np.interp(lag * k, idx, ac)) for k in beats if lag * k < len(ac) - 1)

    coarse = max(np.arange(70, 220, 0.1), key=lambda b: comb(b, (1, 2, 4, 8)))
    fine = max(np.arange(coarse - 2, coarse + 2, 0.01), key=lambda b: comb(b, range(1, 33)))
    return 60 / fine


def beat_features(x: np.ndarray, rate: int, period_s: float) -> tuple[np.ndarray, np.ndarray]:
    """The beat grid (sample positions) and, per beat, what it sounds like: 12 pitch classes and the
    loudness in six bands, normalized. The grid's phase is where the onsets line up best."""
    env = onsets(x).sum(axis=1)
    fps = rate / HOP
    p = period_s * fps
    phase = max(np.arange(0, p, 0.5), key=lambda ph: env[np.round(np.arange(ph, len(env) - 1, p)).astype(int)].sum())
    beats = (np.arange(phase, len(env) - 1, p) * HOP).astype(int)
    mono = x.mean(axis=1)
    feats = []
    for i in range(len(beats) - 1):
        seg = mono[beats[i]:beats[i + 1]]
        n = 1 << int(np.ceil(np.log2(max(len(seg), 2))))
        spec = np.abs(np.fft.rfft(seg * np.hanning(len(seg)), n))
        freqs = np.fft.rfftfreq(n, 1 / rate)
        keep = (freqs > 60) & (freqs < 5000)
        pitch = np.round(12 * np.log2(freqs[keep] / 440.0)).astype(int) % 12
        chroma = np.bincount(pitch, weights=spec[keep], minlength=12)
        bands = np.array([spec[(freqs >= a) & (freqs < b)].sum() for a, b in zip(BANDS, BANDS[1:])])
        f = np.concatenate([chroma / (chroma.sum() + 1e-9), np.log(bands + 1e-3) / 10])
        feats.append(f)
    feats = np.array(feats)
    feats = feats - feats.mean(axis=0)
    feats /= np.linalg.norm(feats, axis=1, keepdims=True) + 1e-9
    return beats, feats


def find_loop(x: np.ndarray, rate: int) -> tuple[int, int, float]:
    """Where the loop goes back to (a) and where it jumps from (b), in samples.

    Both are on the beat grid and a whole number of bars (4 beats) apart; a is in the first 40% of the song
    and b in the last 40%, with 2 bars of music after b. The 2 bars after b must sound like the 2 bars after
    a (pitch and loudness, beat by beat). Of the pairs that match at least 97% as well as the best pair,
    the one with the longest loop wins. Then b is fine-tuned to the sample against a."""
    env = onsets(x)
    period = beat_period(env, rate / HOP)
    beats, feats = beat_features(x, rate, period)
    span = 8  # beats compared after each point
    nb = len(feats)
    candidates = []
    for a in range(0, int(nb * 0.4)):
        for b in range(a + 4, nb - span, 4):
            if b < nb * 0.6:
                continue
            sim = float(np.mean(np.sum(feats[a:a + span] * feats[b:b + span], axis=1)))
            candidates.append((sim, a, b))
    top = max(c[0] for c in candidates)
    good = [c for c in candidates if c[0] >= top - 0.03 * abs(top)]
    score, a, b = max(good, key=lambda c: (c[2] - c[1], c[2]))
    a, b = int(beats[a]), int(beats[b])
    mono = x.mean(axis=1)
    n = int(0.05 * rate)
    ref = mono[a:a + n]
    radius = int(0.015 * rate)
    lo, hi = max(a + n, b - radius), min(len(mono) - n, b + radius)
    b = lo + int(np.argmax([float(ref @ mono[c:c + n]) for c in range(lo, hi)]))
    return a, b, score


def make_loop(x: np.ndarray, rate: int) -> tuple[np.ndarray, float, float]:
    """The song up to the jump point b, with its last 0.25 s cross-faded into the 0.25 s before the loop
    start a, so jumping from the end back to a is seamless. Returns (samples, loop start in s, match)."""
    x = trim(x, rate)
    a, b, score = find_loop(x, rate)
    c = min(int(FADE_S * rate), a) if a > 0 else 0
    out = x[:b].copy()
    if c > 0:
        t = np.linspace(0, np.pi / 2, c)[:, None]
        out[b - c:b] = x[b - c:b] * np.cos(t) + x[a - c:a] * np.sin(t)
    else:
        # the loop goes back to the very start: fade the song's start in over the jump instead
        c = int(FADE_S * rate)
        t = np.linspace(0, np.pi / 2, c)[:, None]
        out[:c] = x[:c] * np.sin(t) + x[b:b + c] * np.cos(t)
    return out, a / rate, score


def seam_check(song: np.ndarray, loop_start: float, rate: int) -> float:
    """How much the sound changes at the jump (end of the file into the loop start), next to how much it
    changes at the same spot when the song plays straight through (the beat at the loop start is there either
    way). About 1 means the jump sounds like the song carrying on; well above 1 would be a bump."""
    a = int(loop_start * rate)
    w = 2048

    def flux(sig: np.ndarray) -> float:
        frames = (len(sig) - 1024) // 256
        spec = np.abs(np.stack([np.fft.rfft(sig[i * 256:i * 256 + 1024] * np.hanning(1024)) for i in range(frames)]))
        return float(np.sqrt((np.diff(np.log(spec + 1e-4), axis=0).clip(0) ** 2).sum(axis=1)).max())

    jumped = np.concatenate([song[-w:], song[a:a + w]]).mean(axis=1)
    straight = song[a - w:a + w].mean(axis=1)
    return flux(jumped) / flux(straight)


def encode(wav_samples: np.ndarray, rate: int, out: pathlib.Path, args: list[str]) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        w = pathlib.Path(tmp) / "a.wav"
        write_wav(w, wav_samples, rate)
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(w), *args, str(out)], check=True)


def main() -> None:
    loops = {}
    for aup in sorted(SONGS.glob("*.aup")):
        n = aup.stem
        mix, rate = render(aup)
        song, loop_start, score = make_loop(mix, rate)
        encode(song, rate, GAME / f"bidu_{n}.ogg", ["-c:a", "libvorbis", "-q:a", "4"])
        encode(trim(mix, rate), rate, SITE / f"bidu-{n}.mp3", ["-c:a", "libmp3lame", "-b:a", "128k"])
        loops[f"bidu_{n}"] = round(loop_start, 4)
        print(f"  {n}: song {len(mix) / rate:.1f} s, plays {len(song) / rate:.1f} s, loops back to {loop_start:.2f} s,"
              f" match {score:.2f}, change at the jump {seam_check(song, loop_start, rate):.2f}x the straight play")
    data = json.loads(MUSIC_JSON.read_text(encoding="utf-8"))
    data["loop_start"] = loops
    MUSIC_JSON.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"  loop starts written to {MUSIC_JSON.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

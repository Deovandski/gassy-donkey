#!/usr/bin/env python3
"""Render an Audacity 2.0 project (.aup + _data/ block files) to a WAV file.

Usage: python3 render_aup.py project.aup out.wav
Reads every wavetrack, places each waveclip at its offset, applies track
gain, pan and mute, and mixes to stereo 44.1 kHz float, written as 16-bit WAV.
"""
import struct, sys, pathlib, wave, xml.etree.ElementTree as ET
import numpy as np

NS = "{http://audacity.sourceforge.net/xml/}"

def read_au(path):
    b = path.read_bytes()
    if b[:4] == b".snd": e = ">"
    elif b[:4] == b"dns.": e = "<"
    else: raise ValueError(f"not an .au file: {path}")
    off, size, enc, rate, ch = struct.unpack(e + "5I", b[4:24])
    if enc != 6: raise ValueError(f"{path}: encoding {enc}, expected 32-bit float")
    return np.frombuffer(b[off:], dtype=e + "f4").astype(np.float32)

def main(aup, out):
    aup = pathlib.Path(aup)
    root = ET.parse(aup).getroot()
    data_dir = aup.parent / root.get("projname")
    files = {p.name: p for p in data_dir.rglob("*.au")}
    rate = int(float(root.get("rate")))
    tracks = []
    for t in root.iter(NS + "wavetrack"):
        if t.get("mute") == "1": continue
        clips = []
        for c in t.iter(NS + "waveclip"):
            seq = c.find(NS + "sequence")
            buf = np.zeros(int(seq.get("numsamples")), np.float32)
            for wb in seq.iter(NS + "waveblock"):
                start = int(wb.get("start"))
                for bf in wb:
                    tag = bf.tag.replace(NS, "")
                    n = int(bf.get("len"))
                    if tag == "simpleblockfile":
                        s = read_au(files[bf.get("filename")])[:n]
                        buf[start:start + len(s)] = s
                    elif tag == "silentblockfile":
                        pass
                    else:
                        raise ValueError(f"unsupported block file {tag}")
            clips.append((float(c.get("offset")), buf))
        tracks.append((int(t.get("channel")), float(t.get("gain")), float(t.get("pan")), t.get("linked") == "1", clips))
    start = min(o for *_, cl in tracks for o, _ in cl)
    end = max(o + len(b) / rate for *_, cl in tracks for o, b in cl)
    start = max(start, 0.0)  # Audacity plays from 0; audio before 0 is cut
    n = int(round((end - start) * rate))
    mix = np.zeros((n, 2), np.float32)
    i = 0
    while i < len(tracks):
        ch, gain, pan, linked, clips = tracks[i]
        group = [tracks[i]]
        if linked and i + 1 < len(tracks):
            group.append(tracks[i + 1]); i += 1
        i += 1
        for idx, (ch, gain, pan, linked, clips) in enumerate(group):
            lg = gain * (1 - pan if pan > 0 else 1); rg = gain * (1 + pan if pan < 0 else 1)
            for off, b in clips:
                s0 = int(round((off - start) * rate)); cut = max(0, -s0); s0 = max(0, s0)
                seg = b[cut:cut + max(0, n - s0)]
                if len(group) == 2:
                    mix[s0:s0 + len(seg), idx] += seg * (lg if idx == 0 else rg)
                else:
                    mix[s0:s0 + len(seg), 0] += seg * lg; mix[s0:s0 + len(seg), 1] += seg * rg
    pcm = (np.clip(mix, -1, 1) * 32767).astype("<i2")
    with wave.open(str(out), "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(rate); w.writeframes(pcm.tobytes())
    print(f"{aup.name}: {n / rate:.2f} s, peak {np.abs(mix).max():.2f} -> {out}")

if __name__ == "__main__":
    if len(sys.argv) != 3: sys.exit(__doc__)
    main(*sys.argv[1:])

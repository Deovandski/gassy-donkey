#!/usr/bin/env python3
"""Draw the finished game's placeholder art (everything the 2016 originals don't have).

    python3 tools/make_art.py

Writes game/art/new/ (committed). Every picture is drawn here in code with pycairo, in the style of the
2016 donkey: flat colours, a dark outline, soft shading. They are placeholders: an illustrator can replace
any file with a hand-drawn one of the same name and size (docs/ART.md lists them) and the game picks it up.
Needs pycairo and Pillow. The drawing is seeded, so running it again gives the same files.
"""
import math
import pathlib
import random

import cairo

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "game/art/new"
INK = (0.13, 0.08, 0.04)  # outline colour, close to the donkey's


def hexc(h: str, a: float = 1.0):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)) + (a,)


class Pic:
    """A transparent canvas; `save()` writes it to game/art/new/<name>.png."""

    def __init__(self, name: str, w: int, h: int):
        self.name, self.w, self.h = name, w, h
        self.surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
        self.c = cairo.Context(self.surface)
        self.c.set_line_join(cairo.LINE_JOIN_ROUND)
        self.c.set_line_cap(cairo.LINE_CAP_ROUND)

    def save(self):
        path = OUT / f"{self.name}.png"
        path.parent.mkdir(parents=True, exist_ok=True)
        self.surface.write_to_png(str(path))
        print(f"  {self.name}.png {self.w}x{self.h}")

    # --- drawing helpers ---
    def fill_stroke(self, fill, width=4.0, ink=INK):
        c = self.c
        c.set_source_rgba(*fill)
        c.fill_preserve()
        c.set_source_rgba(*ink) if len(ink) == 4 else c.set_source_rgb(*ink)
        c.set_line_width(width)
        c.stroke()

    def fill(self, color):
        self.c.set_source_rgba(*color)
        self.c.fill()

    def stroke(self, color=INK, width=4.0):
        self.c.set_source_rgba(*color) if len(color) == 4 else self.c.set_source_rgb(*color)
        self.c.set_line_width(width)
        self.c.stroke()

    def ellipse(self, cx, cy, rx, ry, angle=0.0):
        c = self.c
        c.save()
        c.translate(cx, cy)
        c.rotate(angle)
        c.scale(rx, ry)
        c.new_sub_path()
        c.arc(0, 0, 1, 0, 2 * math.pi)
        c.restore()

    def rrect(self, x, y, w, h, r):
        c = self.c
        c.new_sub_path()
        c.arc(x + w - r, y + r, r, -math.pi / 2, 0)
        c.arc(x + w - r, y + h - r, r, 0, math.pi / 2)
        c.arc(x + r, y + h - r, r, math.pi / 2, math.pi)
        c.arc(x + r, y + r, r, math.pi, 3 * math.pi / 2)
        c.close_path()

    def poly(self, pts, close=True):
        c = self.c
        c.move_to(*pts[0])
        for p in pts[1:]:
            c.line_to(*p)
        if close:
            c.close_path()

    def smooth(self, pts, close=True):
        """A closed (or open) curve through the points (Catmull-Rom turned into Béziers)."""
        c = self.c
        n = len(pts)
        c.move_to(*pts[0])
        rng = range(n) if close else range(n - 1)
        for i in rng:
            p0 = pts[(i - 1) % n] if close or i > 0 else pts[i]
            p1, p2 = pts[i], pts[(i + 1) % n]
            p3 = pts[(i + 2) % n] if close or i + 2 < n else p2
            c.curve_to(p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6,
                       p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6, p2[0], p2[1])
        if close:
            c.close_path()

    def shade(self, x0, y0, x1, y1, top=(1, 1, 1, 0.25), bottom=(0, 0, 0, 0.2)):
        """Fill the current path with a light-to-dark wash (call after a fill, with the path rebuilt)."""
        g = cairo.LinearGradient(x0, y0, x1, y1)
        g.add_color_stop_rgba(0, *top)
        g.add_color_stop_rgba(1, *bottom)
        self.c.set_source(g)
        self.c.fill()

    def eye(self, x, y, r=6.0, look=(1.5, 0)):
        self.ellipse(x, y, r, r)
        self.fill_stroke((1, 1, 1, 1), 2)
        self.ellipse(x + look[0], y + look[1], r * 0.5, r * 0.55)
        self.fill((0.05, 0.03, 0.02, 1))


# ---------------------------------------------------------------------------------------------- pickups and HUD

def corn():
    p = Pic("corn", 48, 76)
    c = p.c
    p.smooth([(24, 4), (36, 18), (37, 46), (24, 64), (11, 46), (12, 18)])
    p.fill_stroke(hexc("#f7d23e"), 3)
    for row in range(8):
        for col in range(3):
            x = 17 + col * 7 + (row % 2) * 2
            y = 14 + row * 6
            p.ellipse(x, y, 2.8, 2.4)
            p.fill(hexc("#e8a917", 0.9))
    for side in (-1, 1):
        p.smooth([(24, 72), (24 + side * 20, 52), (24 + side * 16, 26), (24 + side * 6, 52)])
        p.fill_stroke(hexc("#5aa832"), 3)
    p.poly([(24, 74), (24, 60)], close=False)
    p.stroke(hexc("#3d7a20"), 3)
    p.save()


def beans():
    p = Pic("beans", 64, 48)
    for i, (x, y, a) in enumerate([(20, 30, -0.4), (42, 30, 0.3), (31, 17, 0.0)]):
        p.c.save()
        p.c.translate(x, y)
        p.c.rotate(a)
        p.smooth([(-14, -2), (-6, -10), (8, -9), (14, 0), (6, 9), (0, 4), (-8, 9)])
        p.fill_stroke(hexc(["#8e2f1f", "#a33c22", "#7c2818"][i]), 3)
        p.ellipse(-3, -4, 5, 2)
        p.fill((1, 1, 1, 0.35))
        p.c.restore()
    p.save()


def heart(name, full):
    p = Pic(name, 44, 40)
    c = p.c
    c.move_to(22, 36)
    c.curve_to(2, 22, 2, 4, 13, 4)
    c.curve_to(18, 4, 21, 8, 22, 11)
    c.curve_to(23, 8, 26, 4, 31, 4)
    c.curve_to(42, 4, 42, 22, 22, 36)
    c.close_path()
    if full:
        p.fill_stroke(hexc("#e8402c"), 3)
        p.ellipse(13, 13, 5, 3, -0.6)
        p.fill((1, 1, 1, 0.5))
    else:
        p.fill_stroke(hexc("#3a2a2a", 0.55), 3)
    p.save()


def puff(name, seed, color="#9fd36a"):
    rnd = random.Random(seed)
    p = Pic(name, 112, 92)
    for _ in range(7):
        x, y, r = rnd.uniform(30, 82), rnd.uniform(30, 62), rnd.uniform(16, 28)
        p.ellipse(x, y, r, r * 0.85)
        p.fill_stroke(hexc(color, 0.8), 3, (0.3, 0.45, 0.15, 0.7))
    for _ in range(5):
        x, y, r = rnd.uniform(30, 82), rnd.uniform(30, 62), rnd.uniform(6, 12)
        p.ellipse(x, y - 6, r, r * 0.8)
        p.fill((1, 1, 1, 0.3))
    p.save()


def gas_icon():
    p = Pic("gas_icon", 52, 44)
    for x, y, r in [(16, 26, 12), (28, 18, 14), (38, 27, 11), (26, 30, 12)]:
        p.ellipse(x, y, r, r * 0.9)
        p.fill_stroke(hexc("#9fd36a"), 3, (0.25, 0.4, 0.1, 1))
    p.save()


def sparkle():
    p = Pic("sparkle", 40, 40)
    pts = []
    for i in range(8):
        r = 18 if i % 2 == 0 else 6
        a = i * math.pi / 4 - math.pi / 2
        pts.append((20 + r * math.cos(a), 20 + r * math.sin(a)))
    p.poly(pts)
    p.fill_stroke(hexc("#fff3a6"), 2, hexc("#e8a917"))
    p.save()


def icons():
    # Touch buttons: jump (up), drop (down), fart (puff), headbutt (impact), pause.
    def arrow(name, up):
        p = Pic(name, 96, 96)
        s = 1 if up else -1
        p.c.translate(48, 48)
        p.poly([(0, -30 * s), (28, 2 * s), (12, 2 * s), (12, 30 * s), (-12, 30 * s), (-12, 2 * s), (-28, 2 * s)])
        p.fill_stroke((1, 1, 1, 0.95), 5)
        p.save()
    arrow("icon_jump", True)
    arrow("icon_drop", False)

    p = Pic("icon_fart", 96, 96)
    for x, y, r in [(34, 54, 18), (52, 40, 20), (64, 58, 16), (48, 62, 16)]:
        p.ellipse(x, y, r, r * 0.9)
        p.fill_stroke(hexc("#b6e38a"), 4)
    for i in range(3):
        p.poly([(18 - i * 4, 40 + i * 12), (6 - i * 4, 38 + i * 12)], close=False)
        p.stroke(INK, 4)
    p.save()

    p = Pic("icon_headbutt", 96, 96)
    pts = []
    for i in range(16):
        r = 38 if i % 2 == 0 else 20
        a = i * math.pi / 8
        pts.append((48 + r * math.cos(a), 48 + r * math.sin(a)))
    p.poly(pts)
    p.fill_stroke(hexc("#ffcf4a"), 4)
    p.c.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    p.c.set_font_size(30)
    p.c.move_to(25, 59)
    p.c.text_path("BAM")
    p.fill_stroke((1, 1, 1, 1), 2)
    p.save()

    p = Pic("icon_pause", 64, 64)
    for x in (18, 36):
        p.rrect(x, 14, 11, 36, 3)
        p.fill_stroke((1, 1, 1, 0.95), 4)
    p.save()

    p = Pic("lock", 64, 72)
    p.c.arc(32, 30, 16, math.pi, 0)
    p.stroke(INK, 12)
    p.c.arc(32, 30, 16, math.pi, 0)
    p.stroke(hexc("#c9c9c9"), 6)
    p.rrect(10, 30, 44, 36, 6)
    p.fill_stroke(hexc("#f0b429"), 4)
    p.ellipse(32, 46, 5, 5)
    p.fill(INK + (1,))
    p.save()

    p = Pic("medal", 72, 88)
    p.poly([(22, 0), (36, 34), (50, 0)])
    p.fill_stroke(hexc("#2f80c9"), 3)
    p.ellipse(36, 56, 28, 28)
    p.fill_stroke(hexc("#f5c542"), 4)
    p.ellipse(36, 56, 19, 19)
    p.stroke(hexc("#d99a1c"), 3)
    p.save()


# ---------------------------------------------------------------------------------------------- enemies and obstacles

def snake(name, body, belly, pattern, frame):
    p = Pic(name, 140, 64)
    wave = 7 if frame == 0 else -7
    top, bot = [], []
    for i in range(15):
        x = 8 + i * 8
        y = 44 + math.sin(i * 0.8) * wave * (i / 14)
        t = 5 + 6 * math.sin(math.pi * min(i, 13) / 13)
        top.append((x, y - t))
        bot.append((x, y + t))
    p.smooth(top + [(126, 30), (136, 36), (128, 46)] + bot[::-1], close=True)
    p.fill_stroke(hexc(body), 4)
    for i in range(2, 13, 2):
        x, y = 8 + i * 8, 44 + math.sin(i * 0.8) * wave * (i / 14)
        if pattern == "diamond":
            p.poly([(x, y - 6), (x + 5, y), (x, y + 6), (x - 5, y)])
        else:
            p.ellipse(x, y, 3.5, 5)
        p.fill(hexc(belly, 0.9))
    p.eye(126, 34, 4.5)
    p.poly([(136, 38), (140, 40), (137, 42)], close=False)
    p.stroke(hexc("#d42b2b"), 2)
    p.save()


def rock(name, w, h, seed):
    rnd = random.Random(seed)
    p = Pic(name, w, h)
    pts = []
    for i in range(10):
        a = math.pi + i * math.pi / 9
        rx, ry = w * 0.46 * rnd.uniform(0.85, 1.0), h * 0.9 * rnd.uniform(0.85, 1.0)
        pts.append((w / 2 + rx * math.cos(a), h - 4 + ry * math.sin(a)))
    p.smooth(pts)
    p.fill_stroke(hexc("#8d8a86"), 4)
    p.smooth(pts)
    p.shade(0, 0, 0, h)
    for _ in range(3):
        x, y = rnd.uniform(w * 0.25, w * 0.75), rnd.uniform(h * 0.4, h * 0.8)
        p.poly([(x, y), (x + rnd.uniform(6, 14), y + rnd.uniform(-6, 6))], close=False)
        p.stroke((0.25, 0.22, 0.2, 0.8), 3)
    p.save()


def cactus(name, w, h, arms):
    p = Pic(name, w, h)
    green, dark = hexc("#4f9a3c"), hexc("#3a7a2b")
    cx = w / 2
    trunk_w = w * 0.34

    def column(x, y0, y1, cw):
        p.rrect(x - cw / 2, y0, cw, y1 - y0, cw / 2)
        p.fill_stroke(green, 4)
        for k in (-0.22, 0.22):
            p.poly([(x + cw * k, y0 + cw / 2), (x + cw * k, y1 - 4)], close=False)
            p.stroke(dark, 2)
    if arms:
        aw = trunk_w * 0.75
        p.c.move_to(cx - trunk_w / 2, h * 0.55)
        column(cx - w * 0.32, h * 0.25, h * 0.6, aw)
        p.rrect(cx - w * 0.32, h * 0.52, w * 0.32, aw, aw / 2)
        p.fill_stroke(green, 4)
        column(cx + w * 0.32, h * 0.35, h * 0.68, aw)
        p.rrect(cx, h * 0.6, w * 0.32, aw, aw / 2)
        p.fill_stroke(green, 4)
    column(cx, 4, h - 2, trunk_w)
    rnd = random.Random(len(name))
    for _ in range(14):
        x, y = rnd.uniform(cx - trunk_w / 2, cx + trunk_w / 2), rnd.uniform(10, h - 10)
        p.poly([(x, y), (x + rnd.choice([-5, 5]), y - 3)], close=False)
        p.stroke(hexc("#f4f0d0"), 1.5)
    p.save()


def hive():
    p = Pic("hive", 76, 110)
    p.poly([(38, 0), (38, 22)], close=False)
    p.stroke(hexc("#5a3b1c"), 3)
    pts = [(38, 20), (58, 34), (66, 62), (56, 92), (38, 104), (20, 92), (10, 62), (18, 34)]
    p.smooth(pts)
    p.fill_stroke(hexc("#f0b429"), 4)
    for y in (40, 56, 72, 88):
        p.c.move_to(14, y)
        p.c.curve_to(30, y + 6, 46, y + 6, 62, y)
        p.stroke(hexc("#b77d12"), 3)
    p.ellipse(38, 80, 8, 6)
    p.fill(INK + (1,))
    p.save()


def bee():
    p = Pic("bee", 30, 26)
    p.ellipse(11, 7, 7, 5, -0.5)
    p.fill_stroke((1, 1, 1, 0.7), 1.5)
    p.ellipse(15, 15, 10, 7)
    p.fill_stroke(hexc("#f7d23e"), 2)
    for x in (12, 17):
        p.poly([(x, 9), (x, 21)], close=False)
        p.stroke(INK, 2.5)
    p.save()


def mosquito(frame):
    p = Pic(f"mosquito_{frame + 1}", 72, 60)
    wing = -0.9 if frame == 0 else -0.3
    for dx in (0, 8):
        p.ellipse(34 + dx, 18, 14, 6, wing)
        p.fill_stroke((0.85, 0.95, 1, 0.65), 1.5, (0.3, 0.4, 0.5, 0.8))
    for x0 in (28, 34, 40):
        p.poly([(x0, 34), (x0 - 6, 48), (x0 - 10, 56)], close=False)
        p.stroke(INK, 2)
    p.ellipse(40, 32, 16, 6, 0.15)
    p.fill_stroke(hexc("#6b5a4a"), 2.5)
    p.ellipse(22, 30, 7, 7)
    p.fill_stroke(hexc("#5a4a3c"), 2.5)
    p.poly([(16, 31), (2, 36)], close=False)
    p.stroke(INK, 2)
    p.ellipse(20, 28, 2.5, 2.5)
    p.fill(hexc("#e83a2c"))
    p.save()


def tiger(frame):
    p = Pic(f"tiger_{frame + 1}", 230, 120)
    orange, dark = hexc("#f08a24"), INK + (1,)
    legs = [(60, 18), (84, -14), (150, 14), (172, -18)] if frame == 0 else [(60, -14), (84, 16), (150, -16), (172, 12)]
    for x, swing in legs:
        p.poly([(x, 70), (x + swing, 112)], close=False)
        p.stroke(INK, 20)
        p.poly([(x, 70), (x + swing, 110)], close=False)
        p.stroke(orange, 13)
    p.c.move_to(40, 54)
    p.c.curve_to(10, 40, 6, 20, 18, 14)
    p.stroke(INK, 11)
    p.c.move_to(40, 54)
    p.c.curve_to(10, 40, 6, 20, 18, 14)
    p.stroke(orange, 6)
    p.smooth([(40, 46), (100, 34), (170, 38), (194, 58), (176, 82), (100, 84), (44, 78)])
    p.fill_stroke(orange, 4)
    p.smooth([(70, 74), (130, 80), (176, 76), (130, 86)])
    p.fill(hexc("#fff1d6"))
    for x in range(64, 176, 18):
        p.c.move_to(x, 38)
        p.c.curve_to(x + 6, 50, x - 2, 60, x + 4, 70)
        p.stroke(dark, 5)
    p.ellipse(200, 48, 24, 22)
    p.fill_stroke(orange, 4)
    for ex in (188, 206):
        p.poly([(ex - 6, 32), (ex, 22), (ex + 6, 32)])
        p.fill_stroke(orange, 3)
    p.ellipse(212, 58, 11, 8)
    p.fill_stroke(hexc("#fff1d6"), 2)
    p.ellipse(220, 54, 3, 2.5)
    p.fill(dark)
    p.eye(206, 42, 5, (2, 0))
    p.poly([(196, 30), (190, 40)], close=False)
    p.stroke(dark, 3)
    p.save()


def bear():
    p = Pic("bear", 180, 190)
    brown, light = hexc("#7a4a24"), hexc("#b07a48")
    for x in (64, 116):
        p.rrect(x - 18, 140, 36, 48, 14)
        p.fill_stroke(brown, 4)
    p.smooth([(50, 70), (90, 56), (130, 70), (142, 120), (128, 160), (90, 168), (52, 160), (38, 120)])
    p.fill_stroke(brown, 4)
    p.ellipse(90, 122, 30, 36)
    p.fill(light)
    for side in (-1, 1):
        p.c.move_to(90 + side * 36, 84)
        p.c.curve_to(90 + side * 66, 70, 90 + side * 74, 40, 90 + side * 70, 22)
        p.stroke(INK, 24)
        p.c.move_to(90 + side * 36, 84)
        p.c.curve_to(90 + side * 66, 70, 90 + side * 74, 40, 90 + side * 70, 22)
        p.stroke(brown, 17)
        for k in (-6, 0, 6):
            p.poly([(90 + side * 70 + k, 16), (90 + side * 70 + k, 6)], close=False)
            p.stroke(hexc("#f4f0d0"), 3)
    for ex in (64, 116):
        p.ellipse(ex, 34, 13, 13)
        p.fill_stroke(brown, 4)
        p.ellipse(ex, 34, 6, 6)
        p.fill(light)
    p.ellipse(90, 52, 34, 30)
    p.fill_stroke(brown, 4)
    p.ellipse(90, 64, 15, 11)
    p.fill_stroke(light, 2)
    p.ellipse(90, 59, 6, 4)
    p.fill(INK + (1,))
    p.eye(77, 46, 5, (0, 1))
    p.eye(103, 46, 5, (0, 1))
    p.poly([(68, 36), (84, 42)], close=False)
    p.stroke(INK, 3)
    p.poly([(112, 36), (96, 42)], close=False)
    p.stroke(INK, 3)
    p.save()


def cowboy(frame):
    p = Pic(f"cowboy_{frame + 1}", 110, 170)
    skin, shirt, jeans = hexc("#e9b98a"), hexc("#c0392b"), hexc("#2f5d8a")
    for x in (38, 62):
        p.rrect(x - 9, 112, 18, 52, 6)
        p.fill_stroke(jeans, 3)
        p.rrect(x - 12, 156, 24, 12, 4)
        p.fill_stroke(hexc("#5a3b1c"), 3)
    p.rrect(28, 64, 44, 54, 10)
    p.fill_stroke(shirt, 4)
    p.poly([(28, 108), (72, 108)], close=False)
    p.stroke(hexc("#5a3b1c"), 6)
    p.ellipse(50, 108, 6, 5)
    p.fill(hexc("#f0c040"))
    p.rrect(56, 72, 14, 40, 6)
    p.fill_stroke(shirt, 3)
    # gun arm points left (towards the donkey)
    p.poly([(36, 78), (10, 86)], close=False)
    p.stroke(INK, 15)
    p.poly([(36, 78), (10, 86)], close=False)
    p.stroke(shirt, 9)
    p.rrect(-2, 80, 16, 8, 2)
    p.fill_stroke(hexc("#555555"), 2)
    if frame == 1:
        pts = []
        for i in range(10):
            r = 10 if i % 2 == 0 else 4
            a = i * math.pi / 5
            pts.append((2 + r * math.cos(a), 84 + r * math.sin(a)))
        p.poly(pts)
        p.fill_stroke(hexc("#fff07a"), 1.5, hexc("#e8a917"))
    p.ellipse(50, 48, 16, 17)
    p.fill_stroke(skin, 4)
    p.poly([(38, 54), (62, 54), (56, 60), (44, 60)])
    p.fill(hexc("#6b4423"))
    p.eye(44, 46, 3.5, (-1.5, 0))
    p.eye(56, 46, 3.5, (-1.5, 0))
    p.ellipse(50, 34, 34, 7)
    p.fill_stroke(hexc("#8a5a2b"), 4)
    p.rrect(34, 10, 32, 26, 9)
    p.fill_stroke(hexc("#8a5a2b"), 4)
    p.poly([(36, 30), (64, 30)], close=False)
    p.stroke(hexc("#3a2410"), 4)
    p.save()


def bullet():
    p = Pic("bullet", 26, 12)
    p.rrect(2, 2, 22, 8, 4)
    p.fill_stroke(hexc("#c9a227"), 2)
    for i in range(3):
        p.poly([(26, 4 + i * 2), (26 + 0, 4 + i * 2)], close=False)
    p.save()


def flag():
    p = Pic("finish_flag", 90, 170)
    p.rrect(8, 6, 8, 162, 3)
    p.fill_stroke(hexc("#d9d9d9"), 3)
    for r in range(4):
        for col in range(5):
            p.c.rectangle(16 + col * 13, 10 + r * 13, 13, 13)
            p.fill((0.05, 0.05, 0.05, 1) if (r + col) % 2 == 0 else (1, 1, 1, 1))
    p.c.rectangle(16, 10, 65, 52)
    p.stroke(INK, 3)
    p.save()


# ---------------------------------------------------------------------------------------------- worlds

def tileable(name, w, h, draw):
    """Draws `draw(pic, dx)` at dx = -w, 0, +w so shapes crossing an edge wrap around."""
    p = Pic(name, w, h)
    for dx in (-w, 0, w):
        p.c.save()
        p.c.translate(dx, 0)
        draw(p)
        p.c.restore()
    p.save()


def amazon_layers():
    def far(p):
        rnd = random.Random(7)
        for layer, (col, base) in enumerate([("#2f6b4a", 230), ("#285c3f", 290)]):
            pts = [(0, 420)]
            x = 0
            while x <= 1280:
                pts.append((x, base + rnd.uniform(-40, 30) - 30 * math.sin(x / 140 + layer)))
                x += 80
            pts += [(1280, base), (1280, 420)]
            pts[-2] = (1280, pts[1][1])  # match the left edge so the strip tiles
            p.smooth(pts)
            p.fill(hexc(col))
            for _ in range(18):
                cx, cy = rnd.uniform(0, 1280), base + rnd.uniform(-60, 0)
                p.ellipse(cx, cy, rnd.uniform(30, 60), rnd.uniform(24, 40))
                p.fill(hexc(col))
        p.c.rectangle(0, 300, 1280, 120)
        g = cairo.LinearGradient(0, 300, 0, 420)
        g.add_color_stop_rgba(0, 0.85, 0.95, 0.9, 0.0)
        g.add_color_stop_rgba(1, 0.85, 0.95, 0.9, 0.35)
        p.c.set_source(g)
        p.c.fill()
    tileable("amazon_far", 1280, 420, far)

    def near(p):
        rnd = random.Random(11)
        for i in range(6):
            x = 60 + i * 215 + rnd.uniform(-30, 30)
            tw = rnd.uniform(26, 40)
            p.rrect(x - tw / 2, 170, tw, 440, tw / 3)
            p.fill_stroke(hexc("#5b3a1f"), 4)
            p.rrect(x - tw / 2, 170, tw, 440, tw / 3)
            p.shade(x - tw / 2, 0, x + tw / 2, 0, (1, 1, 1, 0.15), (0, 0, 0, 0.25))
            for k in range(5):
                lx, ly = x + rnd.uniform(-90, 90), rnd.uniform(90, 200)
                p.ellipse(lx, ly, rnd.uniform(50, 90), rnd.uniform(30, 50), rnd.uniform(-0.4, 0.4))
                p.fill_stroke(hexc(rnd.choice(["#3f8f3a", "#4aa043", "#357d33"])), 4)
            vx = x + rnd.uniform(30, 90)
            p.c.move_to(vx, 150)
            p.c.curve_to(vx + 20, 250, vx - 20, 320, vx + 10, rnd.uniform(360, 450))
            p.stroke(hexc("#2f6b2a"), 5)
        for _ in range(14):
            x = rnd.uniform(0, 1280)
            for k in range(5):
                a = -math.pi / 2 + (k - 2) * 0.45
                p.c.move_to(x, 600)
                p.c.curve_to(x + 30 * math.cos(a), 600 + 60 * math.sin(a), x + 70 * math.cos(a), 590 + 80 * math.sin(a),
                             x + 90 * math.cos(a), 600 + 70 * math.sin(a))
                p.stroke(hexc("#2e7a35"), 9)
    tileable("amazon_near", 1280, 600, near)


def desert_layers():
    def far(p):
        rnd = random.Random(5)
        for x0, w, h in [(40, 260, 170), (420, 180, 120), (700, 320, 200), (1080, 160, 140)]:
            p.poly([(x0, 420), (x0 + 30, 420 - h), (x0 + w - 30, 420 - h), (x0 + w, 420)])
            p.fill_stroke(hexc("#c96a3d"), 3, hexc("#8c3f1f"))
            for k in range(3):
                y = 420 - h + 20 + k * h / 3.5
                p.poly([(x0 + 24, y), (x0 + w - 24, y)], close=False)
                p.stroke(hexc("#b45a31"), 3)
        pts = [(0, 420), (0, 360)]
        for x in range(0, 1281, 80):
            pts.append((x, 360 + 18 * math.sin(x / 1280 * 2 * math.pi * 3)))
        pts += [(1280, 360), (1280, 420)]
        p.poly(pts)
        p.fill(hexc("#e2b878"))
    tileable("desert_far", 1280, 420, far)

    def near(p):
        rnd = random.Random(9)
        pts = [(0, 600), (0, 420)]
        for x in range(0, 1281, 40):
            pts.append((x, 420 + 40 * math.sin(x / 1280 * 2 * math.pi * 2) + 15 * math.sin(x / 1280 * 2 * math.pi * 5)))
        pts += [(1280, 420), (1280, 600)]
        p.smooth(pts)
        p.fill(hexc("#efc98c"))
        for _ in range(10):
            x, y = rnd.uniform(0, 1280), rnd.uniform(500, 580)
            for k in range(6):
                a = -math.pi / 2 + (k - 2.5) * 0.4
                p.poly([(x, y), (x + 22 * math.cos(a), y + 22 * math.sin(a))], close=False)
                p.stroke(hexc("#8a7a3c"), 3)
        for _ in range(4):
            x = rnd.uniform(0, 1280)
            p.rrect(x - 8, 450, 16, 120, 8)
            p.fill_stroke(hexc("#6aa04a"), 3)
            p.rrect(x - 30, 480, 22, 10, 5)
            p.fill_stroke(hexc("#6aa04a"), 3)
            p.rrect(x - 30, 460, 10, 28, 5)
            p.fill_stroke(hexc("#6aa04a"), 3)
    tileable("desert_near", 1280, 600, near)


def clouds():
    def draw(p):
        rnd = random.Random(3)
        for _ in range(5):
            x, y = rnd.uniform(0, 1280), rnd.uniform(40, 150)
            for k in range(6):
                p.ellipse(x + rnd.uniform(-60, 60), y + rnd.uniform(-12, 12), rnd.uniform(30, 50), rnd.uniform(18, 30))
                p.fill((1, 1, 1, 0.85))
    tileable("clouds", 1280, 220, draw)


def desert_platforms():
    """Sand versions of the 2016 World 1 platform pieces, at the same sizes."""
    rnd = random.Random(21)
    p = Pic("sand_top", 512, 37)
    p.c.rectangle(0, 8, 512, 29)
    p.fill(hexc("#d9a55b"))
    p.c.rectangle(0, 0, 512, 14)
    p.fill(hexc("#efc98c"))
    for _ in range(500):
        x, y = rnd.uniform(0, 512), rnd.uniform(0, 37)
        p.c.rectangle(x, y, 2, 2)
        p.fill(hexc(rnd.choice(["#c48a45", "#f7dca8", "#b77a3a"]), 0.8))
    p.save()
    for name, col in [("sandstone_a", "#c98f55"), ("sandstone_b", "#b97d46")]:
        p = Pic(name, 222, 422)
        p.c.rectangle(0, 0, 222, 422)
        p.fill(hexc(col))
        for y in range(0, 422, 42):
            p.poly([(0, y), (222, y)], close=False)
            p.stroke(hexc("#9c6535"), 3)
            off = 0 if (y // 42) % 2 == 0 else 55
            for x in range(off, 222, 110):
                p.poly([(x, y), (x, y + 42)], close=False)
                p.stroke(hexc("#9c6535"), 3)
        for _ in range(900):
            x, y = rnd.uniform(0, 222), rnd.uniform(0, 422)
            p.c.rectangle(x, y, 2, 2)
            p.fill(hexc(rnd.choice(["#a96e3b", "#dcae78"]), 0.6))
        p.c.rectangle(1.5, 1.5, 219, 419)
        p.stroke(hexc("#7a4a24"), 3)
        p.save()


def main():
    corn(); beans(); heart("heart_full", True); heart("heart_empty", False)
    puff("fart_puff_1", 1); puff("fart_puff_2", 2); puff("fart_puff_3", 3)
    puff("super_puff", 4, "#d8f27a")
    gas_icon(); sparkle(); icons()
    snake("snake_1", "#4c9a2a", "#c7e07a", "spot", 0); snake("snake_2", "#4c9a2a", "#c7e07a", "spot", 1)
    snake("rattlesnake_1", "#c2a26a", "#6b4a2a", "diamond", 0); snake("rattlesnake_2", "#c2a26a", "#6b4a2a", "diamond", 1)
    rock("rock_small", 84, 62, 1); rock("rock_big", 116, 92, 2)
    cactus("cactus_small", 72, 104, False); cactus("cactus_tall", 120, 160, True)
    hive(); bee(); mosquito(0); mosquito(1); tiger(0); tiger(1); bear(); cowboy(0); cowboy(1); bullet(); flag()
    amazon_layers(); desert_layers(); clouds(); desert_platforms()


if __name__ == "__main__":
    main()

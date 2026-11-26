#!/usr/bin/env python3
"""Make the game's copies of the original art. The originals in legacy/ are never changed.

    python3 tools/import_legacy_art.py

Writes game/art/legacy/ (committed, so CI and Godot never need this script):
- donkey/run_1..5.png and donkey_space/run_1..5.png: the 2016 donkey frames at half size (300 x 300);
- menu/space.png: the starfield background at half size;
- menu/<planet>.png: each planet and the Sun, cut out of Stars.png by the rectangles in its Unity .meta file
  (Unity counts y from the bottom), at half size;
- menu/vessel_1..4.png: the main-menu vessel frames at half size;
- menu/text_background.png, logo.png: the unused 2016 text panel and the logo;
- world1/: the World 1 platform pieces (dirt blocks, grass top, water top), cut out of
  "World 1 Platforms.xcf" (flattened with ImageMagick's `convert`).
Half size keeps the web download small; the 2016 port scales them back up (game/original_2016/unity.gd, HALF).
Needs Pillow (and ImageMagick for the .xcf).
"""
import pathlib
import re
import subprocess
import tempfile

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
U = ROOT / "legacy/2016-unity"
OUT = ROOT / "game/art/legacy"

# Stars.png sprite names in the Unity scene: Stars_<n> -> what MainGame.unity shows it as.
PLANETS = {0: "mercury", 1: "venus", 2: "earth", 3: "mars", 4: "saturn", 5: "jupiter", 6: "sun", 7: "uranus", 8: "neptune"}
# World 1 Platforms.xcf pieces: name -> (x, y, w, h) in the 2500 x 2500 canvas.
WORLD1 = {
    "dirt_light_a": (113, 70, 222, 422), "dirt_light_b": (352, 68, 209, 423),
    "dirt_dark_a": (113, 527, 222, 422), "dirt_dark_b": (352, 525, 209, 423),
    "grass_top": (90, 1020, 512, 37), "water_top": (93, 1132, 512, 37),
}


def half(im: Image.Image) -> Image.Image:
    return im.resize((max(1, im.width // 2), max(1, im.height // 2)), Image.LANCZOS)


def save(im: Image.Image, rel: str) -> None:
    path = OUT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, optimize=True)
    print(f"  {rel} {im.width}x{im.height}")


def sprite_rects(meta: pathlib.Path) -> dict[int, tuple[int, int, int, int]]:
    text = meta.read_text(encoding="utf-8")
    rects = {}
    for m in re.finditer(r"name: Stars_(\d+)\s+rect:\s+serializedVersion: \d+\s+x: (\d+)\s+y: (\d+)\s+width: (\d+)\s+height: (\d+)", text):
        n, x, y, w, h = map(int, m.groups())
        rects[n] = (x, y, w, h)
    return rects


def main() -> None:
    sprites = U / "Assets/Sprites"
    for i in range(1, 6):
        save(half(Image.open(sprites / f"Base Donkey/base_char_{i}.png").convert("RGBA")), f"donkey/run_{i}.png")
        save(half(Image.open(sprites / f"Space Base Donkey/space_base_char_{i}.png").convert("RGBA")), f"donkey_space/run_{i}.png")
    for i in range(1, 5):
        save(half(Image.open(sprites / f"Menu Scene/Vessel/Vessel_{i}.png").convert("RGBA")), f"menu/vessel_{i}.png")
    save(half(Image.open(sprites / "Menu Scene/Space.png").convert("RGB")), "menu/space.png")
    save(half(Image.open(sprites / "Menu Scene/Menu Scene Text background.png").convert("RGBA")), "menu/text_background.png")
    stars = Image.open(sprites / "Menu Scene/Stars.png").convert("RGBA")
    rects = sprite_rects(sprites / "Menu Scene/Stars.png.meta")
    for n, name in PLANETS.items():
        x, y, w, h = rects[n]
        top = stars.height - y - h  # Unity's sprite rect y counts from the bottom
        save(half(stars.crop((x, top, x + w, top + h))), f"menu/{name}.png")
    save(Image.open(U / "docs/logo.png").convert("RGBA"), "logo.png")
    with tempfile.TemporaryDirectory() as tmp:
        flat = pathlib.Path(tmp) / "world1.png"
        subprocess.run(["convert", str(U / "GIMP Sources/World 1 Scene/World 1 Platforms.xcf"), "-background", "none", "-flatten", str(flat)], check=True)
        w1 = Image.open(flat).convert("RGBA")
        for name, (x, y, w, h) in WORLD1.items():
            save(w1.crop((x, y, x + w, y + h)), f"world1/{name}.png")


if __name__ == "__main__":
    main()

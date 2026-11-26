# Art and sound

What the game shows and plays, where it comes from, and how to replace it. **Replace a placeholder by saving a file with the same name and size over it** (then open the project once, or run `godot --headless --path game --import`). Don't edit anything in `legacy/`.

## From the 2016 originals (`game/art/legacy/`)

Made by `tools/import_legacy_art.py` from `legacy/2016-unity/`; re-run it instead of editing these.

| Files | From | Used for |
|---|---|---|
| `donkey/run_1..5.png` (300 × 300) | `Base Donkey/base_char_1..5.png`, half size | the donkey: 1–4 running, 3 in the air, 5 headbutting. Feet sit 295 px down the frame. |
| `donkey_space/run_1..5.png` | `Space Base Donkey/` | the helmeted donkey on the world select |
| `menu/vessel_1..4.png` | `Menu Scene/Vessel/` | the vessel flying past the menus (12 frames a second) |
| `menu/space.png`, `menu/<planet>.png`, `menu/sun.png` | `Space.png`, `Stars.png` (cut out by its Unity sprite rectangles) | the menu sky and the planet carousel |
| `menu/text_background.png` | `Menu Scene Text background.png` (not used by the 2016 scene) | the parchment panels |
| `world1/*.png` | `GIMP Sources/World 1 Scene/World 1 Platforms.xcf` | World 1 floor (dark dirt), ledges (light dirt), grass and water tops |
| `logo.png` | `docs/logo.png` | the main menu, app icons, website |

## Placeholders drawn in code (`game/art/new/`)

Made by `tools/make_art.py` (pycairo), in the style of the 2016 donkey: flat colours, dark outline. Things the donkey meets face right in the files and are flipped by the game where needed (the cowboy is drawn aiming left). Things stand on the bottom edge of their picture.

| File | Size |
|---|---|
| `amazon_far.png` | 1280 × 420 |
| `amazon_near.png` | 1280 × 600 |
| `beans.png` | 64 × 48 |
| `bear.png` | 180 × 190 |
| `bee.png` | 30 × 26 |
| `bullet.png` | 26 × 12 |
| `cactus_small.png` | 72 × 104 |
| `cactus_tall.png` | 120 × 160 |
| `clouds.png` | 1280 × 220 |
| `corn.png` | 48 × 76 |
| `cowboy_1.png` | 110 × 170 |
| `cowboy_2.png` | 110 × 170 |
| `desert_far.png` | 1280 × 420 |
| `desert_near.png` | 1280 × 600 |
| `fart_puff_1.png` | 112 × 92 |
| `fart_puff_2.png` | 112 × 92 |
| `fart_puff_3.png` | 112 × 92 |
| `finish_flag.png` | 90 × 170 |
| `gas_icon.png` | 52 × 44 |
| `heart_empty.png` | 44 × 40 |
| `heart_full.png` | 44 × 40 |
| `hive.png` | 76 × 110 |
| `icon_drop.png` | 96 × 96 |
| `icon_fart.png` | 96 × 96 |
| `icon_headbutt.png` | 96 × 96 |
| `icon_jump.png` | 96 × 96 |
| `icon_pause.png` | 64 × 64 |
| `lock.png` | 64 × 72 |
| `medal.png` | 72 × 88 |
| `mosquito_1.png` | 72 × 60 |
| `mosquito_2.png` | 72 × 60 |
| `rattlesnake_1.png` | 140 × 64 |
| `rattlesnake_2.png` | 140 × 64 |
| `rock_big.png` | 116 × 92 |
| `rock_small.png` | 84 × 62 |
| `sand_top.png` | 512 × 37 |
| `sandstone_a.png` | 222 × 422 |
| `sandstone_b.png` | 222 × 422 |
| `snake_1.png` | 140 × 64 |
| `snake_2.png` | 140 × 64 |
| `sparkle.png` | 40 × 40 |
| `super_puff.png` | 112 × 92 |
| `tiger_1.png` | 230 × 120 |
| `tiger_2.png` | 230 × 120 |

Two-frame animations are `<name>_1.png` and `<name>_2.png`. The background layers (`amazon_far`, `amazon_near`, `desert_far`, `desert_near`, `clouds`) repeat sideways, so their left and right edges must match. `sand_top` and `sandstone_a/b` are the desert versions of the World 1 pieces, at the same sizes.

## Sounds and music (`game/audio/`)

Synthesized by `tools/make_audio.py`. Effects are mono 22,050 Hz WAV; music is Ogg Vorbis and loops.

- Effects (`sfx/`): `achievement.wav`, `all_corn.wav`, `beans.wav`, `bonk.wav`, `break.wav`, `buzz.wav`, `click.wav`, `corn.wav`, `double_jump.wav`, `fart_1.wav`, `fart_2.wav`, `fart_3.wav`, `fart_4.wav`, `fart_fizzle.wav`, `finish.wav`, `growl.wav`, `gunshot.wav`, `headbutt.wav`, `hurt.wav`, `jump.wav`, `land.wav`, `level_up.wav`, `splash.wav`, `super_fart.wav`.
- Music (`music/`): `amazon.ogg`, `desert.ogg`, `menu.ogg` (main menus, World 1, World 2).

The 2014 *BIDU songs* (`legacy/2014-bidu-concept/BIDU songs/`) aren't used yet; `tools/render_aup.py` turns an Audacity project into a WAV to listen to them.

## Fonts (`game/fonts/`)

Comic Relief (the finished game) and Liberation Sans (the 2016 port, Arial's widths), both SIL Open Font License, unaltered.

# Building

## What you need
- [Godot 4.7.2](https://godotengine.org/download) (standard build, not .NET) and its export templates.
- Node 22 for the website.
- Python 3 for the tools; Pillow and pycairo to remake art, numpy to remake sound effects, numpy and ffmpeg (libvorbis, libmp3lame) to remake the song loops, ImageMagick for the `.xcf` platform pieces, poppler (`pdftoppm`) for the history pages, Playwright and Chrome for `check_fresh_deploy.py`.

## The game
```
godot --headless --path game --import          # once, and after adding files
godot --path game                               # play (or open game/project.godot in the editor and press F5)
godot --headless --path game -- --scene=tests   # tests; exit code 1 on failure
```
Developer options go after `--` (see `game/scripts/autoload/router.gd`):
- `--scene=<name>`: start on a screen (`main_menu`, `original_2016`, `world_select`, `character`, `achievements`, `credits`, `settings`, `run`, `tests`).
- `--param=stage:desert_2`: which stage `run` opens; `--param=view:world --param=planet:3` for the 2016 port.
- `--param=autoplay:1 --param=quit:1 [--param=stats:3,2,2,2]`: a simple bot plays the stage (it never touches your save), prints `AUTOPLAY … finished=true|false`, and quits. Add `--fixed-fps 60` before `--` to run as fast as the computer allows.
- `--screenshot=shot.png --frames=90`: save a picture after 90 frames and quit (needs a display; on a server use `xvfb-run`).

## The website and the web build
```
npm ci
npm run check                                   # TypeScript, .astro files
npm run build                                   # dist/ -> _site/ with every language
mkdir -p _site/play
godot --headless --path game --export-release "Web" ../_site/play/index.html
python3 tools/web_postexport.py _site/play      # network-first worker, same app as the website, versioned index.js
python3 tools/check_fresh_deploy.py _site       # fake deploy in headless Chrome
npm run preview                                 # serves _site/ at /gassy-donkey/
```
The game is exported once into `_site/play/` and every language links to it (`data-lang-keep`). The website's worker (`public/sw.js`) leaves `play/` to the game's own worker.

## Android
The "Android" preset builds an APK (package `com.wizarddeo.gassydonkey`, landscape). Every push to `master` builds a **debug** APK in CI (`.github/workflows/android.yml`; Actions › Android debug build › Artifacts).

For a release build on your own machine: install the Android SDK and JDK 17, point Godot at them (Editor Settings › Export › Android), create a release keystore **outside the repository**, and give its path and passwords to Godot through `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`, then `godot --headless --path game --export-release "Android" ../build/android/gassy-donkey.apk`. Never commit the keystore or its passwords.

## Remaking the copies and placeholders
```
python3 tools/import_legacy_art.py   # game/art/legacy/, game/web/icon_*.png, public/icons/, src/assets/history/
python3 tools/make_art.py            # game/art/new/
python3 tools/make_audio.py          # game/audio/sfx/
python3 tools/make_bidu_music.py     # game/audio/music/, loop starts in game/data/music.json, public/audio/bidu/
```
They give the same files every time.

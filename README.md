# Gassy Donkey

![The Gassy Donkey logo](legacy/2016-unity/docs/logo.png)

A farting donkey runs, jumps, headbutts and farts through the Amazon and the desert. Sketched in 2014 as *BIDU, the farting donkey*, started in Unity 5.3.5 in 2016, and ported to and finished in Godot in 2026. Free, no ads, no in-app purchases, open source.

**Play it and read its history:** https://deovandski.github.io/gassy-donkey/ · **The 2016 original, ported:** https://deovandski.github.io/gassy-donkey/play/#original-2016

## What the game is

- **A runner made for touch screens and keyboards.** The donkey runs on its own and speeds up every 200 m. Tap the right side to jump, tap again to double jump up to the next level, swipe down to drop a level; the left buttons fart and headbutt (keys: Space/W/↑, S/↓, A/←/Z, D/→/X).
- **Gas.** Corn in the Amazon and beans in the desert fill the gas tank. A fart pushes you forward and scares off what's behind you; a full tank gives a super fart.
- **Two worlds, three stages each:** Earth – Amazon and Earth – Desert (Phase I of the 2016 plan). Rocks, snakes, honey hives, bears, cactus and cowboys in the way; mosquitoes and tigers behind you. The other planets say "Coming soon!".
- **Levels instead of waiting.** Every level gives a point for health, farting power, jump power or headbutt power. Later stages have higher gravity. Achievements, local saves.
- **Music: the 2014 BIDU songs**, made by Deovandski's father, turned into seamless loops.
- **The 2016 original**, ported from the Unity scene as it was: the main menu and the planet carousel, with each C# script rewritten in GDScript.

## Repository layout

```
legacy/               the originals, never edited
  2014-bidu-concept/  the BIDU sketch and the BIDU songs (Audacity projects)
  2016-design/        the Word file behind the game-idea PDF
  2016-unity/         the Unity 5.3.5 project as published in 2016 (Assets, ProjectSettings, GIMP Sources, docs)
game/                 the Godot 4.7 project (GDScript)
  original_2016/      the 2016 Unity menu, ported
  scenes/, scripts/   the finished game (scripts/run/ is the running part)
  data/               worlds, stages, obstacles, progression, achievements, credits (JSON)
  art/legacy/         copies of the 2016 art made by tools/import_legacy_art.py
  art/new/, audio/sfx/  placeholder art and sound effects made by tools/make_art.py and tools/make_audio.py
  audio/music/        the 2014 BIDU songs as loops, made by tools/make_bidu_music.py
  tests/              headless tests
src/, content/i18n/   the website (Astro + TypeScript, from Deovandski-repo-template), in 15 languages
tools/                web_postexport.py and check_fresh_deploy.py (the game's web build),
                      import_legacy_art.py, make_art.py, make_audio.py, make_bidu_music.py, render_aup.py,
                      the website's i18n/llms tools
docs/                 DESIGN.md, ART.md, BUILDING.md, SAVE_FORMAT.md, ARCHITECTURE.md
.github/workflows/    ci.yml (site checks, game tests), pages.yml (site + game -> GitHub Pages), android.yml (debug APK)
```

## Build and run

You need [Godot 4.7](https://godotengine.org) (standard build) and Node 22.

- **Play in the editor:** open `game/project.godot` and press F5.
- **Test:** `godot --headless --path game -- --scene=tests`
- **Website and web build:** `npm ci && npm run build`, then `mkdir -p _site/play && godot --headless --path game --export-release "Web" ../_site/play/index.html && python3 tools/web_postexport.py _site/play`, then `npm run preview`.
- **Android:** see [docs/BUILDING.md](docs/BUILDING.md). Every push to `master` builds a debug APK (Actions › Android debug build › Artifacts).

## Documentation

[Design notes](docs/DESIGN.md) · [Art and sound list](docs/ART.md) · [Building](docs/BUILDING.md) · [Save format](docs/SAVE_FORMAT.md) · [Website architecture](docs/ARCHITECTURE.md) · [Contributing](CONTRIBUTING.md)

## Who makes it

Created by Deovandski Skibinski Junior, author of #HusbandOutWorld and CEO/Founder of Wizard Deo Solutions. The 2026 port and the finished game were built with Claude under his direction ([AI disclosure](AI-DISCLOSURE.md)).

## Support

Brought to you by Deovandski, author of the #HusbandOutWorld series and CEO/Founder of Wizard Deo Solutions. Have fun! If you want to support me, buy the [eBooks on Amazon](https://www.amazon.com/dp/B0BT5XM4QC).

## License

[MIT](LICENSE), as the 2016 project was. See [LICENSE](LICENSE) for what it doesn't cover (fonts, the Godot engine, trademarks). [Privacy](PRIVACY.md) · [Security](SECURITY.md)

# Design notes

Where every part of the finished game comes from: the 2014 BIDU sketch (`legacy/2014-bidu-concept/`), the 2016 game-idea overview (`legacy/2016-unity/docs/GassyDonkeyGameIdea.pdf`) and the 2016 Unity project, or a choice made in 2026 while finishing it. Choices marked **2026** are open to change: they were made by Claude because the originals didn't say.

## From the originals

| What | Source | Where in the game |
|---|---|---|
| A farting donkey that keeps running to score points | 2014 sketch | the runner (`game/scripts/run/run.gd`) |
| Mosquito that follows the donkey when it isn't running | 2014 sketch | `Chaser` "mosquito": it gains whenever you slow down |
| Cactus, honey hive, rocks; snake, bear, cowboys (gun) | 2014 sketch | `game/data/worlds.json` "things" |
| Jungle and Desert | 2014 sketch; 2016 phases ("Earth – Amazon", "Earth – Desert") | the two worlds |
| Corn power-up; "make noise when getting all corn" | 2014 sketch | corn fills gas; collecting all of a stage's gas items plays a fart fanfare and gives XP |
| The BIDU songs | 2014 Audacity projects (made by Deo's father) | all the music: menus `bidu_01`; Amazon stages `bidu_03`, `bidu_02`, `bidu_04`; desert stages `bidu_02`, `bidu_04`, `bidu_05` (quietest song for the menus, the loudest and fastest for the last stages) |
| Main menu: logo, Select World, Character, Achievements, Credits | 2016 notes p.1, Unity scene | main menu (same layout, same sky) |
| Credits: "thanks for playing my 1st game" | 2016 notes p.1 | Credits screen |
| World select: planet, "Recommended LVL X", Play | 2016 notes p.1, Unity scene ("Level X recommended") | world select |
| Fart and head attack on the left, jump anywhere on the right; landscape only | 2016 notes p.2 | touch controls (`run_hud.gd`) |
| Double jump goes to the higher level; a normal jump stays on the same level | 2016 notes p.2 | three levels (floor, tier 1, tier 2); a single jump is just under one level |
| Right finger swipe down goes one level lower | 2016 notes p.2 | swipe down / S / ↓ drops through a platform |
| Water levels for multiple paths | 2016 notes p.2 | water pools on the floor slow you down; ledges above are the dry path |
| Tiger: jump over it, then fart when it follows; farting level 2 needed to scare it | 2016 notes p.2 | `Chaser` "tiger", `Progression.scares_tiger()` |
| Each level has its own gas-filling items, used at the player's discretion | 2016 notes p.2 | corn (Amazon), beans (desert); fart whenever you like |
| A dynamic leveling wall instead of wait times or money walls | 2016 notes p.2 | XP is kept even when a run fails; recommended levels never lock |
| Control overlay: speed, ×1.2 every 200 m; HP and gas left; XP and LV right; big jump area | 2016 notes p.3 | HUD; speed ×1.2 every 200 m (capped at ×2) |
| Character menu: one point per level for health, farting power, jump power (for higher gravity), head attack power; boxes per stat | 2016 notes p.4 | Character screen, 5 boxes per stat, stats start at 1 |
| Release a few worlds first, the rest later ("World 3: Coming soon!") | 2016 notes p.5 | Phase I worlds playable, other planets "Coming soon!" |
| Planet carousel with swipes, planet names, rotating Sun, flying vessel | 2016 Unity project | world select and menu backgrounds reuse the ported scripts |
| Donkey run frames 1–4, frame 5 head down | 2016 sprites | run animation; frame 5 for the headbutt; frame 3 in the air |
| Space donkey (helmet) frames | 2016 sprites | floats beside the planets on the world select |
| World 1 platform pieces (dirt blocks, grass top, water top) | 2016 GIMP source | World 1 floor, ledges and water |

## Decided while finishing (2026)

| Choice | Why |
|---|---|
| One Godot project with both editions; the 2016 port opens from the menu or from `play/#original-2016` | One download and one installed app for both; the website's "one source" rule. |
| Stats go 1 to 5, max level 17 (16 points fills everything) | The sketch shows about five boxes with the first one filled. |
| Hearts: 2 + health rank | Three hearts at the start felt right for a runner. *(inferred)* |
| Fart: costs a third of the tank; pushes forward, lifts a little in the air, scares chasers behind within a radius; a full tank gives a **super fart** (bigger push, two seconds of safety, scares a tiger at any rank) | Makes gas a choice between saving and spending; the super fart echoes the "super power" boxes on the control-overlay sketch. |
| Headbutt breaks things whose toughness is at most your headbutt rank: rocks, snakes, cowboys 1; cactus and bears 2. A failed headbutt bounces you back (and a cactus hurts) | Gives headbutt power a clear job. |
| Gravity per stage: Amazon 1.0, 1.0, 1.08; desert 1.12, 1.18, 1.25 | "jump power (for later levels with higher gravity)". |
| Tigers only in the Amazon, cowboys only in the desert, bears in Amazon stage 3 | Matches the Jungle/Desert split of the sketch. *(inferred)* |
| Desert gas item: beans | "Each level would contain its own version of gas filling items"; beans are the classic. |
| Stage names (Riverbank, Vine Valley, Tiger Trail, Dry Dunes, Cactus Canyon, High Noon), lengths, counts | Placeholders to tune. |
| Achievements (13) | The sketch has an Achievements screen with progress bars but no list. |
| Stages open one after another; World 2 opens after World 1 | So "Level X recommended" can guide without locking anything by level. |
| No pits: the floor never ends, only water slows you | Falling out of the world felt unfair on touch screens. *(inferred)* |
| Each song plays its opening once, then loops a part that starts and ends on the beat, a whole number of bars long, with a 0.25 s cross-fade | Deo asked for loops "without issues"; looping from the very start would replay the intro every time. |

## Ideas log

| Date | Idea | Raised by | Status | Why | Where |
|---|---|---|---|---|---|
| 2014-03 | BIDU, the farting donkey: run, enemies, Jungle/Desert, corn | Deo | kept | The original concept | 2014 sketch |
| 2016-07 | Gassy Donkey design (controls, levels, tiger, stats, phases) | Deo | kept | The original design | 2016 notes |
| 2026-11 | Port the 2016 menu exactly, with "Port extra" marks for anything added | Deo (port it), Claude (how) | kept | People can play the 2016 version as it was | `game/original_2016/` |
| 2026-11 | Super fart on a full tank | Claude | kept | Gives saving gas a reward *(inferred from the "super power" boxes)* | `run.gd` `do_fart()` |
| 2026-11 | Third world on Mars with the space donkey and low gravity | Claude | cut | The 2016 plan says later levels have *higher* gravity, and Phase II wasn't designed; the space donkey floats on the world select instead | — |
| 2026-11 | A bot that plays each stage, in CI | Claude | kept | Catches stages that can't be finished after a tuning change | `run.gd` `_autoplay()`, `ci.yml` |
| 2026-11 | Synthesized placeholder music | Claude | replaced | Deo confirmed the 2014 BIDU songs can be used (they are his father's): they are the music now, as seamless loops | `tools/make_bidu_music.py`, `game/data/music.json` |
| 2026-11 | BIDU songs playable on the history page | Claude | kept | The songs are part of the game's history; the site plays them as they were mixed | `src/pages/history.astro`, `public/audio/bidu/` |
| 2026-11 | Song credit corrected: the BIDU songs are by Deo's father | Deo | changed | Deo: his father made the songs, not him | `game/data/credits.json`, history and home pages, `LICENSE` |
| 2026-11 | The songs are MIT, credited by name | Deo | changed | Deo: his father's songs can be MIT too; his name is Deovandski Skibinski (Deo's without "Junior") | `LICENSE`, `game/data/credits.json`, history page |

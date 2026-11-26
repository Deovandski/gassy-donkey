# Legacy: the original Gassy Donkey files

Everything in this folder is the author's original work, kept **exactly as it was made**. Nothing here is edited, renamed, resized or re-encoded. The game in `game/` and the website read copies made from these files by `tools/import_legacy_art.py`; display fixes happen there, never here.

| Folder | What it is | When |
|---|---|---|
| [2014-bidu-concept/](2014-bidu-concept) | The first idea: *BIDU, the farting donkey*. A concept sketch (character, enemies, Jungle / Desert, corn power-ups) and five Audacity 2.0.5 projects (`BIDU songs/`, `.aup` files with their `_data/` audio blocks). | March and July 2014 |
| [2016-design/](2016-design) | `Gassy Donkey Game Idea.docx`, the Word file the PDF game-idea overview was made from (five scanned notebook pages with notes). | July 2016 |
| [2016-unity/](2016-unity) | The Unity 5.3.5 project as it was published on GitHub in July 2016: `Assets/` (scene `MainGame.unity`, the five C# scripts, sprites, the vessel animation), `ProjectSettings/`, `GIMP Sources/` (`.xcf` files for every sprite and the World 1 platforms), `docs/` (the game-idea PDF and the logo), and the original README and MIT license. | July 2016 (license updated May 2017) |

The 2016 project's own README says it "will not be finished". The Godot port of its main menu and world selection lives in `game/original_2016/` and can be played on the website; the finished game is the rest of `game/`.

To hear the 2014 BIDU songs without Audacity, render them to WAV with `python3 tools/render_aup.py "legacy/2014-bidu-concept/BIDU songs/01.aup" 01.wav`.

# AI Disclosure

This repository was finished with an AI assistant, **Claude** (by Anthropic), working from Deovandski's originals and direction. This page says plainly which parts are human work, which parts the AI made, and how the two fit together. Keep it up to date as the project grows.

## The short version
- **The idea and the originals are human-made.** The 2014 *BIDU, the farting donkey* sketch and songs, the 2016 game-idea notes, the 2016 Unity project (its C# scripts, scene and settings) and all its art (the donkey and space donkey frames, the vessel, the World 1 platforms, the logo, the GIMP sources) are Deovandski Skibinski Junior's. They are kept unchanged in `legacy/`.
- **The planet pictures** in the 2016 `Stars.png` sheet came with the 2016 project; where they were taken from isn't recorded there.
- **No AI image generator was used.** The new pictures (enemies, obstacles, pickups, backgrounds, buttons) were drawn by Claude *in code*, with shapes and colours in `tools/make_art.py`, as placeholders for an illustrator. The sounds and music were synthesized the same way in `tools/make_audio.py`.
- **The code is AI-written.** The Godot port of the 2016 menu, the finished game, its tests, the tools and the website.
- **The design of the finished game follows the 2014 and 2016 notes.** Where they didn't say, Claude made the choice, and [docs/DESIGN.md](docs/DESIGN.md) lists each one so it can be changed.
- **The website's translations are AI-written, and every translated page says so.** Names are written by sound, never translated. English is the source.
- **A human decides.** Deovandski directs the work, sets the rules and chooses what gets committed.

## Attribution statement
Modeled on the questions in IBM's [AI Attribution Toolkit](https://www.research.ibm.com/blog/AI-attribution-toolkit) (what AI was used, what it contributed, how much humans shaped it, and who is accountable):

> **AI system:** Claude, a large language model by Anthropic, used as an assistant with access to the repository files (November 2026).
> **Human contribution:** the concept, the 2014 and 2016 originals (design, art, Unity project), the rules for the repository, review and approval of what is committed.
> **AI contribution:** porting the 2016 Unity menu to Godot; designing and coding the rest of the game from the 2016 notes; drawing placeholder art and synthesizing sounds in code; the tests, build tools and CI; the website and its docs.
> **Human modification:** Deovandski reviews and requests changes.
> **Accountability:** Deovandski Skibinski Junior.

## File by file

| Path | Where it comes from | What the AI did |
|---|---|---|
| [legacy/](legacy) | Deovandski's originals (2014, 2016). | Nothing: moved into this folder unchanged. |
| [game/original_2016/](game/original_2016) | The 2016 Unity scene and C# scripts. | Ported to Godot: the scene rebuilt from the numbers in `MainGame.unity`, each script rewritten in GDScript. |
| [game/art/legacy/](game/art/legacy), [src/assets/history/](src/assets/history), icons | The 2016 art, the 2016 PDF and the 2014 sketch. | Copied, halved in size, cut out of sprite sheets or rendered from the PDF by `tools/import_legacy_art.py`. Not redrawn. |
| [game/art/new/](game/art/new) | — | **Drawn in code by the AI** (`tools/make_art.py`). Placeholders. |
| [game/audio/](game/audio) | — | **Synthesized in code by the AI** (`tools/make_audio.py`). Placeholders. |
| [game/scenes/](game/scenes), [game/scripts/](game/scripts), [game/data/](game/data), [game/tests/](game/tests) | The 2014 sketch and the 2016 notes (controls, tiers, gas items, tiger rule, stats, gravity, world phases). | Designed and written by the AI; see [docs/DESIGN.md](docs/DESIGN.md) for which choices came from where. Stage names and achievement names are the AI's. |
| [src/assets/screenshots/](src/assets/screenshots) | — | Screenshots of the game taken by the AI. |
| [src/](src), [public/](public) | [Deovandski-repo-template](https://github.com/Deovandski/Deovandski-repo-template). | Pages and styles written by the AI. The site's own interface text is AI-written. |
| [tools/](tools) | `i18n.ts`, `llms.ts`, `init.ts`, `prune-originals.ts` from the template; `web_postexport.py` and `check_fresh_deploy.py` from [Sinoi the Fisherman](https://github.com/Deovandski/Sinoi-the-fisherman). | Written or adapted by the AI. |
| [content/i18n](content/i18n) | The website's English. | **Translated by the AI**, segment by segment. |
| [.github/](.github) | The template's and Sinoi the Fisherman's workflows. | Written or adapted by the AI. |
| [README.md](README.md), [CLAUDE.md](CLAUDE.md), [docs/](docs), [PRIVACY.md](PRIVACY.md), [SECURITY.md](SECURITY.md), [CONTRIBUTING.md](CONTRIBUTING.md), this page | Patterns from Deovandski's other repositories. | Written by the AI. |
| [game/fonts/](game/fonts) | Comic Relief and Liberation Sans (SIL Open Font License). | Included unaltered. |

## Contributing
PRs are welcome, with or without AI help. If you used AI for a contribution, say so in the PR description and add a line to the table above.

© Deovandski Skibinski Junior.

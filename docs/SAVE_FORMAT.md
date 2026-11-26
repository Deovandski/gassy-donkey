# Save format

The game keeps one JSON file, `user://save.json` (IndexedDB in browsers, private app storage on Android), written by `game/scripts/autoload/save_manager.gd` after every run and every change in Character or Settings.

```json
{
  "format": "gassy-donkey-save",
  "version": 1,
  "created_at": "2026-11-26T20:00:00",
  "updated_at": "2026-11-26T20:10:00",
  "xp": 0,
  "stats": {"health": 1, "fart": 1, "jump": 1, "headbutt": 1},
  "stages": {
    "amazon_1": {"done": true, "best_m": 450, "best_gas": 9, "all_gas": false, "no_hit": false}
  },
  "achievements": {"first_fart": "2026-11-26"},
  "counters": {"farts": 0, "super_farts": 0, "mosquitoes": 0, "tigers": 0, "bears": 0, "cowboys": 0,
               "enemies": 0, "corn": 0, "distance_m": 0, "runs": 0, "stages_finished": 0},
  "settings": {"music": 0.7, "sfx": 1.0, "touch_buttons": true}
}
```

- **Level** isn't stored: it comes from `xp` and `xp_to_reach` in `game/data/progression.json`. **Free points** = (level − 1) − points already in the stats (each stat starts at 1).
- **stages**: one entry per stage played. A stage opens when the one before it (in `worlds.json` order) is `done`.
- **counters** are lifetime totals; achievements with a `counter` in `achievements.json` unlock when it reaches `goal`.
- Keys missing from an older or hand-edited save are filled in with the defaults; a save with a newer `version` than the game knows is ignored.

## Changing the format
Bump `SaveManager.VERSION`, add a step to `_migrate()` that upgrades the previous version, update this page and `game/tests/test_save_manager.gd`.

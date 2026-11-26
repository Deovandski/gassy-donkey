# Contributing

Thanks for helping the donkey along.

- **Read [CLAUDE.md](CLAUDE.md) first.** It holds the rules for people and agents alike: the originals in `legacy/` are never edited, the 2016 port stays a port, data goes in `game/data/`, every picture on the website needs alt text.
- **Run the checks before a PR:** `godot --headless --path game -- --scene=tests`, `npm run check` and `npm run build`. If you change the game's web build or its worker, also run the export and `python3 tools/check_fresh_deploy.py _site` (see [docs/BUILDING.md](docs/BUILDING.md)).
- **Art and sound:** to replace a placeholder, drop in a file with the same name and size ([docs/ART.md](docs/ART.md)).
- **Design changes:** add a row to the ideas log in [docs/DESIGN.md](docs/DESIGN.md), with the reason.
- **AI help** is fine; say so in the PR and add a line to [AI-DISCLOSURE.md](AI-DISCLOSURE.md).
- No secrets in git, ever (keystores, passwords, `.env`).

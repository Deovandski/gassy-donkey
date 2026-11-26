#!/usr/bin/env python3
"""Finish Godot's web (PWA) export so the game installs cleanly and works offline.

Run after every web export (and after `npm run build`, which writes the website into _site/):
    python3 tools/web_postexport.py _site/play

Copied from Deovandski/Sinoi-the-fisherman's tools/web_postexport.py and adapted: here the website (Astro)
writes its own manifest.webmanifest and its own worker (public/sw.js), so step 4 matches the game's manifest
to the website's instead of writing one.

1. Manifest: Godot 4.7 writes name, start_url, display, orientation,
   background_color and icons. This adds a short home-screen name, a stable
   id and scope, a description and the theme color.
2. Service worker, network first (issue #18): Godot's worker answers from its
   saved copy first, so after a deploy players kept the old game until they
   tapped "update", and its install step fetched through the browser's HTTP
   cache (GitHub Pages lets browsers keep files for 10 minutes), so a new
   worker could even save the *old* files. Now:
   - the page and every game file are fetched from the network first, with
     `cache: 'no-cache'` (a cheap "not modified" when nothing changed), and
     the saved copy is used only offline (or, for the page, after 4 s);
   - install pre-caches the full game (wasm + pck too, so one online visit
     is enough for offline play), also with `no-cache`;
   - a new worker takes over at once (skipWaiting + clients.claim), so no
     stale "new version ready" prompt appears for a game that's already new;
   - the folder URL (/play/) falls back to the saved index.html offline.
   Every export gets a new CACHE_VERSION from Godot (a timestamp), so old
   saved copies are dropped when the new worker activates.
3. Service worker scope stays play/: the landing page and privacy page are
   never served by it.
4. Same app as the website: the game's manifest gets the website's id and
   scope (src/pages/manifest.webmanifest.ts), so installing from either page
   gives the same app, which opens straight into the game.
5. Play page: replaces Godot's bare <noscript> line with a message (the game needs JavaScript and
   WebGL) with a link home, so readers that don't run scripts see what the
   page is, adds the meta description, and loads index.js as
   index.js?v=<CACHE_VERSION>: a new name each export, so the browser's
   in-memory copy of the old script can't run with a new page.
The name and one-line description come from game/data/credits.json, the one
source the game and the website share (CLAUDE.md, "One source").
"""
import html
import json
import pathlib
import re
import sys
import urllib.parse

CREDITS = json.loads((pathlib.Path(__file__).resolve().parent.parent / "game/data/credits.json").read_text(encoding="utf-8"))
NAME = CREDITS["name"]
TAGLINE = CREDITS["tagline"]

# The id is resolved against the site's origin (deovandski.github.io), which
# other Deovandski sites share, so it must be specific to this game. Never
# change it once players have installed the app: a new id is a new app.
APP_ID = "/gassy-donkey/"

MANIFEST_EXTRA = {
    "short_name": CREDITS["short_name"],
    "id": APP_ID,
    # The app covers the whole site (landing page + game), so the landing
    # page can offer the install and links between them stay in the app.
    "scope": "../",
    "description": TAGLINE,
    "theme_color": "#000000",
    "lang": "en",
    "categories": ["games"],
}

SW_PATCHES = [
    # (what Godot writes, what we want, why)
    ("event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES)));",
     "event.waitUntil(caches.open(CACHE_NAME)\n\t\t.then((cache) => cache.addAll(FULL_CACHE.map((name) => new Request(name, { cache: 'no-cache' }))))\n\t\t.then(() => self.skipWaiting()));",
     "install pre-caches the full game, skipping the HTTP cache, and takes over at once"),
    ("return ('navigationPreload' in self.registration) ? self.registration.navigationPreload.enable() : Promise.resolve();",
     "return ('navigationPreload' in self.registration) ? self.registration.navigationPreload.disable() : Promise.resolve();\n\t}).then(function () {\n\t\treturn self.clients.claim();",
     "no navigation preload (it could use the HTTP cache); claims open pages"),
]

# Godot's fetch handler (cache first) is replaced as a whole, from this line
# up to the 'message' handler.
SW_FETCH_START = "self.addEventListener(\n\t'fetch',"
SW_FETCH_END = "self.addEventListener('message'"
SW_FETCH_MARK = "Gassy Donkey: network first"
SW_FETCH = """// Gassy Donkey: network first (tools/web_postexport.py, from Sinoi-the-fisherman issue #18). The page and the
// game files come from the network with cache: 'no-cache' (a cheap 304 when
// nothing changed), so the first visit after a deploy runs the new game. The
// saved copy is used only offline, or for the page after NETWORK_TIMEOUT_MS.
// Game files have no timeout: they're big and must match the page.
const NETWORK_TIMEOUT_MS = 4000;

function fetchFresh(cache, url, key, timeout) {
	const fresh = fetch(url, { cache: 'no-cache', credentials: 'same-origin' }).then((response) => {
		if (response.ok) {
			cache.put(key, response.clone());
		}
		return response;
	});
	if (!timeout) {
		return fresh;
	}
	const late = new Promise((resolve, reject) => setTimeout(() => reject(new Error('network timeout')), timeout));
	return Promise.race([fresh, late]);
}

self.addEventListener('fetch', (event) => {
	const isNavigate = event.request.mode === 'navigate';
	const scope = self.registration.scope;
	const url = event.request.url || '';
	if (!url.startsWith(scope)) {
		return;
	}
	const local = url.slice(scope.length).split('#')[0].split('?')[0];
	if (!isNavigate && !FULL_CACHE.includes(local)) {
		return;
	}
	// A navigation request can't be copied with new options, hence its URL.
	const key = isNavigate ? CACHED_FILES[0] : local;
	event.respondWith((async () => {
		const cache = await caches.open(CACHE_NAME);
		try {
			return await fetchFresh(cache, url, key, isNavigate ? NETWORK_TIMEOUT_MS : 0);
		} catch (e) {
			const saved = await cache.match(key);
			if (saved) {
				return saved;
			}
			if (isNavigate) {
				const offline = await caches.match(OFFLINE_URL);
				if (offline) {
					return offline;
				}
			}
			throw e;
		}
	})());
});

"""


def patch_manifest(path: pathlib.Path) -> dict:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    manifest.update(MANIFEST_EXTRA)
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"manifest: {', '.join(sorted(manifest))}")
    return manifest


def patch_service_worker(path: pathlib.Path) -> None:
    text = path.read_text(encoding="utf-8")
    if "const ENSURE_CROSSORIGIN_ISOLATION_HEADERS = false;" not in text:
        sys.exit(f"service worker: {path} expects cross-origin isolation headers; the network-first handler doesn't add them")
    for before, after, why in SW_PATCHES:
        if after in text:
            print(f"service worker: already patched ({why})")
            continue
        if text.count(before) != 1:
            sys.exit(f"service worker: expected one '{before}' in {path}; Godot's template changed, update this script")
        text = text.replace(before, after)
        print(f"service worker: {why}")
    if SW_FETCH_MARK in text:
        print("service worker: already network first")
    else:
        start, end = text.find(SW_FETCH_START), text.find(SW_FETCH_END)
        if start < 0 or end < start:
            sys.exit(f"service worker: couldn't find Godot's fetch handler in {path}; Godot's template changed, update this script")
        text = text[:start] + SW_FETCH + text[end:]
        print("service worker: page and game files network first (no-cache), saved copy offline")
    path.write_text(text, encoding="utf-8")


NOSCRIPT_MARK = "data-gassy-noscript"
NOSCRIPT_TEXT = (
    f'<p {NOSCRIPT_MARK} style="color:#ffffff;font-family:system-ui,sans-serif;padding:1rem">'
    f"{html.escape(NAME)}: {html.escape(TAGLINE)} This page runs the game, which needs JavaScript and WebGL. "
    '<a style="color:#ffa608" href="../">About the game and its history</a>.'
    "</p>"
)
META_DESCRIPTION = f'<meta name="description" content="{html.escape(NAME)}: {html.escape(TAGLINE)} Play in the browser with a keyboard or a touch screen.">'



GODOT_NOSCRIPT = "Your browser does not support JavaScript."


GODOT_SCRIPT_TAG = '<script src="index.js"></script>'


def patch_play_page(path: pathlib.Path) -> None:
    text = path.read_text(encoding="utf-8")
    sw = (path.parent / "index.service.worker.js").read_text(encoding="utf-8")
    version = re.search(r"const CACHE_VERSION = '([^']*)';", sw)
    if not version:
        sys.exit("play page: no CACHE_VERSION in the service worker; Godot's template changed, update this script")
    if 'src="index.js?v=' in text:
        print("play page: index.js already versioned")
    elif text.count(GODOT_SCRIPT_TAG) != 1:
        sys.exit(f"play page: expected Godot's '{GODOT_SCRIPT_TAG}' in {path}; Godot's template changed, update this script")
    else:
        text = text.replace(GODOT_SCRIPT_TAG, '<script src="index.js?v=%s"></script>' % urllib.parse.quote(version.group(1), safe=""), 1)
        print("play page: index.js loads with this export's version")
    if NOSCRIPT_MARK in text:
        print("play page: <noscript> message already set")
    elif text.count(GODOT_NOSCRIPT) != 1:
        sys.exit(f"play page: expected Godot's '{GODOT_NOSCRIPT}' in {path}; Godot's template changed, update this script")
    else:
        text = text.replace(GODOT_NOSCRIPT, NOSCRIPT_TEXT, 1)
        print("play page: replaced Godot's <noscript> line with a description and a link home")
    if 'name="description"' in text:
        print("play page: meta description already set")
    else:
        if text.count("</title>") != 1:
            sys.exit(f"play page: expected one </title> in {path}")
        text = text.replace("</title>", "</title>\n\t\t" + META_DESCRIPTION, 1)
        print("play page: added the meta description")
    path.write_text(text, encoding="utf-8")


def main(folder: str) -> None:
    base = pathlib.Path(folder)
    patch_manifest(base / "index.manifest.json")
    patch_service_worker(base / "index.service.worker.js")
    patch_play_page(base / "index.html")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])

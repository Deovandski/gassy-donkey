// Shared helpers for pages and components.
import config from '../../site.config.json' with { type: 'json' };
// The game's name, description, credits and links: one source for the game and the website.
import creditsJson from '../../game/data/credits.json' with { type: 'json' };

export const credits = creditsJson;

export const site = config;

// One source for what the site says about itself. Pages, the layout and the app manifest read these; don't type them
// again anywhere (see "One source" in CLAUDE.md). `npm run init -- <repo> --name "…"` fills in SITE_NAME.
/** The site's name: header, home page, browser tab and installed app. */
export const SITE_NAME = credits.name;
/** One or two sentences: the home page's description for search engines and link previews, and the app's. */
export const SITE_DESCRIPTION = `${credits.tagline} Started in Unity in 2016, finished in Godot: play it in the browser, or play the 2016 original.`;
/** Browser bar and app colour: the icon's background. CSS can't import this, so --night in site.css repeats it. */
export const THEME_COLOR = '#000000';
/** localStorage key for Settings. Base.astro puts it on <html data-store>, where its inline script and
 *  src/scripts/settings.ts both read it. */
export const STORAGE_KEY = 'gassy-donkey-site';

/** The base path without a trailing slash: "/gassy-donkey", or "" at a domain root. */
export const BASE = (config.base || '').replace(/\/$/, '');

/** A link inside the site: url('notes/') -> "/gassy-donkey/notes/". tools/i18n.ts moves these into each language. */
export function url(path = ''): string {
  return `${BASE}/${path.replace(/^\//, '')}`;
}

/** The repository on GitHub, for "source" and "issues" links. */
export const REPO_URL = 'https://github.com/Deovandski/gassy-donkey';

/** Header links. Add a page by adding a file under src/pages/ and, if it belongs in the menu, a line here. */
export const NAV: { href: string; label: string }[] = [
  { href: url('#play'), label: 'Play' },
  { href: url('history/'), label: 'History' },
  { href: url('#privacy'), label: 'Privacy' },
];

/** The game (the Godot web export at play/, built once, not per language: link with data-lang-keep). */
export const PLAY_URL = url('play/');
/** The 2016 Unity version, ported: the same build opens it from this address (game/scripts/autoload/router.gd). */
export const PLAY_2016_URL = url('play/#original-2016');

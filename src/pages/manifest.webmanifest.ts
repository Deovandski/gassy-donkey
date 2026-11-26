// The web app manifest: what Android, desktop Chrome and Edge need to offer "Install app" for the site.
// Built here (not in public/) so every address starts with the base path from site.config.json.
// The same as the Deovandski site's (Deovandski/Deovandski#160). Swap the icons in public/icons/ for the repo's own.
import type { APIRoute } from 'astro';
import { credits, PLAY_2016_URL, PLAY_URL, SITE_DESCRIPTION, SITE_NAME, THEME_COLOR, url } from '../lib/site';

export const GET: APIRoute = () => {
  const base = url();
  const manifest = {
    id: base,
    name: SITE_NAME,
    short_name: credits.short_name,
    description: SITE_DESCRIPTION,
    lang: 'en',
    // The installed app opens straight into the game. tools/web_postexport.py gives the game's own manifest
    // (play/index.manifest.json) this same id and scope, so installing from either page is the same app.
    start_url: PLAY_URL,
    scope: base, // covers every language folder too (/zh/, /ja/, …)
    display: 'standalone',
    orientation: 'landscape',
    categories: ['games'],
    background_color: THEME_COLOR,
    theme_color: THEME_COLOR,
    icons: [
      { src: url('icons/icon-192.png'), sizes: '192x192', type: 'image/png', purpose: 'any' },
      { src: url('icons/icon-512.png'), sizes: '512x512', type: 'image/png', purpose: 'any' },
      { src: url('icons/icon-maskable-512.png'), sizes: '512x512', type: 'image/png', purpose: 'maskable' },
    ],
    // Long-press the installed app's icon to see these. Example:
    // { name: 'Notes', short_name: 'Notes', url: url('notes/'), icons: [{ src: url('icons/icon-192.png'), sizes: '192x192', type: 'image/png' }] },
    shortcuts: [
      { name: 'The 2016 original', short_name: '2016', url: PLAY_2016_URL, icons: [{ src: url('icons/icon-192.png'), sizes: '192x192', type: 'image/png' }] },
      { name: 'About the game', short_name: 'About', url: base, icons: [{ src: url('icons/icon-192.png'), sizes: '192x192', type: 'image/png' }] },
    ],
  };
  return new Response(JSON.stringify(manifest, null, 2), { headers: { 'Content-Type': 'application/manifest+json' } });
};

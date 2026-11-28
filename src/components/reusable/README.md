# Reusable components

Components here follow "Build reusable components" in CLAUDE.md: one `.astro` file each, no imports from the
site, everything in through props or data attributes, scoped styles themed with CSS custom properties.
Copy one into another repo as is.

| Component | What it is | Used on |
|---|---|---|
| [PhotoViewer.astro](PhotoViewer.astro) | The one photo viewer (lightbox) for a page: every content picture, gallery button and link to an image file opens in it, with its caption and date; ‹ › between pictures. From Deovandski/Deovandski, with translatable words and dates in the page's language. | Every page (in `Base.astro`) |
| [InstallApp.astro](InstallApp.astro) | An "Install app" button for an installable site (PWA): shown only when the browser can install it right now, otherwise a short line on how (open in Chrome on Android, Share → Add to Home Screen on iPhone), and "You're using the installed app" inside the app. From Deovandski/Deovandski (#292, #293), unchanged. | Settings menu (#1) |
| [TerminalScreen.astro](TerminalScreen.astro) | An old-school computer terminal (green on black, amber headings, scan lines, blinking cursor) that types its text out one character at a time, fast. Click or any key shows it all; reduced motion shows it all at once. From Deovandski-repo-template (#19, merged in #20), unchanged. | Stats for nerds (`/debug/`, #2) |
| [PixelLoader.astro](PixelLoader.astro) | A full-screen "one moment" cover while a page loads: a pixel-art sprite (PixelPet's shapes, drawn at build time) under a speech bubble. Lifts once the page's scripts and fonts are ready. From Deovandski/Deovandski (Deovandski#337), unchanged. | Every page: Peeta, "Please wait a sec" (#3) |

## PhotoViewer

```astro
---
import PhotoViewer from './reusable/PhotoViewer.astro';
---
<!-- once, at the end of the layout's <body> -->
<PhotoViewer />
```

| Prop | Default | |
|---|---|---|
| `label` | `"Photo"` | The dialog's name for screen readers. |

What opens in it, with no extra markup:
- **any `<img>` with alt text**; ‹ › step through the other visible pictures on the page, or in the nearest `[data-zoom-group]`;
- **links straight to an image file** (they open in the viewer instead of leaving the page);
- **gallery buttons**: `<button data-gallery="name" data-full="big.webp" data-alt="…" data-date="YYYY-MM-DD">`; ‹ › step through the same gallery.

It skips decorative pictures (`alt=""`), pictures inside links or buttons, the header and nav, maps,
pictures under 64px, and anything in `[data-no-zoom]`. `data-zoom` forces a picture on.

The caption is the alt text, then the date in the page's language: `data-date="YYYY-MM-DD"` or
`data-date-label`, else a `YYYY-MM-DD` at the start of the file name. The picture shown is `data-full`, else
the largest srcset size. Its button labels and the "Enlarge" word sit in its markup, so translations cover
them. Theme with `--photo-viewer-accent`, `--photo-viewer-bg`, `--photo-viewer-text`, `--photo-viewer-muted`
and `--photo-viewer-backdrop` (set in `src/styles/site.css`). Keyboard: Tab to a picture, then Enter or
Space; ← → move between pictures; Esc closes and returns focus.

## InstallApp

An "Install app" button for a site that's installable (a web app manifest and a service worker). The browser fires
`beforeinstallprompt` when the site can be installed; a tiny inline script keeps that event, and the button calls its
`prompt()`. When the browser can't install it right now, a short line says how: on Android, open the page in Chrome (links
opened from WhatsApp, Instagram or Gmail land in a viewer with no install option); on iPhone and iPad, Share → Add to
Home Screen; elsewhere, which browsers can. Inside the installed app it says so. Nothing is saved.

```astro
<InstallApp />
```

| Prop | Default | |
|---|---|---|
| `text` | | Replace any of its words: `install`, `installed`, `done`, `android`, `ios`, `other`. |

Theme with `--install-accent`, `--install-ink` and `--install-muted`.

## TerminalScreen

```astro
---
import TerminalScreen from './reusable/TerminalScreen.astro';
---
<TerminalScreen title="sysinfo" label="Build details">
  <div class="term-h">== CODE ==</div>
  <div class="term-row"><span class="term-k">Commit</span><span class="term-v">abc1234</span></div>
  <div class="term-gap"></div>
  <div class="term-hi">READY.</div>
</TerminalScreen>
```

Each direct child is one line, shown in order as its text is typed. To fill in values first, pass `wait` and fire
`terminal:start` on the element when ready (it fires `terminal:done` at the end). `terminal:start` again types it again.

| Prop | Default | |
|---|---|---|
| `label` | `"Terminal"` | What screen readers call it. |
| `title` | none | Text in a title bar with three dots; no bar without it. |
| `duration` | `1800` | About how long the whole text takes, in ms. Long texts type more characters per frame. |
| `wait` | `false` | Wait for `terminal:start` instead of starting by itself. |
| `class` | none | Extra class. |

Line classes: `.term-h` (amber heading), `.term-row` with `.term-k` and `.term-v` (key and value columns), `.term-dim`,
`.term-hi`, `.term-amber`, `.term-warn`, `.term-gap` (empty line), `.term-bar` and `.term-pre` (keep spaces). It is
always left to right and `translate="no"`. Theme with `--term-bg`, `--term-ink`, `--term-dim`, `--term-amber`,
`--term-warn`, `--term-font`, `--term-size`, `--term-size-phone`, `--term-key` and `--term-key-phone`.

## PixelLoader

```astro
---
import PixelLoader from './reusable/PixelLoader.astro';
import { PIXEL_PETS } from '../lib/pixelPets';
---
<PixelLoader shapes={PIXEL_PETS.peeta.shapes} text="Please wait a sec" label="Loading" />
```

| Prop | Default | |
|---|---|---|
| `shapes` | (required) | The sprite on a 32 × 32 grid, the same shapes `PixelPet` takes. |
| `text` | (required) | What the speech bubble says. |
| `label` | `Loading` | What screen readers hear while it shows. |
| `outline` | `#111` | The sprite's outline colour, or `none`. |

A full-screen cover shown while the page loads, so nobody sees it half laid out (#337). It lifts once the page's scripts
have run and its fonts are in (at most 1.5 s for fonts, 8 s in all), and never shows without JavaScript. The sprite is
turned into pixels at build time (no image file). Put it once, first in `<body>` (Base.astro does). Theming:
`--loader-bg`, `--loader-bubble`, `--loader-ink`, `--loader-px`. The sprite bobs and the dots blink only without
prefers-reduced-motion.

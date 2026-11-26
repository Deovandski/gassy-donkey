# Reusable components

Components here follow "Build reusable components" in CLAUDE.md: one `.astro` file each, no imports from the
site, everything in through props or data attributes, scoped styles themed with CSS custom properties.
Copy one into another repo as is.

| Component | What it is | Used on |
|---|---|---|
| [PhotoViewer.astro](PhotoViewer.astro) | The one photo viewer (lightbox) for a page: every content picture, gallery button and link to an image file opens in it, with its caption and date; ‹ › between pictures. From Deovandski/Deovandski, with translatable words and dates in the page's language. | Every page (in `Base.astro`) |
| [InstallApp.astro](InstallApp.astro) | An "Install app" button for an installable site (PWA): shown only when the browser can install it right now, otherwise a short line on how (open in Chrome on Android, Share → Add to Home Screen on iPhone), and "You're using the installed app" inside the app. From Deovandski/Deovandski (#292, #293), unchanged. | Settings menu (#1) |

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

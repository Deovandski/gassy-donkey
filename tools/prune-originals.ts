// Runs right after `astro build`, before tools/i18n.ts copies dist/ into _site/ (see "build" in package.json).
// Astro copies the full-size original of every imported picture into dist/_astro/, even when pages only show its
// resized copies. On the Deovandski site those originals (phone photos up to ~11 MB each) made the deploy 1.25 GB,
// past GitHub Pages' 1 GB limit (Deovandski/Deovandski#211). This deletes every picture in dist/_astro/ that no
// built page, script, stylesheet or text file mentions. The originals in src/ and public/ are never touched.
// The same as the Deovandski site's scripts/prune-originals.mjs. Node runs it directly: `node tools/prune-originals.ts`.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const DIST = path.join(ROOT, 'dist');
const ASSETS = path.join(DIST, '_astro');
const PICTURE = /\.(jpe?g|png|gif|webp|avif|heic|heif|tiff?)$/i;
const TEXT = /\.(html|js|mjs|css|json|md|txt|xml|svg|webmanifest)$/i;
const mb = (n: number): string => (n / 1e6).toFixed(n < 1e7 ? 1 : 0);

if (!fs.existsSync(DIST)) {
  console.error('No dist/ yet: run `npx astro build` first (or `npm run build`).');
  process.exit(2);
}

const walk = (dir: string): string[] =>
  fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(path.join(dir, e.name)) : [path.join(dir, e.name)]));
const size = (files: string[]): number => files.reduce((n, f) => n + fs.statSync(f).size, 0);

const files = walk(DIST);
const before = size(files);
const text = files.filter((f) => TEXT.test(f)).map((f) => fs.readFileSync(f, 'utf8')).join('\n');
// A picture counts as used if its file name appears in any text file, as is or URL-encoded
// (src, srcset, data-full for the photo viewer, CSS backgrounds, scripts).
const used = (name: string): boolean => text.includes(name) || text.includes(encodeURIComponent(name)) || text.includes(encodeURI(name));

let count = 0;
let removed = 0;
if (fs.existsSync(ASSETS)) {
  for (const f of walk(ASSETS)) {
    const name = path.relative(ASSETS, f).split(path.sep).join('/');
    if (!PICTURE.test(name) || used(name)) continue;
    removed += fs.statSync(f).size;
    fs.unlinkSync(f);
    count++;
  }
}
console.log(`prune-originals: removed ${count} unused picture${count === 1 ? '' : 's'} (${mb(removed)} MB); dist/ went from ${mb(before)} MB to ${mb(before - removed)} MB.`);

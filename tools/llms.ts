// Files for AI tools and search engines, written into _site/ after the translations (`npm run build` runs it last).
// The same idea as the Deovandski site's scripts/llms.mjs (Deovandski/Deovandski#150), for any repo made from the template.
//   _site/llms.txt            an index of the site, per https://llmstxt.org/: one line per page, linked to its Markdown twin
//   _site/<page>/index.md     the page's main content as Markdown (a "Markdown twin"), one per English page
//   _site/llms-full.txt       every page in one file
//   _site/sitemap.xml         every page (and every language that is translated enough to be indexed) and the files above
//   _site/robots.txt          only when the site sits at a domain root (base ""), and only if public/ doesn't ship one
// Why: some AI tools can't fetch github.io at all, search-based ones only see indexed pages, and fetchers skip
// hidden content, don't run JavaScript and cut off long files. Plain Markdown at a stable address avoids all of that.
//
// What goes into the Markdown: only <main>. The header, footer, Settings dialog and #ui-strings are left out, and so is
// anything hidden, aria-hidden="true", a form control or button, or marked data-llms-skip (for decorations whose
// text means nothing read aloud, like a clock's digits).
// Pages under a folder (a content collection, like notes/) get their own section in llms.txt.
// A page with <meta name="robots" content="noindex"> is left out of everything.
// Node runs this file directly (it strips the types): `node tools/llms.ts`.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseHTML } from 'linkedom';

type Doc = ReturnType<typeof parseHTML>['document'];
interface SiteConfig { site: string; base: string; languages: string[] }
interface Page { file: string; dir: string; url: string; md: string; title: string; description: string; body: string }

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const CONFIG: SiteConfig = JSON.parse(fs.readFileSync(path.join(ROOT, 'site.config.json'), 'utf8'));
const OUT = path.join(ROOT, '_site');
const STORE = path.join(ROOT, 'content', 'i18n');
const BASE = (CONFIG.base || '').replace(/\/$/, '');
const SITE_URL = CONFIG.site.replace(/\/$/, '') + BASE;   // "https://deovandski.github.io/gassy-donkey"
const FULL_WARN_BYTES = 200 * 1024;                       // past this, many readers cut llms-full.txt off

if (!fs.existsSync(OUT)) {
  console.error('No _site/ yet: run `npm run build` (astro build, then tools/i18n.ts build) first.');
  process.exit(2);
}

// ---------------------------------------------------------------- HTML -> Markdown

const SKIP_TAGS = new Set(['SCRIPT', 'STYLE', 'SVG', 'NOSCRIPT', 'TEMPLATE', 'DIALOG', 'BUTTON', 'INPUT', 'SELECT',
  'TEXTAREA', 'IFRAME', 'CANVAS', 'VIDEO', 'AUDIO', 'FORM']);
const BLOCKS = new Set(['P', 'DIV', 'SECTION', 'ARTICLE', 'HEADER', 'FOOTER', 'ASIDE', 'NAV', 'FIGURE', 'FIGCAPTION',
  'DETAILS', 'SUMMARY', 'TABLE', 'TR', 'DL', 'DT', 'DD', 'MAIN', 'ADDRESS']);

const skipped = (el: Element): boolean =>
  SKIP_TAGS.has(el.tagName) || el.hasAttribute('hidden') || el.hasAttribute('data-llms-skip') ||
  el.getAttribute('aria-hidden') === 'true';

const block = (s: string): string => (s.trim() ? `\n\n${s.trim()}\n\n` : '');

/** Child nodes -> Markdown. Sibling elements with no space between them (buttons in a row, a title and its blurb)
 *  still read as separate words. */
function join(nodes: NodeListOf<ChildNode>, pageUrl: string, depth: number): string {
  let out = '';
  let prevEl = false;
  for (const c of nodes) {
    const s = toMarkdown(c, pageUrl, depth);
    if (prevEl && c.nodeType === 1 && s && out && !/\s$/.test(out) && !/^\s/.test(s)) out += ' ';
    out += s;
    if (c.nodeType === 1 && s) prevEl = true; else if (s.trim()) prevEl = false;
  }
  return out;
}

/** Element -> Markdown. `pageUrl` makes relative links absolute; `depth` indents nested lists. */
function toMarkdown(node: Node, pageUrl: string, depth = 0): string {
  if (node.nodeType === 3) return (node.textContent ?? '').replace(/\s+/g, ' ');
  if (node.nodeType !== 1) return '';
  const el = node as Element;
  if (skipped(el)) return '';
  const kids = (d = depth): string => join(el.childNodes, pageUrl, d);
  const abs = (u: string): string => { try { return new URL(u, pageUrl).href; } catch { return u; } };
  const tag = el.tagName;

  const h = /^H([1-6])$/.exec(tag);
  if (h) return block(`${'#'.repeat(Number(h[1]))} ${kids().trim()}`);
  if (tag === 'UL' || tag === 'OL') {
    const items = [...el.children].filter((c) => c.tagName === 'LI' && !skipped(c));
    const lines = items.map((li, i) => {
      const text = join(li.childNodes, pageUrl, depth + 1).trim().replace(/\n{2,}/g, '\n');
      return `${'  '.repeat(depth)}${tag === 'OL' ? `${i + 1}.` : '-'} ${text}`;
    });
    return depth ? `\n${lines.join('\n')}` : block(lines.join('\n'));
  }
  if (tag === 'PRE') return block('```\n' + (el.textContent ?? '').replace(/\n$/, '') + '\n```');
  if (tag === 'BLOCKQUOTE') return block(kids().trim().split('\n').map((l) => `> ${l}`.trimEnd()).join('\n'));
  if (tag === 'HR') return block('---');
  if (tag === 'BR') return '\n';
  if (tag === 'CODE') return '`' + (el.textContent ?? '') + '`';
  if (tag === 'STRONG' || tag === 'B') { const t = kids().trim(); return t ? `**${t}**` : ''; }
  if (tag === 'EM' || tag === 'I') { const t = kids().trim(); return t ? `*${t}*` : ''; }
  if (tag === 'IMG') { const alt = el.getAttribute('alt')?.trim(); return alt ? `![${alt}](${abs(el.getAttribute('src') ?? '')})` : ''; }
  if (tag === 'A') {
    const label = kids().trim();
    const href = el.getAttribute('href');
    if (!label) return '';
    if (!href || href.startsWith('#') || href.startsWith('javascript:')) return label;
    return `[${label}](${abs(href)})`;
  }
  if (tag === 'TD' || tag === 'TH') return kids().trim() + ' · ';
  if (BLOCKS.has(tag)) return block(kids());
  return kids();
}

const tidy = (md: string): string =>
  md.split('\n').map((l) => l.trimEnd()).join('\n')
    .replace(/ · (\n|$)/g, '$1')       // table rows: no separator after the last cell
    .replace(/[ \t]+\n/g, '\n').replace(/\n{3,}/g, '\n\n').trim();

// ---------------------------------------------------------------- pages

/** Every index.html under dir, relative to it ("", "notes", "notes/first-note"). */
function pageDirs(dir: string, skipTop: Set<string>): string[] {
  return (fs.readdirSync(dir, { recursive: true }) as string[])
    .map((f) => f.split(path.sep).join('/'))
    .filter((f) => f === 'index.html' || f.endsWith('/index.html'))
    .map((f) => f.replace(/\/?index\.html$/, ''))
    .filter((d) => !skipTop.has(d.split('/')[0]))
    .sort();
}
const noindex = (doc: Doc): boolean => /noindex/i.test(doc.querySelector('meta[name="robots"]')?.getAttribute('content') ?? '');
const urlOf = (dir: string): string => `${SITE_URL}/${dir ? dir + '/' : ''}`;

const langCodes = fs.existsSync(STORE)
  ? fs.readdirSync(STORE).filter((d) => fs.existsSync(path.join(OUT, d, 'index.html')))
  : [];
const langSet = new Set(langCodes);

const pages: Page[] = [];
for (const dir of pageDirs(OUT, langSet)) {
  const file = path.join(OUT, dir, 'index.html');
  const { document } = parseHTML(fs.readFileSync(file, 'utf8'));
  if (noindex(document)) continue;
  const url = urlOf(dir);
  const main = document.querySelector('main');
  main?.querySelector('h1')?.remove(); // the twin's own heading is the page title
  pages.push({
    file, dir, url, md: `${url}index.md`,
    title: (document.querySelector('title')?.textContent ?? dir).trim(),
    description: (document.querySelector('meta[name="description"]')?.getAttribute('content') ?? '').trim(),
    body: main ? tidy(toMarkdown(main, url)) : '',
  });
}
if (!pages.length) { console.error('llms: no pages found in _site/'); process.exit(2); }

const home = pages.find((p) => p.dir === '') ?? pages[0];
const siteTitle = home.title;

// Translated languages that search engines are told about (tools/i18n.ts marks the others noindex).
const readyLangs = langCodes.filter((code) => {
  const { document } = parseHTML(fs.readFileSync(path.join(OUT, code, 'index.html'), 'utf8'));
  return !noindex(document);
}).sort((a, b) => (CONFIG.languages.indexOf(a) + 1 || 999) - (CONFIG.languages.indexOf(b) + 1 || 999));
const langName = (code: string): string => {
  try { return JSON.parse(fs.readFileSync(path.join(STORE, code, 'meta.json'), 'utf8')).name || code; } catch { return code; }
};

// ---------------------------------------------------------------- Markdown twins

const twinHeader = (p: Page): string[] => [
  `# ${p.title}`, '',
  ...(p.description ? [`> ${p.description}`] : []),
  `> Web page: ${p.url}`,
  `> Every page of ${siteTitle}: ${SITE_URL}/llms.txt`, '',
];
for (const p of pages) {
  fs.writeFileSync(path.join(path.dirname(p.file), 'index.md'), [...twinHeader(p), p.body, ''].join('\n'));
}

// ---------------------------------------------------------------- llms-full.txt

const full = [
  `# ${siteTitle}`, '',
  ...(home.description ? [`> ${home.description}`, ''] : []),
  `Every page of ${SITE_URL}/ as Markdown, one after another. The index is ${SITE_URL}/llms.txt.`, '',
  ...pages.flatMap((p) => [`## ${p.title}`, '', `URL: ${p.url}`, '', ...(p.description ? [p.description, ''] : []), p.body.replace(/^(#{1,5}) /gm, '#$1 '), '']),
].join('\n');
fs.writeFileSync(path.join(OUT, 'llms-full.txt'), full);
const fullBytes = Buffer.byteLength(full);
const fullKb = Math.ceil(fullBytes / 1024);

// ---------------------------------------------------------------- llms.txt

/** Pages under a folder with its own index (notes/first-note under notes/) form that folder's section. */
const sectionOf = (p: Page): string | null => {
  const parts = p.dir.split('/');
  return parts.length > 1 ? parts[0] : null;
};
const entry = (p: Page): string => `- [${p.title}](${p.md})${p.description ? `: ${p.description}` : ''}`;
const sections = new Map<string, Page[]>();
for (const p of pages) {
  const s = sectionOf(p);
  if (s) sections.set(s, [...(sections.get(s) ?? []), p]);
}
const sectionTitle = (folder: string): string => {
  const idx = pages.find((p) => p.dir === folder);
  const t = idx?.title.split(' · ')[0].trim();
  return t || folder.charAt(0).toUpperCase() + folder.slice(1).replace(/-/g, ' ');
};

const index = [
  `# ${siteTitle}`, '',
  ...(home.description ? [`> ${home.description}`, ''] : []),
  `Web site: ${SITE_URL}/. Every page below links to its Markdown copy; on the site, the same page is at the address without index.md.`,
  ...(readyLangs.length ? ['', `Also published in: ${readyLangs.map((c) => `${langName(c)} (${SITE_URL}/${c}/)`).join(', ')}. English is the original.`] : []),
  '',
  '## Pages', '',
  ...pages.filter((p) => !sectionOf(p)).map(entry),
  '',
  ...[...sections].flatMap(([folder, list]) => [`## ${sectionTitle(folder)}`, '', ...list.map(entry), '']),
  '## Optional', '',
  `- [Every page in one file](${SITE_URL}/llms-full.txt): ${fullKb} KB` +
    (fullBytes > FULL_WARN_BYTES ? '. Long: some readers cut it off, so prefer the pages above.' : ''),
  `- [Sitemap](${SITE_URL}/sitemap.xml)`,
  '',
];
fs.writeFileSync(path.join(OUT, 'llms.txt'), index.join('\n'));

// ---------------------------------------------------------------- sitemap.xml and robots.txt

const indexed: string[] = [];
for (const dir of pageDirs(OUT, new Set())) {
  const { document } = parseHTML(fs.readFileSync(path.join(OUT, dir, 'index.html'), 'utf8'));
  if (!noindex(document)) indexed.push(urlOf(dir));
}
const urls = [...indexed, `${SITE_URL}/llms.txt`, `${SITE_URL}/llms-full.txt`, ...pages.map((p) => p.md)];
const xml = (s: string): string => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
fs.writeFileSync(path.join(OUT, 'sitemap.xml'), [
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
  ...urls.map((u) => `  <url><loc>${xml(u)}</loc></url>`),
  '</urlset>', '',
].join('\n'));

// Crawlers only read robots.txt at the domain root, so a project site (base "/repo") can't use one: submit
// sitemap.xml in Google Search Console and Bing Webmaster Tools instead (see README.md).
let robots = 'not written (the site is under a base path)';
if (!BASE) {
  const p = path.join(OUT, 'robots.txt');
  if (fs.existsSync(p)) robots = 'kept the one from public/';
  else { fs.writeFileSync(p, `User-agent: *\nAllow: /\n\nSitemap: ${SITE_URL}/sitemap.xml\n`); robots = 'written'; }
}

console.log(`llms.txt: ${pages.length} pages, ${sections.size} section(s) · llms-full.txt: ${fullKb} KB · ` +
  `${pages.length} Markdown twins · sitemap.xml: ${urls.length} URLs · robots.txt: ${robots}`);
if (fullBytes > FULL_WARN_BYTES) console.warn(`llms-full.txt is ${fullKb} KB; llms.txt tells readers to prefer the per-page files.`);

// First step in a repo made from the template: `npm run init -- <repo-name> [--name "Display name"]`.
// Replaces the REPO-NAME placeholder in every text file (links, base path, storage key), optionally the
// "Project name" placeholder, then re-keys the stored translations so they still match the new English.
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const SKIP_DIRS = new Set(['.git', 'node_modules', 'dist', '_site', '.astro']);
const SKIP_FILES = new Set(['README.md', 'package-lock.json', 'tools/init.ts']);
const TEXT = /\.(astro|ts|mjs|js|json|md|css|html|yml|yaml|svg|txt)$|^(LICENSE|CLAUDE\.md)$/;

const args = process.argv.slice(2);
const repo = args.find((a) => !a.startsWith('--'));
const nameAt = args.indexOf('--name');
const display = nameAt >= 0 ? args[nameAt + 1] : undefined;
if (!repo || !/^[A-Za-z0-9._-]+$/.test(repo)) {
  console.error('usage: npm run init -- <repo-name> [--name "Display name"]');
  process.exit(2);
}

function* files(dir: string): Generator<string> {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (SKIP_DIRS.has(e.name)) continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) yield* files(p);
    else if (TEXT.test(e.name)) yield p;
  }
}

let changed = 0;
for (const p of files(ROOT)) {
  const rel = path.relative(ROOT, p).split(path.sep).join('/');
  if (SKIP_FILES.has(rel)) continue;
  const before = fs.readFileSync(p, 'utf8');
  let after = before.replaceAll('REPO-NAME', repo);
  if (display && rel.startsWith('src/')) after = after.replaceAll('Project name', display);
  if (after !== before) { fs.writeFileSync(p, after); changed++; console.log(`  ${rel}`); }
}
console.log(`Replaced the placeholders in ${changed} files.`);
execFileSync(process.execPath, [path.join(ROOT, 'tools', 'i18n.ts'), 'rehash'], { stdio: 'inherit' });
console.log('Next: rewrite src/pages/ with the project\'s content, then `npm run check` and `npm run build`. See README.md.');

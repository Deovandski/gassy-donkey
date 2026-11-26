// The Settings menu (gear, top right): language and text size, remembered in this browser.
// The storage key is STORAGE_KEY in src/lib/site.ts, put on <html data-store> by Base.astro (its inline script reads
// the same attribute). Add new settings to the same object.
interface Saved { lang?: string; size?: number }

const root = document.documentElement;
const KEY = root.dataset.store ?? '';
const BASE = root.dataset.base ?? '';
const LANG = root.dataset.lang ?? '';  // "" on English pages, "ja", "pt", ... on translated ones

function load(): Saved {
  try { return JSON.parse(localStorage.getItem(KEY) || '{}') as Saved; } catch { return {}; }
}
function save(patch: Saved): void {
  try { localStorage.setItem(KEY, JSON.stringify({ ...load(), ...patch })); } catch { /* private mode: lasts for this page only */ }
}

/** The same page in another language: /gassy-donkey/ja/notes/ <-> /gassy-donkey/notes/. */
function langHref(code: string): string {
  let path = location.pathname.slice(BASE.length);
  if (LANG && path.startsWith(`/${LANG}/`)) path = path.slice(LANG.length + 1);
  return BASE + (code === 'en' ? '' : `/${code}`) + path + location.hash;
}
function goLang(code: string): void {
  save({ lang: code });
  location.href = langHref(code);
}

const dialog = document.querySelector<HTMLDialogElement>('#site-settings');
document.querySelector('#gear')?.addEventListener('click', () => dialog?.showModal());

// The banner's "English" link (and anything with data-lang-switch) remembers the choice too.
document.addEventListener('click', (e) => {
  const a = (e.target as Element | null)?.closest<HTMLElement>('[data-lang-switch]');
  if (a?.dataset.langSwitch) { e.preventDefault(); goLang(a.dataset.langSwitch); }
});

const langSelect = dialog?.querySelector<HTMLSelectElement>('[data-setting="lang"]');
if (langSelect) {
  langSelect.value = LANG || 'en';
  langSelect.addEventListener('change', () => goLang(langSelect.value));
}
const sizeInput = dialog?.querySelector<HTMLInputElement>('[data-setting="size"]');
if (sizeInput) {
  sizeInput.value = String(load().size ?? 17);
  sizeInput.addEventListener('input', () => {
    root.style.setProperty('--scale', String(Number(sizeInput.value) / 17));
    save({ size: Number(sizeInput.value) });
  });
}

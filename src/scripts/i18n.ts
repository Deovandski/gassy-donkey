// Text a script shows comes from #ui-strings in the page (translated with it), never from JavaScript.
// Put <span data-k="key">English</span> in a page's "ui-strings" slot, then call t("key").
export function t(key: string): string {
  const el = document.querySelector<HTMLElement>(`#ui-strings [data-k="${CSS.escape(key)}"]`);
  return el?.textContent?.trim() || key;
}

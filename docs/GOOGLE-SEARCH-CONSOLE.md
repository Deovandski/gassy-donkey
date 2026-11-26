# Getting the site on Google: Search Console

New sites usually aren't indexed, and search-based AI assistants only see indexed pages. A project site
(under `/<repo>/`) can't point to its sitemap from a `robots.txt`, so telling Google about it in
Search Console is the way it gets found. Deovandski/Deovandski did this in #214 (PR #215).

## 1. Add the site (Deo)
Open [Google Search Console](https://search.google.com/search-console) › **Add property**, and pick one:

- **URL prefix**, for a site on GitHub Pages' address: `https://deovandski.github.io/<repo>/`.
  Choose **HTML file** as the way to verify and download the `google….html` file it gives you.
- **Domain**, for a custom domain (`example.com`): Google gives a **DNS TXT record** to add at the
  domain registrar. That one record covers `www`, the bare domain, and http/https. No file goes in the
  repo; skip to step 3 once the record is in.

## 2. Add the file to the repo (Claude or Deo)
- Put Google's file in `public/`, **unchanged** (same name, same one line; don't reformat it or add a
  newline). Astro copies `public/` as is, so it's served at `https://deovandski.github.io/<repo>/google….html`.
- Nothing else touches it: `tools/i18n.ts` only translates `index.html` pages, `tools/llms.ts` only lists
  `index.html` pages in `sitemap.xml` and `llms.txt`, and translated copies (`/ja/` …) don't get one.
- Check after `npm run build`: `_site/google….html` is identical to Google's file.
- **Never remove it**, even after verification succeeds. Search Console re-checks it from time to time,
  and removing it un-verifies the site. Say so in the project's README or CLAUDE.md where the file is listed.

## 3. Verify and send the sitemap (Deo)
1. Once the PR merges and the Website workflow finishes, open the file's address; it should show its one line.
2. Press **Verify** in Search Console.
3. In **Sitemaps**, submit `https://deovandski.github.io/<repo>/sitemap.xml` (written by `tools/llms.ts` on
   every build). Do the same in [Bing Webmaster Tools](https://www.bing.com/webmasters), which can import the
   site from Search Console.

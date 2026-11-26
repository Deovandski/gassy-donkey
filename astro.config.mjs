// Astro settings. The address and base path come from site.config.json, which tools/i18n.ts reads too.
import { defineConfig } from 'astro/config';
import cfg from './site.config.json' with { type: 'json' };

export default defineConfig({
  site: cfg.site,
  base: cfg.base || '/',
  trailingSlash: 'always',
  build: { format: 'directory' }, // every page is <path>/index.html, so translated copies sit at /<lang>/<path>/
});

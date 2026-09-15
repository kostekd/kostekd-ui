# kostekd-ui

The Nx workspace for [kostekd.com](https://kostekd.com). The Astro application lives in
`web/kostekd-ui`.

**Live site:** [kostekd.com](https://kostekd.com)

![Astro Sienna home page in dark and light themes](.github/assets/preview.png)

## Features

- Astro 7 with content collections (posts and pages, both validated by Zod)
- MDX support — embed Astro/JSX components, imports, and JS expressions inside posts
- Light and dark mode with a CSS-only theme toggle
- Self-hosted serif body font ([Newsreader](https://github.com/productiontype/Newsreader)) and mono (JetBrains Mono)
- Code blocks via [astro-expressive-code](https://expressive-code.com): themes, copy button, terminal frames, line
  highlighting
- Math via KaTeX (`$inline$` and `$$display$$`)
- Custom containers (`:::note`, `:::tip`, `:::caution`)
- Tag pages — post tags link to per-tag archives, with a browsable `/tags/` index
- Per-post OG images generated at build time (Satori + resvg)
- RSS feed, sitemap, robots.txt, web manifest
- Optional [Giscus](https://giscus.app) comments with custom matched themes
- Optional GA4 and Goatcounter analytics, both loaded via [Partytown](https://partytown.qwik.dev/) so they run on a
  worker thread
- Optional [webmentions](https://webmention.io), fetched at build and cached locally
- Perfect Lighthouse scores (Performance, Accessibility, Best Practices, SEO)

## Quick start

```sh
pnpm install
pnpm dev
```

Open http://localhost:4321.

## Commands

| Command        | What it does                                 |
|----------------|----------------------------------------------|
| `pnpm dev`     | Start the dev server with HMR                |
| `pnpm build`   | Type-check, build, and run Pagefind indexing |
| `pnpm preview` | Preview the production build locally         |
| `pnpm format`  | Run Biome and Prettier                       |
| `pnpm lint`    | Lint with Biome                              |

Root commands delegate to the `kostekd-ui` Nx project. You can also run targets explicitly:

```sh
pnpm nx run kostekd-ui:dev
pnpm nx run kostekd-ui:lint
pnpm nx run kostekd-ui:build
```

## Configuration

Most personalisation happens in two files.

**`web/kostekd-ui/src/site.config.ts`** holds author, profile, comments, analytics, and webmentions.
Every field in `profile` is optional. Leave any of `email`, `github`, `linkedin`, `employer`, `alumni`,
or `avatar` undefined and the corresponding link is hidden site-wide. Same for `comments` and
`analytics`: undefined means the script never loads.

**`web/kostekd-ui/astro.config.ts`** is where you set `site` to your final domain (used for canonical
URLs, sitemap, RSS, and OG image URLs). The base path is handled automatically — see
[Deploying](#deploying); you normally don't touch it.

Replace these assets in `web/kostekd-ui/public/`:

- `icon.png` (512×512). Drives the favicon and the auto-generated `apple-touch-icon`, `icon-192`, and `icon-512` PWA
  manifest icons.
- `social-card.png` (1200×630). Fallback OG image, used when a post doesn't have its own. The default is a placeholder
  you can swap.
- `avatar.png` (optional). Referenced from `siteConfig.profile.avatar`, used in the About page's structured data and any
  avatar slot you add.

### Per-post OG images

Every post gets its own 1200×630 OG image generated at build time by [Satori](https://github.com/vercel/satori). The
markup lives in `web/kostekd-ui/src/pages/og-image/[...slug].png.ts`. Tweak it once and every post's
card updates on the next build. To skip the generated image and point a post at your own, set
`ogImage: "/path/to/image.png"` in the post's frontmatter.

## Writing posts

Posts live in `web/kostekd-ui/src/content/post/` as `.md` or `.mdx` files. The filename becomes the
slug.

```yaml
---
title: "Your post title"
publishDate: 2026-01-12
description: "One-sentence summary used in cards, social previews, and meta tags."
tags: [ tag-one, tag-two ]
# updatedDate: 2026-02-01     # optional, shown as "Updated …"
# draft: true                  # excludes the post from production builds
# coverImage:
#   src: ./_assets/cover.png
#   alt: "Description for screen readers"
---
```

The about page is also markdown, at `web/kostekd-ui/src/content/page/about.md`. Showcase entries are
typed objects in `web/kostekd-ui/src/data/showcase.ts`; empty the array and the Showcase tab is
hidden automatically.

## Project layout

```
web/
  kostekd-ui/
    package.json        # app scripts and dependencies; inferred Nx project
    astro.config.ts
    src/                # pages, content, components, styles, and plugins
    public/             # static assets served at site root
nx.json                 # workspace layout and target defaults
package.json            # root Nx command aliases
pnpm-workspace.yaml
```

## Theming

Design tokens are CSS variables at the top of `web/kostekd-ui/src/styles/global.css`: accent colour,
hairlines, surfaces, fonts. The light and dark variants are gated by `[data-theme="light"]` and
`[data-theme="dark"]` on the `<html>` element, so swapping them is a single re-render with no script.

Code-block themes are configured separately in `expressiveCodeOptions` in `site.config.ts` (defaults: `min-light` and
`min-dark`).

## Deploying

The app uses Astro's standalone Node adapter. `pnpm build` creates the production server under
`web/kostekd-ui/dist/server/entry.mjs` and Pagefind indexes the generated client pages.

Pull requests verify the Nx lint/build targets and the production Docker image. Merges to `main`
build and push `ghcr.io/kostekd/kostekd-ui`, then the deploy workflow replaces the running
`kostekd-ui` container on the VPS.

### Base path

Defaults to root (`/`). The whole site (links, assets, feeds, OG/canonical, manifest, Markdown links)
is base-aware. For a subpath deployment, build with `BASE_PATH=/sub pnpm build`.

## Pulling theme updates

To keep tracking upstream changes after you've forked, add this repo as a second remote:

```sh
git remote add theme https://github.com/anjay-goel/astro-sienna.git
git fetch theme
git merge theme/main --allow-unrelated-histories
```

Use `.gitattributes` with a `merge=ours` driver on personal-content paths (e.g.
`web/kostekd-ui/src/content/post/*`, `web/kostekd-ui/src/site.config.ts`,
`web/kostekd-ui/public/avatar.png`) to keep your changes through the merge.

## Credits

Originally forked from [astro-theme-cactus](https://github.com/chrismwilliams/astro-theme-cactus)
by [Chris Williams](https://github.com/chrismwilliams), then heavily revamped into its current form.

## License

[MIT](./LICENSE).

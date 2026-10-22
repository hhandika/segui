# SEGUL Website

The SEGUL documentation and website, built with [Astro](https://astro.build/) and [Starlight](https://starlight.astro.build/), and managed with [Bun](https://bun.sh/).

## Quick start

Install dependencies:

```bash
bun install
```

Run the development server with hot reload:

```bash
bun run dev
```

Check types and build the static site into `dist/`:

```bash
bun run check
bun run build
```

Preview the production build:

```bash
bun run preview
```

## Project structure

- `src/content/docs/docs/`: Starlight documentation pages, served under `/docs/`.
- `src/pages/`: the landing (`index.astro`), get started, and about pages, styled with Tailwind. `src/layouts/Layout.astro` and `src/components/Navbar.astro` frame them.
- `src/data/site.ts`: shared content for those pages, such as the tool list and citation.
- `src/components/`: Astro components.
- `src/assets/` and `public/`: images and static files.
- `astro.config.mjs`: site configuration, sidebar, and redirects from former Docusaurus URLs.

See the [documentation build guide](https://segul.app/docs/advance-guides/build-docs/) for details.

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

- `src/content/docs/docs/`: documentation pages, served under `/docs/`.
- `src/content/docs/index.mdx`: the landing page.
- `src/content/blog/`: news posts named `YYYY-MM-DD-name.md`, served at `/blog/YYYY/MM/DD/name/`.
- `src/components/`: Astro components.
- `src/assets/` and `public/`: images and static files.
- `astro.config.mjs`: site configuration, sidebar, and redirects from former Docusaurus URLs.

See the [documentation build guide](https://segul.app/docs/advance-guides/build-docs/) for details.

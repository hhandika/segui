---
title: Building SEGUL Documentation
description: Guides on building SEGUL documentation.
sidebar:
  order: 3
---

SEGUL documentation is built using [Astro](https://astro.build/) and [Starlight](https://starlight.astro.build/), and deployed using [Vercel](https://vercel.com/). The documentation is written in Markdown and MDX. We use [Bun](https://bun.sh/) to manage dependencies and run scripts.

## Prerequisites

- [Bun](https://bun.sh/)
- [Git](https://git-scm.com/downloads)
- [GH CLI (recommended)](https://cli.github.com/)

## Clone the repository

```bash
gh repo clone hhandika/segui
```

Using git:

```bash
git clone https://github.com/hhandika/segui.git
```

## Install dependencies

Install Bun:

```bash
curl -fsSL https://bun.sh/install | bash
```

On Windows, use PowerShell:

```powershell
powershell -c "irm bun.sh/install.ps1 | iex"
```

Change directory to the website folder:

```bash
cd segui/website
```

Install the website dependencies:

```bash
bun install
```

## Run the website

To run the website locally with hot reload, use the following command:

```bash
bun run dev
```

The website will be available at `http://localhost:4321/`.

## Build the website

Check types and build the static site into `dist/`:

```bash
bun run check
bun run build
```

Preview the production build locally:

```bash
bun run preview
```

## Project structure

- `src/content/docs/docs/`: documentation pages. The folder structure maps to the URL, for example `src/content/docs/docs/cli-usage/align-concat.md` is served at `/docs/cli-usage/align-concat/`.
- `src/pages/`: the landing (`index.astro`), get started, and about pages, styled with Tailwind. `src/layouts/Layout.astro` and `src/components/Navbar.astro` frame them.
- `src/data/site.ts`: shared content for those pages, such as the tool list and citation.
- `src/components/`: Astro components used by pages.
- `src/assets/` and `public/`: images and static files.
- `astro.config.mjs`: site configuration, including the sidebar and redirects.

Each page needs a `title` in its frontmatter. Use `sidebar.order` to order pages within a sidebar group, and use Starlight [asides](https://starlight.astro.build/guides/authoring-content/#asides) (`:::note`, `:::tip`, `:::caution`, and `:::danger`) for callouts.

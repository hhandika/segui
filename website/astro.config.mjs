// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import tailwindcss from "@tailwindcss/vite";

// https://astro.build/config
export default defineConfig({
  site: "https://segul.app",
  // Keep links from the former Docusaurus site working.
  redirects: {
    "/docs": "/docs/intro/",
    "/blog": "/",
    "/blog/2023/07/08/updates": "/",
    "/docs/category/installation": "/docs/installation/intro/",
    "/docs/category/gui-usages": "/docs/gui-usage/intro/",
    "/docs/category/cli-usages": "/docs/cli-usage/intro/",
    "/docs/category/api-usages": "/docs/api-usage/",
    "/docs/category/python": "/docs/api-usage/python/intro/",
    "/docs/category/advanced-guides": "/docs/advance-guides/architecture/",
    "/docs/category/tutorials": "/docs/tutorials/tutorial-1/",
  },
  integrations: [
    starlight({
      title: "SEGUL",
      description:
        "SEGUL is an ultrafast, memory-efficient, and mobile-friendly phylogenomic tool.",
      logo: {
        src: "./src/assets/logo.svg",
      },
      favicon: "/favicon.ico",
      head: [
        {
          tag: "link",
          attrs: { rel: "icon", type: "image/svg+xml", href: "/logo.svg" },
        },
      ],
      customCss: ["./src/styles/global.css"],
      components: {
        Footer: "./src/components/Footer.astro",
      },
      editLink: {
        baseUrl: "https://github.com/hhandika/segui/edit/main/website/",
      },
      lastUpdated: true,
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/hhandika/segul",
        },
      ],
      sidebar: [
        { label: "Introduction", slug: "docs/intro" },
        { label: "Quick Start", slug: "docs/quick_start" },
        { label: "CLI vs GUI", slug: "docs/cli_gui" },
        { label: "Features", slug: "docs/features" },
        {
          label: "Installation",
          collapsed: true,
          items: [{ autogenerate: { directory: "docs/installation" } }],
        },
        {
          label: "GUI Usages",
          collapsed: true,
          items: [{ autogenerate: { directory: "docs/gui-usage" } }],
        },
        {
          label: "CLI Usages",
          collapsed: true,
          items: [{ autogenerate: { directory: "docs/cli-usage" } }],
        },
        {
          label: "API Usages",
          collapsed: true,
          items: [
            "docs/api-usage",
            {
              label: "Python",
              collapsed: true,
              items: [{ autogenerate: { directory: "docs/api-usage/python" } }],
            },
            "docs/api-usage/rust-api",
            "docs/api-usage/r-api",
          ],
        },
        {
          label: "Advanced Guides",
          collapsed: true,
          items: [{ autogenerate: { directory: "docs/advance-guides" } }],
        },
        {
          label: "Tutorials",
          collapsed: true,
          items: [{ autogenerate: { directory: "docs/tutorials" } }],
        },
        { label: "Support", slug: "docs/support" },
        { label: "Terms and Conditions", slug: "docs/terms" },
        { label: "Privacy Policy", slug: "docs/privacy" },
      ],
    }),
  ],
  vite: {
    plugins: [tailwindcss()],
  },
});

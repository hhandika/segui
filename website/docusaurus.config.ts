import { themes as prismThemes } from "prism-react-renderer";
import type { Config } from "@docusaurus/types";
import type * as Preset from "@docusaurus/preset-classic";

const config: Config = {
  title: "SEGUL",
  tagline: "An ultrafast and mobile-friendly phylogenomic tool",
  favicon: "img/favicon.ico",
  url: "https://segul.app",
  baseUrl: "/",
  organizationName: "hhandika",
  projectName: "segul",
  onBrokenLinks: "throw",

  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  i18n: {
    defaultLocale: "en",
    locales: ["en"],
  },

  presets: [
    [
      "classic",
      {
        docs: {
          sidebarPath: "./sidebars.ts",
          editUrl: "https://github.com/hhandika/segui/tree/main/website",
        },
        blog: {
          showReadingTime: true,
        },
        theme: {
          customCss: "./src/css/custom.css",
        },
      } satisfies Preset.Options,
    ],
  ],

  plugins: ["./src/plugins/tailwind.config.ts"],

  themeConfig: {
    image: "img/docusaurus-social-card.jpg",
    navbar: {
      title: "SEGUL",
      logo: {
        alt: "SEGUL Logo",
        src: "img/logo.svg",
      },
      items: [
        {
          type: "docSidebar",
          sidebarId: "docsSidebar",
          position: "left",
          label: "Docs",
        },
        {
          to: "/blog",
          label: "News",
          position: "left",
        },
        {
          href: "https://github.com/hhandika/segul",
          label: "GitHub",
          position: "right",
        },
      ],
    },
    footer: {
      style: "light",
      copyright: `Copyright © ${new Date().getFullYear()} H. Handika & J. A. Esselstyn.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;

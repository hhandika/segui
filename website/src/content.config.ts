import { defineCollection } from "astro:content";
import { glob } from "astro/loaders";
import { z } from "astro/zod";
import { docsLoader } from "@astrojs/starlight/loaders";
import { docsSchema } from "@astrojs/starlight/schema";

export const collections = {
  docs: defineCollection({ loader: docsLoader(), schema: docsSchema() }),
  blog: defineCollection({
    loader: glob({ pattern: "**/*.md", base: "./src/content/blog" }),
    schema: z.object({
      title: z.string(),
      date: z.coerce.date(),
      description: z.string(),
      /// Keys from `src/data/authors.ts`.
      authors: z.union([z.string(), z.string().array()]).default([]),
      tags: z.string().array().default([]),
    }),
  }),
};

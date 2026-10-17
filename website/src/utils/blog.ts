import { getCollection, type CollectionEntry } from "astro:content";
import { authors } from "../data/authors";

export type BlogPost = CollectionEntry<"blog">;

/// Returns posts, newest first.
export async function getPosts(): Promise<BlogPost[]> {
  const posts = await getCollection("blog");
  return posts.sort((a, b) => b.data.date.getTime() - a.data.date.getTime());
}

/// Builds the Docusaurus-compatible route `YYYY/MM/DD/name` from `YYYY-MM-DD-name`.
export function postSlug(post: BlogPost): string {
  const match = post.id.match(/^(\d{4})-(\d{2})-(\d{2})-(.+)$/);
  return match ? `${match[1]}/${match[2]}/${match[3]}/${match[4]}` : post.id;
}

export function postAuthors(post: BlogPost) {
  const keys = Array.isArray(post.data.authors) ? post.data.authors : [post.data.authors];
  return keys.map((key) => authors[key] ?? { name: key, title: "", url: "" });
}

export function formatDate(date: Date): string {
  return date.toLocaleDateString("en-US", { dateStyle: "long", timeZone: "UTC" });
}

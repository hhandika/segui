/// Usage guides for each feature, per interface. An empty list means the
/// interface does not support the feature yet.

export interface GuideLink {
  href: string;
  /// Distinguishes several guides for one interface, such as reads and contigs.
  label?: string;
}

export interface FeatureGuides {
  gui: GuideLink[];
  cli: GuideLink[];
  python: GuideLink[];
}

export const interfaces = [
  { key: "gui", name: "GUI", icon: "laptop" },
  { key: "cli", name: "CLI", icon: "seti:shell" },
  { key: "python", name: "Python", icon: "seti:python" },
] as const;

const gui = (page: string): GuideLink[] => [{ href: `/docs/gui-usage/${page}/` }];
const cli = (page: string): GuideLink[] => [{ href: `/docs/cli-usage/${page}/` }];
const python = (page: string): GuideLink[] => [{ href: `/docs/api-usage/python/${page}/` }];
const none: GuideLink[] = [];

export const featureGuides = {
  "align-concat": { gui: gui("align-concat"), cli: cli("align-concat"), python: python("align_concat") },
  "align-convert": { gui: gui("align-convert"), cli: cli("align-convert"), python: python("align_convert") },
  "align-distance": { gui: gui("align-distance"), cli: cli("align-distance"), python: none },
  "align-filter": { gui: gui("align-filter"), cli: cli("align-filter"), python: python("align_filter") },
  "align-partition": {
    gui: gui("align-partition"),
    cli: cli("align-partition"),
    python: python("align_partition"),
  },
  "align-split": { gui: gui("align-split"), cli: cli("align-split"), python: python("align_split") },
  "align-summary": { gui: gui("align-summary"), cli: cli("align-summary"), python: python("align_summary") },
  "genomic-summary": {
    gui: [
      { label: "reads", href: "/docs/gui-usage/genomic/#sequence-read-summary-statistics" },
      { label: "contigs", href: "/docs/gui-usage/genomic/#contig-summary-statistics" },
    ],
    cli: [
      { label: "reads", href: "/docs/cli-usage/genomic-summary/#raw-reads" },
      { label: "contigs", href: "/docs/cli-usage/genomic-summary/#contiguous-sequences" },
    ],
    python: [
      { label: "reads", href: "/docs/api-usage/python/genomic_summary/#genomic-fastq-read-summary" },
      {
        label: "contigs",
        href: "/docs/api-usage/python/genomic_summary/#genomic-contiguous-sequence-summary",
      },
    ],
  },
  "sequence-id": { gui: gui("sequence-id"), cli: cli("sequence-id"), python: python("sequence_id") },
  "sequence-map": { gui: gui("sequence-id-map"), cli: cli("sequence-map"), python: python("sequence_id") },
  "sequence-rename": { gui: gui("sequence-rename"), cli: cli("sequence-rename"), python: none },
  "sequence-extract": {
    gui: gui("sequence-extract"),
    cli: cli("sequence-extract"),
    python: python("sequence_extract"),
  },
  "sequence-filter": { gui: gui("sequence-filter"), cli: cli("sequence-filter"), python: none },
  "sequence-remove": {
    gui: gui("sequence-remove"),
    cli: cli("sequence-remove"),
    python: python("sequence_remove"),
  },
  "sequence-translate": {
    gui: gui("sequence-translate"),
    cli: cli("sequence-translate"),
    python: python("sequence_translation"),
  },
  "sequence-transpose": {
    gui: gui("sequence-transpose"),
    cli: cli("sequence-transpose"),
    python: none,
  },
} satisfies Record<string, FeatureGuides>;

export type Feature = keyof typeof featureGuides;

/// Shared content for the landing, get started, and about pages.
/// Tool names and descriptions match `lib/services/home_features.dart` in SEGUI.
import concatenate from "../assets/icons/concatenate_outlined.svg";
import convert from "../assets/icons/convert_outlined.svg";
import filter from "../assets/icons/filter_outlined.svg";
import partition from "../assets/icons/partition_outlined.svg";
import split from "../assets/icons/split_outlined.svg";
import alignmentSummary from "../assets/icons/alignment_summary_outlined.svg";
import readSummary from "../assets/icons/read_summary_outlined.svg";
import contigSummary from "../assets/icons/contig_summary_outlined.svg";
import extract from "../assets/icons/extract_outlined.svg";
import extractId from "../assets/icons/extract_id_outlined.svg";
import remove from "../assets/icons/remove_outlined.svg";
import rename from "../assets/icons/rename_outlined.svg";
import translate from "../assets/icons/translate_outlined.svg";
import distance from "../assets/icons/distance_outlined.svg";
import trim from "../assets/icons/trim_outlined.svg";
import unalign from "../assets/icons/unalign_outlined.svg";
import add from "../assets/icons/add_outlined.svg";
import sequenceFilter from "../assets/icons/sequence_filter_outlined.svg";
import transpose from "../assets/icons/transpose_outlined.svg";
import mafConvert from "../assets/icons/maf_convert_outlined.svg";
import mafSummary from "../assets/icons/maf_summary_outlined.svg";
import genomics from "../assets/icons/genomics_outlined.svg";
import alignments from "../assets/icons/alignments_outlined.svg";
import sequences from "../assets/icons/sequences_outlined.svg";
import readQualityScreenshot from "../assets/news/segui-android-read-quality.webp";
import desktopViewerScreenshot from "../assets/showcase/segui-desktop-alignment.webp";
import cliViewerScreenshot from "../assets/showcase/segul-cli-alignment.webp";
import desktopSummaryScreenshot from "../assets/showcase/segui-desktop-summary.webp";
import cliSummaryScreenshot from "../assets/showcase/segul-cli-summary.webp";
import pythonSummaryChart from "../assets/charts/python/align-completeness.webp";
import pythonDistanceChart from "../assets/charts/python/distance-group-mean.webp";
import phoneAlignmentViewer from "../assets/screenshots/gui/viewer-alignment-small.webp";
import phoneReadReport from "../assets/screenshots/gui/genomic-read-report-small.webp";
import phoneAlignmentReport from "../assets/screenshots/gui/align-summary-report-small.webp";

export const docsPath = "/docs/intro/";

export const navItems = [
  { path: "/", label: "Home" },
  { path: "/get-started", label: "Get Started" },
  { path: docsPath, label: "Docs" },
  { path: "/about", label: "About" },
];
export const githubUrl = "https://github.com/hhandika/segul";

export const tagline = "An ultrafast and mobile-friendly genomic toolkit";

export const summary =
  "SEGUL prepares genomic datasets: concatenate, convert, filter, split, and " +
  "summarize thousands of loci in seconds, on anything from a phone to a computing cluster.";

export const categories = [
  {
    key: "alignment",
    label: "Alignments",
    description: "Multi-locus alignment matrices",
    icon: alignments,
    docs: "/docs/gui-usage/align-concat/",
  },
  {
    key: "sequence",
    label: "Sequences",
    description: "Samples and IDs inside alignments",
    icon: sequences,
    docs: "/docs/gui-usage/sequence-extract/",
  },
  {
    key: "genomics",
    label: "Genomics",
    description: "Raw reads and assemblies",
    icon: genomics,
    docs: "/docs/gui-usage/read-summary/",
  },
] as const;

export type CategoryKey = (typeof categories)[number]["key"];

export const tools: {
  category: CategoryKey;
  title: string;
  description: string;
  icon: typeof concatenate;
  docs: string;
}[] = [
    {
      category: "alignment",
      title: "Concatenate alignments",
      description: "Merge locus alignments into a supermatrix with partitions.",
      icon: concatenate,
      docs: "/docs/gui-usage/align-concat/",
    },
    {
      category: "alignment",
      title: "Convert alignments",
      description: "Switch alignments between FASTA, NEXUS, and PHYLIP.",
      icon: convert,
      docs: "/docs/gui-usage/align-convert/",
    },
    {
      category: "alignment",
      title: "Compute genetic distances",
      description: "Pairwise p, JC69, K2P, TN93, or Poisson distances and group means.",
      icon: distance,
      docs: "/docs/gui-usage/align-distance/",
    },
    {
      category: "alignment",
      title: "Filter alignments",
      description: "Keep loci by taxon coverage, length, or informative sites.",
      icon: filter,
      docs: "/docs/gui-usage/align-filter/",
    },
    {
      category: "alignment",
      title: "Convert partition",
      description: "Convert between RAxML, NEXUS, and charset partitions.",
      icon: partition,
      docs: "/docs/gui-usage/align-partition/",
    },
    {
      category: "alignment",
      title: "Split alignments",
      description: "Break a concatenated matrix back into individual loci.",
      icon: split,
      docs: "/docs/gui-usage/align-split/",
    },
    {
      category: "alignment",
      title: "Summarize alignments",
      description: "Missing data, informative sites, GC, and length statistics.",
      icon: alignmentSummary,
      docs: "/docs/gui-usage/align-summary/",
    },
    {
      category: "alignment",
      title: "Trim alignments",
      description: "Drop sites with too much missing data or too little signal.",
      icon: trim,
      docs: "/docs/gui-usage/align-trim/",
    },
    {
      category: "alignment",
      title: "Unalign sequences",
      description: "Strip alignment gaps to get raw sequences for realignment.",
      icon: unalign,
      docs: "/docs/gui-usage/align-unalign/",
    },
    {
      category: "sequence",
      title: "Add sequences",
      description: "Append new samples to matching alignments or a single file.",
      icon: add,
      docs: "/docs/gui-usage/sequence-add/",
    },
    {
      category: "sequence",
      title: "Extract sequences",
      description: "Pull sequences out of alignments by ID list or regex.",
      icon: extract,
      docs: "/docs/gui-usage/sequence-extract/",
    },
    {
      category: "sequence",
      title: "Extract and map sequence IDs",
      description: "List unique sample IDs and the files each one appears in.",
      icon: extractId,
      docs: "/docs/gui-usage/sequence-id/",
    },
    {
      category: "sequence",
      title: "Filter sequences",
      description: "Keep samples by sequence length or proportion of gaps.",
      icon: sequenceFilter,
      docs: "/docs/gui-usage/sequence-filter/",
    },
    {
      category: "sequence",
      title: "Remove sequences",
      description: "Drop samples by ID or regex across many alignments.",
      icon: remove,
      docs: "/docs/gui-usage/sequence-remove/",
    },
    {
      category: "sequence",
      title: "Rename sequence IDs",
      description: "Rename samples from a mapping file or a text pattern.",
      icon: rename,
      docs: "/docs/gui-usage/sequence-rename/",
    },
    {
      category: "sequence",
      title: "Translate sequences",
      description: "Translate DNA to amino acids with NCBI genetic codes.",
      icon: translate,
      docs: "/docs/gui-usage/sequence-translate/",
    },
    {
      category: "sequence",
      title: "Transpose sequences",
      description: "Turn locus alignments into one file of loci per sample.",
      icon: transpose,
      docs: "/docs/gui-usage/sequence-transpose/",
    },
    {
      category: "genomics",
      title: "Summarize genomic reads",
      description: "FASTQ quality: read counts, length, GC content, and Q-scores.",
      icon: readSummary,
      docs: "/docs/gui-usage/read-summary/",
    },
    {
      category: "genomics",
      title: "Summarize genomic contigs",
      description: "Contig counts, N50, length, and GC content for assemblies.",
      icon: contigSummary,
      docs: "/docs/gui-usage/contig-summary/",
    },
    {
      category: "genomics",
      title: "Convert MAF alignments",
      description: "Turn whole-genome MAF blocks into per-locus FASTA, NEXUS, or PHYLIP.",
      icon: mafConvert,
      docs: "/docs/gui-usage/maf-convert/",
    },
    {
      category: "genomics",
      title: "Summarize MAF alignments",
      description: "Blocks, species, reference coverage, and gaps in MAF files.",
      icon: mafSummary,
      docs: "/docs/gui-usage/maf-summary/",
    },
  ];

export const pillars = [
  {
    title: "Easy to use",
    description:
      "A guided graphical app and a concise command line, backed by documentation for every feature.",
  },
  {
    title: "Accessible and reproducible",
    description:
      "Runs on phones, laptops, and clusters with no runtime dependencies, Docker, or Singularity.",
  },
  {
    title: "Fast and memory efficient",
    description:
      "Written in Rust and parallel by default, making it simple to use, fast and memory efficient.",
  },
];

export const platforms = [
  { name: "Windows", gui: true, cli: true, python: true },
  { name: "macOS", gui: true, cli: true, python: true },
  { name: "Linux", gui: true, cli: true, python: true },
  { name: "WSL", gui: false, cli: true, python: true },
  { name: "iOS & iPadOS", gui: true, cli: false, python: false },
  { name: "Android", gui: true, cli: false, python: false },
];

export const interfaces = [
  {
    name: "GUI",
    title: "SEGUI app",
    description:
      "Point-and-click tools for desktop, tablet, and phone. Install from your platform's app store.",
    command: "",
    href: "/docs/installation/install_gui/",
  },
  {
    name: "CLI",
    title: "Command line",
    description:
      "Script thousands of loci in a pipeline. Install a pre-built binary, or use Bioconda or Cargo.",
    command: "curl -fsSL https://segul.app/install.sh | sh",
    href: "/docs/installation/intro/",
  },
  {
    name: "API",
    title: "Python and Rust",
    description: "Call SEGUL from your own code with pysegul or the segul crate.",
    command: "pip install pysegul",
    href: "/docs/api-usage/",
  },
];

/// Example commands for the terminal showcase.
export const cliExamples = [
  {
    comment: "Concatenate 4,000 loci into a supermatrix",
    command: "segul align concat -d loci/ --output supermatrix --part raxml",
  },
  {
    comment: "Keep loci with at least 75% taxon coverage",
    command: "segul align filter -d loci/ --percent 0.75",
  },
  {
    comment: "Summarize raw reads",
    command: "segul read summary -d raw_reads/",
  },
];

/// Input formats shown on the landing page. `glyph` picks the illustration in
/// `components/landing/FormatGlyph.astro`; `gzip` marks formats read compressed.
export const fileFormats: {
  name: string;
  role: string;
  exts: string[];
  glyph: "fasta" | "nexus" | "phylip" | "fastq" | "maf" | "bed" | "partition";
  gzip?: boolean;
}[] = [
    { name: "FASTA", role: "Alignments, contigs", exts: [".fasta", ".fa", ".fas"], glyph: "fasta" },
    { name: "NEXUS", role: "Alignments", exts: [".nex", ".nexus"], glyph: "nexus" },
    { name: "PHYLIP", role: "Relaxed alignments", exts: [".phy", ".phylip"], glyph: "phylip" },
    { name: "FASTQ", role: "Raw reads", exts: [".fastq", ".fq"], glyph: "fastq", gzip: true },
    { name: "MAF", role: "Genome alignments", exts: [".maf"], glyph: "maf", gzip: true },
    { name: "BED", role: "Loci", exts: [".bed"], glyph: "bed", gzip: true },
    { name: "Partitions", role: "RAxML, NEXUS", exts: [".txt", ".nex"], glyph: "partition" },
  ];

export const workflows = [
  {
    title: "Build a genomic supermatrix",
    steps: ["Summarize", "Filter", "Concatenate"],
  },
  { title: "Check a sequencing run", steps: ["Read summary", "Contig summary"] },
  { title: "Clean up sample names", steps: ["Extract IDs", "Rename"] },
  { title: "Reformat for another program", steps: ["Convert", "Partition"] },
];

/// Viewer showcase on the landing page. All screenshots show the UCE loci of
/// Esselstyn et al. 2021: SEGUI from `integration_test/screenshots_test.dart`
/// on Linux, `segul view` rendered from a virtual terminal, and PySEGUL charts
/// written with `PlotOptions` defaults. The alignment views show locus uce-10
/// at site 400.
export const viewerShowcase = {
  summary:
    "Check thousands of loci and their summary statistics without leaving SEGUL. The app and the command line show the same views, and PySEGUL writes the same charts from Python.",
  views: [
    {
      title: "SEGUI alignment viewer.",
      caption: "Point and click through loci.",
      label: "SEGUI · Linux",
      terminal: false,
      src: desktopViewerScreenshot,
      alt: "SEGUI alignment viewer on Linux showing 49 shrew taxa of a UCE locus with colored bases",
      href: "/docs/gui-usage/viewer/",
    },
    {
      title: "segul view align.",
      caption: "The same viewer in the terminal.",
      label: "$ segul view align --input uce-10.nex",
      terminal: true,
      src: cliViewerScreenshot,
      alt: "segul view align in a terminal showing the same UCE locus with colored bases",
      href: "/docs/cli-usage/view-align/",
    },
    {
      title: "SEGUI summary report.",
      caption: "Charts and tables of a summary run.",
      label: "SEGUI · Linux",
      terminal: false,
      src: desktopSummaryScreenshot,
      alt: "SEGUI alignment summary report showing a histogram of locus length across 4,040 loci",
      href: "/docs/gui-usage/viewer/#summary-reports",
    },
    {
      title: "segul view summary.",
      caption: "The same report as terminal plots.",
      label: "$ segul view summary --input alignment-report.json",
      terminal: true,
      src: cliSummaryScreenshot,
      alt: "segul view summary in a terminal showing a histogram of sites per locus across 4,040 loci",
      href: "/docs/cli-usage/view-summary/",
    },
    {
      title: "PySEGUL summary charts.",
      caption: "Write charts from a Python script.",
      label: "PySEGUL · AlignmentSummary · Beta",
      terminal: false,
      src: pythonSummaryChart,
      alt: "PySEGUL line chart of matrix completeness across 4,040 UCE loci",
      href: "/docs/api-usage/python/plots_reports/",
    },
    {
      title: "PySEGUL distance charts.",
      caption: "Group mean distances as a heatmap.",
      label: "PySEGUL · AlignmentDistance · Beta",
      terminal: false,
      src: pythonDistanceChart,
      alt: "PySEGUL heatmap of mean pairwise distances between shrew groups",
      href: "/docs/api-usage/python/plots_reports/",
    },
  ],
  source: {
    description: "4,040 UCE loci from 102 shrew samples",
    citation: "Esselstyn et al. 2021",
    href: "https://doi.org/10.1206/0003-0090.454.1.1",
  },
};

/// Classroom section on the landing page. The screenshots are the phone
/// layouts of the SEGUI data viewers.
export const classroom = {
  summary:
    "SEGUI works on any platform, including phones and tablets. Students explore real alignments and sequencing reads on the devices they already have, with no command line and no computer lab.",
  href: "/docs/installation/install_gui/",
  viewerHref: "/docs/gui-usage/viewer/",
  tutorialHref: "/docs/tutorials/tutorial-1/",
  screens: [
    {
      title: "Alignment viewer",
      caption: "Scroll and zoom through aligned sequences.",
      src: phoneAlignmentViewer,
      alt: "SEGUI alignment viewer on a phone showing colored bases of a shrew UCE locus",
    },
    {
      title: "Read quality",
      caption: "See how sequencing quality changes along a read.",
      src: phoneReadReport,
      alt: "SEGUI read summary report on a phone showing a per-base quality chart",
    },
    {
      title: "Alignment summary",
      caption: "Compare locus lengths and taxon sampling.",
      src: phoneAlignmentReport,
      alt: "SEGUI alignment summary report on a phone showing a histogram of locus length",
    },
  ],
};
/// Latest release news on the landing page. The screenshot is SEGUI v1.2.0
/// on an Android emulator, after a complete read summary of the raw reads in
/// the segul2-bench repository.
export const latestRelease = {
  version: "v0.25.0",
  summary:
    "Terminal viewers, charts, and a much faster read summary. The redesigned SEGUI v1.2.0 is out on Google Play, the Microsoft Store, the Snap Store, and the App Store for iPhone, iPad, and Mac.",
  href: "/docs/intro/#segul-v0250",
  highlights: [
    { title: "Terminal alignment viewer", href: "/docs/cli-usage/view-align/" },
    { title: "Summary charts and reports", href: "/docs/cli-usage/view-summary/" },
    { title: "Richer read summary", href: "/docs/cli-usage/read-summary/" },
    { title: "SEGUI v1.2.0", href: "/docs/installation/install_gui/" },
  ],
  screenshot: {
    src: readQualityScreenshot,
    alt: "SEGUI on Android showing per-base read quality for a Bunomys sample",
    caption: "Read quality in SEGUI v1.2.0 on Android, from 921 MB of raw reads.",
  },
};

export const citation = {
  text: "Handika, H., and J. A. Esselstyn. 2024. SEGUL: Ultrafast, memory-efficient and mobile-friendly software for manipulating and summarizing phylogenomic datasets. Molecular Ecology Resources, 24(7).",
  doi: "https://doi.org/10.1111/1755-0998.13964",
};

/// Funder disclaimer shown in the site and docs footers.
export const funderDisclaimer =
  "This material is based upon work supported by the National Science Foundation under " +
  "grant numbers: DEB-1754393 and DEB-2244754. Any opinions, findings, and conclusions or " +
  "recommendations expressed in this material are those of the authors and do not " +
  "necessarily reflect the views of the National Science Foundation.";

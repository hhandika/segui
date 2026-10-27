/// Benchmark data for the CLI vs GUI page. `src/data/benchmark.csv` holds the
/// raw replicates from segul-bench; regenerate it with
/// `python3 scripts/docs/export_benchmark.py <path-to-segul-bench>`.
import raw from "../../data/benchmark.csv?raw";

export type Series = "cli" | "gui" | "ipad" | "android" | "other";

export interface Replicate {
  app: string;
  analysis: string;
  dataset: string;
  os: string;
  timeSecs: number;
  ramMb: number | null;
}

export interface Bar {
  label: string;
  series: Series;
  mean: number;
  sd: number;
  n: number;
}

/// Display names and color series for each benchmarked app, in chart order.
export const apps: { app: string; label: string; series: Series }[] = [
  { app: "SEGUL CLI", label: "SEGUL CLI · Linux", series: "cli" },
  { app: "SEGUL GUI (Linux)", label: "SEGUL GUI · Linux", series: "gui" },
  { app: "SEGUL GUI (iPadOS)", label: "SEGUL GUI · iPadOS", series: "ipad" },
  { app: "SEGUL GUI (Android)", label: "SEGUL GUI · Android", series: "android" },
  { app: "AMAS", label: "AMAS", series: "other" },
  { app: "goalign (single-core)", label: "goalign", series: "other" },
];

export const datasets = {
  dna: "Oliveros et al. 2019 (522.5 MBases, DNA)",
  aa: "Shen et al. 2018 (398.8 MBases, AA)",
  reads: "SRR26062012 (0.0 MBases, Whole Genome)",
};

export const replicates: Replicate[] = parseCsv(raw).map((row) => ({
  app: row.app,
  analysis: row.analysis,
  dataset: row.dataset,
  os: row.os,
  timeSecs: Number(row.time_secs),
  ramMb: row.ram_mb === "" ? null : Number(row.ram_mb),
}));

/// Mean and sample standard deviation of `metric` for each app that has
/// data for this analysis and dataset, in `apps` order.
export function bars(
  analysis: string,
  dataset: string,
  metric: "timeSecs" | "ramMb",
  only?: string[],
): Bar[] {
  return apps
    .filter(({ app }) => !only || only.includes(app))
    .map(({ app, label, series }) => {
      const values = replicates
        .filter((r) => r.app === app && r.analysis === analysis && r.dataset === dataset)
        .map((r) => r[metric])
        .filter((v): v is number => v !== null);
      return { label, series, ...summarize(values) };
    })
    .filter((bar) => bar.n > 0);
}

function summarize(values: number[]): { mean: number; sd: number; n: number } {
  const n = values.length;
  if (n === 0) return { mean: 0, sd: 0, n };
  const mean = values.reduce((sum, v) => sum + v, 0) / n;
  const variance = n > 1 ? values.reduce((sum, v) => sum + (v - mean) ** 2, 0) / (n - 1) : 0;
  return { mean, sd: Math.sqrt(variance), n };
}

/// Minimal CSV reader that handles quoted fields, enough for the export.
function parseCsv(text: string): Record<string, string>[] {
  const lines = text.trim().split(/\r?\n/);
  const header = splitLine(lines[0]);
  return lines.slice(1).map((line) => {
    const cells = splitLine(line);
    return Object.fromEntries(header.map((key, i) => [key, cells[i] ?? ""]));
  });
}

function splitLine(line: string): string[] {
  const cells: string[] = [];
  let cell = "";
  let quoted = false;
  for (const char of line) {
    if (char === '"') quoted = !quoted;
    else if (char === "," && !quoted) {
      cells.push(cell);
      cell = "";
    } else cell += char;
  }
  cells.push(cell);
  return cells;
}

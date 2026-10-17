"""Export SEGUL benchmark replicates for the CLI vs GUI documentation charts.

Reads `results/benchmark.csv` from a segul-bench checkout
(https://github.com/hhandika/segul-bench) and writes the replicate rows the
website charts use to `website/src/data/benchmark.csv`. The charts compute
means and standard deviations at build time.

Usage:
    python3 scripts/docs/export_benchmark.py <path-to-segul-bench>
"""

import csv
import sys
from pathlib import Path

APPS = {
    "SEGUL CLI",
    "SEGUL GUI (Linux)",
    "SEGUL GUI (iPadOS)",
    "SEGUL GUI (Android)",
    "AMAS",
    "goalign (single-core)",
}
# Match the GUI benchmark, which used SEGUL v0.20.0.
SEGUL_VERSION = "v0.20.0"
ANALYSES = {
    "Alignment Concatenation (NEXUS)",
    "Alignment Conversion (NEXUS)",
    "Alignment Splitting (NEXUS)",
    "Alignment Summary (NEXUS)",
    "Sequence Removal (NEXUS)",
    "Read Summary (FASTQ)",
}
DATASETS = {
    "Oliveros et al. 2019 (522.5 MBases, DNA)",
    "Shen et al. 2018 (398.8 MBases, AA)",
    "SRR26062012 (0.0 MBases, Whole Genome)",
}
FIELDS = ["app", "analysis", "dataset", "os", "time_secs", "ram_mb"]


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    source = Path(sys.argv[1]) / "results" / "benchmark.csv"
    target = Path(__file__).resolve().parents[2] / "website" / "src" / "data" / "benchmark.csv"
    with source.open(newline="") as handle:
        rows = [row for row in csv.DictReader(handle) if keep(row)]
    with target.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow(
                {
                    "app": row["Apps"],
                    "analysis": row["Analyses"].replace(" (NEXUS)", ""),
                    "dataset": row["Datasets"],
                    "os": row["OS_name"],
                    "time_secs": row["Execution_time_secs"],
                    "ram_mb": round(float(row["RAM_usage_Mb"]), 2) if row["RAM_usage_Mb"] else "",
                }
            )
    print(f"Wrote {len(rows)} rows to {target}")


def keep(row: dict) -> bool:
    if row["Apps"] not in APPS or row["Analyses"] not in ANALYSES:
        return False
    if row["Datasets"] not in DATASETS:
        return False
    return not row["Apps"].startswith("SEGUL") or row["Version"] == SEGUL_VERSION


if __name__ == "__main__":
    main()

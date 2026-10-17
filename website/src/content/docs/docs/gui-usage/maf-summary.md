---
title: MAF Summary
sidebar:
  order: 8.6
---

Summarize Multiple Alignment Format (MAF) files: the number of blocks, the alignment length, how much of the reference genome each species covers, and the proportion of gaps.

## Steps

1. Select the `Genomics` button from the navigation bar.
2. Select `Summarize MAF alignments` from the tool list. On narrower windows, select the tool name at the top of the page to switch tools.
3. Add the MAF files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app finds `.maf` and gzipped `.maf.gz` files in the directory.
4. Set the reference species or the species to report (optional). By default, the reference is the species of the first sequence in the first block, and every species is reported.
5. Select the output directory by clicking the `Add directory` button.
6. Add a prefix for the output files (optional). The default is `maf_summary`.
7. Click the `Run` button labeled `Summarize` to start the task.

## Output

The app writes two CSV files, which you can open in the app's table viewer:

1. **Per file** (`maf_summary_per_file.csv`): one row per MAF file with the number of blocks and species, the alignment length, the reference bases covered, the mean block score, and the proportion of gaps.
2. **Per species** (`maf_summary_per_species.csv`): one row per species in each file with the number of blocks it appears in, its bases and gaps, and the share of reference bases it covers. With more than one file, rows with the path `all` combine every file.

See the [CLI guide](/docs/cli-usage/maf-summary/) for a description of every column.

---
sidebar_position: 7
---

# Alignment Summary

Summary statistics for many alignments.

## Steps

1. Select the `Alignment` button from the navigation bar.
2. Select `Summarize alignments` from the dropdown menu.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. Select the output directory by clicking the `Add directory` button.
5. Add prefix for the output files.
6. Click the `Run` button labeled `Summarize` to start the task.

## Output

The app have three output files:

1. **Alignment summary**: A summary of the input alignments written to a text file (default name: `alignment_summary.txt`).
2. **Locus summary**: A summary of each alignment/locus written to a csv file (default name: `locus_summary.csv`).
3. **Taxon summary**: A summary of each taxon written to a csv file (default name: `taxon_summary.csv`).

## Prefix

The prefix is the name of the output files.  For example, if the prefix is `output`, the app will generate `output_locus_summary.csv`, `output_taxon_summary.csv`, and so on.

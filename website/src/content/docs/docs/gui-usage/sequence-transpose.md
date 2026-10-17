---
title: Sequence Transposition
sidebar:
  order: 16
---

Transpose locus alignments into per-sample sequence files. Locus alignments store one locus per file with a sequence for each sample. Transposing creates one file for each sample with a sequence for each locus, for example to build sample-level references for read mapping.

## Steps

1. Select the `Sequences` button from the navigation bar.
2. Select `Transpose sequences` from the tool list. On narrower windows, select the tool name at the top of the page to switch tools.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. Select the input format (optional) and the data type.
5. Select the output directory by clicking the `Add directory` button.
6. Turn on `Set interleaved format` to write interleaved FASTA (optional).
7. Click the `Run` button labeled `Transpose` to start the task.

## Output

The app writes each sample to its own folder: `<sample>/<sample>.fas`. Each sequence is named after the locus it comes from, which is the input file name without its extension. Gaps (`-`) and missing data (`?`) are removed, so the output is always unaligned FASTA. Samples missing from a locus are skipped for that locus.

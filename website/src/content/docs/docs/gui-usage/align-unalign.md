---
title: Unalign Alignments
sidebar:
  order: 7
---

Remove alignment gaps to produce unaligned sequences, for example to realign them with a different aligner.

## Steps

1. Select the `Alignments` button from the navigation bar.
2. Select `Unalign sequences` from the tool list. On narrower windows, select the tool name at the top of the page to switch tools.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. Select the input format (optional) and the data type.
5. Select the output directory by clicking the `Add directory` button.
6. Turn on `Set interleaved format` to write interleaved FASTA (optional).
7. Click the `Run` button labeled `Unalign` to start the task.

## Output

The app writes one FASTA file for each input alignment, named after the input file. Gap characters are removed from every sequence. The output is always FASTA because unaligned sequences cannot be stored in NEXUS or PHYLIP.

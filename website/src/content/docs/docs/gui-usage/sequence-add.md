---
title: Sequence Addition
sidebar:
  order: 10
---

Add sequences to existing sequence files. Use it to add new samples to a set of loci, or to collect sequences from many files into one file.

## Steps

1. Select the `Sequences` button from the navigation bar.
2. Select `Add sequences` from the tool list. On narrower windows, select the tool name at the top of the page to switch tools.
3. Under `Sequences to add`, add the files that contain the new sequences, then select their input format (optional) and data type.
4. Under `Destination`, choose how to add the sequences:
   - Leave `Add all to a single file` off to add sequences to destination files with the same file name. For example, sequences in `new/locus_1.fas` are added to `existing/locus_1.nex`.
   - Turn `Add all to a single file` on to add every sequence to one destination file. Turn on `Add source file name to IDs` to keep track of where each sequence came from.
5. Select the destination files and their format.
6. Select the output directory by clicking the `Add directory` button.
7. Turn on `Set interleaved format` or `Only write files with added sequences` (optional).
8. Click the `Run` button labeled `Add` to start the task.

## Output

The output is unaligned FASTA, even when the inputs are aligned, because the new sequences may not share the alignment of the destination files. We recommend realigning the output, for example with [MAFFT](https://mafft.cbrc.jp/alignment/software/).

By default, the app writes every destination file, including those that did not receive new sequences. Turn on `Only write files with added sequences` to skip them.

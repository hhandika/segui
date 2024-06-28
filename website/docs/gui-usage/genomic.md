---
sidebar_position: 8
---

# Genomic Summary

This feature provides summary statistics for sequence reads and contiguous sequences (contigs).

## Sequence Read Summary Statistics

### Steps for Sequence Read Summary Statistics

1. Select the `Genomic` button from the navigation bar.
2. Select `Summarize genomic reads` from the dropdown menu.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. All the input files will be displayed in the input tab bar. You can remove the file by clicking the `Remove` button. Removing the file will only remove it from input list and not from the file system.
5. Select the summary mode.
6. Click the `Run` button labeled `Sequence read summary statistics` to start the task.
7. Share the output (optional).

### Summary Mode

The app supports the following summary modes:

- **Minimal**: read count only
- **Default**: generate essential statistics (see below)
- **Complete**: generate all the essential statistics plus summary statistics per position in read for each file.

### Essential statistics for raw reads

- Number of reads
- Number of bases
- Mean read length
- Minimum read length
- Maximum read length
- GC count
- GC content
- AT count
- AT content
- A, C, G, T, N count
- Low quality base count
- Mean base quality
- Min base quality
- Max base quality

## Contig Summary Statistics

### Steps for Contig Summary Statistics

1. Select the `Genomic` button from the navigation bar.
2. Select `Summarize genomic contigs` from the dropdown menu.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. All the input files will be displayed in the input tab bar. You can remove the file by clicking the `Remove` button. Removing the file will only remove it from input list and not from the file system.
5. Add the output directory by clicking the `Add output directory` button. On mobile platforms, the directory will be the default directory for the app.
6. Click the `Run` button labeled `Contig summary statistics` to start the task.
7. Share the output (optional).

### Available statistics for contiguous sequences

- Contig count
- Base count
- Nucleotide
- GC content
- AT content
- Minimum contig length
- Maximum contig length
- Mean contig length
- Median contig length
- N50
- N75
- N90
- Contig 750 bp
- Contig 1000 bp
- Contig 1500 bp
- Cumulative length
- A, C, G, T, N counts

---
title: MAF Conversion
sidebar:
  order: 8
---

Convert Multiple Alignment Format (MAF) files, such as whole-genome alignments, into one alignment per locus in FASTA or PHYLIP format.

## Steps

1. Select the `Genomics` button from the navigation bar.
2. Select `Convert MAF alignments` from the tool list. On narrower windows, select the tool name at the top of the page to switch tools.
3. Add the MAF files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for files with the `.maf` extension in the directory.
4. Select the BED file that names the loci.
5. Select the output directory by clicking the `Add directory` button.
6. Select the output format. Turn on `Set interleaved format` to write interleaved output (optional).
7. Click the `Run` button labeled `Convert` to start the task.

## BED file

The app matches each MAF alignment block to a locus by the start position of the reference sequence, which must be the first sequence in each block. The BED file uses the standard BED6 columns without a header: chromosome name, start position, end position, locus name, score, and strand.

```plaintext
chr1	100	200	locus_1	0	+
chr1	300	400	locus_2	0	-
```

## Output

The app writes one alignment per locus, named after the BED record as `<locus>-<chromosome>-<start>-<end>`, for example `locus_1-chr1-100-200.fas`. Dots in the name become underscores. Blocks from the same locus are merged. Blocks without a matching BED record are written to a `missing-refs` folder, named after the reference sequence, start position, and size. See the [CLI guide](/docs/cli-usage/maf-convert/) for more details.

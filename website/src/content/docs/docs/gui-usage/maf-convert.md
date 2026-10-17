---
title: MAF Conversion
sidebar:
  order: 8.5
---

Convert Multiple Alignment Format (MAF) files, such as whole-genome alignments, into FASTA, NEXUS, or PHYLIP alignments: one per locus in a BED file, or one per block or chromosome without one.

## Steps

1. Select the `Genomics` button from the navigation bar.
2. Select `Convert MAF alignments` from the tool list. On narrower windows, select the tool name at the top of the page to switch tools.
3. Add the MAF files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app finds `.maf` and gzipped `.maf.gz` files in the directory.
4. Select a BED file of loci (optional). Without a BED file, choose whether to write one file per block or one per reference chromosome.
5. Set block options (optional). See [Block options](#block-options).
6. Select the output directory by clicking the `Add directory` button.
7. Select the output format. Turn on `Set interleaved format` to write interleaved output (optional).
8. Click the `Run` button labeled `Convert` to start the task.

## Sample names

The app names each sample after the text before the first dot of its MAF source, so `hg38.chr1` becomes `hg38` in every alignment. The reference is the species of the first sequence in the first block, unless you set `Reference species`. Positions always follow the forward strand of the reference.

## With a BED file

Each block is matched to every locus it overlaps on the same chromosome. Blocks of a locus are joined in reference order across all input files, and species missing from a block are filled with gaps (`-`).

- `Clip blocks to each locus` (on by default) trims each block to the positions of the locus. Turn it off to keep whole blocks.
- `Reverse complement minus-strand loci` writes loci whose BED strand is `-` in the orientation of the feature, for example before translating coding sequences.

The BED file needs at least three columns without a header: chromosome, start, and end. The fourth column is the locus name and the sixth is the strand. Gzipped BED files (`.bed.gz`) work too.

```plaintext
chr1	100	200	locus_1
chr1	300	400	locus_2	0	-
```

Each locus is written as `<locus>-<chromosome>-<start>-<end>`, for example `locus_1-chr1-100-200.fas`. The app also writes `maf_convert.csv`, which lists every locus, how many blocks it joined, and whether an alignment was written. Blocks that overlap no locus are skipped.

## Without a BED file

Choose `One file per block` to write each block as `<chromosome>-<start>-<end>`, such as `chr1-100-110.fas`, or `One file per chromosome` to join all blocks of each reference chromosome into one alignment, such as `chr1.fas`.

## Block options

All block options are optional:

| Option                  | Description                                                         |
| ----------------------- | ------------------------------------------------------------------- |
| Reference species       | Species used for positions. Default: the first species in the file  |
| Species to write        | Comma-separated species to keep, such as `hg38, panTro6`            |
| Minimum reference bases | Skip blocks with fewer reference bases                              |
| Minimum species         | Skip blocks with fewer species, counting the reference              |
| Minimum score           | Skip blocks with a lower score. Blocks without a score are kept     |

See the [CLI guide](/docs/cli-usage/maf-convert/) for examples of clipping and joining blocks. To check MAF files before converting them, use [MAF summary](/docs/gui-usage/maf-summary/).

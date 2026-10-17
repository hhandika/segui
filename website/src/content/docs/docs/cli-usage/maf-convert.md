---
title: MAF Conversion
sidebar:
  order: 10.5
---

Multiple Alignment Format (MAF) stores whole-genome alignments as blocks. Each block aligns a stretch of a reference genome to the matching sequence in other genomes, with details such as the source, position, strand, and score of each sequence. Most phylogenetic software does not read MAF. SEGUL converts MAF blocks to FASTA, NEXUS, or PHYLIP alignments, either one alignment per block or one alignment per locus defined in a BED file.

:::note
This page describes SEGUL v0.24.0 and later. In earlier versions, the command was `segul maf maf` and it required `--reference` and `--from-bed`. See [Migrating from v0.23](#migrating-from-v023). To check your SEGUL version, run in your terminal:

```bash
segul --version
# Compatible version example:
# segul 0.24.0
```

Check the [Installation Guide](/docs/installation/update/#segul-cli) to update SEGUL to the latest version.
:::

## Quick example

Assume we have a MAF file named `genome.maf` with two blocks. The human genome (`hg38`) is the reference:

```plaintext
##maf version=1
a score=100.0
s hg38.chr1    100 10 + 248956422 ACGT--ACGTAC
s panTro6.chr1  90 12 + 224244399 ACGTTTACGTAC
s mm10.chr4    500 10 - 156508116 ACGA--ACGTAC

a score=-5.0
s hg38.chr1    110  5 + 248956422 GGCCA
s mm10.chr4    510  5 - 156508116 GGCTA
```

To convert each block to its own alignment, run:

```bash
segul maf convert --input genome.maf
```

SEGUL writes two files to `Maf-Convert`, named after the reference chromosome and position of each block. `Maf-Convert/chr1-100-110.fas`:

```plaintext
>hg38
ACGT--ACGTAC
>panTro6
ACGTTTACGTAC
>mm10
ACGA--ACGTAC
```

## How SEGUL reads MAF blocks

### Reference and sample names

MAF sources usually combine an assembly name and a chromosome, such as `hg38.chr1`. SEGUL names each sample after the text before the first dot (`hg38`), so a species is a single sample in every block, whichever chromosome it comes from. Sources without a dot, such as `baboon`, are used as they are.

The reference is the species of the first sequence in the first block. Use `--ref-species` to choose another species. Blocks without a sequence from the reference species are skipped and counted in the log. If a species appears more than once in a block, SEGUL keeps the first sequence and reports the number of dropped rows.

Some assembly names contain dots, such as `GCF_000001405.40`. List those species with `--species` or `--species-file` (see [Filtering blocks](#filtering-blocks)) so SEGUL matches the full assembly name. To keep the full source names as sample names instead, use `--full-source-name`. Each chromosome then becomes a separate sample.

### Strand and coordinates

SEGUL uses the forward strand of the reference for all positions. If the reference sequence of a block is on the minus strand, SEGUL reverse complements every sequence in the block first. Positions are zero-based and half-open, as in MAF and BED files: `chr1-100-110` covers bases 100 to 109.

### Compressed files

SEGUL reads gzipped MAF (`.maf.gz`) and BED (`.bed.gz`) files directly. There is no need to decompress them first.

## Converting with a BED file

Use a BED file to get one alignment per locus, such as a gene or an exon. For example, `loci.bed`:

```plaintext
chr1	100	115	geneA	0	+
chr1	103	108	exon1	0	+
chr1	108	115	exon2	0	-
chr2	0	50	geneB	0	+
```

```bash
segul maf convert --input genome.maf --bed loci.bed
```

For each block, SEGUL finds every BED locus it overlaps on the same chromosome. The BED chromosome is matched to the chromosome part of the reference source (`chr1` in `hg38.chr1`), or to the full source.

Each locus is written to a file named `{name}-{chrom}-{start}-{end}`, such as `geneA-chr1-100-115.fas`. Without a name column, the file is named `{chrom}-{start}-{end}`. Dots and characters that are not allowed in file names become underscores.

### Clipping to the locus

SEGUL trims each block to the positions of the locus. Insertions in other species, where the reference has a gap, are kept when they fall inside the locus and dropped at its edges. `exon1` covers positions 103 to 107, so the insertion after position 103 is kept. `Maf-Convert/exon1-chr1-103-108.fas`:

```plaintext
>hg38
T--ACGT
>panTro6
TTTACGT
>mm10
A--ACGT
```

Use `--no-clip` to keep every block that overlaps a locus whole.

### Joining blocks

When several blocks overlap a locus, SEGUL joins them in reference order, across all input files. A species missing from a block is filled with gaps (`-`) for that part of the alignment. `geneA` spans both blocks, and `panTro6` is missing from the second one. `Maf-Convert/geneA-chr1-100-115.fas`:

```plaintext
>hg38
ACGT--ACGTACGGCCA
>panTro6
ACGTTTACGTAC-----
>mm10
ACGA--ACGTACGGCTA
```

If two blocks cover the same reference positions in a locus, for example the same region in two MAF files, SEGUL keeps the first one by position and file name, then warns with the number of dropped blocks.

### Minus-strand loci

By default, loci are written in the orientation of the reference, which is what most phylogenetic analyses need. Use `--strand-aware` to reverse complement loci whose BED strand is `-`, for example before translating coding sequences. With `--strand-aware`, `exon2` becomes:

```plaintext
>hg38
TGGCCGT
>panTro6
-----GT
>mm10
TAGCCGT
```

### BED file format

SEGUL reads BED3 to BED12 files. Only the first three columns are required: chromosome, start, and end. The fourth column is the locus name, and the sixth column is the strand. Columns are separated by tabs or spaces. Comments (`#`), `track` and `browser` lines, and blank lines are skipped. Windows line endings work on every platform.

### Locus report

SEGUL writes `maf_convert.csv` to the output directory, with one row for every locus in the BED file. Use `--prefix` to change its name.

```plaintext
locus,chrom,start,end,strand,blocks,ref_bases,aligned_columns,samples,written
geneA-chr1-100-115,chr1,100,115,+,2,15,17,3,true
exon1-chr1-103-108,chr1,103,108,+,1,5,7,3,true
exon2-chr1-108-115,chr1,108,115,-,2,7,7,3,true
geneB-chr2-0-50,chr2,0,50,+,0,0,0,0,false
```

| Column            | Description                                       |
| ----------------- | ------------------------------------------------- |
| `locus`           | Output file name without its extension            |
| `chrom`           | Chromosome from the BED file                      |
| `start`, `end`    | Locus position from the BED file                  |
| `strand`          | Strand from the BED file (`.` when missing)       |
| `blocks`          | Number of blocks joined into the locus            |
| `ref_bases`       | Reference bases in the alignment                  |
| `aligned_columns` | Alignment length                                  |
| `samples`         | Number of samples                                 |
| `written`         | Whether an alignment was written                  |

Loci with no aligned data, such as `geneB`, are listed with `written` set to `false`. Blocks that overlap no locus are counted in the log. Use `--write-unmatched` to write them to an `unmatched` folder in the output directory, one file per block.

## Converting without a BED file

Without a BED file, each block is written to its own file, named `{chrom}-{start}-{end}`. If two blocks have the same name, for example when the same region appears in two files, the second gets a `-2` suffix, the third a `-3` suffix, and so on.

To join blocks by reference chromosome instead, use `--group-by chrom`. SEGUL writes one alignment per chromosome, such as `chr1.fas`, with blocks joined in reference order and missing species filled with gaps:

```bash
segul maf convert --input genome.maf --group-by chrom
```

## Filtering blocks

SEGUL can skip blocks before converting them:

| Option                  | Skips blocks                                                     |
| ----------------------- | ---------------------------------------------------------------- |
| `--min-block-len <N>`   | With fewer than N reference bases (gaps are not counted)         |
| `--min-species <N>`     | With fewer than N species, counting the reference                |
| `--min-score <SCORE>`   | With a lower score. Blocks without a score are kept              |

For example, to skip blocks shorter than 50 bases or with a negative score:

```bash
segul maf convert --dir maf/ --bed loci.bed --min-block-len 50 --min-score 0
```

To write only some species, list them with `--species` (comma-separated) or `--species-file` (one per line):

```bash
segul maf convert --dir maf/ --bed loci.bed --species hg38,panTro6,mm10
```

The reference is still used for positions when it is not listed, but it is not written.

## Input and output

Use `--dir` or `-d` to convert every `.maf` and `.maf.gz` file in a directory. Subdirectories are not searched. Use `--input` or `-i` to provide one or more files, including [wildcards](https://en.wikipedia.org/wiki/Wildcard_character):

```bash
segul maf convert --input maf/*.maf.gz --bed loci.bed
```

The output directory is `Maf-Convert` by default. Use `--output` or `-o` to change it, and `--force` to overwrite an existing directory. The default output format is sequential FASTA. Use `--output-format` or `-F` to choose `fasta`, `nexus`, `phylip`, or an interleaved format: `fasta-int`, `nexus-int`, or `phylip-int`.

```bash
segul maf convert --dir maf/ --bed loci.bed --output loci --output-format nexus
```

## All options

| Option                     | Description                                                          |
| -------------------------- | -------------------------------------------------------------------- |
| `-d`, `--dir`              | Directory with MAF files                                             |
| `-i`, `--input`            | MAF files                                                            |
| `--bed`                    | BED file of loci                                                     |
| `--group-by`               | Without `--bed`: one file per `block` (default) or per `chrom`       |
| `--no-clip`                | With `--bed`: keep whole blocks instead of clipping to the locus     |
| `--strand-aware`           | With `--bed`: reverse complement minus-strand loci                   |
| `--write-unmatched`        | With `--bed`: write blocks that overlap no locus                     |
| `--ref-species`            | Reference species                                                    |
| `--species`                | Species to write, comma-separated                                    |
| `--species-file`           | File of species to write, one per line                               |
| `--full-source-name`       | Use full MAF source names as sample names                            |
| `--min-block-len`          | Minimum reference bases in a block                                   |
| `--min-species`            | Minimum species in a block, counting the reference                   |
| `--min-score`              | Minimum block score                                                  |
| `-F`, `--output-format`    | Output format. Default: `fasta`                                      |
| `-o`, `--output`           | Output directory. Default: `Maf-Convert`                             |
| `--prefix`                 | Name of the locus report. Default: `maf_convert`                     |
| `--force`                  | Overwrite an existing output directory                               |
| `--log`                    | Log file path. Default: `segul.log`                                  |

## Migrating from v0.23

| v0.23                                         | v0.24                                     |
| --------------------------------------------- | ----------------------------------------- |
| `segul maf maf`                               | `segul maf convert`                       |
| `--reference loci.bed --from-bed`             | `--bed loci.bed`                          |
| `--reference` without `--from-bed`            | No option needed                          |
| `-t`, `--output-format`                       | `-F`, `--output-format`                   |
| Output in `Genomic-Convert`                   | Output in `Maf-Convert`                   |
| Unmatched blocks in `missing-refs`            | Use `--write-unmatched` (`unmatched`)     |
| Sample names such as `hg38.chr1`              | Sample names such as `hg38`. Use `--full-source-name` for the old names |

Blocks of the same locus are now joined instead of replacing each other, and loci are matched by overlap on the same chromosome instead of by exact start position, so outputs from v0.24 can differ from v0.23 for the same input.

To summarize MAF files before converting them, see [MAF summary](/docs/cli-usage/maf-summary/).

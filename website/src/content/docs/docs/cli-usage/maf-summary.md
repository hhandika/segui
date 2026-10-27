---
title: MAF Summary
sidebar:
  order: 10.6
---

Summarize Multiple Alignment Format (MAF) files: the number of blocks, the alignment length, how much of the reference genome each species covers, and the proportion of gaps. Use it to check whole-genome alignments before [converting them](/docs/cli-usage/maf-convert/).

:::note
This feature is available in SEGUL v0.24.0 and later versions. To check your SEGUL version, run in your terminal:

```bash
segul --version
# Compatible version example:
# segul 0.24.0
```

Check the [Installation Guide](/docs/installation/update/#segul-cli) to update SEGUL to the latest version.
:::

## Quick example

Using the `genome.maf` file from the [MAF conversion](/docs/cli-usage/maf-convert/#quick-example) example:

```bash
segul maf summary --input genome.maf
```

SEGUL writes two files to `Maf-Summary`. `maf_summary_per_species.csv` has one row per species:

```plaintext
path,name,blocks_present,block_proportion,aligned_columns,bases,gaps,gap_proportion,n_count,ref_bases_covered,ref_coverage
genome.maf,hg38,2,1.0000,17,15,2,0.1176,0,15,1.0000
genome.maf,mm10,2,1.0000,17,15,2,0.1176,0,15,1.0000
genome.maf,panTro6,1,0.5000,12,12,0,0.0000,0,10,0.6667
```

`panTro6` is in one of the two blocks and aligns to 10 of the 15 reference bases.

SEGUL reads blocks the same way as the conversion: it names samples after their assembly (`hg38.chr1` becomes `hg38`), uses the forward strand of the reference, and reads gzipped files directly. See [how SEGUL reads MAF blocks](/docs/cli-usage/maf-convert/#how-segul-reads-maf-blocks).

## Per-file summary

`maf_summary_per_file.csv` has one row per MAF file:

| Column                   | Description                                                                 |
| ------------------------ | --------------------------------------------------------------------------- |
| `path`                   | MAF file                                                                    |
| `ref_species`            | Reference species                                                           |
| `blocks`                 | Blocks with a reference sequence                                            |
| `blocks_no_ref`          | Blocks without a reference sequence (not included in other columns)         |
| `species`                | Number of species                                                           |
| `ref_chromosomes`        | Number of reference chromosomes                                             |
| `ref_chrom_size_total`   | Total length of those chromosomes                                           |
| `ref_bases`              | Reference bases in all blocks                                               |
| `ref_genome_coverage`    | `ref_bases` divided by `ref_chrom_size_total`                               |
| `aligned_columns`        | Total alignment length of all blocks                                        |
| `mean_block_columns`     | Mean alignment length of a block                                            |
| `min_block_columns`      | Shortest block alignment                                                    |
| `max_block_columns`      | Longest block alignment                                                     |
| `mean_block_ref_len`     | Mean reference bases in a block                                             |
| `mean_species_per_block` | Mean number of species in a block                                           |
| `mean_score`             | Mean score of blocks with a score. Empty if no block has a score            |
| `gap_proportion`         | Gaps (`-`) divided by all characters                                        |
| `duplicate_rows`         | Rows dropped because a species appeared more than once in a block           |

Overlapping blocks are counted each time they appear, so `ref_genome_coverage` can be higher than the share of the genome that is covered. Very small values are written in scientific notation, such as `3.5952e-7`.

## Per-species summary

`maf_summary_per_species.csv` has one row per species in each file. The reference comes first, followed by the other species in alphabetical order.

| Column              | Description                                                                 |
| ------------------- | --------------------------------------------------------------------------- |
| `path`              | MAF file, or `all` for every file combined                                  |
| `name`              | Species                                                                     |
| `blocks_present`    | Blocks with the species                                                     |
| `block_proportion`  | `blocks_present` divided by the number of blocks                            |
| `aligned_columns`   | Total alignment length of the blocks with the species                       |
| `bases`             | Characters other than gaps                                                  |
| `gaps`              | Gaps (`-`)                                                                  |
| `gap_proportion`    | `gaps` divided by `aligned_columns`                                         |
| `n_count`           | Unknown bases (`N` and `?`)                                                 |
| `ref_bases_covered` | Reference bases aligned to a base of the species                            |
| `ref_coverage`      | `ref_bases_covered` divided by the reference bases of all blocks            |

With more than one input file, SEGUL adds rows with `path` set to `all` that combine every file.

## All options

| Option                  | Description                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| `-d`, `--dir`           | Directory with `.maf` and `.maf.gz` files. Subdirectories are not searched |
| `-i`, `--input`         | MAF files                                                        |
| `--ref-species`         | Reference species. Default: the first species in the first block |
| `--species`             | Species to report, comma-separated                               |
| `--species-file`        | File of species to report, one per line                          |
| `--full-source-name`    | Use full MAF source names as sample names                        |
| `-o`, `--output`        | Output directory. Default: `Maf-Summary`                         |
| `--prefix`              | Prefix of the output files. Default: `maf_summary`               |
| `--force`               | Overwrite an existing output directory                           |
| `--log`                 | Log file path. Default: `segul.log`                              |

For example, to summarize every MAF file in a directory and name the output files `primates_per_file.csv` and `primates_per_species.csv`:

```bash
segul maf summary --dir maf/ --prefix primates
```

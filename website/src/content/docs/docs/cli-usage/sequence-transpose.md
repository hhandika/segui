---
title: Sequence Transposition
sidebar:
  order: 20
---

Transpose locus alignments into per-sample sequence files. Locus alignments store one locus per file with a sequence for each sample. Transposing creates one file for each sample with a sequence for each locus. This is useful for creating sample-level reference sequences, for example, to map reads from each sample back to its own loci.

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

Assume we have two alignment files in FASTA format. `locus_1.fas`:

```plaintext
>sample1
AT-GC?
>sample2
ATTGCA
```

And `locus_2.fas`, which does not have `sample2`:

```plaintext
>sample1
--GGCC
```

To transpose the alignments, use the following command:

```bash
segul sequence transpose --dir alignments/
```

SEGUL creates one file for each sample. Each sequence is named after the locus it comes from, and gaps (`-`) and missing data (`?`) are removed. `Sequence-Transpose/sample1/sample1.fas`:

```plaintext
>locus_1
ATGC
>locus_2
GGCC
```

`Sequence-Transpose/sample2/sample2.fas`:

```plaintext
>locus_1
ATTGCA
```

## Detailed usage

### Transposing sequences

To transpose sequences, use the `sequence transpose` command:

```bash
segul sequence transpose --dir <alignment-dir>
```

The locus name is the input file name without its extension. Samples missing from a locus are skipped for that locus, so each sample file only contains the loci where the sample is present.

For amino acid sequences, use the `--datatype aa` option:

```bash
segul sequence transpose --dir alignments/ --datatype aa
```

### Specifying the output directory and format

By default, the output directory is `Sequence-Transpose`. Each sample is written to its own folder: `Sequence-Transpose/<sample>/<sample>.fas`. You can change the output directory name using the `--output` or `-o` option:

```bash
segul sequence transpose --dir alignments/ --output sample-references
```

Because gaps are removed, the output sequences are unaligned and are always in FASTA format. Use the `--output-format` or `-F` option to choose between sequential (`fasta`, the default) and interleaved (`fasta-int`) FASTA:

```bash
segul sequence transpose --dir alignments/ --output-format fasta-int
```

### More ways to specify input files

You can also specify input files using the `--input` or `-i` option. For example:

```bash
segul sequence transpose --input alignments/*.fasta
```

## All options

| Option                  | Description                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------- |
| `-d`, `--dir`           | Directory with alignments                                                           |
| `-i`, `--input`         | Alignment files. Allows wildcards                                                   |
| `-f`, `--input-format`  | Input format: `auto` (default), `fasta`, `nexus`, or `phylip`                       |
| `--datatype`            | Data type: `dna` (default), `aa`, or `ignore`                                       |
| `-F`, `--output-format` | Output format: `fasta` (default) or `fasta-int`                                     |
| `-o`, `--output`        | Output directory. Default: `Sequence-Transpose`                                     |
| `--force`               | Overwrite an existing output directory                                              |
| `--log`                 | Log file path. Default: `segul.log`                                                 |

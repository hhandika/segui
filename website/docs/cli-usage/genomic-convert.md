---
sidebar_position: 10
title: Genomic File Conversion (Beta)
---

SEGUL currently only support converting Multi Alignment Format (MAF).

## Multiple Alignment Format (MAF) conversion

Multiple Alignment Format (MAF) is a text-based format for representing multiple sequence alignments. Current version, supports converting this format to FASTA or PHYLIP format, including support for interleaved and sequential formats. It requires BED file to extract the name of the sequences for the output file.

### How does it work?

The MAF file is parsed and the sequences are extracted. SEGUL will match the sequence names with the BED file based on the start position of the reference sequence. It requires the reference sequence is the first sequence in each MAF alignment block (or paragraph in MAF term). The output file will be in FASTA or PHYLIP format.

### Preparing the BED file

The BED file should contain the following columns without a header:

1. Chromosome name
2. Start position
3. End position
4. Sequence name

```plaintext
chr1 100 200 seq1
chr1 300 400 seq2
chr1 500 600 seq3
```

:::note
We are working on improving BED file support to include more columns and headers.
:::

### Converting MAF

Current version supports input multiple MAF files. However, it restricts name sources from a single BED file. Future updates will include multiple BED file support with implementation similar to the [sequence addition](/docs/cli-usage/sequence-add) feature.

```bash
segul genomic convert -d <directory-with-maf-files> --reference <bed-file> -o <output-file> --from-bed
```

You can also use standard input to provide the MAF file.

```bash
segul genomic convert -i <input-maf-file> --reference <bed-file> --from-bed
```

### Specifying output directory and format

By default, the output directory is `Genomic-Convert` in the current working directory. You can specify the output directory and format using the following options:

```bash
segul genomic convert -d <directory-with-maf-files> --reference <bed-file> -o <output-file> --from-bed --output-dir <output-directory> --output-format <format>
```

For FASTA format:

```bash
segul genomic convert -d <directory-with-maf-files> --reference <bed-file> -o <output-file> --from-bed --output-dir <output-directory> --output-format fasta
```

For PHYLIP format:

```bash
segul genomic convert -d <directory-with-maf-files> --reference <bed-file> -o <output-file> --from-bed --output-dir <output-directory> --output-format phylip
```

Use the `-int` suffix to specify the interleaved format for the output file. For example, for interleaved FASTA format: `fasta-int` and for interleaved PHYLIP format: `phylip-int`.

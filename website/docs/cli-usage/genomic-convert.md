---
sidebar_position: 10
title: Genomic File Conversion (Beta)
---

SEGUL currently supports only converting Multiple Alignment Format (MAF).

## Multiple Alignment Format (MAF) conversion

Multiple Alignment Format (MAF) is a text-based format for representing multiple sequence alignments. Unlike the NEXUS or PHYLIP format, which usually contains a single alignment, each MAF file can contain multiple alignments. This format helps store alignments with detailed information about the sequences, such as the sample name, scores, size, strand, and other attributes. However, most phylogenetic software does not support this format. SEGUL aims to bridge this gap by converting MAF files to FASTA or PHYLIP format, including support for interleaved and sequential formats. The output will be in multiple files containing sequences with a matching locus/gene. The filenames will be the locus/gene names.

:::info
The current beta version only supports sourcing the names from a BED file. NEXUS output is not yet supported. We are working on adding a feature to get the reference names from FASTA files and supports for NEXUS output.
:::

:::info
To use this feature, follow the [Try Beta Feature](/docs/installation/install_dev) installation guideline.
:::

### How does it work?

After parsing the MAF file and extracting the sequences, SEGUL will match the locus/gene names with the BED file based on the start position of the reference sequence. The reference sequence must be the first in each MAF alignment block (or __paragraph__ in MAF terms). Thankfully, it is typical for an aligner to place the reference as the first sequence. SEGUL will write the output for each locus/gene. The output file will be named based on the locus/gene names from the BED file. If the name cannot be found in the BED file, SEGUL will use the reference name instead and output the results in a `missing-refs` directory inside the output directory.

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
We are improving BED file support to include more columns and headers.
:::

### Converting MAF

The current version supports inputting multiple MAF files. However, it restricts name sources from a single BED file. Future updates will include multiple BED file support with an implementation similar to the [sequence addition](/docs/cli-usage/sequence-add) feature.

```bash
segul genomic convert -d <directory-with-maf-files> --reference <bed-file> -o <output-file> --from-bed
```

You can also use standard input to provide the MAF file.

```bash
segul genomic convert -i <input-maf-file> --reference <bed-file> --from-bed
```

### Specifying output directory and format

The output directory is `Genomic-Convert` in the current working directory by default. You can specify the output directory and format using the following options:

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

Use the `-int` suffix to specify the interleaved format for the output file. For example, for interleaved FASTA format: `fasta-int` and interleaved PHYLIP format: `phylip-int`.

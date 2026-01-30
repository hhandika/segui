---
sidebar_position: 9
title: Alignment Trimming
---

Trim alignments based on the proportion of missing data or the number of parsimony informative sites. This feature will filter sites based on the specified parameters.

:::info
This feature is available in SEGUL v0.23.0 and later versions. To check your SEGUL version, run in your terminal:

```Bash
segul --version
# Result example:
$ segul 0.23.0
```

Check the [Installation Guide](/docs/installation/install) to update SEGUL to the latest version.
:::

## Quick example

Assume we have an alignment file in FASTA format as follows:

```plaintext
>seq1
ATGCAT--A
>seq2
ATGCATA--
>seq3
ATGCAA-A-
>seq4
ATGCATA--
```

If we set the proportion of missing data to 0.5. It will generate an output without the last two sites using the following command:

```Bash
segul align trim --dir alignments/ --missing-data 0.5
```

The output as follows. Note that the last two sites were removed because they had more than 50% missing data.

```plaintext
>seq1
ATGCAT-
>seq2
ATGCATA
>seq3
ATGCAA-
>seq4
ATGCATA
```

## Detailed usage

### Filtering based on the proportion of missing data

To trim alignments, use the `align trim` command with the following options:

```Bash
segul align trim --dir <alignment-dir> --missing-data <value>
```

For example:

```Bash
segul align trim --dir alignments/ --missing-data 0.5
```

### Filtering based on parsimony informative sites

To trim based on the minimum threshold of parsimony informative sites, use the `--pinf` option:

```Bash
segul align trim --dir <alignment-dir> --pinf <value>
```

For example, this command will retain sites with at least 50 parsimony informative sites:

```Bash
segul align trim --dir alignments/ --pinf 50
```

### Amino acid alignment trimming

If the input is amino acid sequences, you need to use the `datatype aa` option. For example:

```Bash
segul align trim --dir alignments/ --missing-data 0.5 --datatype aa
```

### Specifying the output directory and format

By default, the output directory is `Align-Trim`. You can change the output directory name using the `--output` or `-o` option. For example, to name the output directory `align-trim`, use the command below:

```Bash
segul align trim --dir alignments/ --output align-trim
```

To specify the output format, use the `--output-format` or `-F` option. The default output format is NEXUS. For example, to change the output format to FASTA, use the command below:

```Bash
segul align trim --dir alignments/ --output-format fasta
```

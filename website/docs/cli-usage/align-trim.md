---
sidebar_position: 9
title: Alignment Trimming (Beta)
---

Trim alignments based on the proportion of missing data or the number of parsimony informative sites. This feature will filter sites based on the proportion of missing data and the number of parsimony informative sites.

For example:

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

If we set the proportion of missing data to 0.5. It will generate an output without the last two sites. The output will be:

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

:::info
This feature is still in beta. Please report any issues you encounter. For more information, see the [Try Beta Features](/docs/installation/install_dev) section.
:::

## Filtering based on the proportion of missing data

To trim alignments, use the `align trim` command with the following options:

```Bash
segul align trim --dir <alignment-dir> --missing-data <value>
```

For example:

```Bash
segul align trim --dir alignments/ --missing-data 0.5
```

## Filtering based on parsimony informative sites

To trim based on the minimum threshold of parsimony informative sites, use the `--pinf` option:

```Bash
segul align trim --dir <alignment-dir> --pinf <value>
```

For example, this command will retain sites with at least 50 parsimony informative sites:

```Bash
segul align trim --dir alignments/ --pinf 50
```

## Amino acid alignment trimming

If the input is amino acid sequences, you need to use the `datatype aa` option. For example:

```Bash
segul align trim --dir alignments/ --missing-data 0.5 --datatype aa
```

## Specifying the output directory and format

By default, the output directory is `Align-Trim`. You can change the output directory name using the `--output` or `-o` option. For example, to name the output directory `align-trim`, use the command below:

```Bash
segul align trim --dir alignments/ --output align-trim
```

To specify the output format, use the `--output-format` or `-F` option. The default output format is NEXUS. For example, to change the output format to FASTA, use the command below:

```Bash
segul align trim --dir alignments/ --output-format fasta
```

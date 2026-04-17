---
sidebar_position: 10
title: Unalign Alignments
---

Unalign alignments to produce unaligned sequence files.

Under the hood, SEGUL will read the alignment files and remove all gap characters to produce unaligned sequences. SEGUL can do it for thousands of files in a single command.

:::info
This feature is available in SEGUL v0.23.0 and later versions. To check your SEGUL version, run in your terminal:

```Bash
segul --version
# Compatible version example:
# segul 0.23.0
```

Check the [Installation Guide](/docs/installation/update#segul-cli) to update SEGUL to the latest version.
:::

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

To unalign the sequences, use the following command:

```Bash
segul align unalign --dir alignments/
```

The output will be as follows, with all gap characters removed:

```plaintext
>seq1
ATGCATA
>seq2
ATGCATA
>seq3
ATGCAAA
>seq4
ATGCATA
```

## Detailed usage

### Unaligning alignments (DNA)

To unalign alignments, use the `align unalign` command with the following options. It will automatically detect the input format.

```Bash
segul align unalign --dir <alignment-dir>
```

### Unaligning alignments (Amino Acid)

To unalign amino acid alignments, use the `--amino-acid` flag as follows:

```Bash
segul align unalign --dir <alignment-dir> --input-format aa
```

### Specifying output directory

By default, the output directory will be named `Align-Unalign` in the current working directory. You can change the output directory name using the `--output` or `-o` option. For example, to name the output directory `unalign-output`, use the command below:

```Bash
segul align unalign --dir <alignment-dir> --output unalign-output
```

:::note
Due to the nature of unaligning, the output format will always be in FASTA format.
:::

### More ways to specify input files

You can also specify input files using the `--input` or `-i` option. This option allows you to provide a single alignment file or multiple alignment files using [wildcards](https://en.wikipedia.org/wiki/Wildcard_character). For example:

```Bash
segul align unalign --input alignments/*.fasta
```

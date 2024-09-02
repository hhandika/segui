---
sidebar_position: 2
title: Sequence Addition (Beta)
---

Add sequences to existing sequence files/alignments. Allow adding sequences from multiple sources to multiple destinations. The file formats for the source and destinations can be different, but SEGUL requires matching file names for both to add the sequences. If the destination files are aligned, all the output sequences will be unaligned. We recommend using [MAFFT](https://mafft.cbrc.jp/alignment/software/) to align the sequences after adding them.

:::info
This feature is still in beta. Please report any issues you encounter. For more information, see the [Try Beta Features](/docs/installation/install_dev) section.
:::

## Quick Start

To add sequences, use the `add` command with the following options:

```Bash
segul sequence add -d <source-sequence-dir> --destination-dir <destination-sequence-dir>
```

For example:

```Bash
segul sequence add -d source-sequence/ --destination-dir destination-sequence/
```

## Specify the input format

The command above will look for any FASTA, NEXUS, or PHYLIP format sequences in the source directory and add them to the destination directory. You can specify the input format using the `--input-format` option. For example, to add sequences in NEXUS format, use the command below:

```Bash
segul sequence add -d <source-sequence-dir> --destination-dir <destination-sequence-dir> --input-format nexus
```

You can specify the destination format using the `--destination-format` option. For example, to add sequences in NEXUS format to the destination directory in FASTA format, use the command below:

```Bash
segul sequence add -d <source-sequence-dir> --destination-dir <destination-sequence-dir> --input-format nexus --destination-format fasta
```

## Specify the output directory name and format

By default, the output directory will be named `Sequence-Addition`. You can change the output directory name using the `--output` or `-o` option. For example, to name the output directory `seq-add`, use the command below:

```Bash
segul sequence add -d <source-sequence-dir> --destination-dir <destination-sequence-dir> --output seq-add
```

The output format will be in interleaved FASTA format. The other option is in sequential FASTA format. Use the `--output-format fasta` or `-F fasta` option to change the output to sequential FASTA format. For example:

```Bash
segul sequence add -d <source-sequence-dir> --destination-dir <destination-sequence-dir> --output-format fasta
```

## Output only the added sequences

By default, SEGUL will output all sequences in the destination directory. If the destination directory format differs from the output format, all the output will be changed to the selected output format. If you only want to output files with the added sequences, use the `added-only` flag. For example:

```Bash
segul sequence add -d <source-sequence-dir> --destination-dir <destination-sequence-dir> --added-only
```

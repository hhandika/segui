---
title: Sequence Addition
sidebar:
  order: 12
---

Add sequences to existing sequence files/alignments. Allow adding sequences from multiple sources to multiple destinations. The file formats for the source and destinations can be different, but SEGUL requires matching file names for both to add the sequences. If the destination files are aligned, all the output sequences will be unaligned. We recommend using [MAFFT](https://mafft.cbrc.jp/alignment/software/) to align the resulting sequence files.

:::note
This feature is available in SEGUL v0.23.0 and later versions. To check your SEGUL version, run in your terminal:

```bash
segul --version
# Compatible version example:
# segul 0.23.0
```

:::

## Quick start

To add sequences, use the `add` command with the following options:

```bash
segul sequence add -d <source-sequence-dir> --to-dir <destination-sequence-dir>
```

For example:

```bash
segul sequence add -d source-sequence/ --to-dir destination-sequence/
```

## Specify the input format

The command above will look for any FASTA, NEXUS, or PHYLIP format sequences in the source directory and add them to the destination directory. You can specify the input format using the `--input-format` option. For example, to add sequences in NEXUS format, use the command below:

```bash
segul sequence add -d <source-sequence-dir> --to-dir <destination-sequence-dir> --input-format nexus
```

You can specify the destination format using the `--to-fmt` option. For example, to add sequences in NEXUS format to the destination directory in FASTA format, use the command below:

```bash
segul sequence add -d <source-sequence-dir> --to-dir <destination-sequence-dir> --input-format nexus --to-fmt fasta
```

## Specify the output directory name and format

By default, the output directory will be named `Sequence-Addition`. You can change the output directory name using the `--output` or `-o` option. For example, to name the output directory `seq-add`, use the command below:

```bash
segul sequence add -d <source-sequence-dir> --to-dir <destination-sequence-dir> --output seq-add
```

The output format will be in interleaved FASTA format. The other option is in sequential FASTA format. Use the `--output-format fasta` or `-F fasta` option to change the output to sequential FASTA format. For example:

```bash
segul sequence add -d <source-sequence-dir> --to-dir <destination-sequence-dir> --output-format fasta
```

## Output only the added sequences

By default, SEGUL will output all sequences in the destination directory. If the destination directory format differs from the output format, all the output will be changed to the selected output format. If you only want to output files with the added sequences, use the `--added-only` flag. For example:

```bash
segul sequence add -d <source-sequence-dir> --to-dir <destination-sequence-dir> --added-only
```

## All options

| Option                  | Description                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------- |
| `-d`, `--dir`           | Directory with the sequences to add                                                           |
| `-i`, `--input`         | Sequence files. Allows wildcards                                                   |
| `-f`, `--input-format`  | Input format: `auto` (default), `fasta`, `nexus`, or `phylip`                       |
| `--datatype`            | Data type: `dna` (default), `aa`, or `ignore`                                       |
| `--to-dir`              | Directory with the files to add sequences to                                        |
| `--to-input`            | Files to add sequences to. Allows wildcards                                         |
| `--to-fmt`              | Format of the files to add to: `auto` (default), `fasta`, `nexus`, or `phylip`      |
| `--to-file`             | Add all sequences to a single file instead                                          |
| `--added-only`          | Only write files that received new sequences                                        |
| `--include-filename`    | Add the source file name to sequence IDs. Only with `--to-file`                     |
| `-F`, `--output-format` | Output format: `fasta-int` (default) or `fasta`                                     |
| `-o`, `--output`        | Output directory. Default: `Sequence-Addition`                                      |
| `--force`               | Overwrite an existing output directory                                              |
| `--log`                 | Log file path. Default: `segul.log`                                                 |

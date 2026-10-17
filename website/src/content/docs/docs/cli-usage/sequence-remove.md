---
title: Sequence Removal
sidebar:
  order: 17
---

Based on a list of IDs, you can remove sequences in a collection of alignments. This feature is the opposite of the `segul sequence extract` feature. Removing less than half of the sequences is faster than `segul sequence extract`.

## Remove sequences based on a list of IDs

You can remove sequences based on a list of sequence IDs. Input a list of IDs as a string separated by semi-colons.

```bash
segul sequence remove --dir [alignment-dir] -f [sequence-format-keyword] --id="[list-of-id]"
```

Example:

```bash
segul sequence remove --dir ./data/ -f fasta --id="seq_1;seq_2;seq_3"
```

:::caution
To input a list of IDs, you must use the equal sign "=" and quotation marks `"`.
:::

## Remove sequences based on a regular expression

Using regular expression:

```bash
segul sequence remove --dir [alignment-dir] -f [sequence-format-keyword] --re="[regex]"
```

Example:

The command below will remove all sequences whose IDs with the name started with `Mus`.

```bash
segul sequence remove --dir ./data/ -f fasta --re="^Mus"
```

## All options

| Option                  | Description                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------- |
| `-d`, `--dir`           | Directory with alignments                                                           |
| `-i`, `--input`         | Alignment files. Allows wildcards                                                   |
| `-f`, `--input-format`  | Input format: `auto` (default), `fasta`, `nexus`, or `phylip`                       |
| `--datatype`            | Data type: `dna` (default), `aa`, or `ignore`                                       |
| `--id=`                 | Sequence IDs to remove, separated by semicolons                                     |
| `--re=`                 | Regular expression that matches the sequence IDs to remove                          |
| `-F`, `--output-format` | Output format: `nexus` (default), `phylip`, `fasta`, `nexus-int`, `phylip-int`, or `fasta-int` |
| `-o`, `--output`        | Output directory. Default: `Sequence-Remove`                                        |
| `--force`               | Overwrite an existing output directory                                              |
| `--log`                 | Log file path. Default: `segul.log`                                                 |

---
title: Sequence ID Extraction
sidebar:
  order: 15
---

Often, we need to know what the taxa in our dataset are. The most straightforward command would be:

```bash
segul sequence id -i [input-path]
```

or using directory input:

```bash
segul sequence id -d alignment_dir
```

SEGUL will generate the unique ID across all input alignments. The output is a text file containing a list of the IDs in alphabetical order. By default, the output directory is `Sequence-ID`. The file will be saved as `id.txt` in the output directory. For example, if all your alignments contain three samples, the output file will look like this:

```text
sequence_1
sequence_2
sequence_3
```

To change the output directory, use the `-o` or `--output` option:

```bash
segul sequence id -d alignments/ -o my_alignment_id
```

To change the output file name, use the `--prefix` option:

```bash
segul sequence id -d alignments/ --prefix my_alignment_id
```

:::note
Before version 0.19.0, the SEGUL CLI outputs the sequence IDs in the current working directory. The output option will only change the file name.
:::

## All options

| Option                  | Description                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------- |
| `-d`, `--dir`           | Directory with alignments                                                           |
| `-i`, `--input`         | Alignment files. Allows wildcards                                                   |
| `-f`, `--input-format`  | Input format: `auto` (default), `fasta`, `nexus`, or `phylip`                       |
| `--datatype`            | Data type: `dna` (default), `aa`, or `ignore`                                       |
| `--map`                 | Also write the presence of each ID in each alignment                                |
| `-o`, `--output`        | Output directory. Default: `Sequence-ID`                                            |
| `-p`, `--prefix`        | Prefix of the output files                                                          |
| `--force`               | Overwrite an existing output directory                                              |
| `--log`                 | Log file path. Default: `segul.log`                                                 |

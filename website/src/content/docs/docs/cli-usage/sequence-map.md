---
title: Sequence ID Mapping
sidebar:
  order: 16
---

To map the distribution of your samples across your dataset, you only need to pass `--map` flag in the finding unique IDs command:

```bash
segul sequence id -i [input-path] --map
```

It will generate two files, saved to `Sequence-ID` by default. The first file is the list of unique IDs in your dataset (named default to id.txt). This file is similar to generating unique IDs. The second file is a CSV file (named default to `map.csv`) containing the distribution of your samples presented in `true`/`false` values across your alignments. The content of the file will look like as below:

| locus   | sequence_1 | sequence_2 | sequence_3 |
| ------- | ---------- | ---------- | ---------- |
| locus_1 | true       | false      | true       |
| locus_2 | true       | true       | true       |
| locus_3 | false      | false      | true       |

To change the output directory, use the `-o` or `--output` option:

```bash
segul sequence id -d alignments/ --map -o my_alignment_id
```

To change the output file name, use the `--prefix` option:

```bash
segul sequence id -d alignments/ --map --prefix my_alignment_id
```

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

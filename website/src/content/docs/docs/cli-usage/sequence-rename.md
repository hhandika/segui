---
title: Sequence ID Renaming
sidebar:
  order: 18
---

SEGUL provides an easy way to rename sequence IDs across all your alignments. To use this function, SEGUL requires a list of the original IDs and the names it needs to change. The input IDs can be written in a tabulated format as a comma-delimited file (`.csv`) or a tab-delimited file (`.tsv`).

The table must contain two columns with a header for each column. Both the header names and the IDs should contain no space. The name of the header does not matter. You'll be able to name it whichever makes sense for you. It is only there for record keeping. The order of the columns, however, is essential. The first column should be the original IDs, and the second should be the new ones. For example:

| Original_names        | New_names                |
| --------------------- | ------------------------ |
| Genus_species1_random | Genus_species1_voucherID |
| Genus_species2_random | Genus_species2_voucherID |

:::tip
If you need to rename a lot of sequence IDs, you can simplify the process by [generating the unique IDs first](/docs/cli-usage/sequence-id/). Then, copy the IDs you want to rename in the `csv` or `tsv` input. Use the `--replace-id` option to input this file. SEGUL will infer the file format based on its extension. The full command is structured as below:

```bash
segul sequence rename -d [alignment-dir] -f [sequence-format-keyword] --replace-id [file-path-to-IDs]
```

For example:

```bash
segul sequence rename -d alignments/ -f nexus --replace-id new_names.csv
```

:::

You can use `--dry-run` option to check if the input names are parsed correctly:

```bash
segul sequence rename -d alignments/ -f nexus --replace-id new_names.csv --dry-run
```

By default, SEGUL will write the result in `Sequence-Rename` directory. To change the output directory, use the `--output` or `-o` option.

```bash
segul sequence rename -d alignments/ --input-format nexus --replace-id new_names.csv --output new_seq_names/
```

Like other functions, SEGUL will not overwrite your original files. The output files will default to NEXUS. To change the output format, use the `--output-format` or `-F` function:

```bash
segul sequence rename -d alignments/ --input-format nexus --replace-id new_names.csv --output new_seq_names/ --output-format fasta
```

## Other renaming options

### Remove matching input text

You can remove a matching text from the sequence ID. This is useful if you have a common text in all your sequence IDs that you want to remove. For example, if all your sequence IDs have a common suffix `_contigs`, you can remove this suffix using the `--remove` option:

```bash
segul sequence rename -d alignments/ --input-format nexus --remove _contigs
```

### Remove matching regular expression

You can also remove a matching regular expression from the sequence ID. This is useful if you have a common pattern in all your sequence IDs that you want to remove. For example, if all your sequence IDs have a common prefix `locus` followed by a number, you can remove this pattern using the `--remove-re`:

```bash
segul sequence rename -d alignments/ --input-format nexus --remove-re="^locus[0-9]"
```

Suppose multiple patterns exist in a single sequence ID. The command above will only remove the first matching pattern. Then, it will continue to look for the same pattern in the following sequence ID.

You can also remove all the matches found in a single sequence ID by using the `--remove-re-all` option instead:

```bash
segul sequence rename -d alignments/ --input-format nexus --remove-re-all="locus[0-9]"
```

### Find and replace a matching text

You can also replace a matching text from the sequence ID. For example, you can replace `locus01` with `locus1` using the `--replace-from` and `--replace-to` options:

```bash
segul sequence rename -d alignments/ --input-format nexus --replace-from="locus01" --replace-to="locus1"
```

### Find and replace a matching regular expression

You can also replace a regular expression matching the sequence ID. For example, if all your sequence IDs have a common prefix `locus` followed by a number, you can use the regular expression `^locus[0-9]` to match the pattern. Use the `--replace-from-re` and `--replace-to` options to replace the matching prefix. Use `--replace-from-re-all` to replace every match in each ID:

```bash
segul sequence rename -d alignments/ --input-format nexus --replace-from-re="^locus[0-9]" --replace-to="locus"
```

## All options

| Option                  | Description                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------- |
| `-d`, `--dir`           | Directory with alignments                                                           |
| `-i`, `--input`         | Alignment files. Allows wildcards                                                   |
| `-f`, `--input-format`  | Input format: `auto` (default), `fasta`, `nexus`, or `phylip`                       |
| `--datatype`            | Data type: `dna` (default), `aa`, or `ignore`                                       |
| `--replace-id`          | CSV or TSV file of original and new IDs                                             |
| `--dry-run`             | Check the parsed IDs without writing files                                          |
| `--remove`              | Remove matching text                                                                |
| `--remove-re=`          | Remove the first match of a regular expression                                      |
| `--remove-re-all=`      | Remove all matches of a regular expression                                          |
| `--replace-from=`       | Text to replace. Use with `--replace-to=`                                           |
| `--replace-from-re=`    | Replace the first match of a regular expression. Use with `--replace-to=`           |
| `--replace-from-re-all=`| Replace all matches of a regular expression. Use with `--replace-to=`               |
| `--replace-to=`         | Replacement text                                                                    |
| `-F`, `--output-format` | Output format: `nexus` (default), `phylip`, `fasta`, `nexus-int`, `phylip-int`, or `fasta-int` |
| `-o`, `--output`        | Output directory. Default: `Sequence-Rename`                                        |
| `--force`               | Overwrite an existing output directory                                              |
| `--log`                 | Log file path. Default: `segul.log`                                                 |

Use one renaming option per run. Options that end with `=` need the equal sign, with the value in quotes.

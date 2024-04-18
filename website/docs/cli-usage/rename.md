---
sidebar_position: 12
title: Sequence ID Renaming
---

`segul` provide an easy way to rename sequence IDs across all your alignments. To use this function, segul require a list of the original IDs and the the name IDs that it needs to change to. The input IDs can be written in a tabulated format as a comma-delimited file (`.csv`) or a tab-delimited file (`.tsv`).

The table must contain two columns with a header for each column. Both the header names and the IDs should contain no space. The name of the header does not matter. You can name it whichever makes sense for you. It is only there for record keeping. The order of the column, however, is important. The first column should be the original IDs and the second column should the new IDs. For example:

| Original_names        | New_names                |
| --------------------- | ------------------------ |
| Genus_species1_random | Genus_species1_voucherID |
| Genus_species2_random | Genus_species2_voucherID |

:::tip
If you need to rename a lot of sequence ID, you can simplify the process by [generating the unique IDs first](./id). Then, copy the IDs that you would like to rename in the `csv` or `tsv` input. To input this file, we will use the `--replace-id` option. `segul` will infer the file format based on its extension. The full command is structure as below:
:::

```Bash
segul sequence rename -d [alignment-dir] -f [sequence-format-keyword] --replace-id [file-path-to-IDs]
```

For example:

```Bash
segul sequence rename -d alignments/ -f nexus --replace-id new_names.csv
```

You can use `--dry-run` option to check if the input names are parsed correctly:

```Bash
segul sequence rename -d alignments/ -f nexus --replace-id new_names.csv --dry-run
```

By default, `segul` will write the result in `SEGUL-Rename` directory. To change the output directory, use the `--output` or `-o` option.

```Bash
segul sequence rename -d alignments/ --input-format nexus --replace-id new_names.csv --output new_seq_names/
```

Like other functions, `segul` will not overwrite your original files. The output files will be default to nexus. To change the output format use the `--output-format` or `-F` function:

```Bash
segul sequence rename -d alignments/ --input-format nexus --replace-id new_names.csv --output new_seq_names/ --output-format fasta
```

## Other renaming options

### Remove matching input text

You can remove a matching text from the sequence ID. This is useful if you have a common text in all your sequence IDs that you would like to remove. For example, if all your sequence IDs have a common suffix `_contigs`, you can remove this suffix using the `--remove` or `-r` option:

```Bash
segul sequence rename -d alignments/ --input-format nexus --remove _contigs
```

### Remove matching regular expression

You can also remove a matching regular expression from the sequence ID. This is useful if you have a common pattern in all your sequence IDs that you would like to remove. For example, if all your sequence IDs have a common prefix `locus` followed by a number, you can remove this pattern using the `--remove-re`:

```Bash
segul sequence rename -d alignments/ --input-format nexus --remove-re ^locus[0-9]
```

If multiple pattern exist in a single sequence ID. The command above will only remove the first matching pattern in it. Then, it will continue to look for the same pattern in the next sequence ID.

You can also remove all the matches found in a sequence ID by using the `--remove-all` option:

```Bash
segul sequence rename -d alignments/ --input-format nexus --remove-re ^locus[0-9] --remove-all
```

### Find and replace a matching text

You can also replace a matching text from the sequence ID. This is useful if you have a common text in all your sequence IDs that you would like to replace. For example, you can replace `locus01` with `locus` using the `--replace-from` and `--replace-to` options:

```Bash
segul sequence rename -d alignments/ --input-format nexus --replace-from locus01 --replace-to locus
```

### Find and replace a matching regular expression

You can also replace a matching regular expression from the sequence ID. This is useful if you have a common pattern in all your sequence IDs that you would like to replace. For example, if all your sequence IDs have a common prefix `locus` followed by a number, you can replace this pattern using the `--replace-from-re` and `--replace-to` options:

```Bash
segul sequence rename -d alignments/ --input-format nexus --replace-from-re ^locus[0-9] --replace-to locus
```

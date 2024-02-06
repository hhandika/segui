---
sidebar_position: 12
---

# Sequence ID Renaming

`segul` provide an easy way to rename sequence IDs across all your alignments. To use this function, segul require a list of the original IDs and the the name IDs that it needs to change to. The input IDs can be written in a tabulated format as a comma-delimited file (`.csv`) or a tab-delimited file (`.tsv`).

The table must contain two columns with a header for each column. Both the header names and the IDs should contain no space. The name of the header does not matter. You can name it whichever makes sense for you. It is only there for record keeping. The order of the column, however, is important. The first column should be the original IDs and the second column should the new IDs. For example:

| Original_names        | New_names                |
| --------------------- | ------------------------ |
| Genus_species1_random | Genus_species1_voucherID |
| Genus_species2_random | Genus_species2_voucherID |

If you need to rename a lot of sequence ID, you can simplify the process by [generating the unique IDs first](./id). Then, copy the IDs that you would like to rename in the `csv` or `tsv` input. To input this file, we will use the `--name` or `-n` option. `segul` will infer the file format based on its extension. The full command is structure as below:

```Bash
segul sequence rename -d [alignment-dir] -f [sequence-format-keyword] -n [file-path-to-IDs]
```

For example:

```Bash
segul sequence rename -d alignments/ -f nexus -n new_names.csv
```

You can use `--dry-run` option to check if the input names are parsed correctly:

```Bash
segul sequence rename -d alignments/ -f nexus -n new_names.csv --dry-run
```

By default, `segul` will write the result in `SEGUL-Rename` directory. To change the output directory, use the `--output` or `-o` option.

```Bash
segul sequence rename -d alignments/ --input-format nexus --name new_names.csv --output new_seq_names/
```

Like other functions, `segul` will not overwrite your original files. The output files will be default to nexus. To change the output format use the `--output-format` or `-F` function:

```Bash
segul sequence rename -d alignments/ --input-format nexus --name new_names.csv --output new_seq_names/ --output-format fasta
```

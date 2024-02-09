---
sidebar_position: 12
---

# Sequence ID Renaming

A quick way to rename sequence IDs in across many alignments.

## Steps

1. Select the `Alignment` button from the navigation bar.
2. Select `Rename sequence IDs` from the dropdown menu.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. Select renaming parameters.
5. Add the output directory by clicking the `Add directory` button.
6. Select the output sequence format.
7. Click the `Run` button labeled `Rename` to start the task.

## Renaming Parameters

### Input file

Example input file:

The first column should be the original IDs and the second column should the new IDs. Save as `.tsv` or `.csv`. For example:

| Original_names        | New_names                |
| --------------------- | ------------------------ |
| Genus_species1_random | Genus_species1_voucherID |
| Genus_species2_random | Genus_species2_voucherID |

:::tip
You can use the [sequence ID extraction](./sequence-id) feature to generate all the unique sequence IDs in your dataset. Then, input the file into an Excel sheet and add the new names in the second column.
:::

### Remove text

You can remove a specific text from the sequence IDs. For example, you can remove `_contigs` from all the sequence IDs.

### Remove regular expression

Use the regular expression to remove a specific pattern from the sequence IDs. For example, you can remove `^locus[0-9]` from all the sequence IDs. This will remove all the sequence IDs starting with `locus` followed by a number. If you select `remove all matches`, it will remove all the matches found in a sequence ID. Otherwise, it will remove the first match found in a sequence ID, then continue to the next sequence ID.

### Find and replace string

You can find a specific text and replace it with another text. For example, you can replace `locus01` with `locus`.

### Find and replace regular expression

Use the regular expression to find a specific pattern and replace it with a string. For example, you can replace `^locus[0-9]` with `locus`. This will replace all the sequence IDs starting with `locus` followed by a number with `locus`. Similar to other regular expression options, you can select `replace all matches` to replace all the matches found in a sequence ID.

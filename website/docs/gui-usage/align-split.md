---
sidebar_position: 6
---

# Alignment Splitting

Split alignments into multiple files based on the partition.

## Steps

1. Select the `Alignment` button from the navigation bar.
2. Select `Split alignments` from the dropdown menu.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. Select the output directory by clicking the `Add directory` button.
5. Input alignment partition.
6. Add the output directory by clicking the `Add directory` button.
7. Add prefix for the output files.
8. Add output format.
9. Click the `Run` button labeled `Split` to start the task.

## Input Partition

The app supports input partition formats. The input partition format is the format of the partition file you want to split. Partition options include:

- **Charset**: partition embedded in NEXUS sequence files
- **Nexus**: partition file in NEXUS format
- **Raxml**: partition file in RAxML format

It supports standard and codon model partitions. However, merged partitions are not supported. The partition format will include the datatype as below:

```Text
DNA, locus_1 = 1-100
DNA, locus_2 = 101-150
DNA, locus_3 = 151-200
```

Unsupported partition format examples:

```Text
DNA, part1 = 1-100, 201-300
DNA, part2 = 101-200
```

## Check Partition for Errors

The app checks for the following rules:

1. First partition position starts with 1.
2. The next partition is next number after the end of the previous partition. If codon model, it will check the next locus applies the rule.

## Prefix

The prefix is the name of the output files.  For example, if the prefix is `output`, the app will generate `output_locus1`, `output_locus2`, and so on.

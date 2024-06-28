---
sidebar_position: 6
---

# Alignment Partition Conversion

Convert partition from one format to another.

## Steps

1. Select the `Alignment` button from the navigation bar.
2. Select `Convert partition` from the dropdown menu.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. Select input partition format.
5. Add the output directory by clicking the `Add directory` button.
6. Select output partition format.
7. Click the `Run` button labeled `Convert` to start the task.

## Partition Format

The app supports input and output partition formats. The input partition format is the format of the partition file you want to convert. The output partition format is the format of the partition file you want to generate. Partition options include:

- **Charset**: partition embedded in NEXUS sequence files
- **Nexus**: partition file in NEXUS format
- **Raxml**: partition file in RAxML format

For DNA sequences, we recommend using the `--datatype dna` option when converting to RAxML partition format. The partition format will include the datatype as below:

```Text
DNA, locus_1 = 1-100
DNA, locus_2 = 101-150
DNA, locus_3 = 151-200
```

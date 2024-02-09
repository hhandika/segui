---
sidebar_position: 5
---

# Alignment Filtering

This page provides guidelines for filtering multiple sequence alignments using SEGUI. We recommend checking the [general guidelines](./general) before using the app. This page covers the following topics:

- [Steps](#steps)
- [Parameters](#parameters)
- [Concatenating the output](#concatenating-the-output)

## Steps

1. Select the `Alignments` button from the navigation bar.
2. Select `Filter alignments` from the dropdown menu.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. All the input files will be displayed in the input tab bar. You can remove the file by clicking the `Remove` button. Removing the file will only remove it from input list and not from the file system.
5. Select input format (optional). See the [supported file extensions](./general#supported-file-extensions) for the list of supported extensions for alignment files.
6. Add filtering parameters.
7. Add the output directory by clicking the `Add output directory` button. On mobile platforms, the directory will be the default directory for the app.
8. Set to concatenate the output (optional).
9. Click the `Run` button labeled `Filter` to start the task.
10. Share the output (optional).

## Parameters

The app allows you to filter alignments based on the following parameters:

### Minimal length

The app will filter out sequences that are shorter than the minimum alignment length (number of sites). The input is a positive integer, such as 100 for 100 sites.

### Minimal taxa

This filter is based on the taxon completeness. The app will filter out alignments that have fewer taxa than the minimum number of taxa. For example, given a collection of alignments with 100 taxa with 90 percent completeness, segul will filter alignments with at least containing 90 taxa. The input is a decimal number between 0 and 1, such as 0.9 for 90 percent completeness.

### Parsimony informative sites

The app will filter out alignments that have fewer parsimony informative sites than the minimum number of parsimony informative sites. The input is a positive integer, such as 100 for 100 parsimony informative sites.

### Percent of parsimony informative sites

The value is counted based on to highest number of parsimony informative sites across all input alignments. The app will filter out alignments that have fewer parsimony informative sites than the minimum percent of parsimony informative sites. The input is a decimal number between 0 and 1, such as 0.1 for 10 percent of parsimony informative sites.

## Concatenating the output

You can opt to concatenate the output by clicking the `Concatenate output` button. It will show the parameters to concatenate the output. It similar to the [alignment concatenation](./concat.md) parameters. The app will concatenate the output based on the parameters you set. The app will also create a partition file.

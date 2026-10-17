---
title: Alignment Trimming
sidebar:
  order: 7
---

Trim alignment sites based on the proportion of missing data or the number of parsimony informative sites.

## Steps

1. Select the `Alignments` button from the navigation bar.
2. Select `Trim alignments` from the tool list. On narrower windows, select the tool name at the top of the page to switch tools.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. Select the input format (optional) and the data type.
5. Select the trimming method and enter its value.
6. Select the output directory by clicking the `Add directory` button.
7. Select the output format. Turn on `Set interleaved format` to write interleaved output (optional).
8. Click the `Run` button labeled `Trim` to start the task.

## Parameters

### Maximal missing data per site

The app keeps sites whose proportion of missing data (`-` or `?`) is at most the value. The input is a decimal number between 0 and 1. For example, 0.5 removes sites where more than half of the samples have missing data.

### Parsimony informative sites

The app keeps sites with at least the given number of parsimony informative characters. The input is a whole number, such as 2.

## Output

The trimmed alignments are written to a `trimmed_alignments` folder in the output directory. The app also writes `trimming_summary.csv`, which lists the number of sites in each alignment before and after trimming. Alignments with no remaining sites are not written.

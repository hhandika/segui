---
title: Sequence Filtering
sidebar:
  order: 14
---

Remove sequences inside each file based on their length or proportion of gaps. Unlike [alignment filtering](/docs/gui-usage/align-filter/), which keeps or drops whole alignments, this task keeps or drops individual sequences.

## Steps

1. Select the `Sequences` button from the navigation bar.
2. Select `Filter sequences` from the tool list. On narrower windows, select the tool name at the top of the page to switch tools.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. Select the input format (optional) and the data type.
5. Select the filtering method and enter its value.
6. Select the output directory by clicking the `Add directory` button.
7. Select the output format. Turn on `Set interleaved format` to write interleaved output (optional).
8. Click the `Run` button labeled `Filter` to start the task.

## Parameters

### Minimal sequence length

The app removes sequences with fewer non-gap characters than the value. The input is a whole number, such as 100.

### Maximal sequence length

The app removes sequences with more non-gap characters than the value. The input is a whole number, such as 5000.

### Maximal proportion of gaps

The app removes sequences whose proportion of gaps (`-` or `?`) is greater than the value. The input is a decimal number between 0 and 1, such as 0.3.

## Output

The app writes one file for each input file, named after the input file, with the sequences that pass the filter.

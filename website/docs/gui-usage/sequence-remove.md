---
sidebar_position: 15
---

# Sequence Removal

This feature is the opposite of [sequence extraction](./sequence-extract) feature. It removes sequences based on a list of IDs or a regular expression. It is faster than sequence extraction if you remove less than a half of the sequences.

## Steps

1. Select the `Alignment` button from the navigation bar.
2. Select `Remove sequences` from the dropdown menu.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. Select the option to remove sequences based on a list of IDs or a regular expression.
5. Add the list of IDs or regular expression.
6. Add the output directory by clicking the `Add directory` button.
7. Select the output sequence format.
8. Click the `Run` button labeled `Remove` to start the task.

## Removal Options

### Remove by ID

The IDs should be separated by semicolon (`;`). For example, `seq1;seq2;seq3`.

### Remove by Regular Expression

SEGUI uses Rust [regex](https://docs.rs/regex/latest/regex/). The regular expression should be a valid regex pattern. For example, `seq[0-9]+` will remove all sequences with IDs like `seq1`, `seq2`, `seq3`, and so on.

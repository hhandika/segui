---
sidebar_position: 14
---

# Sequence Extraction

Extract sequences from alignment files based on sequence IDs or regular expression.

## Steps

1. Select the `Sequences` button from the navigation bar.
2. Select `Extract sequences` from the dropdown menu.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. All the input files will be displayed in the input tab bar. You can remove the file by clicking the `Remove` button. Removing the file will only remove it from input list and not from the file system.
5. Select input format (optional). See the [supported file extensions](/docs/features#supported-file-extensions) for the list of supported extensions for alignment files.
6. Add extraction parameters.
7. Add the output directory by clicking the `Add output directory` button. On mobile platforms, the directory will be the default directory for the app.
8. Click the `Run` button labeled `Extract` to start the task.
9. Share the output (optional).

## Parameters

The app allows you to extract sequences based on the following parameters:

### Input ID in a file

The app allows you to input a file containing sequence IDs to extract. The app will use the file to match the sequence ID. The file should be in plain text format. Each line should contain one sequence ID.

```plaintext
seq1
seq2
seq3
```

### Input semi-colon separated IDs

The app will use the sequence IDs to match the sequence ID.

```plaintext
seq1;seq2;seq3
```

### Write regular expression

The regular expression will be used to match the sequence ID. The syntax for the regular expression follows the [Rust regex syntax](https://docs.rs/regex/1.6.1/regex/#syntax). You can use [regex101](https://regex101.com/) to test your regular expression.

Example:

- `^seq[0-9]+` will match all sequence ID that starts with `seq` followed by one or more numbers.
- `^seq[0-9]{2}` will match all sequence ID that starts with `seq` followed by exactly two numbers.
- `^rattus` will match all sequence ID that starts with `rattus`.

## Output file

All matched sequences will be extracted from each input file. The app will create a new file for each input file. For example, if theSet the format in output section to determine the output format.

---
sidebar_position: 4
---

# Alignment Conversion

Convert alignment from one format to another.

## Steps

1. Select the `Alignments` button from the navigation bar.
2. Select `Convert alignments` from the dropdown menu.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. All the input files will be displayed in the input tab bar. You can remove the file by clicking the `Remove` button. Removing the file will only remove it from input list and not from the file system.
5. Select input format (optional). See the [supported file extensions](/docs/features#supported-file-extensions) for the list of supported extensions for alignment files.
6. Add the output directory by clicking the `Add output directory` button. On mobile platforms, the directory will be the default directory for the app.
7. Set the output format.
8. Set the sort sequences (optional).
9. Click the `Run` button labeled `Convert` to start the task.
10. Share the output (optional).

### Output

The app will create converted files in the output directory. The app will display the output in the output tab bar once it's done.

#### Output format

The app supports FASTA, NEXUS, and PHYLIP output formats. By default, it sets to non-interleaved format. You can set it to interleaved format by clicking the `set interleave format` button. Use the `show more` button to see the options.

### Sort sequences

By default the app keep the original order of the sequence. You can sort the sequences by clicking the `Sort by sequence ID` button. The app will sort the sequences based on the sequence ID. The sorting is in alphanumeric order.

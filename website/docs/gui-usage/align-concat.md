---
sidebar_position: 3
---
# Alignment Concatenation

Concatenate multiple alignments into a single alignment with partition output.

## Steps

1. Select the `Alignments` button from the navigation bar.
2. Select `Concatenate alignments` from the dropdown menu.
3. Add the input files by clicking the `Add file` button. On desktop platforms, you can also input a directory by clicking the `Add directory` button. The app will look for matching files in the directory.
4. All the input files will be displayed in the input tab bar. You can remove the file by clicking the `Remove` button. Removing the file will only remove it from input list and not from the file system.
5. Select input format (optional). See the [supported file extensions](./general#supported-file-extensions) for the list of supported extensions for alignment files.
6. Add the output directory by clicking the `Add output directory` button. On mobile platforms, the directory will be the default directory for the app.
7. Set the prefix for the output file.
8. Set the output format.
9. Set the partition format (optional).
10. Click the `Run` button labeled `Concatenate` to start the task.
11. Share the output (optional).

## Prefix

The app will use the prefix to name the output file. In the CLI version, the app has a default prefix. However, for the GUI version, you need to set the prefix manually. The prefix will be used as the output file name for the concatenated alignment and the partition file.

For example, if you set the prefix to `concat`, for nexus output and RAxML partition, the app will create two files: `concat.nex` and `concat_partitions.txt`.

## Output format

The app supports FASTA, NEXUS, and PHYLIP output formats. By default, it sets to non-interleaved format. You can set it to interleaved format by clicking the `set interleave format` button. Use the `show more` button to see the options.

## Partition format

The app supports Charset, NEXUS, and RAxML. The charset option only works when the output is NEXUS. It also allows to set to codon model partition. Use the `show more` button to see the options.

## Output file

- Concatenated alignment file
- Partition file (optional)

For charset partition, the partition will be in the same file as the alignment.

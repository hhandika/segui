---
sidebar_position: 3
---
# Alignment Concatenation

This page provides guidelines for concatenating multiple sequence alignments using SEGUI. We recommned checking the [general guidelines](./general) before using the app. This page covers the following topics:

- [Alignment Concatenation](#alignment-concatenation)
  - [File Input](#file-input)
    - [Input format](#input-format)
      - [Supported file extensions](#supported-file-extensions)
    - [Data Type](#data-type)
    - [Output](#output)

## File Input

The app allows you to input multiple files. You can add more files to the input list by clicking the `Add files` button. This button is available on both mobile and desktop platforms. On desktop platforms, it also allows you to add files from a directory.

### Input format

SEGUI supports NEXUS, FASTA, and PHYLIP file formats. By default it sets to `Auto`. However, you can manually set the input format by clicking the `Format` button. The `Auto` option will automatically detect the file format based on the file extension. In most cases, the `Auto` is sufficient. The app will not allow you to add files with unsupported formats. If you encounter any issues with the input format, please report it to us.

#### Supported file extensions

- NEXUS: `.nex`, `.nexus`
- FASTA: `.fasta`, `.fa`, `.fna`, `.fsa`, `.fas`
- PHYLIP: `.phy`, `.phylip`

### Data Type

The app supports both nucleotide and amino acid sequences. By default, it sets to `DNA`. You can also use `Ignore` to ignore the data type.

:::warning
We recommend using the `Ignore` option only if you are sure the file is intact and the output is not NEXUS.
:::

### Output

On desktop, you can add the output directory by clicking the `Add output directory` button. On mobile, the directory will be the default directory for the app. The directory name input will create a new directory if it doesn't exist inside the default directory.

#### Prefix

The app will use the prefix to name the output file. In the CLI version, the app has a default prefix. However, for the GUI version, you need to set the prefix manually. The prefix will be used as the output file name for the concatenated alignment and the partition file.

For example, if you set the prefix to `concat`, for nexus output and RAxML partition, the app will create two files: `concat.nex` and `concat_partitions.txt`.

#### Output format

The app supports FASTA, NEXUS, and PHYLIP output formats. By default, it sets to non-interleaved format. You can set it to interleaved format by clicking the `set interleave format` button. Use the `show more` button to see the options.

#### Partition format

The app supports Charset, NEXUS, and RAxML. The charset option only works when the output is NEXUS. It also allows to set to codon model partition. Use the `show more` button to see the options.

### Running the task

Click the `Run` button labeled `Concatenate` to start the task. We recommend to not leave the app window while the task is running. The app will display the output in the output tab bar once it's done.

#### Output file

- Concatenated alignment file
- Partition file (optional)

For charset partition, the partition will be in the same file as the alignment.

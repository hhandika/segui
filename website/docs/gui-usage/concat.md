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

The app saves the output in the user's chosen directory. However, due to the restrictive nature of mobile platforms, the application defaults to saving the output in its designated directory. To copy the output or share it with other applications or devices, simply utilize the 'Share' button. The quick share button will compress output files and share it as a single file, whereas the 'Share' button the `Output` window allows you to share the output individually.

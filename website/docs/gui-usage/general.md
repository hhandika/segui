---
sidebar_position: 0
title: General Guidelines
---

This page provides guidelines that are applicable to all tasks available in the app. For task-specific guidelines, refer to the respective task documentation.

## Task Selection

The app allows you to select a task from the navigation bar. Task categories include:

### Alignments

For tasks related to multiple sequence alignments, such as concatenation, conversion, filtering, and splitting.

- [Alignment concatenation](./align-concat)
- [Alignment conversion](./align-convert)
- [Alignment filtering](./align-filter)
- [Alignment splitting](./align-split)
- [Alignment partition conversion](./align-partition)
- [Alignment summary statistics](./align-summary)

### Genomic

For tasks related to genomic data, such as sequence read and contig.

- [Sequence read summary statistics](./genomic#sequence-read-summary-statistics)
- [Contig summary statistics](./genomic#contig-summary-statistics)

### Sequences

For works in sequence basis. The input can also be alignment files. We refer the input for these tasks throughout the documentation as **standard sequence files**.

- [Sequence extraction](./sequence-extract)
- [Sequence ID extraction](./sequence-id)
- [Sequence ID mapping](./sequence-id-map)
- [Sequence removal](./sequence-remove)
- [Sequence translation](./sequence-translate)

## File Input

The GUI version offer two input options for the desktop application and one input option for the mobile applications.

### Input from selected files (mobile and desktop)

This option requires users to select file individually. You can use the `Select All` button on mobile devices to select all files in a directory. On desktop platforms, you can use the `Ctrl/Cmd` or `Shift` key to select multiple files or use `Ctrl/Cmd + A` to select all files.

### Input from a directory (desktop only)

This option allows users to select a directory. The app will look for files in the directory and subdirectory that match the supported file extensions for the task. If you only interested to include the files in a directory, use the `Select files` button instead. Then, select the files in similar manner as mentioned above.

### Adding more files

For tasks that allow multiple input files, you can add more files to the input list by clicking the `Add files` button. This button is available on both mobile and desktop platforms. On desktop platforms, it also allows you to add files from a directory.

### Removing files

To remove a file, select the input tab. You can remove files from the input list by clicking the `remove` button. Removing files will not delete the files from your storage. It only removes them from the input list.

### Specific Guideline for Mobile Users

Phylogenomic datasets typically consist of over a thousand files. Mobile operating systems, including Android since SDK 30, forbid direct access to a file for security reasons. The app needs to cache input files to the app designated temporary directory. This process can be slow and may cause the app to crash if the device's RAM is insufficient. For Android, we suggest dividing the files into smaller batches for optimal performance. Our tests show that the app can handle up to 1,500 files at once on a [Xiaomi Redmi Note 12](https://www.gsmarena.com/xiaomi_redmi_note_12-12063.php) with 8 Gb of RAM. Smaller batches will make the input process faster and more stable. For iOS, we only able to input >1000 of files when the data stored in an external drive. Future updates will include support for compressed files, which will allow users to input large datasets more efficiently.

### Specific Guideline for macOS Users

Our app prioritizes security by utilizing [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox), which inherently limits its access to your file system to protect your data. When you first use the app, it may prompt you to grant permission for file access. Once granted, the app should already have permission to access the files you selected, whether they are stored in internal or external storage. However, if you encounter file access issues, we recommend allowing full disk access to the app. You can do this by going to `System Preferences > Security & Privacy > Privacy > Full Disk Access` and adding the app to the list. This will enable the app to access your files in the document folder.

## Input format

SEGUI supports NEXUS, FASTA, and PHYLIP file formats. By default it sets to `Auto`. However, you can manually set the input format by clicking the `Format` button. The `Auto` option will automatically detect the file format based on the file extension. Unlike, the CLI version, the GUI version will not allow inputting non-standard file extensions. If you have a non-standard file extension, you can change the file extension to one of the supported file extensions or use the CLI version.

:::note
The Android version may still allow non-standard file extensions. However, we recommend using the supported file extensions to avoid potential issues. Future updates may only support the standard file extensions.
:::

### Supported file extensions

#### Alignment and standard sequence files

List of supported file extensions for alignment and sequence tasks:

- NEXUS: `.nex`, `.nexus`, `.nxs`
- FASTA: `.fasta`, `.fa`, `.fna`, `.fsa`, `.fas`
- PHYLIP*: `.phy`, `.phylip`, `.ph`

:::note
SEGUL only supports relaxed PHYLIP format. The strict PHYLIP format is not supported.

Example of relaxed PHYLIP format:

```plaintext
5 10
Seq1    ATCGATCGATATCGATCGAT
Seq2    ATCGATCGATATCGATCGAT
Seq3    ATCGATCGATATCGATCGAT
```

Example of strict PHYLIP format (note the space between each sequence):

```plaintext
5 10

Seq1    ATCGATCGAT ATCGATCGAT
Seq2    ATCGATCGAT ATCGATCGAT
Seq3    ATCGATCGAT ATCGATCGAT
```

:::

#### Genomic data files

List of supported file extensions for genomic tasks:

- Sequence read: `.fastq`, `.fq`
- Compressed sequence read: `.fastq.gz`, `.fq.gz`
- Contig: `.fasta`, `.fa`, `.fna`, `.fsa`, `.fas`

## Data Type (alignment and standard sequence only)

The app supports both nucleotide and amino acid sequences. By default, it sets to `DNA`. You can also use `Ignore` to ignore the data type.

:::warning
We recommend using the `Ignore` option only if you are sure the file is intact and the output is not NEXUS.
:::

## Optional Parameters

Some tasks have optional parameters. Follow the task's documentation to learn more about the parameters and their usage.

## Output

On desktop platforms, the application saves the output in the user's chosen directory. However, due to the restrictive nature of mobile platforms, the application defaults to saving the output in its designated directory. To copy the output or share it with other applications or devices, simply utilize the `Share` button. The quick share button will compress output files and share it as a single file, whereas the `Share` button the `Output` window allows you to share the output individually.

## Sharing Output

The app allows you to share the output files to other devices or with other apps, such as [OneDrive](https://onedrive.live.com/), [DropBox](https://www.dropbox.com/), and other installed cloud provider apps. For instance, using AirDrop for macOS. After the app finishes executing a task, the "Run" button will be replace by a `Quick Share` button. Pressing this button will compress the output files and share them as a single file. Additionally, you can share individual files by clicking the `three dots menu button` for each file. Then, select `Share`.

## In-App built-in file viewer

Supported file types:

- Plain-text files (`.txt`)
- Comma separated values (`.csv`)

The app can directly view the supported file types. The content will be displayed in a new window. For a CSV file, the data is visualized in a table format with numbers formatted based on the locale settings of the device. For example in the US, the number will be formatted with thousand separator for integer and two decimal points for floating numbers (e.g., `1,000`, `0.65`). For the desktop version, you can also select open the file in other app. It will open default on default apps for the file type. This method also works for unsupported file types.

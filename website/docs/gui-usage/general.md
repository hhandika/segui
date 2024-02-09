---
sidebar_position: 0
---

# General Guidelines

This page provides general guidelines for using SEGUI. It covers the following topics:

- [File Input](#file-input)
  - [Input from selected files (mobile and desktop)](#input-from-selected-files-mobile-and-desktop)
  - [Input from a directory (desktop only)](#input-from-a-directory-desktop-only)
  - [Adding more files](#adding-more-files)
  - [Removing files](#removing-files)
  - [Specific Guideline for Smartphone Users](#specific-guideline-for-smartphone-users)
  - [Specific Guideline for macOS Users](#specific-guideline-for-macos-users)
- [Optional Parameters](#optional-parameters)
- [Output](#output)
- [Sharing Output](#sharing-output)

## File Input

The GUI version offer two input options for the desktop application and one input option for the mobile applications.

### Input from selected files (mobile and desktop)

This option requires users to select file individually. You can use the `Select All` button on mobile devices to select all files in a directory. On desktop platforms, you can use the `Ctrl/Cmd` or `Shift` key to select multiple files or use `Ctrl/Cmd + A` to select all files.

### Input from a directory (desktop only)

This option allows users to select a directory. The app will look for files that match the supported file extensions in the directory. Recursive search is not yet supported.

### Adding more files

For tasks that allow multiple input files, you can add more files to the input list by clicking the `Add files` button. This button is available on both mobile and desktop platforms. On desktop platforms, it also allows you to add files from a directory.

### Removing files

To remove a file, select the input tab. You can remove files from the input list by clicking the `remove` button. Removing files will not delete the files from your storage. It only removes them from the input list.

### Specific Guideline for Smartphone Users

Phylogenomic datasets typically consist of over a thousand files. Mobile operating systems, including Android since SDK 30, forbid direct access to a file for security reasons. The app to cache input files to the app designated temporary directory. This process can be slow and may cause the app to crash if the device's RAM is insufficient. We suggest dividing the files into smaller batches for optimal performance. Our tests show that the app can handle up to 1,500 files at once on a [Xiaomi Redmi Note 12](https://www.gsmarena.com/xiaomi_redmi_note_12-12063.php) with 8 Gb of RAM. Smaller batches will make the input process faster and more stable. Future updates will include support for compressed files, which will allow users to input large datasets more efficiently.

### Specific Guideline for macOS Users

Our app prioritizes security by utilizing [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox), which inherently limits its access to your file system to protect your data. During our testing phase on macOS Sonoma, we found that the app encountered issues when processing thousands of files stored in the document folder. However, it functioned as expected when the data was located in the download folder or an external drive. You can allow full disk access to the app by going to `System Preferences > Security & Privacy > Privacy > Full Disk Access` and adding the app to the list. This will allow the app to access your files in the document folder. However, we do not recommend this approach due to the security risks it poses. We are working on a solution to improve the app's performance when accessing files in the document folder.

## Input format

SEGUI supports NEXUS, FASTA, and PHYLIP file formats. By default it sets to `Auto`. However, you can manually set the input format by clicking the `Format` button. The `Auto` option will automatically detect the file format based on the file extension. In most cases, the `Auto` is sufficient. The app will not allow you to add files with unsupported formats. If you encounter any issues with the input format, please report it to us.

### Supported file extensions

#### Alignment and standard sequence files

List of supported file extensions for alignment and sequence tasks:

- NEXUS: `.nex`, `.nexus`
- FASTA: `.fasta`, `.fa`, `.fna`, `.fsa`, `.fas`
- PHYLIP: `.phy`, `.phylip`

#### Genomic data files

List of supported file extensions for genomic tasks:

- Sequence read: `.fastq`, `.fq`
- Compressed sequence read: `.fastq.gz`, `.fq.gz`
- Contig: `.fasta`, `.fa`, `.fna`, `.fsa`, `.fas`

## Data Type (Alignment and standard sequence only)

The app supports both nucleotide and amino acid sequences. By default, it sets to `DNA`. You can also use `Ignore` to ignore the data type.

:::warning
We recommend using the `Ignore` option only if you are sure the file is intact and the output is not NEXUS.
:::

## Optional Parameters

Some tasks have optional parameters. Follow the task's documentation to learn more about the parameters and their usage.

## Output

On desktop platforms, the application saves the output in the user's chosen directory. However, due to the restrictive nature of mobile platforms, the application defaults to saving the output in its designated directory. To copy the output or share it with other applications or devices, simply utilize the 'Share' button. The quick share button will compress output files and share it as a single file, whereas the 'Share' button the `Output` window allows you to share the output individually.

## Sharing Output

The app allows you to share the output files with other apps, such as OneDrive, DropBox, etc. or devices. For instance, using AirDrop for macOS. After the app finish executing a task, the "Run" button will be replace by the `Quick Share` button. Pressing this button will compress the output files and share them as a single file. You can also use the `Share` button in the `Output` window to share the output files individually.

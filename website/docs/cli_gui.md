---
sidebar_position: 2
---

# CLI vs GUI

## Platform Support

The GUI version of `segul` is available for all major desktop and mobile platforms. The CLI version is available for all major desktop platforms and Windows Subsystem for Linux (WSL). Here is a summary of the platform support for both versions:

### Desktop

| Platform                          | GUI | CLI |
| --------------------------------- | --- | --- |
| Linux                             | ✅   | ✅   |
| MacOS                             | ✅   | ✅   |
| Windows                           | ✅   | ✅   |
| Windows Subsystem for Linux (WSL) | ✅   | ✅   |

### Mobile

| Platform | GUI | CLI |
| -------- | --- | --- |
| iOS      | ✅   | ❌   |
| iPadOS   | ✅   | ❌   |
| Android  | ✅   | ❌   |

## Features comparison

All the main features are supported in both CLI and GUI. However, there are some differences between the two versions. In general, the GUI version provides interactive and user-friendly features, while the CLI version is more suitable for fast and memory efficient execution, automation, large-scale projects, and/or dealing with complex directory structure. Here is a summary of the differences:

| Feature                                              | CLI | GUI |
| ---------------------------------------------------- | --- | --- |
| Text and table viewer                                | ❌   | ✅   |
| Mobile OS support                                    | ❌   | ✅   |
| `--dry-run` option for some commands                 | ✅   | ❌   |
| Filter out alignment with multiple percentage values | ✅   | ❌   |
| Handling complex directory structure                 | ✅   | ❌   |

## Task Group

In general, the GUI and CLI version of `segul` have the same task group. The task group is equal to parent subcommand, whereas the task is equal to child subcommand in the CLI version. The CLI version has the same task group as the GUI version, except for contig summary statistics and partition conversion. The contig summary statistics is available in the contig subcommand. The partition conversion is available in the partition subcommand.

The task categories for GUI are:

### Genomics

Available tasks:

- Read summary statistics
- Contiguous summary statistics

### Alignments

Available tasks:

- Concatenation
- Conversion
- Filtering
- Splitting
- Partition conversion
- Summary statistics

### Sequences

Available tasks:

- Extraction
- ID extraction
- ID mapping
- Removal
- Translation

## Performance

The CLI version is faster and more memory-efficient than the GUI version. It is purely written in a high-performance programming language, Rust. For the GUI version, we use Flutter and Dart for the front-end and some light-weight backend code. However, the GUI version is still fast and memory-efficient for most use cases. On mobile devices supporting the GUI version, the input file access would require caching the file in the designated app temporary directory. This process might take longer than running CLI or GUI on desktop operating system and may no be possible for large files.

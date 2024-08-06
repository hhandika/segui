---
sidebar_position: 2
title: CLI vs GUI
---

For general users, SEGUL is available in two interfaces: **Command Line Interface** (CLI) and **Graphical User Interface** (GUI). Both have the same core functionality but are designed to cater to different use cases and user preferences.

Summary of the CLI version advantages:

- Faster and more memory-efficient
- Supports non-GUI platforms, such as HPC clusters.
- Supports non-standard file extensions
- Supports complex directory structure
- Supports filter-out alignments with multiple percentage values
- Supports `--dry-run` option for some commands
- Supports all major desktop platforms and Windows Subsystem for Linux (WSL)
- The ability to compile from the source code for any platform that supports Rust

Summary of the GUI version advantages:

- Interactive and user-friendly
- Supports text and table viewer without third-party software
- Supports mobile platforms
- Easier to use for users who are not familiar with the command line
- Available for all major desktop and mobile platforms but is limited by the Flutter framework platform support

:::note
You can install GUI and CLI interfaces in the system supporting them. Each operates in its own contained environment and does not interfere with the other.
:::

## Platform Support

The GUI is available for all major desktop and mobile platforms. The CLI is available for all major desktop platforms and Windows Subsystem for Linux (WSL). Here is a summary of the platform support:

### Desktop

| Platform                          | GUI | CLI |
| --------------------------------- | --- | --- |
| Linux*                            | ✅   | ✅   |
| MacOS                             | ✅   | ✅   |
| Windows*                          | ✅   | ✅   |
| Windows Subsystem for Linux (WSL) | ❌   | ✅   |

:::note
 The GUI on **Linux** required GLIBC 2.34+. The CLI works in any Linux distribution. We provide a fully static binary for older Linux and a dynamically linked binary to GLIBC for newer distributions. See [GUI](./installation/install_gui) and [CLI](./installation/install_binary) installation instruction for more details.

 You can also compile the CLI version from the source code for any platform that supports Rust. See [installation from source code](./installation/install_source) for more details.
:::

:::info
Since version 0.21.3, the CLI binary has also been available for ARM64 architecture on Linux.
:::

### Mobile

| Platform | GUI | CLI |
| -------- | --- | --- |
| iOS      | ✅   | ❌   |
| iPadOS   | ✅   | ❌   |
| Android  | ✅   | ❌   |

:::note
The CLI version works on Android using [Termux](https://termux.dev/). However, we recommend using the GUI version for better access to the file system.
:::

## Features comparison

All the main features are supported in both CLI and GUI. However, there are some differences between them. Here is a summary of the differences:

| Feature                                              | CLI | GUI |
| ---------------------------------------------------- | --- | --- |
| Text and table viewer                                | ❌   | ✅   |
| Mobile OS support                                    | ❌   | ✅   |
| `--dry-run` option for some commands                 | ✅   | ❌   |
| Filter out alignment with multiple percentage values | ✅   | ❌   |
| Handling complex directory structure                 | ✅   | ❌   |
| Non-standard file extensions                         | ✅   | ❌   |

## Task Group

The features are grouped into the kind of data they operate on. The alignment task group operates at the alignment level, taking input from alignment files. While taking alignment input, the sequence task group operates at the sequence level. The genomic task group takes input from genomic sequences, such as raw read FASTQ or contiguous sequence files. 

The GUI and CLI of SEGUL have similar task groups. In the CLI, the task group equals a command, and the task equals a subcommand.  The CLI task group's name is the same as the GUI version, except for **genomic summary statistics** and **partition conversion**. The genomic summary statistics are split into commands for sequence reads and contigs. The partition conversion is available in the partition command. 

Learn more about [CLI](/docs/cli-usage/command_options) and [GUI](/docs/gui-usage/general) options.

## Performance and Memory Efficiency

Generally, the CLI outperforms the GUI in terms of speed and memory efficiency. However, the GUI maintains similar speed and memory efficiency for most use cases on identical hardware (see below).

:::warning
For the GUI version on mobile devices, accessing the input file requires caching the file in the app’s designated temporary directory. This process may be more time-consuming, and handling many files may not be feasible. In our test on iOS, we could input up to 1,500 UCE loci on an iPhone 14. On Android, we could input over 4,000 UCE loci on a Xiaomi Redmi Note 12 by inputting the file in batches, with a maximum of 1,500 loci per batch. We are working on making the mobile app experience on par with the desktop app.
:::

## Performance Comparison

Below is a performance comparison for **alignment concatenation** across different platforms. We tested SEGUL CLI and GUI on Linux using identical hardware. We also include [AMAS](https://github.com/marekborowiec/AMAS) and [goalign](https://github.com/evolbioinfo/goalign) to provide additional context about SEGUL's performance. Learn more about testing methodology and more benchmarks on SEGUL [publication](https://doi.org/10.1111/1755-0998.13964).

### Execution time comparison

![Execution time comparison](/docs/img/execution_graph.svg)

### RAM usage comparison

![RAM usage comparison](/docs/img/ram_graph.svg)

:::note
The RAM usage comparison is only available for the desktop versions of SEGUL.
:::

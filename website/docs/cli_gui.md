---
sidebar_position: 2
---

# CLI vs GUI

## Platform Support

The GUI version of `segul` is available for all major desktop and mobile platforms. The CLI version is available for all major desktop platforms and Windows Subsystem for Linux (WSL). Here is a summary of the platform support for both versions:

### Desktop

| Platform                          | GUI | CLI |
| --------------------------------- | --- | --- |
| Linux                             | ✅  | ✅  |
| MacOS                             | ✅  | ✅  |
| Windows                           | ✅  | ✅  |
| Windows Subsystem for Linux (WSL) | ❌  | ✅  |

### Mobile

| Platform | GUI | CLI |
| -------- | --- | --- |
| iOS      | ✅  | ❌  |
| iPadOS   | ✅  | ❌  |
| Android  | ✅  | ❌  |

:::note
The CLI version works on Android using [Termux](https://termux.dev/). However, we recommend using the GUI version instead.
:::

## Performance

The CLI version is faster and more memory-efficient than the GUI version. It is purely written in a high-performance programming language, Rust. For the GUI version, we use Flutter and Dart for the front-end and some light-weight backend code. However, the GUI version is still fast and memory-efficient for most use cases. For GUI version on mobile devices, the input file access would require caching the file in the designated app temporary directory. This process might take longer than running CLI or GUI on desktop operating system and may not be possible for large files.

## Features comparison

All the main features are supported in both CLI and GUI. However, there are some differences between the two versions. In general, the GUI version provides interactive and user-friendly features, while the CLI version is more suitable for fast and memory efficient execution, automation, CLI only environment (e.g., HPC), large-scale projects, and/or dealing with complex directory structure. Here is a summary of the differences:

| Feature                                              | CLI | GUI |
| ---------------------------------------------------- | --- | --- |
| Text and table viewer                                | ❌  | ✅  |
| Mobile OS support                                    | ❌  | ✅  |
| `--dry-run` option for some commands                 | ✅  | ❌  |
| Filter out alignment with multiple percentage values | ✅  | ❌  |
| Handling complex directory structure                 | ✅  | ❌  |
| Non-standard file extensions                         | ✅  | ❌  |

## Task Group

The GUI and CLI version of `segul` have the same task group. The task group is equal to command, whereas the task is equal to subcommand in the CLI version. The name of the task group for CLI version is the same as the GUI version, except for contig summary statistics and partition conversion. The contig summary statistics is available in the contig subcommand. The partition conversion is available in the partition subcommand.

Learn more about [CLI](./cli-usage/command_options) and [GUI](./gui-usage/general) options.

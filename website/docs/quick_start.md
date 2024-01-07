---
sidebar_position: 2
---

# Quick Start

## CLI or GUI

If your answer is yes to any of the following questions, you should use the CLI version of the app. otherwise, either GUI or CLI will serve your need.

1. Are you planning to run the app on a High-Performance Computing (HPC) cluster or Linux system?
2. Do you run SEGUL as part of a pipeline?
3. Do you you need the utmost efficiency?

## Installation

Follow the installation instruction for your operating system. The CLI is available for Linux, MacOS, and Windows. The GUI is available for Windows, macOS, iOS, iPadOS, and Android.

The fastest installation route for CLI is using the pre-compiled binaries [here](./installation/install_binary). Get the most up to date link for GUI installation [here](./installation/install_gui).

## Usage quick links

| Feature                        | Quick Link                                                                                                                                |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Alignment concatenation        | [CLI](./cli-usage/concat) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_concat)                 |
| Alignment conversion           | [CLI](https://docs.page/hhandika/segul-docs/usage_convert) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_convert)               |
| Alignment filtering            | [CLI](https://docs.page/hhandika/segul-docs/usage_filter) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_filter)                 |
| Alignment splitting            | [CLI](https://docs.page/hhandika/segul-docs/usage_split) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_split)                   |
| Alignment partition conversion | [CLI](https://docs.page/hhandika/segul-docs/usage_part) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_part)                     |
| Alignment summary statistics   | [CLI](https://docs.page/hhandika/segul-docs/usage_summary) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_summary)               |
| Contig summary statistics      | [CLI](https://docs.page/hhandika/segul-docs/usage_contig_summary) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_contig_summary) |
| Raw read summary statistics    | [CLI](https://docs.page/hhandika/segul-docs/usage_raw_summary) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_raw_summary)       |
| Sample distribution mapping    | [CLI](https://docs.page/hhandika/segul-docs/usage_map) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_map)                       |
| Sequence extraction            | [CLI](https://docs.page/hhandika/segul-docs/usage_extract) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_extract)               |
| Sequence ID parsing            | [CLI](https://docs.page/hhandika/segul-docs/usage_id) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_id)                         |
| Sequence ID renaming           | [CLI](https://docs.page/hhandika/segul-docs/usage_rename) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_rename)                 |
| Sequence removal               | [CLI](https://docs.page/hhandika/segul-docs/usage_remove) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_remove)                 |
| Sequence translation           | [CLI](https://docs.page/hhandika/segul-docs/usage_translate) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_translate)           |
| Log file                       | [CLI](https://docs.page/hhandika/segul-docs/usage_log) / [GUI](https://docs.page/hhandika/segul-docs/gui_usage_log)                       |

## CLI Command List

Command below expect SEGUL version 0.19.0+. If you are using lower version, such as 0.18.0, ignore the parent subcommands and dir input option required input format.

For example:

```bash
segul alignment concat -d <input-directory>
```

should be:

```bash
segul concat -d <input-directory> -f <input-format>
```

| Feature                        | Commands                                                           |
| ------------------------------ | ------------------------------------------------------------------ |
| Alignment concatenation        | `segul align concat -d <input-directory>`                          |
| Alignment conversion           | `segul align convert -d <input-directory>`                         |
| Alignment filtering            | `segul align filter -d <input-directory> <filtering-options>`      |
| Alignment splitting            | `segul align split -d <input-directory>`                           |
| Alignment partition conversion | `segul partition convert -d <input-directory>`                     |
| Alignment summary statistics   | `segul align summary -d <input-directory>`                         |
| Contig summary statistics      | `segul contig summary -d <input-directory>`                        |
| Raw read summary statistics    | `segul read summary -d <input-directory>`                          |
| Sample distribution            | `segul sequence id --map -d <input-directory>`                     |
| Sequence extraction            | `segul sequence extract -d <input-directory> <extraction-options>` |
| Sequence ID parsing            | `segul sequence id -d <input-directory>`                           |
| Sequence ID renaming           | `segul sequence rename -d <input-directory>`                       |
| Sequence removal               | `segul sequence remove -d <input-directory>`                       |
| Sequence translation           | `segul sequence translate -d <input-directory>`                    |
| Main help                      | `segul --help`                                                     |
| Parent subcommand help         | `segul <subcommand> --help`                                        |
| Child subcommand help          | `segul <subcommand> <subcommand> --help`                           |

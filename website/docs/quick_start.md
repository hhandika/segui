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

| Feature                        | Quick Link                                                  |
| ------------------------------ | ----------------------------------------------------------- | --- |
| Alignment concatenation        | [CLI](./cli-usage/concat) / [GUI](./gui-usage/concat)       |
| Alignment conversion           | [CLI](./cli-usage/convert) / [GUI](./gui-usage/convert)     |
| Alignment filtering            | [CLI](./cli-usage/filter) / [GUI](./gui-usage/filter)       |
| Alignment splitting            | [CLI](./cli-usage/split) / [GUI](./gui-usage/split)         |
| Alignment partition conversion | [CLI](./cli-usage/partition) / [GUI](./gui-usage/partition) |
| Alignment summary statistics   | [CLI](./cli-usage/summary) / [GUI](./gui-usage/summary)     |
| Genomic summary statistics     | [CLI](./cli-usage/genomic) / [GUI](./gui-usage/genomic)     |     |
| Sequence extraction            | [CLI](./cli-usage/extract) / [GUI](./gui-usage/extract)     |
| Sequence ID extraction         | [CLI](./cli-usage/id) / [GUI](./gui-usage/id)               |
| Sequence ID mapping            | [CLI](./cli-usage/map.md) / [GUI](./gui-usage/id)           |
| Sequence ID renaming           | [CLI](./cli-usage/rename) / [GUI](./gui-usage/rename)       |
| Sequence removal               | [CLI](./cli-usage/remove) / [GUI](./gui-usage/remove)       |
| Sequence translation           | [CLI](./cli-usage/translate) / [GUI](./gui-usage/translate) |
| Log file                       | [CLI](./cli-usage/log) / [GUI](./gui-usage/log)             |

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

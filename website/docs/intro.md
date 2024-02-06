---
sidebar_position: 1
---

# Introduction

**Thank you for using SEGUL!** 🙏🏻

We develop `segul` to fill the need for a high-performance and accessible phylogenomic tools. The program is designed to be fast, memory-efficient, cross-platform, and easy to use. It is suitable for large-scale phylogenomic projects, especially for those who work with thousands of loci and hundreds of samples.

## Citation

> Heru Handika, Jacob Esselstyn. SEGUL: An ultrafast, memory-efficient alignment manipulation and summary tool for phylogenomics. _Authorea_. May 04, 2022. DOI: [10.22541/au.165167823.30911834/v1](https://www.authorea.com/doi/full/10.22541/au.165167823.30911834/v1).

## Platform Support

### Desktop

| Platform                          | GUI | CLI |
| --------------------------------- | --- | --- |
| Linux                             | ✅   | ✅   |
| MacOS                             | ✅   | ✅   |
| Windows                           | ✅   | ✅   |
| Windows Subsystem for Linux (WSL) | ❌   | ✅   |

### Mobile

| Platform | GUI | CLI |
| -------- | --- | --- |
| iOS      | ✅   | ❌   |
| iPadOS   | ✅   | ❌   |
| Android  | ✅   | ❌   |

## Quick Start ⏱️

### Command line (CLI) vs GUI

If your answer is yes to any of the following questions, you should use the CLI version of the app. Otherwise, either GUI or CLI will serve your need.

1. Are you planning to run the app on a High-Performance Computing (HPC) cluster?
2. Do you run SEGUL as part of a pipeline?
3. Do you you need the utmost efficiency?

### Installation

Follow the installation instruction for your operating system. The fastest installation route for CLI is using the pre-compiled binaries [here](./installation/install_binary). Get the most up to date link for GUI installation [here](./installation/install_gui).

### Usage

#### Usage quick links

| Feature                        | Quick Link                                                  |
| ------------------------------ | ----------------------------------------------------------- |
| Alignment concatenation        | [CLI](./cli-usage/concat) / [GUI](./gui-usage/concat)       |
| Alignment conversion           | [CLI](./cli-usage/convert) / [GUI](./gui-usage/convert)     |
| Alignment filtering            | [CLI](./cli-usage/filter) / [GUI](./gui-usage/filter)       |
| Alignment splitting            | [CLI](./cli-usage/split) / [GUI](./gui-usage/split)         |
| Alignment partition conversion | [CLI](./cli-usage/partition) / [GUI](./gui-usage/partition) |
| Alignment summary statistics   | [CLI](./cli-usage/summary) / [GUI](./gui-usage/summary)     |
| Genomic summary statistics     | [CLI](./cli-usage/genomic) / [GUI](./gui-usage/genomic)     |
| Sequence extraction            | [CLI](./cli-usage/extract) / [GUI](./gui-usage/extract)     |
| Sequence ID extraction         | [CLI](./cli-usage/id) / [GUI](./gui-usage/id)               |
| Sequence ID mapping            | [CLI](./cli-usage/map.md) / [GUI](./gui-usage/id)           |
| Sequence ID renaming           | [CLI](./cli-usage/rename) / [GUI](./gui-usage/rename)       |
| Sequence removal               | [CLI](./cli-usage/remove) / [GUI](./gui-usage/remove)       |
| Sequence translation           | [CLI](./cli-usage/translate) / [GUI](./gui-usage/translate) |
| Log file                       | [CLI](./cli-usage/log) / [GUI](./gui-usage/log)             |

#### GUI Usage

1. Open the app.
2. Use the navigation bar to select the feature you want to use. For example, if you want to concatenate alignments, click the "Alignments" button.
3. Use the dropdown menu to select the task. For example, if you want to concatenate alignments, select "Concatenate alignments".
4. Add the input files by clicking the "Add file" button. On desktop platforms, you can also input a directory by clicking the "Add directory" button. The app will look for matching files in the directory. All the input files will be displayed in the input tab bar.
5. Add the output directory by clicking the "Add output directory" button. On mobile platforms, the directory will be the default directory for the app.
6. For some tasks, you also need to add the parameters. For example, if you want to filter alignments, you need to add the filtering parameters.
7. Click the "Run" button to start the task.
8. Once it's done, the app will display the output in the output tab bar. You can also tab the file to open it in the app file viewer. Current version only support plain text and comma-separated (CSV) data.

:::note
The GUI version is still in beta. If you encounter any issues, please report them to the [issue tracker](https://github.com/hhandika/segui/issues).
:::

#### CLI Usage

`segul` command is structured as follows:

```bash
segul <parent-subcommand> <child-subcommand> --option1 value1 --option2 value2
```

For example, to concatenate alignments:

```bash
segul align concat --input alignments/*.nexus --output aln-concat
```

See the [command usage](./cli-usage/command_options.md) section for more detailed usage.

:::warning
Command below expect SEGUL version 0.19.0+. If you are using lower version, ignore the parent subcommands and dir input option required input format.

For example:

```bash
segul alignment concat -d <input-directory>
```

should be:

```bash
segul concat -d <input-directory> -f <input-format>
```

:::

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

## Additional Resources

- [API Documentation](https://docs.rs/segul/0.18.1/segul/)
- [GUI Source Code](https://github.com/hhandika/segui)
- [CLI & API Source Code](https://github.com/hhandika/segul)

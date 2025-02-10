---
sidebar_position: 2
title: Quick Start
---

## CLI vs GUI vs API

For general users, the choice will be between the command-line (CLI) and graphical interface (GUI) applications. If you answer yes to any of the following questions, use SEGUL CLI. Otherwise, either GUI or CLI will help you.

1. Are you planning to run the app in a non-GUI environment like an [HPC](https://www.ibm.com/topics/hpc) cluster?
2. Do you run SEGUL as part of a pipeline?
3. Do you need the utmost efficiency?

You can also install both interfaces and use them interchangeably. They operate in their environment and do not interfere with the other. Depending on workflow scenarios, you can take advantage of the strengths of either one. Learn more about the differences between the CLI and GUI versions [here](/docs/cli_gui).

For developers, SEGUL is available as a Rust crate, which you can easily integrate into Rust code. The Python library is available as a Python binding to the SEGUL API called PySEGUL. It does not require Rust knowledge to use it. The Rust crate also works with R. However, using it in R requires some Rust knowledge.

Learn more about using SEGUL API [here](/docs/category/api-usages).

:::tip
If you write a pipeline in Python, we recommend using PySEGUL. It is available in the Python Package Index (PyPI), which will simplify dependency management.
:::

## Installation

We recommend downloading GUI apps from your operating system's [official store](/docs/installation/install_gui). It is a one-click installation. The fastest installation route for CLI is using the pre-compiled binaries. If you are familiar with installing single executable CLI apps, download the latest release using the links below. The [installation guide](/docs/installation/install_binary) provides more detailed instructions.

| Platform              | Link                                                                                                  | Description                                                                                                               |
| --------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Linux ARM64           | [download](https://github.com/hhandika/segul/releases/latest/download/segul-Linux-arm64.tar.gz)       | For Linux on ARM64 architecture (uncommon).                                                                               |
| Linux x86_64 (static) | [download](https://github.com/hhandika/segul/releases/latest/download/segul-Linux-musl-x86_64.tar.gz) | For Linux with old [GLIBC](https://www.gnu.org/software/libc/) version. Common in HPC clusters.                           |
| Linux x86_64          | [download](https://github.com/hhandika/segul/releases/latest/download/segul-Linux-x86_64.tar.gz)      | For Linux with modern [GLIBC](https://www.gnu.org/software/libc/) version. Most recent Linux distribution, including WSL. |
| MacOS ARM64           | [download](https://github.com/hhandika/segul/releases/latest/download/segul-macOS-x86_64.tar.gz)      | For MacOS on Apple M series.                                                                                              |
| MacOS x86_64          | [download](https://github.com/hhandika/segul/releases/latest/download/segul-macOS-x86_64.tar.gz)      | For MacOS on Intel.                                                                                                       |
| Windows x86_64        | [download](https://github.com/hhandika/segul/releases/latest/download/segul-Windows-x86_64.zip)       | Most Windows devices. It may work on ARM Windows as well.                                                                 |

:::tip
If you use [conda](https://anaconda.org/bioconda/segul) on Linux or MacOS. You can install SEGUL using it. Ensure you have [bioconda](https://bioconda.github.io/) channel setup before installing SEGUL. To install SEGUL, use the following command:

```bash
conda install bioconda::segul
```

Or if you use mamba:

```bash
mamba install segul
```

Note that the Conda installation may not work in old Linux distributions often found in HPC clusters. Learn more about the installation using Bioconda [here](/docs/installation/install_conda).
:::

## Usage Overview

SEGUL has a growing list of features to help you manipulate and summarize your phylogenomic datasets.

### Feature Quick Links

| Feature                        | Quick Link                                                                                                                      |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| Alignment concatenation        | [CLI](https://www.segul.app/docs/cli-usage/align-concat) / [GUI](https://www.segul.app/docs/gui-usage/align-concat)             |
| Alignment conversion           | [CLI](https://www.segul.app/docs/cli-usage/align-convert) / [GUI](https://www.segul.app/docs/gui-usage/align-convert)           |
| Alignment filtering            | [CLI](https://www.segul.app/docs/cli-usage/align-filter) / [GUI](https://www.segul.app/docs/gui-usage/align-filter)             |
| Alignment splitting            | [CLI](https://www.segul.app/docs/cli-usage/align-split) / [GUI](https://www.segul.app/docs/gui-usage/align-split)               |
| Alignment partition conversion | [CLI](https://www.segul.app/docs/cli-usage/align-partition) / [GUI](https://www.segul.app/docs/gui-usage/align-partition)       |
| Alignment summary statistics   | [CLI](https://www.segul.app/docs/cli-usage/align-summary) / [GUI](https://www.segul.app/docs/gui-usage/align-summary)           |
| Genomic summary statistics     | [CLI](https://www.segul.app/docs/cli-usage/genomic-summary) / [GUI](https://www.segul.app/docs/gui-usage/genomic)               |
| Sequence extraction            | [CLI](https://www.segul.app/docs/cli-usage/sequence-extract) / [GUI](https://www.segul.app/docs/gui-usage/sequence-extract)     |
| Sequence filtering             | [CLI](https://www.segul.app/docs/cli-usage/sequence-filter) / GUI feature in development                                        |
| Sequence ID extraction         | [CLI](https://www.segul.app/docs/cli-usage/sequence-id) / [GUI](https://www.segul.app/docs/gui-usage/sequence-id)               |
| Sequence ID mapping            | [CLI](https://www.segul.app/docs/cli-usage/sequence-map) / [GUI](https://www.segul.app/docs/gui-usage/sequence-id-map)          |
| Sequence ID renaming           | [CLI](https://www.segul.app/docs/cli-usage/sequence-rename) / [GUI](https://www.segul.app/docs/gui-usage/sequence-rename)       |
| Sequence removal               | [CLI](https://www.segul.app/docs/cli-usage/sequence-remove) / [GUI](https://www.segul.app/docs/gui-usage/sequence-remove)       |
| Sequence translation           | [CLI](https://www.segul.app/docs/cli-usage/sequence-translate) / [GUI](https://www.segul.app/docs/gui-usage/sequence-translate) |

### Supported File Formats

Supported input formats for **Genomic** tasks:

| File Format | Description                                                                      | Supported extensions                    |
| ----------- | -------------------------------------------------------------------------------- | --------------------------------------- |
| FASTQ       | For genomic read summary statistics. Support compressed and uncompressed format. | `.fastq`, `.fq`, `fastq.gz`, `fg.gz`    |
| FASTA       | For contig summary statistics.                                                   | `.fasta`, `.fa`, `.fna`, `.fsa`, `.fas` |

Supported input and output file formats for **Alignment** and **Sequence** tasks:

| File Format | Description                                                                                                                                                       | Supported extensions                    |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| FASTA       | Include support for interleaved format.                                                                                                                           | `.fasta`, `.fa`, `.fna`, `.fsa`, `.fas` |
| PHYLIP      | Support relaxed-PHYLIP only. Include support for interleaved format. Learn the differences [here](https://biopython.org/docs/1.74/api/Bio.AlignIO.PhylipIO.html). | `.phy`, `.phylip`, `.ph`                |
| NEXUS       | Include support for interleaved format.                                                                                                                           | `.nexus`, `.nex`, `.nxs`                |

Supported input and output partition formats:

| File Format | Description           | Supported extensions          |
| ----------- | --------------------- | ----------------------------- |
| RAxML       | RAxML partition file. | `.txt`, `.part`, `.partition` |
| NEXUS       | NEXUS partition file. | `.nexus`, `.nex`, `.nxs`      |

:::info
SEGUL CLI can handle non-standard file extensions that are not listed above. Use the `--format` option to set the input format. The GUI version will not allow inputting non-standard file extensions. You can change the file extension to one of the supported extensions or use the CLI version.
:::

### Example Dataset

We provide sample datasets to help you get started or test the app if you find any issues using your datasets. The datasets include small alignments in SEGUL-supported formats. Due to the large file sizes, we cannot provide genomic datasets. You can download the genomic data from public repositories, such as [NCBI SRA](https://www.ncbi.nlm.nih.gov/sra).

| Dataset                    | Link                                                                                |
| -------------------------- | ----------------------------------------------------------------------------------- |
| FASTA                      | [Download](https://github.com/hhandika/segul/raw/main/examples/data-fasta.zip)      |
| NEXUS                      | [Download](https://github.com/hhandika/segul/raw/main/examples/data-nexus.zip)      |
| Relaxed-PHYLIP             | [Download](https://github.com/hhandika/segul/raw/main/examples/data-phylip.zip)     |
| Interleaved relaxed-PHYLIP | [Download](https://github.com/hhandika/segul/raw/main/examples/data-phylip.zip)     |
| Concatenated NEXUS         | [Download](https://github.com/hhandika/segul/raw/main/examples/data-concat-nex.zip) |

## GUI Usage

1. Open the app.
2. Use the navigation bar to select the feature you want to use. For example, to concatenate alignments, click the "Alignments" button.
3. Use the dropdown menu to select the task. For alignment concatenation, select "Concatenate alignments."
4. Click the "Add file" button to add the input files. You can also input a directory on desktop platforms by clicking the "Add directory" button. The app will look for files matching the directory.
5. The input tab bar displays all the input files. You can remove a file by clicking the "Remove" button. Removing a file will only remove it from the input list, not the file system.
6. Click the "Add output directory" button to add the output directory. On mobile platforms, this directory will be the app's default directory.
7. You also need to add the parameters for some tasks. For example, you must add the filtering parameters to filter alignments.
8. Click the "Run" button to start the task.
9. Once done, the app will display the output in the output tab bar. You can also tab the file to open it in the app file viewer. The current version only supports plain text and comma-separated (CSV) data.
10. You can also share the output. There are two share options. The quick share will create a zip file containing the output and share it using the system share sheet. You can also share individual files by clicking the share button on the output viewer.

:::warning
The mobile version of the GUI has limited capabilities in handling many files. Find out more in the [guideline for mobile users](/docs/gui-usage/general#specific-guideline-for-mobile-users).
:::

## CLI Usage

The `segul` command is structured as follows:

```bash
segul <command> <subcommand> --option1 value1 --option2 value2
```

For example, to concatenate alignments:

```bash
segul align concat --dir alignments/ --output aln-concat
```

Some arguments are required, while others are optional. For example, the `--output` option is optional. The app will use the default output directory if you do not provide it. The command below will concatenate all the alignments in the `alignments/` directory and save the output in the `Align-Concat` directory.

```bash
segul align concat --dir alignments/
```

We recommend using the `segul --help` option to see the available options for each command, the `segul <command> --help` option to see the available options for each subcommand, and the `segul <command> <subcommand> --help` option to see the available options for each subcommand.

Please see the [command usage](./cli-usage/command_options.md) section for more detailed usage information.

:::tip
Since version 0.19.0, you don't need to specify the input format. The app will automatically detect the format based on the file extension. The lower version only allows auto-detect format for non-directory input. If you have non-standard file extensions, use the `--format` option to set the input format regardless of the version.
:::

:::warning
The commands below expect SEGUL version 0.19.0+. If you use a lower version, the subcommand becomes the command, and the dir input option requires a specific input format.

For example:

```bash
segul alignment concat -d <input-directory>
```

In the version lower than 0.19.0, the command above will be:

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
| Read summary statistics        | `segul read summary -d <input-directory>`                          |
| Sequence extraction            | `segul sequence extract -d <input-directory> <extraction-options>` |
| Sequence filtering             | `segul sequence filter -d <input-directory> <filtering-options>`   |
| Sequence ID extraction         | `segul sequence id -d <input-directory>`                           |
| Sequence ID mapping            | `segul sequence id --map -d <input-directory>`                     |
| Sequence ID renaming           | `segul sequence rename -d <input-directory>`                       |
| Sequence removal               | `segul sequence remove -d <input-directory>`                       |
| Sequence translation           | `segul sequence translate -d <input-directory>`                    |
| Main help                      | `segul --help`                                                     |
| Command help                   | `segul <command> --help`                                           |
| Subcommand help                | `segul <command> <subcommand> --help`                              |

## API Usage

SEGUL API is available as a Rust crate. You can use it to develop your application or integrate it with other programming languages. The API is available on [crates.io](https://crates.io/crates/segul).

To add SEGUL API to your project, you can use the `cargo add` command:

```bash
cd my-project

cargo add segul
```

Or add manually in the `Cargo.toml` file:

```toml
[dependencies]
segul = "0.*"
```

If you want to use SEGUL API in Python, we provide a Python binding called PySEGUL. The library allows you to access SEGUL features like using any Python library. No Rust knowledge is needed. Install it using pip:

```bash
pip install pysegul
```

```python
import pysegul

def concat_alignments():
    input_dir = 'tests/data'
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    partition_format = 'raxml'
    prefix = 'concatenated'
    output_dir = 'tests/output'
    concat = pysegul.AlignmentConcatenation(
        input_format,
        datatype,
        output_dir,
        output_format,
        partition_format,
        prefix
        )
    concat.from_dir(input_dir)
    # For inputting a list of files instead of a directory
    input_paths = ['tests/data/alignment1.nex', 'tests/data/alignment2.nex']
    concat.from_files(input_paths)
```

Most of the PySEGUL features follow the same code pattern except for features that require specific parameters, such as alignment filtering, sequence extraction, and sequence removal. For these features, use a setter to input files or directories. Then, the matching method parameters are used to run the analyses. For example, to extract sequences using regular expression:

```python
import pysegul

def extract_sequences():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    output_dir = 'tests/output'
    extract = pysegul.SequenceExtraction(
        input_format,
        datatype,
        output_dir,
        output_format,
        )
    extract.input_dir = input_dir
    extract.extract_regex("(?i)^(abce)")
```

Learn more about using PySEGUL [here](/docs/api-usage/python/intro).

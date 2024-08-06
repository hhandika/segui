---
sidebar_position: 4
title: CLI Conda Installation
---

SEGUL CLI is available on [Bioconda](https://anaconda.org/bioconda/segul). To install SEGUL CLI, make sure you have [Conda](https://docs.conda.io/en/latest/) installed on your system and [Bioconda](https://bioconda.github.io/index.html) channel is added to your Conda configuration. Then, you can install SEGUL CLI by running the following command:

```bash
conda install bioconda::segul
```

Or if you use [mamba](https://github.com/mamba-org/mamba):

```bash
mamba install segul
```

## Supported Platforms

- Linux (ARM64, x86_64, required [GLIBC](https://www.gnu.org/software/libc/) 2.17+) 
- macOS (Intel and Apple Silicon)

:::note
SEGUL Conda installation may not work on old Linux distributions often found in HPC clusters. We recommend installing SEGUL using [the Linux MUSL binary](/docs/installation/install_binary#linuxwsl) or through [the package manager](/docs/installation/install_cargo).
:::

## Detailed Installation Guide

### Install Miniforge

If you start fresh, we recommend using [Miniforge](https://github.com/conda-forge/miniforge). First, download the Miniforge installer from the [Miniforge GitHub release page](https://github.com/conda-forge/miniforge/releases). The [README](https://github.com/conda-forge/miniforge) file in the Miniforge also contains a quick link to the latest release.

Briefly, you can download the installer using `wget`:

```bash
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
```

Or using `curl`:

```bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
```

After downloading the installer, install Miniforge by running the following command:

```bash
bash Miniforge3-$(uname)-$(uname -m).sh
```

Detailed installation instructions for Miniforge can be found [here](https://github.com/conda-forge/miniforge).

### Check Conda and Mamba Installation

You can check both by checking the Mamba version:

```bash
mamba --version
```

It will print the Mamba and Conda versions if installed correctly.

For example:

```bash
mamba 1.5.8
conda 24.5.0
```

### Add Bioconda Channel

Next, you need to add the Bioconda channel to your Conda configuration:

```bash
conda config --add channels bioconda
```

### Install SEGUL CLI

Finally, you can install SEGUL CLI using the following command:

```bash
mamba install segul
```

### To test the SEGUL CLI installation

To check the version number:

```bash
segul --version
```

To print the help message on your terminal:

```bash
segul
```

---
sidebar_position: 7
---
# Try Beta Features

We welcome our users to try new features as we develop them. However, these features are usually only partially or not tested, so we recommend only using them for testing purposes.

The features are in the development branch and listed as beta in the documentation. The installation process is similar to installing from [Github Repository](./install_source) and add `--branch dev`.

## Requirements

- [Rust compiler toolchain](https://www.rust-lang.org/tools/install)

## Installation Steps

### Install Rust

Follow the instructions on the [Rust website](https://www.rust-lang.org/tools/install) to install the Rust compiler toolchain. The link will direct you to the installation instructions based on your operating system. On macOS and Linux, you will use your terminal application to install the toolchain and then follow on-screen instructions. On Windows, you will download the installer and follow the installation wizard. Some package managers, such as `brew` on macOS, also provide an option to install Rust.

After the installation, on your terminal, run this command to verify the installation:

```Bash
cargo --version
```

It should show the version number of the number app. If it says command not found, we recommend restarting your system. On Linux or macOS, you can also try to run this command:

```bash
which $SHELL
```

If it contains ZSH, do:

```bash
source ~/.zshrc
```

If BASH, do:

```bash
source ~/.bashrc
```


### Install SEGUL Development Version

To install the SEGUL development version on your terminal application, use the command below:

```Bash
cargo install --git https://github.com/hhandika/segul.git --branch dev
```

:::tip
If you encounter compiling issues on Linux and Windows, such as linker not found or something similar, try additional steps explained in the [package manager installation guide](/docs/installation/install_cargo).
:::

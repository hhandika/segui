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

If you encounter compiling issues on Linux and Windows, you will need to take additional steps to compile SEGUL. For more information, see the [/docs/installation/install_cargo](source installation guide).

### Install SEGUL Development Version

To install the SEGUL development version, on your terminal application, use the command below:

```Bash
cargo install --git https://github.com/hhandika/segul.git --branch dev
```

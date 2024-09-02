---
sidebar_position: 7
---
# Try Beta Features

We welcome our users to try new features as we develop them. These features usually only partially or have not been tested. We recommend only using them for testing purposes.

The features are in the development branch and listed as beta in the documentation. The installation process is similar to installing from [Github Repository](./install_source) and add `--branch dev`.

## Requirements

- [Rust compiler toolchain](https://www.rust-lang.org/tools/install)

## Installation Steps

### Install Rust

Follow the instruction on the [Rust website](https://www.rust-lang.org/tools/install) to install the Rust compiler toolchain. Briefly, the link will direct you to the installation instruction based on your operating system. On macOS and Linux, you will use your terminal application to install the toolchain and then follow on screen instruction. On Windows, you will download the installer and follow the installation wizard. Some package manager, such as `brew` on macOS, also provides an option to install Rust.

After the installation, on your terminal, run this command to verify the installation:

```Bash
cargo --version
```

On Linux and Windows, if you encounter compiling issues, you will need additional steps to compile SEGUL. See the [/docs/installation/install_cargo](source installation guide) for more information.

### Install SEGUL Development Version

To install SEGUL, in your terminal application, use the command below to install the development version of the app:

```Bash
cargo install --git https://github.com/hhandika/segul.git --branch dev
```

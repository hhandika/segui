---
title: CLI Package Manager
sidebar:
  order: 5
---

If you have experience with Rust, this is the recommended option. Cargo will compile the app and fine-tuned it for your specific hardware. It also allows to easily updating the app.

First, download and install [the Rust compiler toolchain](https://www.rust-lang.org/learn/get-started). It requires Rust version 1.5 or higher. Then, check if the toolchain installation successful:

```bash
cargo --version
```

It should show the cargo version number. Then, install the app:

```bash
cargo install segul
```

If you encounter a compiling issue (usually happens on Linux or Windows), you may need to install the C-development toolkit. For Debian-based Linux distribution, such as Debian, Ubuntu, PopOS, etc., the easiest way is to install build-essential:

```bash
sudo apt install build-essential
```

For OpenSUSE:

```bash
zypper install -t pattern devel_basis
```

For Fedora:

```bash
sudo dnf groupinstall "Development Tools" "Development Libraries"
```

For Windows, you only need to install the GNU toolchain for rust. The installation should be straighforward using rustup. Rustup comes as a part of the rust-compiler toolchain. It should be available in your system at the same time as you install cargo.

```bash
rustup toolchain install stable-x86_64-pc-windows-gnu
```

Then set the GNU toolchain as the default compiler

```bash
rustup default stable-x86_64-pc-windows-gnu
```

Try to install SEGUL again:

```bash
cargo install segul
```

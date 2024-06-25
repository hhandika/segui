---
sidebar_position: 4
title: Cross Compilation
---

The CLI version of SEGUL support cross-complication for target platform Linux, macOS, and Windows. This method allow us to create executable for target platform using a different operating system. For example, your system is running macOS and you want to create SEGUL executable for Linux. The cross-compilation can be done using the [`cargo-zigbuild`](https://github.com/rust-cross/cargo-zigbuild) crate.

## Installation

Install the `cargo-zigbuild` tool using pip that will also install zig compiler:

```bash
pip install cargo-zigbuild
```

## Cross-compiling SEGUL

Example below shows how to cross-compile SEGUL for the Linux GNU target on macOS/Windows:

```bash
rustup target add aarch64-unknown-linux-gnu
```

Build using zigbuild:

```bash
cargo zigbuild --target aarch64-unknown-linux-gnu
```

Learn more about cross-compiling Rust using zigbuild [here](https://github.com/rust-cross/cargo-zigbuild).

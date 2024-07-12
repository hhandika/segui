---
sidebar_position: 6
---

# CLI Source Code

To install from the source code, you will need [the Rust compiler toolchain](https://www.rust-lang.org/learn/get-started). The setup procedure is similar to installing the app using cargo. To install the development version for any supported platform:

```Bash
cargo install --git https://github.com/hhandika/segul.git
```

You should have SEGUL ready to use.

It is equivalent to:

```Bash
git clone https://github.com/hhandika/segul

cd segul/

cargo build --release
```

The different is that, for the latter, the executable will be in the `segul` repository: `/target/release/segul`. Copy the `segul` binary and then add it to your environment path folder.

Then, try to call SEGUL:

```Bash
segul --version
```

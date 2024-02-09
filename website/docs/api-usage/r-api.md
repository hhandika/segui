---
sidebar_position: 3
title: R
---

## Using SEGUL API in R

We recommend to use the R package [`rextendr`](https://extendr.github.io/rextendr/index.html) to interact with SEGUL API. Check out [rsegul](https://github.com/hhandika/rsegul) to see how to use `rextendr` to interact with SEGUL API. A comprehensive list of available SEGUL functions and how to use them is available in the [SEGUL API documentation](https://docs.rs/segul/latest/segul/index.html).

## Step-by-step guide

### Install Rust

Follow the [Rust installation guide](https://www.rust-lang.org/tools/install) to install Rust.

### Install `rextendr`

```r
install.packages("rextendr")
```

### Load `rextendr`

```python
library(rextendr)
```

### Check Rust installation

```python
rust_sitrep()

# Rust infrastructure sitrep:
# ✔ "rustup": 1.26.0 (5af9b9484 2023-04-05)
# ✔ "cargo": 1.75.0 (1d8b05cdd 2023-11-20)
# ℹ host: aarch64-apple-darwin
# ℹ toolchain: stable-aarch64-apple-darwin
# ℹ targets: aarch64-apple-darwin, aarch64-apple-ios, aarch64-apple-ios-sim, aarch64-linux-android, armv7-linux-androideabi,
#   i686-linux-android, x86_64-apple-darwin, x86_64-apple-ios, and x86_64-linux-android
```

### Write SEGUL code in R

For example, to call the `alphabet` function from the `segul` crate:

```rust
use segul::helper::alphabet;

fn alphabet() -> String {
    alphabet::DNA_STR_UPPERCASE.to_string()
}
```

In R, you can use the `rust_source` function from `rextendr` to call the SEGUL function.

```r
segul_code <- r"(
use segul::helper::alphabet;

#[extendr]
fn alphabet() -> String {
    alphabet::DNA_STR_UPPERCASE.to_string()
}
)"

rust_source(code = segul_code, dependencies = list(segul = "*"))
```

### Call SEGUL function in R

```python
alphabet()

# [1] "?-ACGTNRYSWKMBDHV."
```

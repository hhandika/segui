---
sidebar_position: 4
title: Developing Python Library using SEGUL API
---

We recommend to use [`PyO3`](https://pyo3.rs/) and [Maturin](https://www.maturin.rs/) to develop python library using SEGUL API. The PyO3 and Maturin documentation provides a comprehensive guide on how to use the tools. You can also checkout [pysegul](https://github.com/hhandika/pysegul) to see how we use SEGUL API in Python.

## Quick Guideline

### Install Rust and Maturin

1. [Install Rust](https://www.rust-lang.org/tools/install)
2. [Install Maturin](https://www.maturin.rs/installation)

### Create a new Rust project

```bash
cargo new segul-python --lib

cd segul-python
```

### Create Python project

```bash
maturin new
```

### Add SEGUL API as a dependency

```bash
cargo add segul
```

Or add it manually in your `Cargo.toml` file:

```toml
[dependencies]
segul = "0.*"
```

Find out more about available SEGUL functions and how to use them in the [SEGUL API documentation](https://docs.rs/segul/latest/segul/index.html).

### Add Python binding

Add the following code in your `src/lib.rs`:

```rust
use pyo3::prelude::*;

use segul::helper::alphabet::DNA_STR_UPPERCASE;

// pyO3 recommend the same function name as the module name
#[pymodule]
fn segul_python(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(alphabet, m)?)?;
    Ok(())
}

// Wrap SEGUL API function using pyO3 `pyfunction` macro
#[pyfunction]
fn alphabet() -> String {
    DNA_STR_UPPERCASE.to_string()
}
```

### Build the Python library

```bash
maturin develop
```

### Test the Python library

```python
import segul_python

print(segul_python.alphabet())
```

---
title: Rust
sidebar:
  order: 2
---

## Using SEGUL API in Rust

Starting from SEGUL v0.24.0, the SEGUL library lives in the [`segul-core`](https://crates.io/crates/segul-core) crate. The [`segul`](https://crates.io/crates/segul) crate is the command-line app. Add `segul-core` to your `Cargo.toml` file:

```toml
[dependencies]
segul-core = "0.24"
```

Or use cargo to add the dependency:

```bash
cd my-project

cargo add segul-core
```

The API documentation is available on [docs.rs](https://docs.rs/segul-core).

### Choosing features

All features are enabled by default. To reduce compile time and dependencies, disable the default features and pick the ones you need:

```toml
[dependencies]
segul-core = { version = "0.24", default-features = false, features = ["align", "sequence"] }
```

| Feature    | Provides                                                          |
| ---------- | ----------------------------------------------------------------- |
| `align`    | Alignment concat, convert, distance, filter, split, summary, trim |
| `sequence` | Sequence extract, filter, rename, remove, translate, transpose, ID |
| `read`     | Raw read (FASTQ) summary statistics                               |
| `contig`   | Contiguous sequence summary statistics                            |
| `maf`      | Multiple alignment format (MAF) conversion                        |

The base modules, such as the helpers, the FASTA, NEXUS, and PHYLIP parsers, and the sequence and partition writers, are always available.

### Example

Convert a FASTA alignment to PHYLIP:

```rust
use std::path::Path;

use segul_core::helper::sequence::SeqParser;
use segul_core::helper::types::{DataType, InputFmt, OutputFmt};
use segul_core::writer::sequences::SeqWriter;

let input = Path::new("alignment.fas");
let output = Path::new("output/alignment");
let datatype = DataType::Dna;
let (matrix, header) = SeqParser::new(input, &datatype).parse(&InputFmt::Fasta);
let mut writer = SeqWriter::new(output, &matrix, &header);
writer
    .write_sequence(&OutputFmt::Phylip)
    .expect("Failed to write the alignment");
```

### Migrating from SEGUL v0.23 and earlier

Replace `segul` with `segul-core` in your `Cargo.toml` file and `segul::` with `segul_core::` in your imports. The `segul` crate v0.24 still re-exports the library modules, so existing code keeps compiling, but these re-exports will be removed in a future release.

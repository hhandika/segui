---
title: Sequence Transpose
sidebar:
  order: 20
  badge:
    text: Upcoming
    variant: caution
---

:::caution[Upcoming]
This feature is not yet published on PyPI. It will be available in the next PySEGUL release. To use it now, build PySEGUL from [source](https://github.com/hhandika/pysegul).
:::

Transpose locus alignments into one sequence file per sample. Each output file contains all loci for one sample, labeled by the locus (input file name) they come from. Gaps and missing data are removed. PySEGUL writes each sample to `output_dir/<sample_id>/<sample_id>.<ext>`.

Use `fasta` or `fasta-int` output, because the transposed sequences are unaligned.

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def transpose_sequences():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    output_dir = 'tests/output'
    transpose = pysegul.SequenceTranspose(
        input_format,
        datatype,
        output_dir,
        # Optional. Default: 'fasta'
        output_fmt='fasta',
        )
    transpose.from_dir(input_dir)
```

To use a list of files, call `from_files` instead of `from_dir`:

```python
transpose.from_files(['tests/align-data/locus1.nex', 'tests/align-data/locus2.nex'])
```

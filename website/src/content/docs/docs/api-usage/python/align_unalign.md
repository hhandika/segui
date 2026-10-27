---
title: Alignment Unalignment
sidebar:
  order: 10
  badge:
    text: Upcoming
    variant: caution
---

:::caution[Upcoming]
This feature is not yet published on PyPI. It will be available in the next PySEGUL release. To use it now, build PySEGUL from [source](https://github.com/hhandika/pysegul).
:::

Convert alignments to unaligned sequences by removing gaps and missing data. The output format can be `fasta` or `fasta-int` (interleaved).

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def unalign_alignments():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    output_dir = 'tests/output'
    unalign = pysegul.AlignmentUnalignment(
        input_format,
        datatype,
        output_dir,
        # Optional. Default: 'fasta'
        output_fmt='fasta',
        )
    unalign.from_dir(input_dir)
```

To use a list of files, call `from_files` instead of `from_dir`:

```python
unalign.from_files(['tests/align-data/locus1.nex', 'tests/align-data/locus2.nex'])
```

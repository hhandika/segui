---
title: Sequence Addition
sidebar:
  order: 13
  badge:
    text: Beta
    variant: caution
---

:::caution[Beta]
This feature is in beta and may still change.
:::

Add sequences to existing sequence files. Input sequences are matched to destination files by file name, excluding the extension. The input and destination files can be in different formats. The output is unaligned: gaps and missing data are removed. The output format can be `fasta` or `fasta-int`.

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def add_sequences():
    input_dir = 'tests/new-sequences'
    input_format = 'fasta'
    datatype = 'dna'
    output_dir = 'tests/output'
    add = pysegul.SequenceAddition(
        input_format,
        datatype,
        output_dir,
        # Optional. Default: 'fasta'
        output_fmt='fasta',
        # Optional. Write only the destination files that received new sequences.
        added_only=False,
        )
    add.input_dir = input_dir
    # Or use a list of files:
    # add.input_files = ['tests/new-sequences/locus1.fas']

    # Add to all files in a destination directory
    add.add_to_dir('tests/align-data', 'nexus')
    # Or add to a list of destination files
    # add.add_to_files(['tests/align-data/locus1.nex'], 'nexus')
```

To add all input sequences into a single file:

```python
# Set include_filename to True to append the input file name to each sequence ID.
add.add_to_file('tests/output/all_sequences.fas', include_filename=True)
```

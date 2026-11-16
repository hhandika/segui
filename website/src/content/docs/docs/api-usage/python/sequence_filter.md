---
title: Sequence Filtering
sidebar:
  order: 15
  badge:
    text: Beta
    variant: caution
---

:::caution[Beta]
This feature is in beta and may still change.
:::

Filter sequences across many sequence files. Available filtering methods:

- Minimum sequence length (gaps excluded)
- Maximum sequence length (gaps excluded)
- Maximum proportion of gaps

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def filter_sequences():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    output_dir = 'tests/output'
    filter = pysegul.SequenceFiltering(
        input_format,
        datatype,
        output_dir,
        output_format,
        )
    filter.input_dir = input_dir
    # Or use a list of files:
    # filter.input_files = ['tests/align-data/locus1.nex']
    # Remove sequences shorter than 100 bp
    filter.minimal_length(100)
    # Or remove sequences longer than 1000 bp
    # filter.maximal_length(1000)
    # Or remove sequences with more than 50% gaps
    # filter.maximal_gap(0.5)
```

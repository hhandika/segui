---
title: Alignment Trimming
sidebar:
  order: 9
  badge:
    text: Upcoming
    variant: caution
---

:::caution[Upcoming]
This feature is not yet published on PyPI. It will be available in the next PySEGUL release. To use it now, build PySEGUL from [source](https://github.com/hhandika/pysegul).
:::

Trim alignment sites across many alignments at once. Available trimming methods:

- Missing data: remove sites whose proportion of missing data (gaps and `?`) is above a threshold.
- Parsimony informative sites: trim using a threshold of parsimony informative sites.

PySEGUL writes the trimmed alignments to the `trimmed_alignments` directory and a trimming summary to `trimming_summary.csv`.

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def trim_alignments():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    output_dir = 'tests/output'
    trim = pysegul.AlignmentTrimming(
        input_format,
        datatype,
        output_dir,
        output_format,
        )
    trim.input_dir = input_dir
    # Or use a list of files:
    # trim.input_files = ['tests/align-data/locus1.nex']
    # Remove sites with more than 50% missing data
    trim.missing_data(0.5)
    # Or trim using parsimony informative sites
    # trim.parsimony_inf(1)
```

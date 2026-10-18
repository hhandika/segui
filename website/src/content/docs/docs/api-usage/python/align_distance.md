---
title: Alignment Distance
sidebar:
  order: 4
  badge:
    text: Upcoming
    variant: caution
---

:::caution[Upcoming]
This feature is not yet published on PyPI. It will be available in the next PySEGUL release. To use it now, build PySEGUL from [source](https://github.com/hhandika/pysegul).
:::

Compute pairwise genetic distances between samples for each alignment. PySEGUL writes a distance matrix for every locus and a summary table across all loci. It can also compute the mean distance within and between groups of samples. See the [CLI guideline](/docs/cli-usage/align-distance/) for a description of the output files.

Available distance models:

- DNA: `p` (uncorrected p-distance), `jc69`, `k2p`, `tn93`
- Amino acid: `p`, `jc69`, `poisson`

A model that does not match the data type raises a `ValueError`.

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def compute_distances():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    output_dir = 'tests/output'
    distance = pysegul.AlignmentDistance(
        input_format,
        datatype,
        output_dir,
        # Optional. Default: 'p'
        model='k2p',
        # Optional. Part of the matrix to write: 'full', 'lower', 'upper'.
        triangle='full',
        # Optional. Diagonal values: 'zero' (default), 'blank', 'na'.
        diagonal='zero',
        # Optional. Also write long-format tables with one row per pair.
        long_format=False,
        )
    distance.from_dir(input_dir)
```

To use a list of files, call `from_files` instead of `from_dir`:

```python
distance.from_files(['tests/align-data/locus1.nex', 'tests/align-data/locus2.nex'])
```

## Group mean distances

To compute the mean distance within and between groups, such as species or populations, choose one grouping method before running the analysis:

```python
import pysegul

def compute_group_distances():
    distance = pysegul.AlignmentDistance(
        'nexus',
        'dna',
        'tests/output',
        # Optional. Diagonal of the group matrices: 'mean' (default),
        # 'max' (highest within-group distance), 'zero', 'blank', 'na'.
        # Sample matrices hold zero with 'mean' and 'max'.
        diagonal='max',
        )
    # Split IDs on '_' and keep the first 2 parts.
    # For example, Rattus_rattus_FMNH123 belongs to Rattus_rattus.
    distance.group_by_delimiter('_', 2)
    # Or use the first capture group of a regular expression.
    # distance.group_by_regex(r'^([A-Za-z]+_[a-z]+)')
    # Or use a CSV or TSV file with a header row and two columns:
    # sample ID and group.
    # distance.group_by_file('groups.csv')
    # Or detect groups from the sample IDs.
    # distance.group_auto()
    distance.from_dir('tests/align-data')
```

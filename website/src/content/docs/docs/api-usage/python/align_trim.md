---
title: Alignment Trimming
sidebar:
  order: 9
  badge:
    text: Beta
    variant: caution
---

:::caution[Beta]
This feature is in beta and may still change.
:::

Trim alignment sites across many alignments at once. PySEGUL writes the trimmed alignments to the `trimmed_alignments` directory and a trimming summary to `trimming_summary.csv`.

## Example

Set the input with `input_dir` or `input_files`, then call a trimming method.

```python
import pysegul

def trim_alignments():
    trim = pysegul.AlignmentTrimming(
        input_fmt='nexus',
        datatype='dna',
        output_path='tests/output',
        output_fmt='fasta',
        )
    trim.input_dir = 'tests/align-data'
    trim.missing_data(0.5)
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `input_fmt` | Required | `'auto'`, `'fasta'`, `'nexus'`, `'phylip'` |
| `datatype` | Required | `'dna'`, `'aa'`, `'ignore'` |
| `output_path` | Required | Output directory |
| `output_fmt` | Required | `'fasta'`, `'nexus'`, `'phylip'`, or interleaved `'fasta-int'`, `'nexus-int'`, `'phylip-int'` |

## Input

| Attribute | Description |
| --- | --- |
| `input_dir` | Directory of input alignments |
| `input_files` | List of input alignment files |

## Methods

| Method | Description |
| --- | --- |
| `missing_data(max_missing)` | Remove sites with more than `max_missing` (0.0–1.0) missing data (gaps and `?`) |
| `parsimony_inf(threshold)` | Trim using a threshold of parsimony informative sites |

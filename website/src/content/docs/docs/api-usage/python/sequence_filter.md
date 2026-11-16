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

Filter sequences across many sequence files by length or proportion of gaps.

## Example

Set the input with `input_dir` or `input_files`, then call a filtering method.

```python
import pysegul

def filter_sequences():
    filter = pysegul.SequenceFiltering(
        input_fmt='nexus',
        datatype='dna',
        output_path='tests/output',
        output_fmt='fasta',
        )
    filter.input_dir = 'tests/align-data'
    filter.minimal_length(100)
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
| `input_dir` | Directory of input sequence files |
| `input_files` | List of input sequence files |

## Methods

| Method | Remove sequences |
| --- | --- |
| `minimal_length(min_length)` | shorter than `min_length`, gaps excluded |
| `maximal_length(max_length)` | longer than `max_length`, gaps excluded |
| `maximal_gap(max_gap)` | with more than `max_gap` (0.0–1.0) gaps |

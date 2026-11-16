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

Add sequences to existing sequence files. Input sequences are matched to destination files by file name, excluding the extension. The input and destination files can be in different formats. The output is unaligned: gaps and missing data are removed.

## Example

Set the input with `input_dir` or `input_files`, then call an addition method.

```python
import pysegul

def add_sequences():
    add = pysegul.SequenceAddition(
        input_fmt='fasta',
        datatype='dna',
        output_path='tests/output',
        )
    add.input_dir = 'tests/new-sequences'
    add.add_to_dir('tests/align-data', dest_fmt='nexus')
```

To add all input sequences into a single file:

```python
add.add_to_file('tests/output/all_sequences.fas', include_filename=True)
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `input_fmt` | Required | `'auto'`, `'fasta'`, `'nexus'`, `'phylip'` |
| `datatype` | Required | `'dna'`, `'aa'`, `'ignore'` |
| `output_path` | Required | Output directory |
| `output_fmt` | `'fasta'` | `'fasta'` or interleaved `'fasta-int'` |
| `added_only` | `False` | Write only the destination files that received new sequences |

## Input

| Attribute | Description |
| --- | --- |
| `input_dir` | Directory of input sequence files |
| `input_files` | List of input sequence files |

## Methods

| Method | Description |
| --- | --- |
| `add_to_dir(dest_dir, dest_fmt='auto')` | Add sequences to the files in a destination directory |
| `add_to_files(dest_files, dest_fmt='auto')` | Add sequences to a list of destination files |
| `add_to_file(dest_file, include_filename=False)` | Add all input sequences into a single file |

| Argument | Default | Description |
| --- | --- | --- |
| `dest_fmt` | `'auto'` | Destination file format: `'auto'`, `'fasta'`, `'nexus'`, `'phylip'` |
| `include_filename` | `False` | Append the input file name to each sequence ID |

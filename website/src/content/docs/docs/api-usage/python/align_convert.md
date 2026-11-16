---
title: Alignment Conversion
sidebar:
  order: 3
---

Convert alignments from one format to another. Optimized for converting many alignments in parallel without the limitation for Python's GIL.

## Example

```python
import pysegul

def convert_alignments():
    convert = pysegul.AlignmentConversion(
        input_fmt='nexus',
        datatype='dna',
        output_path='tests/output',
        output_fmt='fasta',
        sort_sequence=True,
        )
    convert.from_dir('tests/align-data')
```

To use a list of files, call `from_files` instead of `from_dir`:

```python
convert.from_files(['tests/align-data/alignment1.nex', 'tests/align-data/alignment2.nex'])
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `input_fmt` | Required | `'auto'`, `'fasta'`, `'nexus'`, `'phylip'` |
| `datatype` | Required | `'dna'`, `'aa'`, `'ignore'` |
| `output_path` | Required | Output directory |
| `output_fmt` | Required | `'fasta'`, `'nexus'`, `'phylip'`, or interleaved `'fasta-int'`, `'nexus-int'`, `'phylip-int'` |
| `sort_sequence` | `False` | Sort sequences by ID |

## Methods

| Method | Description |
| --- | --- |
| `from_dir(input_dir)` | Convert the alignments in a directory |
| `from_files(input_files)` | Convert a list of alignment files |

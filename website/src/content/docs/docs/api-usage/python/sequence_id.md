---
title: Sequence ID Extraction & Mapping
sidebar:
  order: 16
---

Extract unique sequence IDs from a collection of alignments and map them to the corresponding loci.

## Example

```python
import pysegul

def extract_sequence_id():
    ids = pysegul.IDExtraction(
        input_fmt='nexus',
        datatype='dna',
        output_path='tests/output',
        map_id=True,
        output_prefix='ids',
        )
    ids.from_dir('tests/align-data')
```

To use a list of files, call `from_files` instead of `from_dir`:

```python
ids.from_files(['tests/align-data/alignment1.nex', 'tests/align-data/alignment2.nex'])
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `input_fmt` | Required | `'auto'`, `'fasta'`, `'nexus'`, `'phylip'` |
| `datatype` | Required | `'dna'`, `'aa'`, `'ignore'` |
| `output_path` | Required | Output directory |
| `map_id` | `False` | Also write a file mapping each ID to the files that contain it |
| `output_prefix` | `None` | Name of the output files |

## Methods

| Method | Description |
| --- | --- |
| `from_dir(input_dir)` | Extract IDs from the sequence files in a directory |
| `from_files(input_files)` | Extract IDs from a list of sequence files |

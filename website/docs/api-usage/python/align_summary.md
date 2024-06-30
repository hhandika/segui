---
sidebar_position: 6
title: Alignment Summary
---

Generate summary statistics for DNA and amino acid alignments.

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def summarize_alignments():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    # Available values for interval: 1, 2, 5, 10.
    completeness_interval = 5
    prefix = 'concatenated'
    output_dir = 'tests/output'
    concat = pysegul.AlignmentSummary(
        input_format,  
        datatype, 
        output_dir,
        completeness_interval,
        prefix
        )
    concat.from_dir(input_dir)
```

You can also input the alignment paths in a list directly instead of using a directory. Replace the `input_dir` with `input_files` and provide a list of paths. Then, call the `from_files` method instead of `from_dir`.

```python
import pysegul

def summarize_alignments():
    input_path = ['tests/align-data/alignment1.nex', 'tests/align-data/alignment2.nex']
    input_format = 'nexus'
    datatype = 'dna'
    completeness_interval = 5
    prefix = 'concatenated'
    output_dir = 'tests/output'
    concat = pysegul.AlignmentSummary(
        input_format,  
        datatype, 
        output_dir,
        completeness_interval,
        prefix
        )
    concat.from_files(input_path)
```

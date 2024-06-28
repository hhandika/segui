---
sidebar_position: 2
title: Alignment Concatenation
---

## Steps

Install `pysegul` using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code

```python
import pysegul

def concat_alignments():
    input_dir = 'tests/data'
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    partition_format = 'raxml'
    prefix = 'concatenated'
    output_dir = 'tests/output'
    concat = pysegul.AlignmentConcatenation(
        input_format,  
        datatype, 
        output_dir, 
        output_format, 
        partition_format, 
        prefix
        )
    concat.from_dir(input_dir)
```

You can also input the alignment paths in a list directly instead of using a directory. Replace the `input_dir` with `input_files` and provide a list of paths. Then, call the `from_files` method instead of `from_dir`.

```python
import pysegul

def concat_alignments():
    input_path = ['tests/data/alignment1.nex', 'tests/data/alignment2.nex']
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    partition_format = 'raxml'
    prefix = 'concatenated'
    output_dir = 'tests/output'
    concat = pysegul.AlignmentConcatenation(
        input_format,  
        datatype, 
        output_dir, 
        output_format, 
        partition_format, 
        prefix
        )
    concat.from_files(input_path)
```

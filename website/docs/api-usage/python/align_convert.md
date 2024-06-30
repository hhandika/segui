---
sidebar_position: 2
title: Alignment Conversion
---

Convert an alignment from one format to another format. Optimized for converting many alignments in parallel without the limitation for Python's GIL.

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code

```python
import pysegul

def convert_alignments():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    sort_sequences = True
    output_dir = 'tests/output'
    convert = pysegul.AlignmentConversion(
        input_format,  
        datatype, 
        output_dir, 
        output_format,
        sort_sequences 
        )
    convert.from_dir(input_dir)
```

You can also input the alignment paths in a list directly instead of using a directory. Replace the `input_dir` with `input_files` and provide a list of paths. Then, call the `from_files` method instead of `from_dir`.

```python
import pysegul

def convert_alignments():
    input_path = ['tests/align-data/alignment1.nex', 'tests/align-data/alignment2.nex']
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    sort_sequences = True
    output_dir = 'tests/output'
    convert = pysegul.AlignmentConversion(
        input_format,  
        datatype, 
        output_dir, 
        output_format,
        sort_sequences 
        )
    convert.from_files(input_path)
```

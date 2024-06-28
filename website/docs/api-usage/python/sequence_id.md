---
sidebar_position: 8
title: Sequence ID Extraction & Mapping
---

Extract unique sequence IDs from a collection of alignments and map them to the corresponding loci.

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code

```python
import pysegul

def extract_sequence_id():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    # Set map_id to True to map the sequence ID
    # to the corresponding loci
    map_id = False
    prefix = 'concatenated'
    output_dir = 'tests/output'
    concat = pysegul.IDExtraction(
        input_format,  
        datatype, 
        output_dir, 
        map_id, 
        prefix
        )
    concat.from_dir(input_dir)
```

You can also input the alignment paths in a list directly instead of using a directory. Replace the `input_dir` with `input_files` and provide a list of paths. Then, call the `from_files` method instead of `from_dir`.

```python
import pysegul

def extract_sequence_id():
    input_path = ['tests/align-data/alignment1.nex', 'tests/align-data/alignment2.nex']
    input_format = 'nexus'
    datatype = 'dna'
    map_id = False
    prefix = 'concatenated'
    output_dir = 'tests/output'
    concat = pysegul.IDExtraction(
        input_format,  
        datatype, 
        output_dir, 
        map_id, 
        prefix
        )
    concat.from_files(input_path)
```

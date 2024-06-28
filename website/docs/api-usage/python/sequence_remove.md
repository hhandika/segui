---
sidebar_position: 9
title: Sequence Removal
---

Remove sequences based on the sequence ID. It is the opposite of [sequence extraction](/docs/api-usage/python/sequence_extract). It is faster when the sequence to be removed is less than a half of the total sequences. Available methods:

- Regular expression
- List of sequence ID

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code

```python
import pysegul

def remove_sequence():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    output_dir = 'tests/output'
    remove = pysegul.SequenceRemoval(
        input_format,  
        datatype, 
        output_dir, 
        output_format,
        )
    remove.input_dir = input_dir
    # Using regular expression method
    remove.remove_regex("(?i)^(abce)")
    # using list of sequence ID method
    remove.remove_list(['abce1', 'abce2'])
```

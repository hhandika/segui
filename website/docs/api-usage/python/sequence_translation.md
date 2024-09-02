---
sidebar_position: 11
title: Sequence Translation
---

Translate nucleotide sequences to amino acid sequences. For available translation tables, see [CLI translation guideline](/docs/cli-usage/sequence-translate#supported-translation-tables). Note that the translation table is in a string format, not an integer.

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code

```python
import pysegul

def translate_sequences():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    table = '1'
    # Set reading frame to 1, 2, or 3
    reading_frame = 1
    output_dir = 'tests/output'
    translate = pysegul.SequenceTranslation(
        input_format,  
        datatype, 
        output_dir, 
        output_format,
        table,
        reading_frame
        )
    translate.from_dir(input_dir)
```

You can also input the alignment paths in a list directly instead of using a directory. Replace the `input_dir` with `input_files` and provide a list of paths. Then, call the `from_files` method instead of `from_dir`.

```python
import pysegul

def translate_sequences():
    input_path = ['tests/align-data/alignment1.nex', 'tests/align-data/alignment2.nex']
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    table = '1'
    reading_frame = 1
    output_dir = 'tests/output'
    translate = pysegul.SequenceTranslation(
        input_format,  
        datatype, 
        output_dir, 
        output_format,
        table,
        reading_frame
        )
    translate.from_files(input_path)
```

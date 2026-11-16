---
title: Sequence Extraction
sidebar:
  order: 14
---

Extract sequences based on the sequence ID. Available methods:

- Regular expression
- List of sequence ID
- Text file of sequence IDs, one per line

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code

```python
import pysegul

def extract_sequences():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    output_dir = 'tests/output'
    extract = pysegul.SequenceExtraction(
        input_format,  
        datatype, 
        output_dir, 
        output_format,
        )
    extract.input_dir = input_dir
    # Using regular expression method
    extract.extract_regex("(?i)^(abce)")
    # using list of sequence ID method
    extract.extract_id_list(['abce1', 'abce2'])
```

You can also input the alignment paths in a list directly instead of using a directory. Replace the `input_dir` with `input_files` and provide a list of paths. Then, call the `from_files` method instead of `from_dir`.

```python
import pysegul

def extract_sequences():
    input_path = ['tests/align-data/alignment1.nex', 'tests/align-data/alignment2.nex']
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    output_dir = 'tests/output'
    extract = pysegul.SequenceExtraction(
        input_format,  
        datatype, 
        output_dir, 
        output_format,
        )
    extract.input_files = input_path
    # Using regular expression method
    extract.extract_regex("(?i)^(abce)")
    # using list of sequence ID method
    extract.extract_id_list(['abce1', 'abce2'])
```

## Extract IDs from a file

:::caution[Upcoming]
This method is not yet published on PyPI. It will be available in the next PySEGUL release. To use it now, build PySEGUL from [source](https://github.com/hhandika/pysegul).
:::

Use `extract_id_file` with a text file that has one sequence ID per line. A missing file raises a `FileNotFoundError`.

```python
extract.extract_id_file('ids.txt')
```

---
sidebar_position: 6
title: Genomic Summary
---

Genomic summary statistics is available for FASTQ reads and contiguous sequences.

## Genomic FASTQ Read Summary

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def genomic_summary():
    input_dir = 'tests/raw-data'
    input_format = 'auto'
    summary_mode = 'default'
    prefix = 'read_summary'
    output_dir = 'tests/output'
    summary = pysegul.ReadSummary(
        input_format,  
        summary_mode,
        output_dir,
        prefix
        )
    summary.from_dir(input_dir)
```

You can also input the alignment paths in a list directly instead of using a directory. Replace the `input_dir` with `input_files` and provide a list of paths. Then, call the `from_files` method instead of `from_dir`.

```python
import pysegul

def genomic_summary():
    input_path = ['tests/raw-data/read1.fastq', 'tests/raw-data/read2.fastq']
    input_format = 'auto'
    # Available values for summary_mode: 'default', 'complete', 'minimal'.
    summary_mode = 'default'
    prefix = 'read_summary'
    output_dir = 'tests/output'
    summary = pysegul.ReadSummary(
        input_format,  
        summary_mode,
        output_dir,
        prefix
        )
    summary.from_files(input_path)
```

## Genomic Contiguous Sequence Summary

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def genomic_summary():
    input_dir = 'tests/contig-data'
    input_format = 'auto'
    prefix = 'contig_summary'
    output_dir = 'tests/output'
    summary = pysegul.ContigSummary(
        input_format,  
        output_dir,
        prefix
        )
    summary.from_dir(input_dir)
```

You can also input the alignment paths in a list directly instead of using a directory. Replace the `input_dir` with `input_files` and provide a list of paths. Then, call the `from_files` method instead of `from_dir`.

```python
import pysegul

def genomic_summary():
    input_path = ['tests/contig-data/contig1.fasta', 'tests/contig-data/contig2.fasta']
    input_format = 'auto'
    prefix = 'contig_summary'
    output_dir = 'tests/output'
    summary = pysegul.ContigSummary(
        input_format,  
        output_dir,
        prefix
        )
    summary.from_files(input_path)
```

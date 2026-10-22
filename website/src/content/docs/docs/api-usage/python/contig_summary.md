---
title: Genomic Contig Summary
sidebar:
  order: 11.1
---

Summary statistics for assembled contigs in FASTA format. For raw reads, see [Genomic Read Summary](/docs/api-usage/python/read_summary/).

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def summarize_contigs():
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

def summarize_contigs():
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

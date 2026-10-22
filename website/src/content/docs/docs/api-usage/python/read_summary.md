---
title: Genomic Read Summary
sidebar:
  order: 11
---

Summary statistics for raw sequence reads in FASTQ format. For assembled contigs, see [Genomic Contig Summary](/docs/api-usage/python/contig_summary/).

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def summarize_reads():
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

def summarize_reads():
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

In `complete` mode, the output directory also has per-position statistics (`read-pos-summary.zip`), read distributions (`read-dist-summary.zip`), and all statistics as JSON (`read-report.json`), which you can load with Python's `json` module:

```python
import json

with open('tests/output/read_summary_read-report.json') as f:
    report = json.load(f)

for sample in report['samples']:
    metrics = sample['metrics']
    print(sample['sample'], metrics['read_count'], metrics['q30_pct'], metrics['duplicate_pct_est'])
```

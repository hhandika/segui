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

In `complete` mode, the output directory also has per-position statistics (`read-pos-summary.zip`), read distributions (`read-dist-summary.zip`), and all statistics as JSON (`read-report.json`).

## More options

:::caution[Upcoming]
These options are not yet published on PyPI. They will be available in the next PySEGUL release. To use them now, build PySEGUL from [source](https://github.com/hhandika/pysegul).
:::

| Option | Default | Description |
| --- | --- | --- |
| `phred` | `'auto'` | Quality score offset: `'auto'`, `'33'`, or `'64'` |
| `dup_sketch_size` | `100000` | Reads sampled to estimate duplication in `complete` mode |
| `plot` | `None` | Write charts. See [Charts and Reports](/docs/api-usage/python/plots_reports/) |

```python
summary = pysegul.ReadSummary(
    'auto',
    'complete',
    'tests/output',
    'read_summary',
    phred='33',
    plot=pysegul.PlotOptions(format='svg'),
    )
outputs = summary.from_dir('tests/raw-data')
```

`from_dir` and `from_files` return the paths of the files they write, such as `outputs['report']`.

## Quality checks

:::caution[Upcoming]
This function is not yet published on PyPI. It will be available in the next PySEGUL release. To use it now, build PySEGUL from [source](https://github.com/hhandika/pysegul).
:::

Load the JSON report with `load_read_report`. Each sample has its statistics, the read quality checks (`qc`), and the worst status among them (`qc_status`: `'Pass'`, `'Warn'`, or `'Fail'`). These are the same checks the GUI and the `segul view summary` viewer show.

```python
report = pysegul.load_read_report(outputs['report'])

for sample in report['samples']:
    metrics = sample['metrics']
    print(sample['sample'], metrics['read_count'], sample['qc_status'])
    for check in sample['qc']:
        print('  ', check['name'], round(check['value'], 1), check['unit'], check['status'])
```

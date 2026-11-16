---
title: Alignment Distance
sidebar:
  order: 4
  badge:
    text: Beta
    variant: caution
---

:::caution[Beta]
This feature is in beta and may still change.
:::

Compute pairwise genetic distances between samples for each alignment. PySEGUL writes a distance matrix for every locus and a summary table across all loci. It can also compute the mean distance within and between groups of samples. See the [CLI guideline](/docs/cli-usage/align-distance/) for a description of the output files.

## Example

```python
import pysegul

def compute_distances():
    distance = pysegul.AlignmentDistance(
        input_fmt='nexus',
        datatype='dna',
        output_path='tests/output',
        model='k2p',
        )
    outputs = distance.from_dir('tests/align-data')
```

To use a list of files, call `from_files` instead of `from_dir`:

```python
distance.from_files(['tests/align-data/locus1.nex', 'tests/align-data/locus2.nex'])
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `input_fmt` | Required | `'auto'`, `'fasta'`, `'nexus'`, `'phylip'` |
| `datatype` | Required | `'dna'` or `'aa'` |
| `output_path` | Required | Output directory |
| `model` | `'p'` | DNA: `'p'` (uncorrected p-distance), `'jc69'`, `'k2p'`, `'tn93'`. Amino acid: `'p'`, `'jc69'`, `'poisson'` |
| `triangle` | `'full'` | Part of the matrix to write: `'full'`, `'lower'`, `'upper'` |
| `diagonal` | `None` | Diagonal values: `'zero'`, `'blank'`, `'na'`. With groups, also `'mean'` or `'max'`. See [Group mean distances](#group-mean-distances) |
| `long_format` | `False` | Also write long-format tables with one row per pair |
| `output_prefix` | `None` | Name of the output files |
| `plot` | `None` | Chart options. See [Charts](#charts) |

A model that does not match the data type raises a `ValueError`.

## Methods

| Method | Description |
| --- | --- |
| `from_dir(input_dir)` | Compute distances for the alignments in a directory |
| `from_files(input_files)` | Compute distances for a list of alignment files |
| `group_by_delimiter(delimiter, fields)` | Group samples by the first `fields` parts of their IDs split on `delimiter` |
| `group_by_regex(pattern)` | Group samples by the first capture group of a regular expression, or the whole match without a capture group |
| `group_by_file(path)` | Group samples using a CSV or TSV file with a header row and two columns: sample ID and group |
| `group_auto()` | Detect groups from the sample IDs |

`from_dir` and `from_files` return a dictionary of output paths: `summary`, `per_locus_dir`, `group_mean`, `pairwise_long`, `report`, and `plots`.

## Group mean distances

To compute the mean distance within and between groups, such as species or populations, call one grouping method before running the analysis:

```python
import pysegul

def compute_group_distances():
    distance = pysegul.AlignmentDistance(
        'nexus',
        'dna',
        'tests/output',
        diagonal='max',
        )
    # Rattus_rattus_FMNH123 belongs to Rattus_rattus
    distance.group_by_delimiter('_', 2)
    distance.from_dir('tests/align-data')
```

With groups, `diagonal` sets the diagonal of the group matrices:

| `diagonal` | Group matrices | Sample matrices |
| --- | --- | --- |
| `None` | Within-group mean distance | Zero |
| `'mean'` | Within-group mean distance | Zero |
| `'max'` | Highest within-group distance | Zero |
| `'zero'`, `'blank'`, `'na'` | The chosen value | The chosen value |

## Charts

Set `plot` to write charts to the `plots` folder of the output directory. See [Charts and Reports](/docs/api-usage/python/plots_reports/) for the chart options.

```python
distance = pysegul.AlignmentDistance(
    'nexus',
    'dna',
    'tests/output',
    plot=pysegul.PlotOptions(format='svg'),
    )
outputs = distance.from_dir('tests/align-data')
report = pysegul.load_distance_report(outputs['report'])
```

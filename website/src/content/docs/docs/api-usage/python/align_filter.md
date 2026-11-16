---
title: Alignment Filtering
sidebar:
  order: 5
---

Filter alignments by length, parsimony informative sites, taxon completeness, or missing data. PySEGUL writes the alignments that pass the filter, or concatenates them.

## Example

Set the input with `input_dir` or `input_files`, then call a filtering method. Each method runs the filter.

```python
import pysegul

def filter_alignments():
    filter = pysegul.AlignmentFiltering(
        input_fmt='nexus',
        datatype='dna',
        output_path='tests/output',
        output_fmt='nexus',
        )
    filter.input_dir = 'tests/align-data'
    # Or use a list of files:
    # filter.input_files = ['tests/align-data/locus1.nex']
    filter.minimal_taxa(0.5)
```

To concatenate the filtered alignments, set `is_concat` with a prefix and a partition format:

```python
filter = pysegul.AlignmentFiltering(
    'nexus',
    'dna',
    'tests/output',
    'nexus',
    is_concat=True,
    prefix='filtered_concat',
    partition_fmt='raxml',
    )
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `input_fmt` | Required | `'auto'`, `'fasta'`, `'nexus'`, `'phylip'` |
| `datatype` | Required | `'dna'`, `'aa'`, `'ignore'` |
| `output_path` | Required | Output directory |
| `output_fmt` | Required | `'fasta'`, `'nexus'`, `'phylip'`, or interleaved `'fasta-int'`, `'nexus-int'`, `'phylip-int'` |
| `is_concat` | `False` | Concatenate the alignments that pass the filter |
| `prefix` | `None` | Name of the concatenated alignment. Required with `is_concat` |
| `partition_fmt` | `None` | `'charset'`, `'nexus'`, `'raxml'`, or a `-codon` version. Required with `is_concat` |

## Input

| Attribute | Description |
| --- | --- |
| `input_dir` | Directory of input alignments |
| `input_files` | List of input alignment files |

## Methods

| Method | Keep alignments that |
| --- | --- |
| `minimal_taxa(percent_taxa)` | have at least `percent_taxa` (0.0–1.0) of all taxa |
| `minimal_length(min_length)` | are at least `min_length` sites long |
| `minimal_parsimony_inf(min_parsimony)` | have at least `min_parsimony` parsimony informative sites |
| `percent_informative(percent_informative)` | have at least `percent_informative` (0.0–1.0) parsimony informative sites |
| `contain_taxa(taxon_id)` | contain all of the taxa in the list |
| `minimal_taxa_count(min_taxa)` *(beta)* | have at least `min_taxa` taxa |
| `maximal_length(max_length)` *(beta)* | are at most `max_length` sites long |
| `maximal_parsimony_inf(max_parsimony)` *(beta)* | have at most `max_parsimony` parsimony informative sites |
| `missing_data(max_missing)` *(beta)* | have at most `max_missing` (0.0–1.0) missing data (gaps and `?`) |

:::caution[Beta]
Methods marked *(beta)* may still change.
:::

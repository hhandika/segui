---
title: Alignment Filtering
sidebar:
  order: 5
---

Filter alignments. Available filtering options:

- Alignment length
- Parsimony informative sites
- Percent parsimony informative sites
- Taxon completeness
- Missing data *(upcoming)*

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code. Example:

```python
import pysegul

def filter_alignments():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'nexus'
    is_concat = False
    output_dir = 'tests/output'
    filter = pysegul.AlignmentFiltering(
        input_format,  
        datatype, 
        output_dir, 
        output_format,
        is_concat
        )
    filter.input_dir = input_dir
    # For filtering by minimal alignment length
    filter.minimal_length(8)
    # For filtering by minimal parsimony informative sites
    filter.minimal_parsimony_inf(4)
    # For filtering by percent parsimony informative sites
    filter.percent_informative(0.5)
    # For filtering by taxon completeness (proportion of all taxa)
    filter.minimal_taxa(0.5)
    # For keeping alignments that contain all listed taxa
    filter.contain_taxa(['taxon_1', 'taxon_2'])
```

To concatenate the filtered alignments, set `is_concat` to `True` and provide a prefix and a partition format:

```python
filter = pysegul.AlignmentFiltering(
    'nexus',
    'dna',
    'tests/output',
    'nexus',
    True,
    prefix='filtered_concat',
    partition_fmt='raxml',
    )
```

## Upcoming filtering methods

:::caution[Upcoming]
These methods are not yet published on PyPI. They will be available in the next PySEGUL release. To use them now, build PySEGUL from [source](https://github.com/hhandika/pysegul).
:::

| Method | Keep alignments that |
| --- | --- |
| `minimal_taxa_count(count)` | have at least `count` taxa |
| `maximal_length(length)` | are at most `length` sites long |
| `maximal_parsimony_inf(count)` | have at most `count` parsimony informative sites |
| `missing_data(proportion)` | have at most `proportion` (0.0–1.0) missing data (gaps and `?`) |

```python
filter.minimal_taxa_count(10)
filter.maximal_length(2000)
filter.maximal_parsimony_inf(500)
filter.missing_data(0.25)
```

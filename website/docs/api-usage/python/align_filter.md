---
sidebar_position: 3
title: Alignment Filtering
---

Filter an alignments. Available filtering options:

- Alignment length
- Parsimony informative sites
- Percent parsimony informative sites
- Taxon completeness

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
    # For filtering by alignment length
    filter.minimal_length(8)
    # For filtering by parsimony informative sites
    filter.percent_informative(0.5)
    # For filtering by percent parsimony informative sites
    filter.percent_informative(0.5)
    # For filtering by minimal informative sites
    filter.minimal_parsimony_inf(4)
    # For filtering by taxon completeness
    filter.minimal_taxa(0.5)
```

---
title: Alignment Splitting
sidebar:
  order: 7
---

Split an alignment into multiple alignments based on partition information.

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code

```python
import pysegul

def split_alignment():
    input_alignment = 'tests/split-data/split-data.nex'
    input_format = 'nexus'
    datatype = 'dna'
    partition_format = 'nexus'
    output_format = 'fasta'
    # Check the partition before splitting. Set to False to skip checking.
    check_partition = True
    input_partition = 'tests/split-data/split-data_partition.nex'
    output_dir = 'tests/output'
    split = pysegul.AlignmentSplitting(
        input_alignment,
        input_format,  
        datatype, 
        output_dir, 
        output_format,
        partition_format,
        check_partition,
        input_partition = input_partition
        )
    split.split()
```

If `input_partition` is not set, PySEGUL reads the partition from the input alignment.

:::note
In PySEGUL 0.4.1 and earlier, `check_partition` is inverted: `True` skips partition checking. The upcoming release fixes it.
:::

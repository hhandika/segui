---
title: Alignment Partition Conversion
sidebar:
  order: 6
---

Convert alignment partition data between different formats. Available partition formats:

- RAxML
- NEXUS
- Charset

Charset is a nexus format that stores partition data in the same file as a NEXUS alignment.

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code. Example:

```python
import pysegul

def convert_partitions():
    input_paths = [
        'tests/partition-data/partition_codon.txt', 
        'tests/partition-data/partition.txt'
        ]
    # Available input and output format values: raxml, nexus, charset.
    input_format = 'raxml'
    output_format = 'nexus'
    datatype = 'dna'
    # Check the partition before converting. Set to False to skip checking.
    check_partition = True
    output_dir = 'tests/output'
    convert = pysegul.PartitionConversion(
        input_format,
        datatype,
        output_dir,
        output_format,
        check_partition
        )
    convert.from_files(input_paths)
```

:::note
Unlike most of other features, partition conversion does not support input directory.
:::

:::note
In PySEGUL 0.4.1 and earlier, `check_partition` is inverted: `True` skips partition checking. The upcoming release fixes it.
:::

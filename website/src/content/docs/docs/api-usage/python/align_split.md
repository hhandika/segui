---
title: Alignment Splitting
sidebar:
  order: 7
---

Split a concatenated alignment into one alignment per partition.

## Example

```python
import pysegul

def split_alignment():
    split = pysegul.AlignmentSplitting(
        input_path='tests/split-data/split-data.nex',
        input_fmt='nexus',
        datatype='dna',
        output_dir='tests/output',
        output_fmt='fasta',
        partition_fmt='nexus',
        input_partition='tests/split-data/split-data_partition.nex',
        )
    split.split()
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `input_path` | Required | Concatenated alignment file |
| `input_fmt` | Required | `'auto'`, `'fasta'`, `'nexus'`, `'phylip'` |
| `datatype` | Required | `'dna'`, `'aa'`, `'ignore'` |
| `output_dir` | Required | Output directory |
| `output_fmt` | Required | `'fasta'`, `'nexus'`, `'phylip'`, or interleaved `'fasta-int'`, `'nexus-int'`, `'phylip-int'` |
| `partition_fmt` | Required | `'charset'`, `'nexus'`, `'raxml'` |
| `check_partition` | `True` | Check that the partitions are valid before splitting |
| `input_partition` | `None` | Partition file. Defaults to the charset block in the input alignment |
| `output_prefix` | `None` | Prefix of the output file names |

## Methods

| Method | Description |
| --- | --- |
| `split()` | Split the alignment |

:::note
In PySEGUL 0.4.1 and earlier, `check_partition` is inverted: `True` skips partition checking. PySEGUL v0.5.0 fixes it.
:::

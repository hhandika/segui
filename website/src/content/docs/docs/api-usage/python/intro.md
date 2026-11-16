---
title: Introduction
sidebar:
  order: 1
---

[![PyPI version](https://badge.fury.io/py/pysegul.svg)](https://badge.fury.io/py/pysegul)

SEGUL is available as a Python library called `PySEGUL`. It allows users to use SEGUL API in Python. You don't need Rust knowledge to use the library. The library is available on [PyPI](https://pypi.org/project/pysegul/) and can be installed using pip:

```bash
pip install pysegul
```

Then, you can use the library in your Python script:

```python
import pysegul

# <Your code here...>
```

Here is an example of how to use the library to concatenate alignments:

- Create a file named `concat_alignments.py`.

- Copy and paste the following code. The shebang line `#!/usr/bin/env python` is optional. It is used to make the script executable on Linux and macOS.

```python
#!/usr/bin/env python
import pysegul

def concat_alignments():
    concat = pysegul.AlignmentConcatenation(
        input_fmt='nexus',
        datatype='dna',
        output_dir='tests/output',
        output_fmt='fasta',
        partition_fmt='raxml',
        output_prefix='concatenated',
        )
    concat.from_files(['tests/data/alignment1.nex', 'tests/data/alignment2.nex'])
    # Or concatenate every alignment in a directory that matches input_fmt
    concat.from_dir('tests/data')

if __name__ == '__main__':
    concat_alignments()
```

- Run the script:

```bash
python concat_alignments.py
```

## Common options

Most classes share these options. Each page lists the options of its class.

| Option | Values |
| --- | --- |
| `input_fmt` | `'auto'`, `'fasta'`, `'nexus'`, `'phylip'`. Interleaved files are detected automatically |
| `datatype` | `'dna'`, `'aa'`, `'ignore'` |
| `output_fmt` / `output_format` | `'fasta'`, `'nexus'`, `'phylip'`, or interleaved `'fasta-int'`, `'nexus-int'`, `'phylip-int'` |
| `partition_fmt` | `'charset'`, `'nexus'`, `'raxml'`. Add `-codon` for codon partitions, e.g. `'raxml-codon'` |

## Input files

Classes take input in one of two ways:

- **Run methods**: call `from_dir(input_dir)` to use every file in a directory that matches `input_fmt`, or `from_files(input_files)` with a list of paths.
- **Input attributes**: classes with several methods, such as `AlignmentFiltering`, take the input from the `input_dir` or `input_files` attribute. Set it before calling a method.

## Available features

| SEGUL command | PySEGUL class |
| --- | --- |
| `segul align concat` | [`AlignmentConcatenation`](/docs/api-usage/python/align_concat/) |
| `segul align convert` | [`AlignmentConversion`](/docs/api-usage/python/align_convert/) |
| `segul align distance` | [`AlignmentDistance`](/docs/api-usage/python/align_distance/) *(beta)* |
| `segul align filter` | [`AlignmentFiltering`](/docs/api-usage/python/align_filter/) |
| `segul align split` | [`AlignmentSplitting`](/docs/api-usage/python/align_split/) |
| `segul align summary` | [`AlignmentSummary`](/docs/api-usage/python/align_summary/) |
| `segul align trim` | [`AlignmentTrimming`](/docs/api-usage/python/align_trim/) *(beta)* |
| `segul align unalign` | [`AlignmentUnalignment`](/docs/api-usage/python/align_unalign/) *(beta)* |
| `segul partition` | [`PartitionConversion`](/docs/api-usage/python/align_partition/) |
| `segul read summary` | [`ReadSummary`](/docs/api-usage/python/read_summary/) |
| `segul contig summary` | [`ContigSummary`](/docs/api-usage/python/contig_summary/) |
| `segul maf convert` | [`MafConversion`](/docs/api-usage/python/maf/) *(beta)* |
| `segul maf summary` | [`MafSummary`](/docs/api-usage/python/maf/) *(beta)* |
| `segul sequence add` | [`SequenceAddition`](/docs/api-usage/python/sequence_addition/) *(beta)* |
| `segul sequence extract` | [`SequenceExtraction`](/docs/api-usage/python/sequence_extract/) |
| `segul sequence filter` | [`SequenceFiltering`](/docs/api-usage/python/sequence_filter/) *(beta)* |
| `segul sequence id` | [`IDExtraction`](/docs/api-usage/python/sequence_id/) |
| `segul sequence remove` | [`SequenceRemoval`](/docs/api-usage/python/sequence_remove/) |
| `segul sequence rename` | [`SequenceRenaming`](/docs/api-usage/python/sequence_rename/) *(beta)* |
| `segul sequence translate` | [`SequenceTranslation`](/docs/api-usage/python/sequence_translation/) |
| `segul sequence transpose` | [`SequenceTranspose`](/docs/api-usage/python/sequence_transpose/) *(beta)* |
| `--plot` and report viewers | [`PlotOptions` and report loaders](/docs/api-usage/python/plots_reports/) *(beta)* |

## Beta features

Features marked *(beta)* are new and may still change. Their options, outputs, and results may differ between versions.

## Citing PySEGUL

If you use PySEGUL in a publication, [cite the SEGUL paper](/docs/intro/#citation) and always report the exact PySEGUL version you used, especially for beta features. Check the version in Python:

```python
from importlib.metadata import version

print(version("pysegul"))
```

If you built PySEGUL from source, also report the commit:

```bash
git -C pysegul rev-parse --short HEAD
```

Starting with v0.5.0, PySEGUL requires Python 3.9 or later. Invalid options, such as an unknown format, raise a `ValueError`. Editors show the parameters and help of each class.

:::note
The [pysegul](https://pypi.org/project/pysegul/) library is still in beta. If you encounter any issues, please report them in the [issue tracker](https://github.com/hhandika/pysegul/issues). It is now support all major features that CLI and GUI versions supports. Our goal is to expose more SEGUL public functions to Python, including the helper functions. It will allow Python developers to create a custom analyses using SEGUL API in Python.
:::

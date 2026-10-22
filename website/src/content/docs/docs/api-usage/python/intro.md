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
    input_paths = ['tests/data/alignment1.nex', 'tests/data/alignment2.nex']
    # Available input_format values: nexus, fasta, phylip.
    # Automatically detect interleaved format.
    input_format = 'nexus'
    # Available datatype values: dna, aa.
    datatype = 'dna'
    # Available output_format values: fasta, phylip, nexus.
    # Suffix with -int for interleaved format. Example: phylip-int
    output_format = 'fasta'
    # Available partition_format values: raxml, nexus, charset.
    # Charset format is only available for nexus output format.
    # The charset partition data is stored in the same file as the alignment.
    partition_format = 'raxml'
    prefix = 'concatenated'
    output_dir = 'tests/output'
    concat = pysegul.AlignmentConcatenation(
        input_format,  
        datatype,
        output_dir,
        output_format,
        partition_format,
        prefix
        )
    concat.from_files(input_paths)
    # If you prefer to input a directory
    # and let SEGUL API to find
    # all alignment files that match the input format.
    input_dir = 'tests/data'
    concat.from_dir(input_dir)

if __name__ == '__main__':
    concat_alignments()
```

- Run the script:

```bash
python concat_alignments.py
```

## Available features

| SEGUL command | PySEGUL class |
| --- | --- |
| `segul align concat` | [`AlignmentConcatenation`](/docs/api-usage/python/align_concat/) |
| `segul align convert` | [`AlignmentConversion`](/docs/api-usage/python/align_convert/) |
| `segul align distance` | [`AlignmentDistance`](/docs/api-usage/python/align_distance/) *(upcoming)* |
| `segul align filter` | [`AlignmentFiltering`](/docs/api-usage/python/align_filter/) |
| `segul align split` | [`AlignmentSplitting`](/docs/api-usage/python/align_split/) |
| `segul align summary` | [`AlignmentSummary`](/docs/api-usage/python/align_summary/) |
| `segul align trim` | [`AlignmentTrimming`](/docs/api-usage/python/align_trim/) *(upcoming)* |
| `segul align unalign` | [`AlignmentUnalignment`](/docs/api-usage/python/align_unalign/) *(upcoming)* |
| `segul partition` | [`PartitionConversion`](/docs/api-usage/python/align_partition/) |
| `segul read summary` | [`ReadSummary`](/docs/api-usage/python/read_summary/) |
| `segul contig summary` | [`ContigSummary`](/docs/api-usage/python/contig_summary/) |
| `segul maf convert` | [`MafConversion`](/docs/api-usage/python/maf/) *(upcoming)* |
| `segul maf summary` | [`MafSummary`](/docs/api-usage/python/maf/) *(upcoming)* |
| `segul sequence add` | [`SequenceAddition`](/docs/api-usage/python/sequence_addition/) *(upcoming)* |
| `segul sequence extract` | [`SequenceExtraction`](/docs/api-usage/python/sequence_extract/) |
| `segul sequence filter` | [`SequenceFiltering`](/docs/api-usage/python/sequence_filter/) *(upcoming)* |
| `segul sequence id` | [`IDExtraction`](/docs/api-usage/python/sequence_id/) |
| `segul sequence remove` | [`SequenceRemoval`](/docs/api-usage/python/sequence_remove/) |
| `segul sequence rename` | [`SequenceRenaming`](/docs/api-usage/python/sequence_rename/) *(upcoming)* |
| `segul sequence translate` | [`SequenceTranslation`](/docs/api-usage/python/sequence_translation/) |
| `segul sequence transpose` | [`SequenceTranspose`](/docs/api-usage/python/sequence_transpose/) *(upcoming)* |

Features marked *(upcoming)* are not yet published on PyPI. To use them now, build PySEGUL from [source](https://github.com/hhandika/pysegul).

:::note
The [pysegul](https://pypi.org/project/pysegul/) library is still in beta. If you encounter any issues, please report them in the [issue tracker](https://github.com/hhandika/pysegul/issues). It is now support all major features that CLI and GUI versions supports. Our goal is to expose more SEGUL public functions to Python, including the helper functions. It will allow Python developers to create a custom analyses using SEGUL API in Python.
:::

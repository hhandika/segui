---
sidebar_position: 1
title: Introduction
---

SEGUL is available as a Python library called `PySEGUL`. It allows users to use SEGUL API in Python. You don't need Rust knowledge to use the library. The library is available on [PyPI](https://pypi.org/project/pysegul/) and can be installed using pip:

```bash
pip install pysegul
```

Then, you can use the library in your Python script:

```python
import pysegul
```

Here is an example of how to use the library to concatenate alignments:

```python
import pysegul

def concat_alignments():
    input_paths = ['tests/data/alignment1.nex', 'tests/data/alignment2.nex']
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
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

if __name__ == '__main__':
    concat_alignments()
```

:::note
The [pysegul](https://pypi.org/project/pysegul/) library is still in development. If you encounter any issues, please report them in the [issue tracker](https://github.com/hhandika/pysegul/issues). Our first goal is to make all SEGUL major features available in Python. The next goal is to expose more SEGUL public functions to Python, including the helper functions. It will allow Python developers to interact, manipulate, or create a custom workflow using SEGUL API in Python.
:::

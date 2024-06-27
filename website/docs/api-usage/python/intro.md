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
    # If you prefer to input a directory
    # and let SEGUL API to find all matching alignment files
    input_dir = 'tests/data'
    concat.from_dir(input_dir)

if __name__ == '__main__':
    concat_alignments()
```

- Run the script:

```bash
python concat_alignments.py
```

:::note
The [pysegul](https://pypi.org/project/pysegul/) library is still in beta. If you encounter any issues, please report them in the [issue tracker](https://github.com/hhandika/pysegul/issues). It is now support all major features that CLI and GUI versions supports. Our goal is to expose more SEGUL public functions to Python, including the helper functions. It will allow Python developers to create a custom analyses using SEGUL API in Python.
:::

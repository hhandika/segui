---
title: Sequence Renaming
sidebar:
  order: 18
  badge:
    text: Upcoming
    variant: caution
---

:::caution[Upcoming]
This feature is not yet published on PyPI. It will be available in the next PySEGUL release. To use it now, build PySEGUL from [source](https://github.com/hhandika/pysegul).
:::

Rename sequence IDs across many sequence files at once. Available renaming methods:

- Replace IDs using a list of ID pairs or a CSV/TSV file
- Remove a string or a regular expression match
- Replace a string or a regular expression match

Regular expressions follow the [Rust regex syntax](https://docs.rs/regex/latest/regex/).

## Steps

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def rename_sequences():
    input_dir = 'tests/align-data'
    input_format = 'nexus'
    datatype = 'dna'
    output_format = 'fasta'
    output_dir = 'tests/output'
    rename = pysegul.SequenceRenaming(
        input_format,
        datatype,
        output_dir,
        output_format,
        # Optional. Log the new IDs without writing any files.
        dry_run=False,
        )
    rename.input_dir = input_dir
    # Or use a list of files:
    # rename.input_files = ['tests/align-data/locus1.nex']

    # Replace IDs using a list of (original ID, new ID) pairs
    rename.replace_id([('seq1', 'Rattus_rattus'), ('seq2', 'Mus_musculus')])
```

Use one of the other methods instead of `replace_id`:

```python
# Replace IDs using a CSV or TSV file with a header row
# and two columns: original ID and new ID
rename.replace_id_from_file('new_ids.csv')
# Remove a string from the IDs
rename.remove_string('_voucher')
# Remove the first regex match. Set all=True to remove every match.
rename.remove_regex(r'_\d+$', all=False)
# Replace a string
rename.replace_string('Rattus', 'R')
# Replace the first regex match. Set all=True to replace every match.
rename.replace_regex(r'^([A-Z])[a-z]+_', 'X_', all=False)
```

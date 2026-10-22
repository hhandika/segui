---
title: MAF Conversion & Summary
sidebar:
  order: 12
  badge:
    text: Upcoming
    variant: caution
---

:::caution[Upcoming]
This feature is not yet published on PyPI. It will be available in the next PySEGUL release. To use it now, build PySEGUL from [source](https://github.com/hhandika/pysegul).
:::

Convert and summarize multiple alignment format (MAF) files, such as whole-genome alignments. See the CLI guidelines for [MAF conversion](/docs/cli-usage/maf-convert/) and [MAF summary](/docs/cli-usage/maf-summary/) for details on the output files.

## MAF Conversion

Install PySEGUL using pip if you haven't done it yet

```bash
pip install pysegul
```

Create a new Python script, import the library, and write python code.

```python
import pysegul

def convert_maf():
    input_dir = 'tests/maf-data'
    output_dir = 'tests/output'
    convert = pysegul.MafConversion(
        output_dir,
        # Optional. Default: 'fasta'
        output_fmt='nexus',
        # Optional. Without a BED file, write one file per 'block'
        # or per reference chromosome ('chrom').
        group_by='block',
        )
    convert.from_dir(input_dir)
```

To extract loci, provide a BED file. Each block goes to every locus it overlaps.

```python
import pysegul

def convert_maf_loci():
    convert = pysegul.MafConversion(
        'tests/output',
        output_fmt='fasta',
        # BED file of loci (.bed or .bed.gz)
        bed='loci.bed',
        # Optional. Set to False to keep whole blocks instead of clipping to loci.
        clip=True,
        # Optional. Reverse complement loci on the minus strand.
        strand_aware=False,
        # Optional. Write blocks that match no locus to the unmatched directory.
        write_unmatched=False,
        # Optional. Name of the locus report CSV.
        output_prefix='loci',
        )
    convert.from_files(['alignment.maf'])
```

All conversion options:

| Option | Default | Description |
| --- | --- | --- |
| `output_fmt` | `'fasta'` | `'fasta'`, `'nexus'`, `'phylip'`, or the interleaved `-int` versions |
| `group_by` | `'block'` | Without a BED file, write one file per `'block'` or per `'chrom'` |
| `bed` | `None` | BED file of loci |
| `clip` | `True` | Clip blocks to the loci. Requires `bed` |
| `strand_aware` | `False` | Reverse complement loci on the minus strand. Requires `bed` |
| `write_unmatched` | `False` | Write blocks that match no locus. Requires `bed` |
| `full_source_name` | `False` | Use full source names (e.g. `hg18.chr7`) as sample names instead of the assembly prefix (`hg18`) |
| `ref_species` | `None` | Reference species. Defaults to the first species in the first block |
| `species` | `None` | List of species to keep. The reference is still used for coordinates |
| `min_block_len` | `None` | Skip blocks with fewer reference bases |
| `min_species` | `None` | Skip blocks with fewer species, counting the reference |
| `min_score` | `None` | Skip blocks with a lower score |
| `output_prefix` | `None` | Name of the locus report CSV written with `bed` |

Errors, such as an unreadable BED file, raise a `ValueError`.

## MAF Summary

Summarize MAF files per species and per file.

```python
import pysegul

def summarize_maf():
    summary = pysegul.MafSummary(
        'tests/output',
        # Optional
        output_prefix='maf',
        # Optional. Use full source names as sample names.
        full_source_name=False,
        # Optional. Reference species.
        ref_species=None,
        # Optional. List of species to keep.
        species=None,
        )
    summary.from_dir('tests/maf-data')
```

---
title: MAF Conversion & Summary
sidebar:
  order: 12
  badge:
    text: Beta
    variant: caution
---

:::caution[Beta]
This feature is in beta and may still change.
:::

Convert and summarize multiple alignment format (MAF) files, such as whole-genome alignments. See the CLI guidelines for [MAF conversion](/docs/cli-usage/maf-convert/) and [MAF summary](/docs/cli-usage/maf-summary/) for details on the output files.

## MAF Conversion

```python
import pysegul

def convert_maf():
    convert = pysegul.MafConversion(
        output_path='tests/output',
        output_fmt='nexus',
        )
    counts = convert.from_dir('tests/maf-data')
```

To extract loci, provide a BED file. Each block goes to every locus it overlaps.

```python
convert = pysegul.MafConversion(
    'tests/output',
    bed='loci.bed',
    output_prefix='loci',
    )
counts = convert.from_files(['alignment.maf'])
print(counts['loci_written'])
```

### Options

| Option | Default | Description |
| --- | --- | --- |
| `output_path` | Required | Output directory |
| `output_fmt` | `'fasta'` | `'fasta'`, `'nexus'`, `'phylip'`, or interleaved `'fasta-int'`, `'nexus-int'`, `'phylip-int'` |
| `group_by` | `'block'` | Without a BED file, write one file per `'block'` or per reference chromosome (`'chrom'`) |
| `bed` | `None` | BED file of loci (`.bed` or `.bed.gz`) |
| `clip` | `True` | Clip blocks to the loci. Set to `False` to keep whole blocks. Requires `bed` |
| `strand_aware` | `False` | Reverse complement loci on the minus strand. Requires `bed` |
| `full_source_name` | `False` | Use full source names (e.g. `hg18.chr7`) as sample names instead of the assembly prefix (`hg18`) |
| `ref_species` | `None` | Reference species. Defaults to the first species in the first block |
| `species` | `None` | List of species to keep. The reference is still used for coordinates |
| `min_block_len` | `None` | Skip blocks with fewer reference bases (gaps excluded) |
| `min_species` | `None` | Skip blocks with fewer species, counting the reference |
| `min_score` | `None` | Skip blocks with a lower score. Blocks without a score pass |
| `write_unmatched` | `False` | Write blocks that match no locus to the unmatched directory. Requires `bed` |
| `output_prefix` | `None` | Name of the locus report CSV written with `bed` |

Errors, such as an unreadable BED file, raise a `ValueError`.

### Methods

| Method | Description |
| --- | --- |
| `from_dir(input_dir)` | Convert the MAF files in a directory |
| `from_files(input_files)` | Convert a list of MAF files |

Both return a dictionary of counts:

| Key | Count |
| --- | --- |
| `files` | MAF files read |
| `blocks_read` | Blocks read |
| `blocks_no_ref` | Blocks without a row from the reference species |
| `blocks_filtered` | Blocks skipped by `min_block_len`, `min_species`, or `min_score` |
| `blocks_unmatched` | Blocks that overlap no BED locus |
| `duplicate_rows` | Rows dropped because a sample appears more than once in a block |
| `overlapping_pieces` | Block pieces dropped because they overlap another piece of the same locus |
| `loci_written` | Loci written |
| `loci_empty` | BED loci without any aligned data |

## MAF Summary

Summarize MAF files per species and per file.

```python
import pysegul

def summarize_maf():
    summary = pysegul.MafSummary(
        output_path='tests/output',
        output_prefix='maf',
        )
    outputs = summary.from_dir('tests/maf-data')
```

### Options

| Option | Default | Description |
| --- | --- | --- |
| `output_path` | Required | Output directory |
| `output_prefix` | `None` | Name of the output files |
| `full_source_name` | `False` | Use full source names as sample names |
| `ref_species` | `None` | Reference species. Defaults to the first species in the first block |
| `species` | `None` | List of species to report |
| `plot` | `None` | Chart options. See [Charts and Reports](/docs/api-usage/python/plots_reports/) |

### Methods

| Method | Description |
| --- | --- |
| `from_dir(input_dir)` | Summarize the MAF files in a directory |
| `from_files(input_files)` | Summarize a list of MAF files |

Both return a dictionary of output paths: `per_file`, `per_species`, and `plots`.

```python
summary = pysegul.MafSummary('tests/output', plot=pysegul.PlotOptions(format='svg'))
outputs = summary.from_dir('tests/maf-data')
print(outputs['per_species'], outputs['plots'])
```

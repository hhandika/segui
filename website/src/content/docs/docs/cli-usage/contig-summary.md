---
title: Genomic Contig Summary
sidebar:
  order: 11.1
---

`segul contig summary` calculates summary statistics for assembled contigs in FASTA format. For raw reads, see [Genomic Read Summary](/docs/cli-usage/read-summary/).

## Input formats

- Gunzip Compressed FASTA (.fa.gz/.fasta.gz)
- Standard FASTA (.fa/.fasta)

## Usage

```bash
segul contig summary -i contigs.fa
```

or using directory input:

```bash
segul contig summary -d /contig_read_dir
```

Use `--output` (or `-o`) to set the output directory and `--prefix` to set the prefix of the output files:

```bash
segul contig summary -d /contig_read_dir -o contig_output --prefix my_contig_summary
```

## Statistics

Available statistics for contiguous sequences:

- Contig count
- Base count
- Nucleotide
- GC content
- AT content
- Minimum contig length
- Maximum contig length
- Mean contig length
- Median contig length
- N50
- N75
- N90
- Contig 750 bp
- Contig 1000 bp
- Contig 1500 bp
- Cumulative length
- A, C, G, T, N counts

## All options

| Option                 | Description                                                    |
| ---------------------- | -------------------------------------------------------------- |
| `-d`, `--dir`          | Directory with contig files                                    |
| `-i`, `--input`        | Contig files. Allows wildcards                                 |
| `-f`, `--input-format` | Input format: `auto` (default), `fasta`, or `gzip`             |
| `-o`, `--output`       | Output directory. Default: `Contig-Summary`                    |
| `--prefix`             | Prefix of the output files                                     |
| `--force`              | Overwrite an existing output directory                         |
| `--log`                | Log file path. Default: `segul.log`                            |

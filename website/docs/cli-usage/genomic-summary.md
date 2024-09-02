---
sidebar_position: 11
title: Genomic Summary
---


Since version 0.19.0, `segul` can calculate summary statistics for raw reads and contiguous sequences.

## Raw reads

Supported file formats:

- Gunzip Compressed FASTQ (.fq.gz/.fastq.gz)
- Standard FASTQ (.fq/.fastq)

Example

```bash
segul read summary -i raw_reads.fq.gz
```

or using directory input:

```bash
segul read summary -d /raw_read_dir
```

The output file will be saved as `default-read-summary.csv` in `Read-Summary` directory.

To specify, the output directory uses the `-output` or `-o` argument:

```bash
segul read summary -d /raw_read_dir -o read_dir_output
```

You can also use the `--prefix` argument to specify the prefix name of the output files:

```bash
segul read summary -d /raw_read_dir -o read_dir_output --prefix my_read_summary
```

SEGUL provides three modes to calculate summary statistics for raw reads:

**Minimal**: read count only
**Default**: generate essential statistics (see below)
**Complete**: generate all the essential statistics plus summary statistics per position in each read of each FASTQ file.

Essential statistics for raw reads:

- Number of reads
- Number of bases
- Mean read length
- Minimum read length
- Maximum read length
- GC count
- GC content
- AT count
- AT content
- A, C, G, T, N count
- Low-quality base count
- Mean base quality
- Min base quality
- Max base quality

## Contiguous sequences

Supported file formats:

- Fasta (fa/fasta)

Example

```bash
segul contig summary -i contigs.fa
```

or using directory input:

```bash
segul contig summary -d /contig_read_dir
```

You can also specify the output directory names and the prefix for the output file names, similar to the read summary above.

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

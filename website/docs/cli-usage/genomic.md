---
sidebar_position: 8
---

# Genomic Summary

Since version 0.19.0, `segul` can calculate summary statistics for raw reads and contiguous sequences.

## Raw reads

Supported file formats:

- Gunzip Compressed fastq (fq.gz/fastq.gz)
- Standard fastq (fq/fastq)

Example

```Bash
segul read summary -i raw_reads.fq.gz -o raw_reads_summary
```

The output file will be saved as `read-summary.csv`.

`segul` provide three modes to calculate summary statistics for raw reads:

**Minimal**: read count only
**Default**: generate essential statistics (see below)
**Complete**: generate all the essential statistics plus summary statistics per position in read for each file.

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
- Low quality base count
- Mean base quality
- Min base quality
- Max base quality

## Contiguous sequences

Supported file formats:

- Fasta (fa/fasta)

Example

```Bash
segul contig summary -i contigs.fa -o contigs_summary
```

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

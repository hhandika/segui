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
segul raw summary -i raw_reads.fq.gz -o raw_reads_summary
```

The output file will be saved as `read-summary.csv`.

## Contiguous sequences

Supported file formats:

- Fasta (fa/fasta)

Example

```Bash
segul contig summary -i contigs.fa -o contigs_summary
```

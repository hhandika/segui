---
sidebar_position: 8
---

# Genomic Summary

`segul` can calculate summary statistics for raw reads and contiguous sequences.

## Raw reads

Supported file formats:

- Gunzip Compressed fastq (fq.gz/fastq.gz)
- Standard fastq (fq/fastq)

Example

```Bash
segul raw summary -i raw_reads.fq.gz -o raw_reads_summary
```

## Contiguous sequences

Supported file formats:

- Fasta (fa/fasta)

Example

```Bash
segul contig summary -i contigs.fa -o contigs_summary
```

---
sidebar_position: 3
title: Features
---

This page provides a detailed explaination and the inner working of the features available in SEGUL. This is **work in progress**.

## Task Group

In GUI, the task group is represented as a navigation bar or navigation rail depending on the platform. In the CLI, the task group is represented as a command group. The task group consists of:

### Alignments

For tasks related to multiple sequence alignments, such as concatenation, conversion, filtering, and splitting. The app enforces the input to be in **the alignment format**. We consider an alignment if the sequence length is the same for each input alignment.

### Genomic

For tasks related to genomic data, such as sequence read and contig. In the CLI, the genomic task group is divided into two different command depending on the input files. The `read` command accepts sequence read files (FASTQ or gunzip compressed FASTQ), while the `contig` command accepts contig files in FASTA.

### Sequences

For works in sequence basis. The input can also be alignment files. However, the app does not check the sequence length is the same for each alignment. We refer the input for these tasks throughout the documentation as **standard sequence files**.

## File Input

SEGUL always operates on multiple files, except for Alignment Splitting that only accepts one alignment file.

## Input Format

### Supported file extensions

#### Alignment and standard sequence files

List of supported file extensions for alignment and sequence tasks:

- NEXUS: `.nex`, `.nexus`, `.nxs`
- FASTA: `.fasta`, `.fa`, `.fna`, `.fsa`, `.fas`
- PHYLIP*: `.phy`, `.phylip`, `.ph`

:::note
SEGUL only supports relaxed PHYLIP format. The strict PHYLIP format is not supported.

Example of relaxed PHYLIP format:

```plaintext
5 10
Seq1    ATCGATCGATATCGATCGAT
Seq2    ATCGATCGATATCGATCGAT
Seq3    ATCGATCGATATCGATCGAT
```

Example of strict PHYLIP format (note the space between each sequence):

```plaintext
5 10

Seq1    ATCGATCGAT ATCGATCGAT
Seq2    ATCGATCGAT ATCGATCGAT
Seq3    ATCGATCGAT ATCGATCGAT
```

:::

#### Genomic data files

List of supported file extensions for genomic tasks:

- Sequence read: `.fastq`, `.fq`
- Compressed sequence read: `.fastq.gz`, `.fq.gz`
- Contig: `.fasta`, `.fa`, `.fna`, `.fsa`, `.fas`

## Alignment Operations

### Alignment Concatenation

### Alignment Conversion

### Alignment Filtering

### Alignment Partition Conversion

### Alignment Splitting

### Alignment Summary

## Genomic Operations

### Sequence Read Summary

### Contiguous Sequence Summary

## Sequence Operations

### Sequence ID Extraction

### Sequence ID Mapping

### Sequence ID Renaming

### Sequence Extraction

### Sequence Filtering

### Sequence Removal

### Sequence Translation

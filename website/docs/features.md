---
sidebar_position: 3
title: Features
---

This page provides a detailed explanation of the inner workings of the features available in SEGUL. It is a work in progress.

## Task Group

The task group is a navigation bar or rail in GUI, depending on the platform. In the CLI, the task group is represented as a command group. The task group consists of:

### Alignments

This is for tasks related to multiple sequence alignments, such as concatenation, conversion, filtering, and splitting. The app enforces the input to be in **the alignment format**. We consider an alignment if the sequence length is the same for each input alignment.

### Genomic

The CLI divides the genomic task group into two commands depending on the input files for tasks related to genomic data, such as sequence read and contig. The `read` command accepts sequence read files (FASTQ or gunzip compressed FASTQ), while the `contig` command accepts contig files in FASTA.

### Sequences

The input for the sequence task group can also be alignment files. However, the app does not check that the sequence length is the same for each alignment. Throughout the documentation, we refer to the input for these tasks as **standard sequence files**.

## File Input

SEGUL always operates on multiple files, except for Alignment Splitting, which only accepts one alignment file.

### Supported file extensions

#### Alignment and standard sequence files

List of supported file extensions for alignment and sequence tasks:

- NEXUS: `.nex`, `.nexus`, `.nxs`
- FASTA: `.fasta`, `.fa`, `.fna`, `.fsa`, `.fas`
- PHYLIP*: `.phy`, `.phylip`, `.ph`

:::note
SEGUL only supports a **relaxed PHYLIP** format. The strict PHYLIP format is not supported.

Example of relaxed PHYLIP format:

```plaintext
5 10
Seq1    ATCGATCGATATCGATCGAT
Seq2    ATCGATCGATATCGATCGAT
Seq3    ATCGATCGATATCGATCGAT
```

Example of strict PHYLIP format (note the space between each sequence). The format also restricts taxon identifiers/sample names to a maximum of 10 characters.

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

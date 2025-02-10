---
sidebar_position: 4
title: Features
---

This page provides a detailed explanation of the inner workings of the features available in SEGUL. It is a work in progress.

## Task Group

We group SEGUL's main features into task groups based on the scope of the analyses and the data input. Each task group is represented as a button in a navigation bar or rail in GUI, depending on the platform. In the CLI, the task group is represented as a command group. The task group consists of:

### Alignments

This is for tasks related to multiple sequence alignments, such as concatenation, conversion, filtering, and splitting. The app enforces the input to be in **the alignment format**, except for partition conversion, which only accepts input in partition formats, such as RaXML or NEXUS partition. We consider an alignment if the sequences within an alignment have the same length. SEGUL will not detect miss-aligned sequences when they are of the same length.

### Genomic

The CLI divides the genomic task group into two commands depending on the input files for tasks related to genomic data, such as sequence read and contig. The `read` command accepts sequence read files (FASTQ or gunzip compressed FASTQ), while the `contig` command accepts contig files in FASTA. The GUI groups the genomic task in the same group and relies on a dropdown menu to provide task selection.

### Sequences

The input for the sequence task group can be either aligned or unaligned sequence files. When the input is an alignment, the app does not check that the sequence length is the same for each alignment. Throughout the documentation, we refer to the input for these tasks as **standard sequence files**.

Example of an aligned sequence file in PHYLIP format:

```plaintext
3 10
sequence1 agtcccc--
sequence2 agtccccaa
sequence3 agtc-cctt
```

Example of the same file when it is unaligned:

```plaintext
3 10
sequence1 agtcccc
sequence2 agtccccaa
sequence3 agtccctt
```

## File Input

SEGUL always supports multiple file inputs, except for Alignment Splitting, which only accepts one concatenated alignment file.

### Supported file extensions

#### Alignment and standard sequence files

List of supported file extensions for alignment and sequence tasks:

- NEXUS: `.nex`, `.nexus`, `.nxs`
- FASTA: `.fasta`, `.fa`, `.fna`, `.fsa`, `.fas`
- Relaxed-PHYLIP*: `.phy`, `.phylip`, `.ph`

#### Genomic data files

List of supported file extensions for genomic tasks:

- Sequence read: `.fastq`, `.fq`
- Compressed sequence read: `.fastq.gz`, `.fq.gz`
- Contig: `.fasta`, `.fa`, `.fna`, `.fsa`, `.fas`

:::info
SEGUL does not support the strict PHYLIP format.

Example of strict PHYLIP format (note the space between each sequence). The format also restricts taxon identifiers/sample names to a maximum of 10 characters.

```plaintext
5 10

Seq1    ATCGATCGAT ATCGATCGAT
Seq2    ATCGATCGAT ATCGATCGAT
Seq3    ATCGATCGAT ATCGATCGAT
```

This is compared to a relaxed PHYLIP format that does not have space between sequences and allows longer taxon identifiers:

```plaintext
5 10
genus_species_museumNo1    ATCGATCGATATCGATCGAT
genus_species_museumNo2    ATCGATCGATATCGATCGAT
genus_species_museumNo3    ATCGATCGATATCGATCGAT
```

:::

## Alignment Task Groups

### Alignment Concatenation

Given a set of aligned sequences, this task concatenates them into a single alignment and generate partition for the concatenated alignment. The concatenation is done by adding the sequences from each alignment file to the end of the previous alignment file. The concatenation used alphanumeric order by the alignment name. It matches the sequences for concatenation based on the taxon identifiers/sample names. Typos or inconsistent naming in the taxon identifiers/sample names across the dataset will result in unmatched sequences.

:::tip
You can use the [Sequence ID Extraction](#sequence-id-extraction) feature to check for typos or inconsistencies in the name.
:::

For example, given the following two alignments:

Alignment 1:

```plaintext
3 10
sequence1 agtcccc--
sequence2 agtccccaa
sequence3 agtc-cctt
```

Alignment 2:

```plaintext
3 10
sequence1 agtcccc--
sequence2 agtccccaa
sequence3 agtc-cctt
```

The concatenated alignment will be:

```plaintext
3 20
sequence1 agtcccc--agtcccc--
sequence2 agtccccaaagtccccaa
sequence3 agtc-ccttagtc-cctt
```

The partition in the RAxML format will be:

```plaintext
DNA, sequence1 = 1-10
DNA, sequence2 = 11-20
DNA, sequence3 = 21-30
```

You can also choose to create NEXUS partition format instead:

```plaintext
#NEXUS
begin sets;
charset sequence1 = 1-10;
charset sequence2 = 11-20;
charset sequence3 = 21-30;
end;
```

### Alignment Conversion

The alignment conversion task converts the alignment file format to another format.

### Alignment Filtering

### Alignment Partition Conversion

### Alignment Splitting

### Alignment Summary

## Genomic Task Groups

### Sequence Read Summary

### Contiguous Sequence Summary

## Sequence Task Groups

### Sequence ID Extraction

### Sequence ID Mapping

### Sequence ID Renaming

### Sequence Extraction

### Sequence Filtering

### Sequence Removal

### Sequence Translation

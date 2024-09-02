---
sidebar_position: 14
---

# Sequence Filtering

The sequence filtering method works at the sequence level, which differs from the SEGUL [alignment filtering](/docs/cli-usage/sequence-filter) feature, which works on the alignment level. Using the alignment filtering feature will filter the entire alignment that does not meet the filtering criteria. However, the sequence filtering feature will remove sequences that do not meet the criteria while retaining the same alignment if at least one sequence is left in the alignment. The feature works on many alignments simultaneously and will never overwrite your original datasets; it will create new files with the filtered sequences.

Available filtering methods:

1. Sequence length
2. Proportion of gaps

The command is structured as below:

```Bash
segul sequence filter <input-option> [alignment-path] <filtering-option> <value>
```

## Filtering based on sequence length

Given a collection of alignments, SEGUL will remove sequences with non-gapped characters less than the specified length in each alignment. For example, we have an alignment with three sequences:

```plaintext
>seq_1
agtctgatc
>seq_2
agtc-----
>seq_3
agtcgatct
```

We want to filter sequences that contain at least 5 bp of sequences, excluding gaps. We can use the `--min-length` option:

```Bash
segul sequence filter --dir alignments/ --min-length 5
```

It will filter out the seq_2 because it only has 4 bp sequences. The result will be:

```plaintext
>seq_1
agtctgatc
>seq_3
agtcgatct
```

## Filtering based on the maximum proportion of gaps

SEGUL considers `-` and `?` as gap characters. The app will remove sequences with a proportion of gaps greater than the specified value. To filter sequences, use the `--max-gap` option with a value between 0 and 1.

```Bash
segul sequence filter --dir alignments/ --max-gap 0.3
```

---
sidebar_position: 15
---

# Sequence Removal

Based on a list of IDs, you can remove sequences in a collection of alignments. This feature is the opposite of `segul extract` feature. It is faster than `segul extract` if you remove less than a half of the sequences.

## Remove sequences based on a list of IDs

You can remove sequences based on a list of IDs. The list of IDs should be a text file with one ID per line. The IDs should be the same as the IDs in the alignment files. The IDs are case-sensitive.

```Bash
segul sequence remove --dir [alignment-dir] -f [sequence-format-keyword] --id [list-of-id]
```

Example:

```Bash
segul sequence remove --dir ./data/ -f fasta --id ./data/id.txt
```

## Remove sequences based on a regular expression

Using regular expression:

```Bash
segul sequence remove --dir [alignment-dir] -f [sequence-format-keyword] --re=["regex"]
```

Example:

Command below will remove all sequences whose IDs with the name started with `Homo`.

```Bash
segul sequence remove --dir ./data/ -f fasta --re="^Homo"
```

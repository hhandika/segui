---
sidebar_position: 15
---

# Sequence Removal

Based on a list of IDs, you can remove sequences in a collection of alignments. This feature is the opposite of `segul extract` feature. It is faster than `segul extract` if you remove less than a half of the sequences.

## Remove sequences based on a list of IDs

You can remove sequences based on a list of sequence IDs. Input a list of IDs as a string separated by semi-colons.

```Bash
segul sequence remove --dir [alignment-dir] -f [sequence-format-keyword] --id="[list-of-id]"
```

Example:

```Bash
segul sequence remove --dir ./data/ -f fasta --id="seq_1;seq_2;seq_3"
```

:::warning
The equal sign "=" and quotation marks `"` are required to input a list of IDs.
:::

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

---
sidebar_position: 16
---

# Sequence Removal

Based on a list of IDs, you can remove sequences in a collection of alignments. This feature is the opposite of the `segul extract` feature. Removing less than half of the sequences is faster than `segul extract`.

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
To input a list of IDs, you must use the equal sign "=" and quotation marks `"`.
:::

## Remove sequences based on a regular expression

Using regular expression:

```Bash
segul sequence remove --dir [alignment-dir] -f [sequence-format-keyword] --re=["regex"]
```

Example:

The command below will remove all sequences whose IDs with the name started with `Mus`.

```Bash
segul sequence remove --dir ./data/ -f fasta --re="^Mus"
```

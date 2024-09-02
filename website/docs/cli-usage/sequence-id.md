---
sidebar_position: 10
---

# Sequence ID Extraction

Often, we need to know what the taxa in our dataset are. The most straightforward command would be:

```bash
segul sequence id -i [input-path]
```

or using directory input:

```bash
segul sequence id -d alignment_dir
```

SEGUL will generate the unique ID across all input alignments. The output is a text file containing a list of the IDs in alphabetical order. By default, the output directory is `SEGUL-ID`. The file will be saved as `id.txt` in the output directory. For example, if all your alignments contain three samples, the output file will look like this:

```Text
sequence_1
sequence_2
sequence_3
```

To change the output directory, use the `-o` or `--output` option:

```Bash
segul sequence id -i alignments/ -o my_alignment_id
```

To change the output file name, use the `--prefix` option:

```Bash
segul sequence id -i alignments/ --prefix my_alignment_id
```

:::info
Before version 0.19.0, the SEGUL CLI outputs the sequence IDs in the current working directory. The output option will only change the file name.
:::

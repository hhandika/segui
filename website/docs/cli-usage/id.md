---
sidebar_position: 10
---

# Sequence ID Extraction

Often, we need to know what are the taxa we in our dataset. The simplest command would be:

```bash
segul sequence id -i [input-path]
```

`segul` will generate the ID in a text file containing a list of the ID in alphabetical order. By default the output directory is `SEGUL-ID`. The file will be saved as `id.txt` in the output directory. For example, if the input directory contains three sequence files, the output file will look like this:

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
Before version 0.19.0, `segul` output sequence ID in the current working directory. The output option will only change the file name.
:::

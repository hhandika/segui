---
sidebar_position: 10
---

# Sequence ID Extraction

Often, we need to know what are the taxa we in our dataset. The simplest command would be:

```bash
segul id -i [input-path]
```

`segul` will generate the ID in a text file containing a list of the ID in alphabetical order. The file will be saved as `id.txt` in your current working directory:

```Text
sequence_1
sequence_2
sequence_3
```

To change the file name, pass the name (without the extension) to the `--output` or `-o` option. For example:

```Bash
segul id -i alignments/ -o my_alignment_id
```

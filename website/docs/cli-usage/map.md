---
sidebar_position: 11
---

# Sequence ID Mapping

To map the distribution of your samples across your dataset, you only need to pass `--map` flag in the finding unique IDs command:

```bash
segul id -i [input-path] --map
```

It will generate two files. The first file is the list of unique IDs in your dataset (named default to id.txt). This file is similar to generating unique IDs. The second file is a csv file (named default to id_map.txt) containing the distrubution of your samples presented in TRUE/FALSE values across your alignments. The content of the file will look like as below:

| Alignments | sequence_1 | sequence_2 | sequence_3 |
| ---------- | ---------- | ---------- | ---------- |
| locus_1    | TRUE       | FALSE      | TRUE       |
| locus_2    | TRUE       | TRUE       | TRUE       |
| locus_3    | FALSE      | FALSE      | TRUE       |

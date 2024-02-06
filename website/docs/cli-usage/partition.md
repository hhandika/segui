---
sidebar_position: 6
---

# Alignment Partition Conversion

`segul` can convert a single and multiple partition files in multiple folders. You can also use this function to extract partition embedded in NEXUS sequence files.

```Bash
segul partition convert --input <a-path/wildcard-to-partition> --input-part <input-partition-format> --output-part<output-partition-format>
```

If you output to RaXML partition and it is a DNA sequence, we recommend to use `--datatype dna` option. The partition format will include the datatype as below:

```Text
DNA, locus_1 = 1-100
DNA, locus_2 = 101-150
DNA, locus_3 = 151-200
```

By default, `segul` check the partition format:

1. First partition position starts with 1.
2. The next partition is next number after the end of the previous partition. If codon model, it will check the next locus applies the rule.

You can ignore format checking by passing the `--uncheck` flag.

For example, to extract nexus in-file partitions (called charset format in `segul`):

```Bash
segul partition convert --input concatenated_alignment.nex --input-part charset --output-part nexus
```

You can also use wildcard to convert multiple concatenated alignment partitions at once:

```Bash
segul partition convert --input ./*/concatenated_alignment.nex --input-part charset --output-part nexus
```

`segul` by default will save the resulting partitions in the parent directory of the input partition (or alignment if the partition is charset).

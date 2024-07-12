---
sidebar_position: 6
---

# Alignment Partition Conversion

SEGUL CLI can convert single and multiple partition files. It can also extract partitions embedded in NEXUS sequence files.

```Bash
segul partition convert --input <a-path/wildcard-to-partition> --input-part <input-partition-format> --output-part<output-partition-format>
```

If you output to RaXML partition and it is a DNA sequence, we recommend using the `--datatype dna` option. The partition format will include the datatype as below:

```Text
DNA, locus_1 = 1-100
DNA, locus_2 = 101-150
DNA, locus_3 = 151-200
```

By default, `segul` checks the partition format:

1. The first partition position starts with 1.
2. The next partition is the next number after the previous partition's end. If using the codon model, the next locus applies the rule.

Passing the `--uncheck` flag allows you to ignore format checking. This is helpful if you only want to extract a specific part of a concatenated alignment.

For example, to extract nexus in-file partitions (called charset format in `segul`):

```Bash
segul partition convert --input concatenated_alignment.nex --input-part charset --output-part nexus
```

You can also use wildcard to convert multiple concatenated alignment partitions at once:

```Bash
segul partition convert --input ./*/concatenated_alignment.nex --input-part charset --output-part nexus
```

By default, SEGUL will save the resulting partitions in the parent directory of the input partition (or alignment if the partition is charset).

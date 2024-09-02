---
sidebar_position: 6
---

# Alignment Splitting

SEGUL alignment splitting splits a concatenated alignment into multiple alignments based on an input partition. 

To split an alignment, you need two input files: the concatenated alignment and the partition file. If you skip inputting the partition file, the app will assume it is embedded in the alignment file.

The command is as follows:

```Bash
segul align split --input <path-to-alignment> --input-partition <path-to-partition-file>
```

For example:

```Bash
segul align split --input concat-alignment.nexus --input-partition concat-alignment-partition.nex
```

## Check Partition for Errors

The command above assumes the partition following this rule:

1. The first partition position starts with 1.
2. The next partition is the next number after the previous partition's end. If the codon model checks, the next locus applies the rule.

Use the `--skip-checking` flag to skip the partition check. This is helpful if you only want to extract a specific part of a concatenated alignment.

```Bash
segul align split --input concat-alignment.nexus --input-partition concat-alignment-partition.nex --skip-checking
```

## Supported partition format for splitting alignment

SEGUL supports two kinds of RaXML format:

With datatype written in the partitions:

```Text
DNA, locus_1 = 1-5
DNA, locus_2 = 6-10
```

Or without the datatype:

```Text
locus_1 = 1-5
locus_2 = 6-10
```

For NEXUS partition:

```Text
#Nexus
begin set
  charset locus_1 = 1-5;
  charset locus_2 = 6-10;
end;
```

The SEGUL partition parser is robust when dealing with extra spaces but forbids using spaces for locus names.

This nexus format will work:

```Text
#Nexus
begin set
  charset locus_1 = 1 - 5 ;
  charset locus_2 = 6 - 10 ;
end;
```

But this will not work (note the space inside the quotes between the locus and number):

```Text
#Nexus
begin set
  charset 'locus 1' = 1-5;
  charset 'locus 2' = 6-10;
end;
```

:::info
SEGUL also does not support merged partitions, such as:

```plaintext
#Nexus
begin set
  charset part1 = 1-5 6-10;
  charset part2 = 11-15;
end;
```
:::

Some other programs write locus names with file extensions (which contain a dot). In that case, SEGUL will replace it with an underscore to avoid a name conflict when changing the file extension.

For example:

```Text
#Nexus
begin set
  charset locus_1.nex = 1 - 5 ;
  charset locus_2.nex = 6 - 10 ;
end;
```

In the above case, SEGUL will write the output file as locus_1_nex.nex and locus_2_nex.nex (if saved to NEXUS).

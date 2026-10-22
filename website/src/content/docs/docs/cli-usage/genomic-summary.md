---
title: Genomic Summary
sidebar:
  order: 11
---

Since version 0.19.0, `segul` can calculate summary statistics for raw reads and contiguous sequences.

## Raw reads

Supported file formats:

- Gunzip Compressed FASTQ (.fq.gz/.fastq.gz), including BGZF
- Standard FASTQ (.fq/.fastq)

SEGUL detects the compression from the file content. Each file is read once and summarized on all CPU cores, and BGZF files are also decompressed in parallel.

Example

```bash
segul read summary -i raw_reads.fq.gz
```

or using directory input:

```bash
segul read summary -d /raw_read_dir
```

The output file will be saved as `default-read-summary.csv` in `Read-Summary` directory.

To specify the output directory, use the `--output` or `-o` argument:

```bash
segul read summary -d /raw_read_dir -o read_dir_output
```

You can also use the `--prefix` argument to specify the prefix name of the output files:

```bash
segul read summary -d /raw_read_dir -o read_dir_output --prefix my_read_summary
```

SEGUL provides three modes to calculate summary statistics for raw reads:

- **Minimal**: read count only
- **Default**: generate essential statistics (see below)
- **Complete**: generate all the essential statistics plus statistics per read position, distributions, duplication, overrepresented sequences, and adapter content (see below).

Use the `--mode` option to choose `minimal`, `default`, or `complete`:

```bash
segul read summary -d /raw_read_dir --mode complete
```

Essential statistics for raw reads:

- Number of reads
- Number of bases
- Mean read length
- Minimum read length
- Maximum read length
- GC count
- GC content
- AT count
- AT content
- A, C, G, T, N count
- Low-quality base count
- Mean base quality
- Min base quality
- Max base quality
- Median, standard deviation, and N50 of read length
- Bases with quality 20 or higher (Q20) and 30 or higher (Q30)
- Mean quality per read, and reads with mean quality below 20
- Quality score offset (Phred+33 or Phred+64)

Complete mode adds:

- Quality quartiles, 10th and 90th percentiles, and base composition, including N, at each read position (`read-pos-summary.zip`)
- Read length, mean read quality, and GC content distributions, with the theoretical GC distribution (`read-dist-summary.zip`)
- Duplication levels estimated from the first 200,000 reads of each file
- Overrepresented sequences, above 0.1% of the sampled reads, with the adapter they match
- Adapter content by position for Illumina Universal, Nextera, Illumina Small RNA, poly-A, and poly-G
- All of the above in `read-report.json`, which SEGUI opens as an interactive report

SEGUL detects the quality score offset from the first reads. Use `--phred 33` or `--phred 64` to set it.

Add `--plot` to also write charts to `<OUTPUT>/plots`. Complete mode adds charts of quality by position (`pos-qscore-box_<sample>`), read length (`length-dist`), mean read quality (`read-qscore-dist`), GC content (`gc-dist_<sample>`), N content (`pos-n-content`), adapter content (`adapter-content_<sample>`), and duplication (`duplication_<sample>`):

```bash
segul read summary -d /raw_read_dir --mode complete --plot
```

### All options

| Option                 | Description                                                    |
| ---------------------- | -------------------------------------------------------------- |
| `-d`, `--dir`          | Directory with FASTQ files                                     |
| `-i`, `--input`        | FASTQ files. Allows wildcards                                  |
| `-f`, `--input-format` | Input format: `auto` (default), `fastq`, or `gzip`             |
| `--mode`               | Summary mode: `default` (default), `minimal`, or `complete`    |
| `--phred`              | Quality score offset: `auto` (default), `33`, or `64`          |
| `-o`, `--output`       | Output directory. Default: `Read-Summary`                      |
| `--prefix`             | Prefix of the output files                                     |
| `--force`              | Overwrite an existing output directory                         |
| `--log`                | Log file path. Default: `segul.log`                            |

## Contiguous sequences

Supported file formats:

- Gunzip Compressed FASTA (.fa.gz/.fasta.gz)
- Standard FASTA (.fa/.fasta)

Example

```bash
segul contig summary -i contigs.fa
```

or using directory input:

```bash
segul contig summary -d /contig_read_dir
```

You can also specify the output directory names and the prefix for the output file names, similar to the read summary above.

Available statistics for contiguous sequences:

- Contig count
- Base count
- Nucleotide
- GC content
- AT content
- Minimum contig length
- Maximum contig length
- Mean contig length
- Median contig length
- N50
- N75
- N90
- Contig 750 bp
- Contig 1000 bp
- Contig 1500 bp
- Cumulative length
- A, C, G, T, N counts

### All options

| Option                 | Description                                                    |
| ---------------------- | -------------------------------------------------------------- |
| `-d`, `--dir`          | Directory with contig files                                    |
| `-i`, `--input`        | Contig files. Allows wildcards                                 |
| `-f`, `--input-format` | Input format: `auto` (default), `fasta`, or `gzip`             |
| `-o`, `--output`       | Output directory. Default: `Contig-Summary`                    |
| `--prefix`             | Prefix of the output files                                     |
| `--force`              | Overwrite an existing output directory                         |
| `--log`                | Log file path. Default: `segul.log`                            |

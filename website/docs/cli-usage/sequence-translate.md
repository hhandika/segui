---
sidebar_position: 19
---

# Sequence Translation

To translate DNA alignment to amino acid:

```Bash
segul sequence translate -d [path-to-alignment-files] -f [sequence-format-keyword]
```

The app will default to the standard code table (NCBI Table 1). Use the `--table` option to set the translation table. For example, to translate DNA sequences using NCBI Table 2 (vertebrate MtDNA):

```Bash
segul sequence translate -d loci/ -f fasta --table 2
```

You can also set the reading frame using the `--rf` option:

```Bash
segul sequence translate -d loci/ -f fasta --table 2 --rf 2
```

To show all the table options, use the `--show-tables` flag:

```Bash
segul sequence translate --show-tables
```

## Supported Translation Tables

| Table No | Genetic Code                                                                                 |
| -------- | -------------------------------------------------------------------------------------------- |
| 1        | The Standard Code                                                                            |
| 2        | The Vertebrate Mitochondrial Code                                                            |
| 3        | The Yeast Mitochondrial Code                                                                 |
| 4        | The Mold, Protozoan, and Coelenterate Mitochondrial Code and the Mycoplasma/Spiroplasma Code |
| 5        | The Invertebrate Mitochondrial Code                                                          |
| 6        | The Ciliate, Dasycladacean and Hexamita Nuclear Code                                         |
| 9        | The Echinoderm and Flatworm Mitochondrial Code                                               |
| 10       | The Euplotid Nuclear Code                                                                    |
| 11       | The Bacterial, Archaeal and Plant Plastid Code                                               |
| 12       | The Alternative Yeast Nuclear Code                                                           |
| 13       | The Ascidian Mitochondrial Code                                                              |
| 14       | The Alternative Flatworm Mitochondrial Code                                                  |
| 16       | Chlorophycean Mitochondrial Code                                                             |
| 21       | Trematode Mitochondrial Code                                                                 |
| 22       | Scenedesmus obliquus Mitochondrial Code                                                      |
| 23       | Thraustochytrium Mitochondrial Code                                                          |
| 24       | Rhabdopleuridae Mitochondrial Code                                                           |
| 25       | Candidate Division SR1 and Gracilibacteria Code                                              |
| 26       | Pachysolen tannophilus Nuclear Code                                                          |
| 29       | Mesodinium Nuclear Code                                                                      |
| 30       | Peritrich Nuclear Code                                                                       |
| 33       | Cephalodiscidae Mitochondrial UAA-Tyr Code                                                   |

Sources: [NCBI Genetic Code Tables](https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi#top)

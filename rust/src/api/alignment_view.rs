//! Load sequence files for the alignment viewer.

use std::panic::{self, AssertUnwindSafe};
use std::path::Path;

use segul::helper::sequence::SeqParser;
use segul::helper::types::{DataType, InputFmt};

const DNA_CHARS: &[u8] = b"ACGTUNRYSWKMBDHV";
// Share of residues that must be nucleotide codes to call a file DNA.
const DNA_THRESHOLD: f64 = 0.9;

/// Sequences ready to draw in the alignment viewer.
pub struct AlignmentViewData {
    pub names: Vec<String>,
    /// Upper-case ASCII residues, one row per taxon.
    pub sequences: Vec<Vec<u8>>,
    /// Longest sequence length.
    pub length: u32,
    /// Whether every sequence has the same length.
    pub is_aligned: bool,
    /// Whether the sequences are DNA rather than amino acids.
    pub is_dna: bool,
}

pub struct AlignmentViewServices {
    pub input_path: String,
}

impl AlignmentViewServices {
    pub fn new(input_path: String) -> AlignmentViewServices {
        AlignmentViewServices { input_path }
    }

    /// Parses FASTA, NEXUS, or PHYLIP, inferring the format from the extension.
    pub fn load(&self) -> anyhow::Result<AlignmentViewData> {
        let path = Path::new(&self.input_path);
        // SEGUL parsers panic on malformed input; report it as an error instead.
        let (matrix, _) = panic::catch_unwind(AssertUnwindSafe(|| {
            SeqParser::new(path, &DataType::Ignore).parse(&InputFmt::Auto)
        }))
        .map_err(|_| anyhow::anyhow!("Could not read {} as a sequence file", path.display()))?;
        let mut names = Vec::with_capacity(matrix.len());
        let mut sequences = Vec::with_capacity(matrix.len());
        for (name, seq) in matrix {
            names.push(name);
            sequences.push(seq.into_bytes().to_ascii_uppercase());
        }
        Ok(Self::build(names, sequences))
    }

    fn build(names: Vec<String>, sequences: Vec<Vec<u8>>) -> AlignmentViewData {
        let length = sequences.iter().map(Vec::len).max().unwrap_or(0);
        let is_aligned = sequences.iter().all(|s| s.len() == length);
        let is_dna = Self::is_dna(&sequences);
        AlignmentViewData {
            names,
            sequences,
            length: u32::try_from(length).unwrap_or(u32::MAX),
            is_aligned,
            is_dna,
        }
    }

    fn is_dna(sequences: &[Vec<u8>]) -> bool {
        let mut residues = 0usize;
        let mut nucleotides = 0usize;
        for &c in sequences.iter().flatten() {
            if c == b'-' || c == b'?' || c == b'.' {
                continue;
            }
            residues += 1;
            if DNA_CHARS.contains(&c) {
                nucleotides += 1;
            }
        }
        residues == 0 || nucleotides as f64 / residues as f64 >= DNA_THRESHOLD
    }
}

#[cfg(test)]
mod test {
    use super::*;

    fn fixture(name: &str) -> String {
        Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("src")
            .join("tests")
            .join("alignments")
            .join(name)
            .to_string_lossy()
            .into_owned()
    }

    #[test]
    fn test_load_fasta() {
        let data = AlignmentViewServices::new(fixture("gene_1.fas"))
            .load()
            .expect("Failed loading fixture");
        assert_eq!(data.names.len(), data.sequences.len());
        assert_eq!(data.names[0], "sample_a");
        assert_eq!(data.sequences[0], b"ATGCATGC--GTACGTAC".to_vec());
        assert_eq!(data.length, 18);
        assert!(data.is_aligned);
        assert!(data.is_dna);
    }

    #[test]
    fn test_amino_acid_detection() {
        let data = AlignmentViewServices::build(
            vec![String::from("a"), String::from("b")],
            vec![b"MKVLEQ-".to_vec(), b"MKILDQW".to_vec()],
        );
        assert!(!data.is_dna);
        assert!(data.is_aligned);
    }

    #[test]
    fn test_unaligned_length() {
        let data = AlignmentViewServices::build(
            vec![String::from("a"), String::from("b")],
            vec![b"ACGT".to_vec(), b"ACGTAC".to_vec()],
        );
        assert_eq!(data.length, 6);
        assert!(!data.is_aligned);
    }
}

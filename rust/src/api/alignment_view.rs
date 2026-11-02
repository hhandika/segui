//! Open sequence files for the alignment viewer.
//!
//! The residues stay in Rust. The viewer reads small tiles of the parts in
//! view, so large files never cross the bridge whole. Reading is done by
//! SEGUL's `AlignmentView`, shared with the `segul view align` terminal
//! viewer; this module adapts it to the bridge.

use std::path::Path;

use flutter_rust_bridge::frb;
use segul::core::align::view::AlignmentView;
use segul::helper::types::{DataType, InputFmt};

/// Names and shape of an open alignment.
pub struct AlignmentSummary {
    pub names: Vec<String>,
    /// Residues in each row.
    pub lengths: Vec<u32>,
    /// Longest sequence length.
    pub length: u32,
    /// Whether every sequence has the same length.
    pub is_aligned: bool,
    /// Whether the sequences are DNA rather than amino acids.
    pub is_dna: bool,
}

/// Gap and variable-site share of a run of sites.
pub struct AlignmentChunkStat {
    /// Zero-based first site and exclusive last site.
    pub start: u32,
    pub end: u32,
    /// Share of cells that are gaps, missing data, or past a sequence's end.
    pub gap_fraction: f64,
    /// Share of sites with more than one residue, ignoring gaps and unknowns.
    pub variable_fraction: f64,
}

/// An open sequence file. Residues are read on request.
#[frb(opaque)]
pub struct AlignmentHandle {
    view: AlignmentView,
}

impl AlignmentHandle {
    /// Opens FASTA, NEXUS, or PHYLIP, inferring the format from the extension.
    pub fn open(path: String) -> anyhow::Result<AlignmentHandle> {
        let view = AlignmentView::open(Path::new(&path), &InputFmt::Auto, &DataType::Ignore)?;
        Ok(AlignmentHandle { view })
    }

    #[frb(sync)]
    pub fn summary(&self) -> AlignmentSummary {
        let summary = self.view.summary();
        AlignmentSummary {
            names: summary.names,
            lengths: summary.lengths.into_iter().map(to_u32).collect(),
            length: to_u32(summary.length),
            is_aligned: summary.is_aligned,
            is_dna: summary.is_dna,
        }
    }

    /// Residues of `row_count` rows from `row_start`, `site_count` sites each
    /// from `site_start`, row after row. Cells past a row's end are zero.
    pub fn tile(
        &self,
        row_start: u32,
        row_count: u32,
        site_start: u32,
        site_count: u32,
    ) -> Vec<u8> {
        self.view.tile(
            row_start as usize,
            row_count as usize,
            site_start as usize,
            site_count as usize,
        )
    }

    /// Residues of `rows` at `width` evenly spaced sites, row after row, for
    /// the overview. Cells past a row's end are zero.
    pub fn sample(&self, rows: Vec<u32>, width: u32) -> Vec<u8> {
        let rows: Vec<usize> = rows.into_iter().map(|r| r as usize).collect();
        self.view.sample(&rows, width as usize)
    }

    /// Gap and variable-site shares of up to `count` chunks of `chunk_size`
    /// sites, from chunk `first`. Only the sites of those chunks are read;
    /// their counts are kept, so later calls and other chunk sizes reuse them.
    pub fn chunk_stats(&self, chunk_size: u32, first: u32, count: u32) -> Vec<AlignmentChunkStat> {
        self.view
            .chunk_stats(chunk_size as usize, first as usize, count as usize)
            .into_iter()
            .map(|stat| AlignmentChunkStat {
                start: to_u32(stat.start),
                end: to_u32(stat.end),
                gap_fraction: stat.gap_fraction,
                variable_fraction: stat.variable_fraction,
            })
            .collect()
    }

    /// One-based position of `site` in `row` without gaps, or none on a gap.
    #[frb(sync)]
    pub fn ungapped_position(&self, row: u32, site: u32) -> Option<u32> {
        self.view
            .ungapped_position(row as usize, site as usize)
            .map(to_u32)
    }

    /// Rows in FASTA format, in alignment order.
    pub fn fasta(&self, rows: Vec<u32>) -> String {
        let rows: Vec<usize> = rows.into_iter().map(|r| r as usize).collect();
        self.view.fasta(&rows)
    }
}

// Dart receives 32-bit counts; longer alignments are capped rather than wrapped.
fn to_u32(value: usize) -> u32 {
    u32::try_from(value).unwrap_or(u32::MAX)
}

#[cfg(test)]
mod test {
    use super::*;

    use std::fs;

    fn fixture(name: &str) -> String {
        Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("src")
            .join("tests")
            .join("alignments")
            .join(name)
            .to_string_lossy()
            .into_owned()
    }

    /// A file in a fresh temporary directory, removed when dropped.
    struct TempFile {
        dir: std::path::PathBuf,
        path: String,
    }

    impl TempFile {
        fn new(name: &str, content: &str) -> TempFile {
            let dir = std::env::temp_dir().join(format!(
                "segui-alignment-{}-{}",
                std::process::id(),
                name
            ));
            fs::create_dir_all(&dir).expect("Failed creating a temp dir");
            let path = dir.join(name);
            fs::write(&path, content).expect("Failed writing a temp file");
            TempFile {
                dir,
                path: path.to_string_lossy().into_owned(),
            }
        }
    }

    impl Drop for TempFile {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.dir);
        }
    }

    // Keep the file until the handle is dropped; Windows cannot remove a
    // mapped file.
    fn open(name: &str, content: &str) -> (AlignmentHandle, TempFile) {
        let file = TempFile::new(name, content);
        let handle = AlignmentHandle::open(file.path.clone()).expect("Failed opening a temp file");
        (handle, file)
    }

    #[test]
    fn test_open_fasta() {
        let handle = AlignmentHandle::open(fixture("gene_1.fas")).expect("Failed loading fixture");
        let summary = handle.summary();
        assert_eq!(summary.names[0], "sample_a");
        assert_eq!(handle.tile(0, 1, 0, 18), b"ATGCATGC--GTACGTAC".to_vec());
        assert_eq!(summary.lengths, vec![18, 18, 18]);
        assert_eq!(summary.length, 18);
        assert!(summary.is_aligned);
        assert!(summary.is_dna);
    }

    #[test]
    fn test_tile_pads_past_row_end() {
        let (handle, _file) = open("pad.fas", ">a\nACG\nTA\n>b\nAC\n");
        assert_eq!(handle.tile(0, 2, 1, 4), b"CGTAC\0\0\0".to_vec());
        assert_eq!(handle.tile(1, 5, 0, 2), b"AC".to_vec());
    }

    #[test]
    fn test_sample() {
        let (handle, _file) = open("sample.fas", ">a\nACGTACGT\n>b\nTT\n");
        assert_eq!(handle.sample(vec![1, 0], 4), b"T\0\0\0AGAG".to_vec());
    }

    #[test]
    fn test_chunk_stats() {
        let (handle, _file) = open("stats.fas", ">a\nACGT--\n>b\nATGTN-\n>c\nACGA\n");
        // The viewer asks for every chunk with a count of u32::MAX.
        let stats = handle.chunk_stats(2, 0, u32::MAX);
        assert_eq!(stats.len(), 3);
        assert_eq!((stats[0].start, stats[0].end), (0, 2));
        assert_eq!(stats[0].variable_fraction, 0.5);
        assert_eq!(stats[2].gap_fraction, 5.0 / 6.0);
        assert!(handle.chunk_stats(2, 999, 5).is_empty());
    }

    #[test]
    fn test_ungapped_position() {
        let (handle, _file) = open("ungapped.fas", ">a\nA--C?G\n");
        let positions: Vec<Option<u32>> = (0..7).map(|s| handle.ungapped_position(0, s)).collect();
        assert_eq!(
            positions,
            vec![Some(1), None, None, Some(2), None, Some(3), None]
        );
    }

    #[test]
    fn test_fasta() {
        let (handle, _file) = open("copy.fas", ">a\nac-t\n>b\nGGCC\n>c\nTTAA\n");
        assert_eq!(handle.fasta(vec![2, 0]), ">a\nAC-T\n>c\nTTAA\n");
    }

    #[test]
    fn test_open_phylip_and_nexus() {
        let (phylip, _file) = open("seq.phy", "2 4\na ACGT\nb AC-T\n");
        assert_eq!(phylip.tile(0, 2, 0, 4), b"ACGTAC-T".to_vec());
        let (nexus, _file) = open(
            "seq.nex",
            "#NEXUS\nbegin data;\ndimensions ntax=2 nchar=4;\n\
             format datatype=dna missing=? gap=- interleave;\nmatrix\n\
             a AC\nb AC\n\na GT\nb -T\n;\nend;\n",
        );
        assert_eq!(nexus.tile(0, 2, 0, 4), b"ACGTAC-T".to_vec());
    }

    #[test]
    fn test_amino_acid_detection() {
        let (handle, _file) = open("aa.fas", ">a\nMKVLEQ-\n>b\nMKILDQW\n");
        assert!(!handle.summary().is_dna);
        assert!(handle.summary().is_aligned);
    }

    #[test]
    fn test_unaligned_length() {
        let (handle, _file) = open("unaligned.fas", ">a\nACGT\n>b\nACGTAC\n");
        assert_eq!(handle.summary().length, 6);
        assert!(!handle.summary().is_aligned);
    }

    #[test]
    fn test_unknown_extension() {
        assert!(AlignmentHandle::open(String::from("seq.txt")).is_err());
    }
}

//! Open sequence files for the alignment viewer.
//!
//! The residues stay in Rust. The viewer reads small tiles of the parts in
//! view, so large files never cross the bridge whole. Reading is done by
//! SEGUL's `AlignmentView`, shared with the `segul view align` terminal
//! viewer; this module adapts it to the bridge.

use std::path::Path;

use flutter_rust_bridge::frb;
use segul_core::core::align::view::{AlignmentView, PartitionTrack, WindowStat};
use segul_core::helper::types::{DataType, InputFmt};

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
pub struct AlignmentWindowStat {
    /// Zero-based first site and exclusive last site.
    pub start: u32,
    pub end: u32,
    /// Share of cells that are gaps, missing data, or past a sequence's end.
    pub gap_fraction: f64,
    /// Share of sites with more than one residue, ignoring gaps and unknowns.
    pub variable_fraction: f64,
}

/// A band of sites in a concatenated alignment: one partition, or codon
/// position subsets of a gene that interleave.
pub struct AlignmentPartition {
    pub name: String,
    /// Zero-based first site and exclusive last site.
    pub start: u32,
    pub end: u32,
    /// Names of the subsets sharing the band; empty for a single partition.
    pub subsets: Vec<String>,
    /// Substitution model, when the partition file gives one.
    pub model: Option<String>,
}

/// Partitions found for an alignment.
pub struct AlignmentPartitions {
    /// File the partitions were read from.
    pub source: String,
    /// Whether they came from the alignment file itself.
    pub is_embedded: bool,
    /// Bands in site order.
    pub partitions: Vec<AlignmentPartition>,
}

/// An open sequence file. Residues are read on request.
#[frb(opaque)]
pub struct AlignmentHandle {
    view: AlignmentView,
    track: Option<PartitionTrack>,
    partition_error: Option<String>,
}

impl AlignmentHandle {
    /// Opens FASTA, NEXUS, or PHYLIP, inferring the format from the extension.
    pub fn open(path: String) -> anyhow::Result<AlignmentHandle> {
        let path = Path::new(&path);
        let view = AlignmentView::open(path, &InputFmt::Auto, &DataType::Ignore)?;
        // A bad partition file should not keep the alignment from opening.
        let (track, partition_error) = match PartitionTrack::detect(path, view.length()) {
            Ok(track) => (track, None),
            Err(e) => (None, Some(format!("Failed reading partitions: {e}"))),
        };
        Ok(AlignmentHandle {
            view,
            track,
            partition_error,
        })
    }

    /// Partitions from a NEXUS sets block in the file or a `<name>_partition`
    /// file next to it, or none.
    #[frb(sync)]
    pub fn partitions(&self) -> Option<AlignmentPartitions> {
        let track = self.track.as_ref()?;
        let partitions = track
            .blocks
            .iter()
            .map(|block| {
                let parts: Vec<_> = block
                    .partitions
                    .iter()
                    .map(|&i| &track.partitions[i])
                    .collect();
                let (subsets, model) = match parts.as_slice() {
                    [only] => (Vec::new(), only.model.clone()),
                    _ => (parts.iter().map(|p| p.gene.clone()).collect(), None),
                };
                AlignmentPartition {
                    name: block.name.clone(),
                    start: to_u32(block.start),
                    end: to_u32(block.end),
                    subsets,
                    model,
                }
            })
            .collect();
        Some(AlignmentPartitions {
            source: track.source.to_string_lossy().into_owned(),
            is_embedded: track.is_embedded,
            partitions,
        })
    }

    /// Why the partition file could not be read, when it exists but fails.
    #[frb(sync)]
    pub fn partition_error(&self) -> Option<String> {
        self.partition_error.clone()
    }

    /// Name of the partition holding `site`, naming the exact codon subset.
    #[frb(sync)]
    pub fn partition_at(&self, site: u32) -> Option<String> {
        let track = self.track.as_ref()?;
        let index = track.partition_at(site as usize)?;
        Some(track.partitions[index].gene.clone())
    }

    /// Gap and variable-site shares of sites `start..end`, such as one
    /// partition.
    pub fn range_stats(&self, start: u32, end: u32) -> AlignmentWindowStat {
        to_stat(self.view.range_stats(start as usize, end as usize))
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

    /// Gap and variable-site shares of up to `count` windows of `window_size`
    /// sites, from window `first`. Only the sites of those windows are read;
    /// their counts are kept, so later calls and other window sizes reuse them.
    pub fn window_stats(
        &self,
        window_size: u32,
        first: u32,
        count: u32,
    ) -> Vec<AlignmentWindowStat> {
        self.view
            .window_stats(window_size as usize, first as usize, count as usize)
            .into_iter()
            .map(to_stat)
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

fn to_stat(stat: WindowStat) -> AlignmentWindowStat {
    AlignmentWindowStat {
        start: to_u32(stat.start),
        end: to_u32(stat.end),
        gap_fraction: stat.gap_fraction,
        variable_fraction: stat.variable_fraction,
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
    fn test_window_stats() {
        let (handle, _file) = open("stats.fas", ">a\nACGT--\n>b\nATGTN-\n>c\nACGA\n");
        // The viewer asks for every window with a count of u32::MAX.
        let stats = handle.window_stats(2, 0, u32::MAX);
        assert_eq!(stats.len(), 3);
        assert_eq!((stats[0].start, stats[0].end), (0, 2));
        assert_eq!(stats[0].variable_fraction, 0.5);
        assert_eq!(stats[2].gap_fraction, 5.0 / 6.0);
        assert!(handle.window_stats(2, 999, 5).is_empty());
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
    fn test_partitions_embedded() {
        let (handle, _file) = open(
            "concat.nex",
            "#NEXUS\nbegin data;\ndimensions ntax=2 nchar=6;\n\
             format datatype=dna missing=? gap=-;\nmatrix\n\
             a ACGTAC\nb ACGTTC\n;\nend;\n\
             begin sets;\ncharset g1 = 1-3;\ncharset g2 = 4-6;\nend;\n",
        );
        let found = handle.partitions().expect("No partitions");
        assert!(found.is_embedded);
        let bands: Vec<(&str, u32, u32)> = found
            .partitions
            .iter()
            .map(|p| (p.name.as_str(), p.start, p.end))
            .collect();
        assert_eq!(bands, vec![("g1", 0, 3), ("g2", 3, 6)]);
        assert_eq!(handle.partition_at(4).as_deref(), Some("g2"));
        assert_eq!(handle.range_stats(3, 6).variable_fraction, 1.0 / 3.0);
    }

    #[test]
    fn test_partitions_codon_sidecar() {
        let file = TempFile::new("cat.fas", ">a\nACGTAC\n>b\nACGTTC\n");
        let sidecar = Path::new(&file.path).with_file_name("cat_partition.txt");
        fs::write(
            &sidecar,
            "DNA, g_Subset1 = 1-6\\3\nDNA, g_Subset2 = 2-6\\3\nDNA, g_Subset3 = 3-6\\3\n",
        )
        .expect("Failed writing partitions");
        let handle = AlignmentHandle::open(file.path.clone()).expect("Failed opening");
        let found = handle.partitions().expect("No partitions");
        assert!(!found.is_embedded);
        assert_eq!(found.partitions.len(), 1);
        assert_eq!(found.partitions[0].name, "g");
        assert_eq!(found.partitions[0].subsets.len(), 3);
        assert_eq!(handle.partition_at(4).as_deref(), Some("g_Subset2"));
    }

    #[test]
    fn test_no_partitions() {
        let handle = AlignmentHandle::open(fixture("gene_1.fas")).expect("Failed loading fixture");
        assert!(handle.partitions().is_none());
        assert!(handle.partition_error().is_none());
    }

    #[test]
    fn test_unknown_extension() {
        assert!(AlignmentHandle::open(String::from("seq.txt")).is_err());
    }
}

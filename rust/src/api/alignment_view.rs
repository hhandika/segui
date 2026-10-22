//! Open sequence files for the alignment viewer.
//!
//! The residues stay in Rust. The viewer reads small tiles of the parts in
//! view, so large files never cross the bridge whole. FASTA files are
//! memory-mapped and indexed by byte offset; other formats are parsed by
//! SEGUL and kept in memory.

use std::collections::HashMap;
use std::ffi::OsStr;
use std::fs::File;
use std::ops::Range;
use std::panic::{self, AssertUnwindSafe};
use std::path::Path;
use std::sync::{Arc, Mutex, RwLock};

use flutter_rust_bridge::frb;
use memchr::memchr;
use memmap2::Mmap;
use rayon::prelude::*;
use segul::helper::sequence::SeqParser;
use segul::helper::types::{DataType, InputFmt};

const DNA_CHARS: &[u8] = b"ACGTUNRYSWKMBDHV";
// Share of residues that must be nucleotide codes to call a file DNA.
const DNA_THRESHOLD: f64 = 0.9;
// Residues read from the start of each row to guess the data type.
const DNA_SAMPLE_PER_ROW: usize = 4096;
const DNA_SAMPLE_TOTAL: usize = 1 << 20;
// Sites between stored ungapped counts. Lookups scan at most this many.
const UNGAPPED_STEP: usize = 4096;
// Sites counted together for chunk statistics. Blocks are counted in
// parallel, only when a chunk over them is asked for, and then kept.
const STAT_BLOCK: usize = 4096;
const GAP: u8 = b'-';
const MISSING: u8 = b'?';
const DNA_UNKNOWN: u8 = b'N';
const AA_UNKNOWN: u8 = b'X';

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
    names: Vec<String>,
    lengths: Vec<u32>,
    length: u32,
    is_aligned: bool,
    is_dna: bool,
    store: Store,
    // Per-site counts of each STAT_BLOCK sites counted so far.
    site_blocks: RwLock<HashMap<usize, Arc<SiteBlock>>>,
    // Residues before every UNGAPPED_STEP sites, per row, built on first use.
    ungapped: Mutex<HashMap<usize, Vec<u32>>>,
}

impl AlignmentHandle {
    /// Opens FASTA, NEXUS, or PHYLIP, inferring the format from the extension.
    pub fn open(path: String) -> anyhow::Result<AlignmentHandle> {
        let path = Path::new(&path);
        let format = Self::format_of(path)?;
        let indexed = match format {
            InputFmt::Fasta => FastaIndex::build(path)?,
            _ => None,
        };
        let (names, store) = match indexed {
            Some(index) => (index.names, Store::Mapped(index.map, index.records)),
            None => Self::parse(path, &format)?,
        };
        Ok(Self::new(names, store))
    }

    #[frb(sync)]
    pub fn summary(&self) -> AlignmentSummary {
        AlignmentSummary {
            names: self.names.clone(),
            lengths: self.lengths.clone(),
            length: self.length,
            is_aligned: self.is_aligned,
            is_dna: self.is_dna,
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
        let rows = row_start as usize..(row_start as usize + row_count as usize).min(self.rows());
        let width = site_count as usize;
        let mut out = vec![0u8; rows.len() * width];
        for (row, cells) in rows.zip(out.chunks_exact_mut(width.max(1))) {
            self.store.read(row, site_start as usize, cells);
        }
        out
    }

    /// Residues of `rows` at `width` evenly spaced sites, row after row, for
    /// the overview. Cells past a row's end are zero.
    pub fn sample(&self, rows: Vec<u32>, width: u32) -> Vec<u8> {
        let width = width as usize;
        let length = self.length as usize;
        let mut out = vec![0u8; rows.len() * width];
        for (&row, cells) in rows.iter().zip(out.chunks_exact_mut(width.max(1))) {
            let row = row as usize;
            if row >= self.rows() {
                continue;
            }
            for (x, cell) in cells.iter_mut().enumerate() {
                let site = x * length / width;
                if site < self.lengths[row] as usize {
                    *cell = self.store.residue(row, site);
                }
            }
        }
        out
    }

    /// Gap and variable-site shares of up to `count` chunks of `chunk_size`
    /// sites, from chunk `first`. Only the sites of those chunks are read;
    /// their counts are kept, so later calls and other chunk sizes reuse them.
    pub fn chunk_stats(&self, chunk_size: u32, first: u32, count: u32) -> Vec<AlignmentChunkStat> {
        let size = chunk_size.max(1) as usize;
        let length = self.length as usize;
        let start = (first as usize * size).min(length);
        let end = ((first as usize + count as usize) * size).min(length);
        if start >= end {
            return Vec::new();
        }
        let blocks = self.site_blocks(start..end);
        let first_block = start / STAT_BLOCK;
        let rows = self.rows();
        (start..end)
            .step_by(size)
            .map(|chunk_start| {
                let chunk_end = (chunk_start + size).min(end);
                let mut gaps = 0u64;
                let mut variable = 0usize;
                let mut site = chunk_start;
                while site < chunk_end {
                    let block = &blocks[site / STAT_BLOCK - first_block];
                    let block_start = site / STAT_BLOCK * STAT_BLOCK;
                    let to = chunk_end.min(block_start + STAT_BLOCK);
                    let range = site - block_start..to - block_start;
                    gaps += block.gaps[range.clone()]
                        .iter()
                        .map(|&g| g as u64)
                        .sum::<u64>();
                    variable += block.variable[range].iter().filter(|&&v| v).count();
                    site = to;
                }
                let sites = chunk_end - chunk_start;
                let cells = sites * rows;
                AlignmentChunkStat {
                    start: chunk_start as u32,
                    end: chunk_end as u32,
                    gap_fraction: if cells == 0 {
                        0.0
                    } else {
                        gaps as f64 / cells as f64
                    },
                    variable_fraction: variable as f64 / sites as f64,
                }
            })
            .collect()
    }

    /// One-based position of `site` in `row` without gaps, or none on a gap.
    #[frb(sync)]
    pub fn ungapped_position(&self, row: u32, site: u32) -> Option<u32> {
        let (row, site) = (row as usize, site as usize);
        if row >= self.rows() || site >= self.lengths[row] as usize {
            return None;
        }
        if Self::is_gap(self.store.residue(row, site)) {
            return None;
        }
        let step = site / UNGAPPED_STEP;
        let before = {
            let mut cache = self.ungapped.lock().ok()?;
            let counts = cache
                .entry(row)
                .or_insert_with(|| self.ungapped_counts(row));
            counts[step]
        };
        let start = step * UNGAPPED_STEP;
        let mut cells = vec![0u8; site + 1 - start];
        self.store.read(row, start, &mut cells);
        let residues = cells.iter().filter(|&&c| !Self::is_gap(c)).count() as u32;
        Some(before + residues)
    }

    /// Rows in FASTA format, in alignment order.
    pub fn fasta(&self, rows: Vec<u32>) -> String {
        let mut rows: Vec<usize> = rows
            .into_iter()
            .map(|r| r as usize)
            .filter(|&r| r < self.rows())
            .collect();
        rows.sort_unstable();
        rows.dedup();
        let mut out = String::new();
        for row in rows {
            let mut cells = vec![0u8; self.lengths[row] as usize];
            self.store.read(row, 0, &mut cells);
            out.push('>');
            out.push_str(&self.names[row]);
            out.push('\n');
            out.push_str(&String::from_utf8_lossy(&cells));
            out.push('\n');
        }
        out
    }

    fn new(names: Vec<String>, store: Store) -> AlignmentHandle {
        let lengths: Vec<u32> = (0..names.len())
            .map(|row| u32::try_from(store.len(row)).unwrap_or(u32::MAX))
            .collect();
        let length = lengths.iter().copied().max().unwrap_or(0);
        let is_aligned = lengths.iter().all(|&l| l == length);
        let is_dna = Self::is_dna(&store, &lengths);
        AlignmentHandle {
            names,
            lengths,
            length,
            is_aligned,
            is_dna,
            store,
            site_blocks: RwLock::new(HashMap::new()),
            ungapped: Mutex::new(HashMap::new()),
        }
    }

    fn rows(&self) -> usize {
        self.names.len()
    }

    fn format_of(path: &Path) -> anyhow::Result<InputFmt> {
        let ext = path
            .extension()
            .and_then(OsStr::to_str)
            .map(str::to_ascii_lowercase)
            .unwrap_or_default();
        match ext.as_str() {
            "fa" | "fasta" | "fna" | "fsa" | "fas" => Ok(InputFmt::Fasta),
            "nex" | "nxs" | "nexus" => Ok(InputFmt::Nexus),
            "phy" | "phylip" | "ph" => Ok(InputFmt::Phylip),
            _ => anyhow::bail!("{} is not a FASTA, NEXUS, or PHYLIP file", path.display()),
        }
    }

    fn parse(path: &Path, format: &InputFmt) -> anyhow::Result<(Vec<String>, Store)> {
        // SEGUL parsers panic on malformed input; report it as an error instead.
        let (matrix, _) = panic::catch_unwind(AssertUnwindSafe(|| {
            SeqParser::new(path, &DataType::Ignore).parse(format)
        }))
        .map_err(|_| anyhow::anyhow!("Could not read {} as a sequence file", path.display()))?;
        let mut names = Vec::with_capacity(matrix.len());
        let mut rows = Vec::with_capacity(matrix.len());
        for (name, seq) in matrix {
            let mut seq = seq.into_bytes();
            seq.make_ascii_uppercase();
            names.push(name);
            rows.push(seq);
        }
        Ok((names, Store::Memory(rows)))
    }

    // Guesses the data type from the start of each row.
    fn is_dna(store: &Store, lengths: &[u32]) -> bool {
        let per_row = (DNA_SAMPLE_TOTAL / lengths.len().max(1)).clamp(1, DNA_SAMPLE_PER_ROW);
        let mut residues = 0usize;
        let mut nucleotides = 0usize;
        let mut cells = Vec::new();
        for (row, &len) in lengths.iter().enumerate() {
            cells.resize((len as usize).min(per_row), 0);
            store.read(row, 0, &mut cells);
            for &c in &cells {
                if c == GAP || c == MISSING || c == b'.' {
                    continue;
                }
                residues += 1;
                if DNA_CHARS.contains(&c) {
                    nucleotides += 1;
                }
            }
        }
        residues == 0 || nucleotides as f64 / residues as f64 >= DNA_THRESHOLD
    }

    fn is_gap(code: u8) -> bool {
        code == GAP || code == MISSING
    }

    // Counts of every block over `sites`, in order, counting missing ones in
    // parallel.
    fn site_blocks(&self, sites: Range<usize>) -> Vec<Arc<SiteBlock>> {
        let ids = sites.start / STAT_BLOCK..sites.end.div_ceil(STAT_BLOCK);
        let missing: Vec<usize> = match self.site_blocks.read() {
            Ok(cache) => ids.clone().filter(|id| !cache.contains_key(id)).collect(),
            Err(_) => ids.clone().collect(),
        };
        let counted: Vec<(usize, Arc<SiteBlock>)> = missing
            .into_par_iter()
            .map(|id| (id, Arc::new(self.count_block(id))))
            .collect();
        let mut cache = match self.site_blocks.write() {
            Ok(cache) => cache,
            Err(poisoned) => poisoned.into_inner(),
        };
        cache.extend(counted);
        ids.map(|id| Arc::clone(&cache[&id])).collect()
    }

    fn count_block(&self, id: usize) -> SiteBlock {
        let start = id * STAT_BLOCK;
        let width = (self.length as usize).saturating_sub(start).min(STAT_BLOCK);
        let unknown = if self.is_dna { DNA_UNKNOWN } else { AA_UNKNOWN };
        let mut gaps = vec![0u32; width];
        let mut first = vec![0u8; width];
        let mut variable = vec![false; width];
        let mut cells = vec![0u8; width];
        for (row, &len) in self.lengths.iter().enumerate() {
            let n = (len as usize).saturating_sub(start).min(width);
            // Sites past the row's end count as gaps.
            gaps[n..].iter_mut().for_each(|g| *g += 1);
            let cells = &mut cells[..n];
            self.store.read(row, start, cells);
            for (i, &code) in cells.iter().enumerate() {
                if Self::is_gap(code) {
                    gaps[i] += 1;
                } else if code != unknown {
                    if first[i] == 0 {
                        first[i] = code;
                    } else if first[i] != code {
                        variable[i] = true;
                    }
                }
            }
        }
        SiteBlock { gaps, variable }
    }

    fn ungapped_counts(&self, row: usize) -> Vec<u32> {
        let len = self.lengths[row] as usize;
        let mut counts = Vec::with_capacity(len / UNGAPPED_STEP + 1);
        let mut cells = vec![0u8; UNGAPPED_STEP];
        let mut total = 0u32;
        let mut start = 0;
        loop {
            counts.push(total);
            if start >= len {
                break;
            }
            let end = (start + UNGAPPED_STEP).min(len);
            let cells = &mut cells[..end - start];
            self.store.read(row, start, cells);
            total += cells.iter().filter(|&&c| !Self::is_gap(c)).count() as u32;
            start = end;
        }
        counts
    }
}

/// Per-site counts of a block of sites, behind the chunk statistics.
struct SiteBlock {
    /// Rows with a gap, missing data, or no residue at each site.
    gaps: Vec<u32>,
    /// Whether a site holds more than one residue.
    variable: Vec<bool>,
}

/// Where residues are read from.
enum Store {
    /// A memory-mapped FASTA file and where each sequence sits in it.
    Mapped(Mmap, Vec<FastaRecord>),
    /// Upper-case residues parsed by SEGUL, one row per taxon.
    Memory(Vec<Vec<u8>>),
}

impl Store {
    fn len(&self, row: usize) -> usize {
        match self {
            Store::Mapped(_, records) => records[row].len,
            Store::Memory(rows) => rows[row].len(),
        }
    }

    fn residue(&self, row: usize, site: usize) -> u8 {
        match self {
            Store::Mapped(map, records) => map[records[row].offset_of(site)].to_ascii_uppercase(),
            Store::Memory(rows) => rows[row][site],
        }
    }

    /// Copies upper-case residues of `row` from `site` into `out`, stopping
    /// at the row's end.
    fn read(&self, row: usize, site: usize, out: &mut [u8]) {
        match self {
            Store::Mapped(map, records) => records[row].read(map, site, out),
            Store::Memory(rows) => {
                let seq = &rows[row];
                if site < seq.len() {
                    let n = out.len().min(seq.len() - site);
                    out[..n].copy_from_slice(&seq[site..site + n]);
                }
            }
        }
    }
}

/// A sequence in a FASTA file, laid out like a `samtools faidx` record.
#[derive(Debug, PartialEq)]
struct FastaRecord {
    /// Byte offset of the first residue.
    offset: usize,
    /// Residues in the sequence.
    len: usize,
    /// Residues on every full line.
    line_bases: usize,
    /// Bytes on every full line, including the line ending.
    line_bytes: usize,
}

impl FastaRecord {
    fn offset_of(&self, site: usize) -> usize {
        self.offset + site / self.line_bases * self.line_bytes + site % self.line_bases
    }

    fn read(&self, map: &[u8], site: usize, out: &mut [u8]) {
        let end = (site + out.len()).min(self.len);
        let mut site = site;
        let mut written = 0;
        while site < end {
            let in_line = site % self.line_bases;
            let take = (self.line_bases - in_line).min(end - site);
            let from = self.offset_of(site);
            let cells = &mut out[written..written + take];
            cells.copy_from_slice(&map[from..from + take]);
            cells.make_ascii_uppercase();
            site += take;
            written += take;
        }
    }
}

/// Byte offsets of every sequence in a FASTA file.
struct FastaIndex {
    map: Mmap,
    names: Vec<String>,
    records: Vec<FastaRecord>,
}

impl FastaIndex {
    /// Indexes a FASTA file, or none when its lines are too irregular to
    /// index, such as wrapped lines of different widths.
    fn build(path: &Path) -> anyhow::Result<Option<FastaIndex>> {
        let file = File::open(path)?;
        if file.metadata()?.len() == 0 {
            anyhow::bail!("{} is empty", path.display());
        }
        // SAFETY: the map is only read. Changing the file while it is open
        // shows changed residues; the viewer reopens files to refresh them.
        let map = unsafe { Mmap::map(&file)? };
        Ok(Self::scan(&map).map(|(names, records)| FastaIndex {
            map,
            names,
            records,
        }))
    }

    fn scan(bytes: &[u8]) -> Option<(Vec<String>, Vec<FastaRecord>)> {
        let mut names = Vec::new();
        let mut records = Vec::new();
        let mut lines = Lines { bytes, pos: 0 };
        let mut next = lines.next();
        // Blank lines before the first header.
        while next
            .as_ref()
            .is_some_and(|l| l.content.trim_ascii().is_empty())
        {
            next = lines.next();
        }
        while let Some(header) = next {
            let id = header.content.strip_prefix(b">")?;
            names.push(String::from_utf8_lossy(id.trim_ascii()).into_owned());
            let (record, after) = Self::record(&mut lines)?;
            records.push(record);
            next = after;
        }
        if records.is_empty() {
            return None;
        }
        Some((names, records))
    }

    // Reads the sequence lines after a header, returning the record and the
    // next header.
    fn record<'a>(lines: &mut Lines<'a>) -> Option<(FastaRecord, Option<Line<'a>>)> {
        let mut record = FastaRecord {
            offset: lines.pos,
            len: 0,
            line_bases: 0,
            line_bytes: 0,
        };
        // A line shorter than the first ends the sequence.
        let mut is_closed = false;
        for line in lines.by_ref() {
            let bases = line.content.len();
            if line.content.first() == Some(&b'>') {
                if record.line_bases == 0 {
                    record.line_bases = 1;
                }
                return Some((record, Some(line)));
            }
            if bases == 0 {
                is_closed = true;
                continue;
            }
            let is_padded = line.content[0].is_ascii_whitespace()
                || line.content[bases - 1].is_ascii_whitespace();
            if is_closed || is_padded {
                return None;
            }
            if record.line_bases == 0 {
                record.offset = line.start;
                record.line_bases = bases;
                record.line_bytes = line.bytes;
            } else {
                // The last line of a file may have no line ending.
                let ending = line.bytes - bases;
                let is_other_ending =
                    ending != 0 && ending != record.line_bytes - record.line_bases;
                if bases > record.line_bases || is_other_ending {
                    return None;
                }
            }
            if bases < record.line_bases {
                is_closed = true;
            }
            record.len += bases;
        }
        if record.line_bases == 0 {
            record.line_bases = 1;
        }
        Some((record, None))
    }
}

/// A line of a file, without its line ending.
struct Line<'a> {
    start: usize,
    content: &'a [u8],
    /// Bytes including the line ending.
    bytes: usize,
}

struct Lines<'a> {
    bytes: &'a [u8],
    pos: usize,
}

impl<'a> Iterator for Lines<'a> {
    type Item = Line<'a>;

    fn next(&mut self) -> Option<Line<'a>> {
        if self.pos >= self.bytes.len() {
            return None;
        }
        let start = self.pos;
        let rest = &self.bytes[start..];
        let (mut content, bytes) = match memchr(b'\n', rest) {
            Some(i) => (&rest[..i], i + 1),
            None => (rest, rest.len()),
        };
        if let Some(stripped) = content.strip_suffix(b"\r") {
            content = stripped;
        }
        self.pos += bytes;
        Some(Line {
            start,
            content,
            bytes,
        })
    }
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

    fn rows(handle: &AlignmentHandle) -> Vec<Vec<u8>> {
        let width = handle.length;
        let tile = handle.tile(0, handle.rows() as u32, 0, width);
        tile.chunks(width.max(1) as usize)
            .zip(&handle.lengths)
            .map(|(row, &len)| row[..len as usize].to_vec())
            .collect()
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
        assert!(matches!(handle.store, Store::Mapped(..)));
        assert_eq!(summary.names[0], "sample_a");
        assert_eq!(rows(&handle)[0], b"ATGCATGC--GTACGTAC".to_vec());
        assert_eq!(summary.length, 18);
        assert!(summary.is_aligned);
        assert!(summary.is_dna);
    }

    #[test]
    fn test_index_matches_segul() {
        let cases = [
            ("single.fas", ">a\nacgt-a\n>b desc\nACGTTA\n"),
            ("wrapped.fas", ">a\nACG\nTAC\nG\n>b\nACG\nTAC\nGT\n\n"),
            ("crlf.fas", ">a\r\nACG\r\nTA\r\n>b\r\nAC-\r\nTA\r\n"),
            ("ragged.fas", ">a\nACGTACGT\n>b\nAC\n>c\n\n"),
            ("no_newline.fas", ">a\nACG\nTA\n>b\nACG\nTA"),
        ];
        for (name, content) in cases {
            let file = TempFile::new(name, content);
            let mapped = AlignmentHandle::open(file.path.clone()).expect("Failed indexing");
            assert!(
                matches!(mapped.store, Store::Mapped(..)),
                "{name} was not indexed"
            );
            let (names, store) = AlignmentHandle::parse(Path::new(&file.path), &InputFmt::Fasta)
                .expect("Failed parsing");
            let parsed = AlignmentHandle::new(names, store);
            assert_eq!(mapped.names, parsed.names, "{name}");
            assert_eq!(rows(&mapped), rows(&parsed), "{name}");
        }
    }

    #[test]
    fn test_irregular_fasta_falls_back() {
        let (handle, _file) = open("irregular.fas", ">a\nAC\nACGT\n>b\nACGTAC\n");
        assert!(matches!(handle.store, Store::Memory(..)));
        assert_eq!(rows(&handle)[0], b"ACACGT".to_vec());
    }

    #[test]
    fn test_upper_case_extension() {
        let (handle, _file) = open("upper.FAS", ">a\nACGT\n");
        assert_eq!(handle.summary().length, 4);
    }

    #[test]
    fn test_open_phylip_and_nexus() {
        let (phylip, _file) = open("seq.phy", "2 4\na ACGT\nb AC-T\n");
        assert_eq!(rows(&phylip), vec![b"ACGT".to_vec(), b"AC-T".to_vec()]);
        let (nexus, _file) = open(
            "seq.nex",
            "#NEXUS\nbegin data;\ndimensions ntax=2 nchar=4;\n\
             format datatype=dna missing=? gap=- interleave;\nmatrix\n\
             a AC\nb AC\n\na GT\nb -T\n;\nend;\n",
        );
        assert_eq!(rows(&nexus), vec![b"ACGT".to_vec(), b"AC-T".to_vec()]);
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
        let stats = handle.chunk_stats(2, 0, u32::MAX);
        assert_eq!(stats.len(), 3);
        assert_eq!((stats[0].start, stats[0].end), (0, 2));
        assert_eq!(stats[0].variable_fraction, 0.5);
        assert_eq!(stats[0].gap_fraction, 0.0);
        assert_eq!(stats[1].variable_fraction, 0.5);
        assert_eq!(stats[2].gap_fraction, 5.0 / 6.0);
        assert_eq!(stats[2].variable_fraction, 0.0);
    }

    #[test]
    fn test_chunk_stats_ignore_unknowns() {
        let (handle, _file) = open("unknown.fas", ">a\nACGT\n>b\nACGA\n>c\nA-N-\n");
        let stats = handle.chunk_stats(2, 0, u32::MAX);
        assert_eq!(stats.len(), 2);
        // Sites 1-2: one gap in six cells, no variable site.
        assert!((stats[0].gap_fraction - 1.0 / 6.0).abs() < 1e-9);
        assert_eq!(stats[0].variable_fraction, 0.0);
        // Sites 3-4: N is ignored, so only site 4 (T, A) varies.
        assert!((stats[1].gap_fraction - 1.0 / 6.0).abs() < 1e-9);
        assert_eq!(stats[1].variable_fraction, 0.5);
    }

    #[test]
    fn test_chunk_stats_count_short_rows_as_gaps() {
        let (handle, _file) = open("short.fas", ">a\nACGT\n>b\nAC\n");
        let stats = handle.chunk_stats(4, 0, u32::MAX);
        assert_eq!(stats.len(), 1);
        assert_eq!(stats[0].gap_fraction, 0.25);
        // Changing the chunk size reuses the per-site counts.
        assert_eq!(handle.chunk_stats(1, 0, u32::MAX).len(), 4);
    }

    #[test]
    fn test_chunk_stats_window_across_blocks() {
        // Row b is variable at every 3rd site and stops before the end.
        let a = "A".repeat(3 * STAT_BLOCK);
        let b: String = (0..3 * STAT_BLOCK - 7)
            .map(|i| if i % 3 == 0 { 'C' } else { 'A' })
            .collect();
        let (handle, _file) = open("blocks.fas", &format!(">a\n{a}\n>b\n{b}\n"));
        let size = 1000u32;
        let all = handle.chunk_stats(size, 0, u32::MAX);
        assert_eq!(all.len() as u32, (3 * STAT_BLOCK as u32).div_ceil(size));
        // A window of chunks matches the same chunks of the whole.
        let window = handle.chunk_stats(size, 3, 6);
        assert_eq!(window.len(), 6);
        for (w, a) in window.iter().zip(&all[3..9]) {
            assert_eq!((w.start, w.end), (a.start, a.end));
            assert_eq!(w.variable_fraction, a.variable_fraction);
            assert_eq!(w.gap_fraction, a.gap_fraction);
        }
        // Chunk 4 (sites 4000-4999) crosses the first block boundary.
        assert_eq!(all[4].variable_fraction, 0.333);
        let last = all.last().unwrap();
        assert_eq!(last.end as usize, 3 * STAT_BLOCK);
        let sites = (last.end - last.start) as f64;
        assert_eq!(last.gap_fraction, 7.0 / (2.0 * sites));
        assert!(handle.chunk_stats(size, 999, 5).is_empty());
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
    fn test_ungapped_position_across_steps() {
        let seq = "A-".repeat(UNGAPPED_STEP + 10);
        let (handle, _file) = open("long.fas", &format!(">a\n{seq}\n"));
        let site = 2 * (UNGAPPED_STEP + 5) as u32;
        assert_eq!(
            handle.ungapped_position(0, site),
            Some(UNGAPPED_STEP as u32 + 6)
        );
    }

    #[test]
    fn test_fasta() {
        let (handle, _file) = open("copy.fas", ">a\nac-t\n>b\nGGCC\n>c\nTTAA\n");
        assert_eq!(handle.fasta(vec![2, 0]), ">a\nAC-T\n>c\nTTAA\n");
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

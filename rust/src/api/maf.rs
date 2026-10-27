use std::path::{Path, PathBuf};
use std::time::Instant;

use segul::core::maf::convert::{MafConverter, MafGrouping};
use segul::core::maf::summary::MafSummary;
use segul::core::maf::BlockFilter;
use segul::helper::types::OutputFmt;
use segul::helper::utils;

pub struct MafConversionServices {
    pub input_files: Vec<String>,
    // BED file of loci. Without it, blocks are grouped by `group_by`.
    pub bed_file: Option<String>,
    pub output_dir: String,
    // fasta, nexus, phylip, or their -int variants
    pub output_fmt: String,
    // block or chrom. Ignored with a BED file.
    pub group_by: String,
    // Clip blocks to BED loci. Only used with a BED file.
    pub clip: bool,
    // Reverse complement minus-strand BED loci.
    pub strand_aware: bool,
    // Defaults to the first species in the first block.
    pub ref_species: Option<String>,
    pub min_block_len: Option<usize>,
    pub min_species: Option<usize>,
    pub min_score: Option<f64>,
    // Write only these species. Empty writes every species.
    pub species: Vec<String>,
}

impl MafConversionServices {
    pub fn new() -> MafConversionServices {
        MafConversionServices {
            input_files: Vec::new(),
            bed_file: None,
            output_dir: String::new(),
            output_fmt: String::from("fasta"),
            group_by: String::from("block"),
            clip: true,
            strand_aware: false,
            ref_species: None,
            min_block_len: None,
            min_species: None,
            min_score: None,
            species: Vec::new(),
        }
    }

    pub fn convert(&self) -> anyhow::Result<()> {
        let time = Instant::now();
        let input_files: Vec<PathBuf> = self.input_files.iter().map(PathBuf::from).collect();
        let output_path = Path::new(&self.output_dir);
        let output_fmt = self.match_output_fmt()?;
        let grouping = self
            .group_by
            .parse::<MafGrouping>()
            .map_err(anyhow::Error::msg)?;
        log::info!(
            "{:18}: {}",
            "File counts",
            utils::fmt_num(&input_files.len())
        );
        log::info!("{:18}: {}", "Input format", "MAF");
        log::info!("{:18}: {}\n", "Task", "MAF Conversion");
        let filter = BlockFilter {
            min_ref_len: self.min_block_len,
            min_species: self.min_species,
            min_score: self.min_score,
            species: species_list(&self.species),
        };
        let mut converter = MafConverter::new(&input_files, output_path, &output_fmt)
            .with_grouping(grouping)
            .with_clip(self.clip)
            .with_strand_aware(self.strand_aware)
            .with_ref_species(self.ref_species.clone())
            .with_filter(filter);
        if let Some(bed) = &self.bed_file {
            converter = converter.with_bed(Path::new(bed));
        }
        converter.convert()?;
        utils::print_execution_time(time.elapsed());
        Ok(())
    }

    fn match_output_fmt(&self) -> anyhow::Result<OutputFmt> {
        self.output_fmt
            .to_lowercase()
            .parse::<OutputFmt>()
            .map_err(|_| anyhow::anyhow!("Invalid output format: {}", self.output_fmt))
    }
}

pub struct MafSummaryServices {
    pub input_files: Vec<String>,
    pub output_dir: String,
    // Prefix of the summary files. Defaults to maf_summary.
    pub prefix: Option<String>,
    // Defaults to the first species in the first block.
    pub ref_species: Option<String>,
    // Report only these species. Empty reports every species.
    pub species: Vec<String>,
}

impl MafSummaryServices {
    pub fn new() -> MafSummaryServices {
        MafSummaryServices {
            input_files: Vec::new(),
            output_dir: String::new(),
            prefix: None,
            ref_species: None,
            species: Vec::new(),
        }
    }

    pub fn summarize(&self) -> anyhow::Result<()> {
        let time = Instant::now();
        let input_files: Vec<PathBuf> = self.input_files.iter().map(PathBuf::from).collect();
        log::info!(
            "{:18}: {}",
            "File counts",
            utils::fmt_num(&input_files.len())
        );
        log::info!("{:18}: {}", "Input format", "MAF");
        log::info!("{:18}: {}\n", "Task", "MAF Summary");
        MafSummary::new(
            &input_files,
            Path::new(&self.output_dir),
            self.prefix.as_deref(),
        )
        .with_ref_species(self.ref_species.clone())
        .with_species(species_list(&self.species))
        .summarize()?;
        utils::print_execution_time(time.elapsed());
        Ok(())
    }
}

fn species_list(species: &[String]) -> Option<Vec<String>> {
    if species.is_empty() {
        None
    } else {
        Some(species.to_vec())
    }
}

#[cfg(test)]
mod test {
    use std::fs;

    use super::*;

    fn fixtures() -> PathBuf {
        Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("src")
            .join("tests")
    }

    fn output_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("segui-test-{}", name));
        if dir.exists() {
            fs::remove_dir_all(&dir).expect("Failed removing old test output");
        }
        dir
    }

    fn file_names(dir: &Path) -> Vec<String> {
        let mut names: Vec<String> = fs::read_dir(dir)
            .expect("Missing output")
            .filter_map(|e| e.ok())
            .filter(|e| e.path().is_file())
            .map(|e| e.file_name().to_string_lossy().into_owned())
            .collect();
        names.sort();
        names
    }

    fn services(output: &Path) -> MafConversionServices {
        let mut services = MafConversionServices::new();
        let input = fixtures().join("simple.maf");
        services.input_files = vec![input.to_string_lossy().into_owned()];
        services.output_dir = output.to_string_lossy().into_owned();
        services
    }

    #[test]
    fn test_convert_maf_without_bed() {
        let output = output_dir("maf-blocks");
        services(&output).convert().unwrap();
        assert_eq!(file_names(&output).len(), 3);
        fs::remove_dir_all(&output).unwrap();
    }

    #[test]
    fn test_convert_maf_regions() {
        let output = output_dir("maf-regions");
        let mut services = services(&output);
        let bed = fixtures().join("simple_regions.bed");
        services.bed_file = Some(bed.to_string_lossy().into_owned());
        services.convert().unwrap();
        assert_eq!(
            file_names(&output),
            [
                "clipA-chr7-27578830-27578834.fas",
                "gapIns-chr7-27578848-27578852.fas",
                "locA-chr7-27578828-27578866.fas",
                "locMerge-chr7-27699739-27707234.fas",
                "maf_convert.csv"
            ]
        );
        fs::remove_dir_all(&output).unwrap();
    }

    #[test]
    fn test_convert_maf_bed_without_matches() {
        // simple.bed is on chr1, but simple.maf is on chr7.
        let output = output_dir("maf-no-match");
        let mut services = services(&output);
        let bed = fixtures().join("simple.bed");
        services.bed_file = Some(bed.to_string_lossy().into_owned());
        services.convert().unwrap();
        assert_eq!(file_names(&output), ["maf_convert.csv"]);
        fs::remove_dir_all(&output).unwrap();
    }

    #[test]
    fn test_convert_maf_errors_instead_of_panicking() {
        let output = output_dir("maf-error");
        let mut services = services(&output);
        services.bed_file = Some(
            fixtures()
                .join("missing.bed")
                .to_string_lossy()
                .into_owned(),
        );
        assert!(services.convert().is_err());
        services.bed_file = None;
        services.output_fmt = String::from("csv");
        assert!(services.convert().is_err());
    }

    #[test]
    fn test_summarize_maf() {
        let output = output_dir("maf-summary");
        let mut services = MafSummaryServices::new();
        let input = fixtures().join("simple.maf");
        services.input_files = vec![input.to_string_lossy().into_owned()];
        services.output_dir = output.to_string_lossy().into_owned();
        services.summarize().unwrap();
        let per_species = fs::read_to_string(output.join("maf_summary_per_species.csv")).unwrap();
        assert!(per_species.starts_with("path,name,blocks_present"));
        assert!(output.join("maf_summary_per_file.csv").is_file());
        fs::remove_dir_all(&output).unwrap();
    }
}

use std::path::{Path, PathBuf};
use std::time::Instant;

use segul::core::maf::convert::MafConverter;
use segul::helper::types::OutputFmt;
use segul::helper::utils;

pub struct MafConversionServices {
    pub input_files: Vec<String>,
    // BED file that names each locus by the reference start position.
    // Blocks without a matching BED record are written to `missing-refs`.
    pub bed_file: String,
    pub output_dir: String,
    // fasta, fasta-int, phylip, or phylip-int
    pub output_fmt: String,
}

impl MafConversionServices {
    pub fn new() -> MafConversionServices {
        MafConversionServices {
            input_files: Vec::new(),
            bed_file: String::new(),
            output_dir: String::new(),
            output_fmt: String::new(),
        }
    }

    pub fn convert(&self) {
        let time = Instant::now();
        let input_files: Vec<PathBuf> = self.input_files.iter().map(PathBuf::from).collect();
        let bed_file = Path::new(&self.bed_file);
        let output_path = Path::new(&self.output_dir);
        let output_fmt = self.match_output_fmt();
        log::info!(
            "{:18}: {}",
            "File counts",
            utils::fmt_num(&input_files.len())
        );
        log::info!("{:18}: {}", "Input format", "MAF");
        log::info!("{:18}: {}\n", "Task", "MAF Conversion");
        let converter = MafConverter::new(&input_files, bed_file, true, output_path, &output_fmt);
        converter.convert();
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_output_fmt(&self) -> OutputFmt {
        match self.output_fmt.to_lowercase().parse::<OutputFmt>() {
            Ok(
                fmt @ (OutputFmt::Fasta
                | OutputFmt::FastaInt
                | OutputFmt::Phylip
                | OutputFmt::PhylipInt),
            ) => fmt,
            _ => panic!("MAF conversion supports FASTA and PHYLIP output only"),
        }
    }
}

#[cfg(test)]
mod test {
    use std::fs;

    use super::*;

    #[test]
    fn test_convert_maf() {
        let fixtures = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("src")
            .join("tests");
        let input = fixtures.join("simple.maf");
        let output = std::env::temp_dir().join("segui-test-maf");
        if output.exists() {
            fs::remove_dir_all(&output).expect("Failed removing old test output");
        }
        let mut services = MafConversionServices::new();
        services.input_files = vec![input.to_string_lossy().into_owned()];
        services.bed_file = fixtures.join("simple.bed").to_string_lossy().into_owned();
        services.output_dir = output.to_string_lossy().into_owned();
        services.output_fmt = String::from("fasta");
        services.convert();
        // No BED record matches these blocks, so each one is a missing reference.
        let missing = fs::read_dir(output.join("missing-refs")).expect("Missing output");
        assert_eq!(missing.count(), 3);
        fs::remove_dir_all(&output).expect("Failed removing test output");
    }
}

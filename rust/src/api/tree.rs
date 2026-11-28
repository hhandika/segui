use std::path::{Path, PathBuf};
use std::time::Instant;

use segul_core::core::tree::convert::TreeConversion;
use segul_core::helper::utils;
use segul_core::parser::tree::{ParseOptions, TreeFmt, TreeOutputFmt};
use segul_core::writer::tree::TreeWriteOptions;

use crate::api::progress::RunMonitor;
use crate::api::report::current_report_context;

pub struct TreeConversionServices {
    pub input_files: Vec<String>,
    // auto, newick, enewick, nexus, phyloxml, or nexml
    pub input_fmt: String,
    pub output_dir: String,
    // newick, enewick, nexus, phyloxml, or nexml
    pub output_fmt: String,
    // Write NEXUS trees without a TRANSLATE block.
    pub no_translate: bool,
    // Drop bracket annotations and comments.
    pub strip_annotations: bool,
    pub gzip: bool,
}

impl Default for TreeConversionServices {
    fn default() -> Self {
        Self::new()
    }
}

impl TreeConversionServices {
    pub fn new() -> TreeConversionServices {
        TreeConversionServices {
            input_files: Vec::new(),
            input_fmt: String::from("auto"),
            output_dir: String::new(),
            output_fmt: String::from("newick"),
            no_translate: false,
            strip_annotations: false,
            gzip: false,
        }
    }

    /// Convert tree files. `monitor` reports progress and can cancel the run.
    pub fn convert(&self, monitor: &RunMonitor) -> anyhow::Result<()> {
        let time = Instant::now();
        let input_files: Vec<PathBuf> = self.input_files.iter().map(PathBuf::from).collect();
        if input_files.is_empty() {
            anyhow::bail!("No input files");
        }
        let input_fmt = self
            .input_fmt
            .parse::<TreeFmt>()
            .map_err(anyhow::Error::msg)?;
        let output_fmt = self
            .output_fmt
            .parse::<TreeOutputFmt>()
            .map_err(anyhow::Error::msg)?;
        log::info!(
            "{:18}: {}",
            "File counts",
            utils::fmt_num(&input_files.len())
        );
        log::info!("{:18}: {}", "Input format", input_fmt);
        log::info!("{:18}: {}\n", "Task", "Tree format conversion");
        let parse_opts = ParseOptions {
            parse_annotations: !self.strip_annotations,
            ..Default::default()
        };
        let write_opts = TreeWriteOptions {
            use_translate: !self.no_translate,
            write_annotations: !self.strip_annotations,
            gzip: self.gzip,
            ..Default::default()
        };
        let output_path = Path::new(&self.output_dir);
        std::fs::create_dir_all(output_path)?;
        TreeConversion::new(&input_fmt, &output_fmt)
            .with_parse_options(parse_opts)
            .with_write_options(write_opts)
            .with_progress(monitor)
            .with_report_context(current_report_context())
            .convert_with_report(&input_files, output_path)?;
        utils::print_execution_time(time.elapsed());
        Ok(())
    }
}

#[cfg(test)]
mod test {
    use std::fs;

    use super::*;

    fn fixture(name: &str) -> String {
        Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("src")
            .join("tests")
            .join("trees")
            .join(name)
            .to_string_lossy()
            .into_owned()
    }

    fn output_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("segui-test-{}", name));
        if dir.exists() {
            fs::remove_dir_all(&dir).expect("Failed removing old test output");
        }
        dir
    }

    fn services(input: &str, output: &Path, output_fmt: &str) -> TreeConversionServices {
        let mut services = TreeConversionServices::new();
        services.input_files = vec![fixture(input)];
        services.output_dir = output.to_string_lossy().into_owned();
        services.output_fmt = String::from(output_fmt);
        services
    }

    #[test]
    fn test_convert_newick_to_nexus() {
        let output = output_dir("tree-nexus");
        services("simple.nwk", &output, "nexus")
            .convert(&RunMonitor::new())
            .unwrap();
        let tree = fs::read_to_string(output.join("simple.nex")).unwrap();
        assert!(tree.to_lowercase().contains("begin trees;"));
        assert!(output.join("report.json").is_file());
        fs::remove_dir_all(&output).unwrap();
    }

    #[test]
    fn test_convert_nexus_to_phyloxml() {
        let output = output_dir("tree-phyloxml");
        services("simple_trees.nex", &output, "phyloxml")
            .convert(&RunMonitor::new())
            .unwrap();
        assert!(output.join("simple_trees.phyloxml").is_file());
        fs::remove_dir_all(&output).unwrap();
    }

    #[test]
    fn test_convert_tree_errors_instead_of_panicking() {
        let output = output_dir("tree-error");
        let mut services = services("simple.nwk", &output, "fasta");
        assert!(services.convert(&RunMonitor::new()).is_err());
        services.output_fmt = String::from("newick");
        services.input_files = vec![fixture("missing.nwk")];
        assert!(services.convert(&RunMonitor::new()).is_err());
        let _ = fs::remove_dir_all(&output);
    }
}

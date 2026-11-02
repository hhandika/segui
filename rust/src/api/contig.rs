use std::path::{Path, PathBuf};
use std::time::Instant;

use segul::core::contig::summarize::ContigSummaryHandler;
use segul::helper::logger::ContigLogger;
use segul::helper::types::ContigFmt;
use segul::helper::utils;

use crate::api::progress::RunMonitor;

pub struct ContigServices {
    pub files: Vec<String>,
    pub file_fmt: String,
    pub output_dir: String,
}

impl ContigServices {
    pub fn new() -> ContigServices {
        ContigServices {
            files: Vec::new(),
            file_fmt: String::new(),
            output_dir: String::new(),
        }
    }

    /// Summarize contigs. `monitor` reports progress and can cancel the run.
    pub fn summarize(&self, prefix: Option<String>, monitor: &RunMonitor) -> anyhow::Result<()> {
        let time = Instant::now();
        let input_fmt = self.match_input_fmt();
        let files = self.find_input_files();
        let output_path = Path::new(&self.output_dir);
        let task = "Contig Summary";
        ContigLogger::new(None, &input_fmt, files.len()).log(task);

        ContigSummaryHandler::new(&files, &input_fmt, output_path, prefix.as_deref())
            .with_progress(monitor)
            .try_summarize()?;
        let duration = time.elapsed();
        utils::print_execution_time(duration);
        Ok(())
    }

    fn match_input_fmt(&self) -> ContigFmt {
        self.file_fmt
            .to_lowercase()
            .parse()
            .expect("Invalid input format")
    }

    fn find_input_files(&self) -> Vec<PathBuf> {
        self.files.iter().map(PathBuf::from).collect()
    }
}

use std::path::{Path, PathBuf};

use segul::handler::contig::summarize::ContigSummaryHandler;
use segul::helper::finder::ContigFileFinder;
use segul::helper::types::ContigFmt;

pub struct ContigServices {
    pub dir_path: Option<String>,
    pub files: Vec<String>,
    pub file_fmt: String,
    pub output_dir: String,
}

impl ContigServices {
    pub fn new() -> ContigServices {
        ContigServices {
            dir_path: None,
            files: Vec::new(),
            file_fmt: String::new(),
            output_dir: String::new(),
        }
    }

    pub fn summarize(&self) {
        let input_fmt = self.match_input_fmt();
        let mut files = self.find_input_files(&input_fmt);
        let output_path = Path::new(&self.output_dir);
        let summary = ContigSummaryHandler::new(&mut files, &input_fmt, output_path);
        summary.summarize();
    }

    fn match_input_fmt(&self) -> ContigFmt {
        self.file_fmt
            .to_lowercase()
            .parse()
            .expect("Invalid input format")
    }

    fn find_input_files(&self, input_fmt: &ContigFmt) -> Vec<PathBuf> {
        if self.files.is_empty() {
            match self.dir_path {
                Some(ref path) => {
                    let path = Path::new(&path);
                    ContigFileFinder::new(path).find(input_fmt)
                }
                None => panic!("No input files found"),
            }
        } else {
            self.files.iter().map(PathBuf::from).collect()
        }
    }
}

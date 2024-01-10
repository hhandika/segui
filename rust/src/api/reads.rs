use std::path::{Path, PathBuf};

use segul::handler::read::summarize::ReadSummaryHandler;
use segul::helper::finder::SeqReadFinder;
use segul::helper::logger::ReadLogger;
use segul::helper::types::{SeqReadFmt, SummaryMode};

pub struct RawReadServices {
    pub dir_path: Option<String>,
    pub files: Vec<String>,
    pub file_fmt: String,
    pub output_dir: String,
}

impl RawReadServices {
    pub fn new() -> RawReadServices {
        RawReadServices {
            dir_path: None,
            files: Vec::new(),
            file_fmt: String::new(),
            output_dir: String::new(),
        }
    }

    pub fn summarize(&self, mode: String) {
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt();
        let mut files = self.find_input_files(&input_fmt);
        let sum_mode = self.match_mode(&mode);
        ReadLogger::new(None, &input_fmt, files.len()).log("Read Summary");
        let mut summary = ReadSummaryHandler::new(&mut files, &input_fmt, &sum_mode, output_path);
        summary.summarize();
    }

    fn match_input_fmt(&self) -> SeqReadFmt {
        self.file_fmt
            .to_lowercase()
            .parse()
            .expect("Invalid input format")
    }

    fn match_mode(&self, mode: &str) -> SummaryMode {
        mode.to_lowercase().parse().expect("Invalid summary mode")
    }

    fn find_input_files(&self, input_fmt: &SeqReadFmt) -> Vec<PathBuf> {
        if self.files.is_empty() {
            match self.dir_path {
                Some(ref path) => {
                    let path = Path::new(&path);
                    SeqReadFinder::new(path).find(input_fmt)
                }
                None => panic!("No input files found"),
            }
        } else {
            self.files.iter().map(PathBuf::from).collect()
        }
    }
}
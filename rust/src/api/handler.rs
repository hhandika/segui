// Synchronous mode for simplicity of the demo
use std::path::{Path, PathBuf};

use segul::handler::align::concat::ConcatHandler;
use segul::handler::align::convert::Converter;
use segul::handler::align::summarize::SeqStats;
use segul::handler::contig::summarize::ContigSummaryHandler;
use segul::handler::read::summarize::ReadSummaryHandler;
use segul::handler::sequence::id::Id;
use segul::handler::sequence::translate::Translate;
use segul::helper::finder::{ContigFileFinder, SeqFileFinder, SeqReadFinder};
use segul::helper::types::{ContigFmt, DataType, GeneticCodes, InputFmt, SeqReadFmt, SummaryMode};
use segul::helper::types::{OutputFmt, PartitionFmt};
use segul::helper::{alphabet, files, logger};

#[flutter_rust_bridge::frb(sync)]
pub fn show_dna_uppercase() -> String {
    alphabet::DNA_STR_UPPERCASE.to_string()
}

#[flutter_rust_bridge::frb(sync)]
pub struct SequenceServices {
    pub dir_path: Option<String>,
    pub files: Vec<String>,
    pub file_fmt: String,
    pub datatype: String,
    pub output_dir: String,
}

impl SequenceServices {
    pub fn new() -> SequenceServices {
        SequenceServices {
            dir_path: None,
            files: Vec::new(),
            file_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
        }
    }

    pub fn concat_alignment(&self, out_fname: String, out_fmt_str: String, partition_fmt: String) {
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype();
        let mut files = self.find_input_files(&input_fmt);
        self.check_file_count(files.len());
        let output_fmt = self.match_output_fmt(&out_fmt_str);
        let output_path = PathBuf::from(&self.output_dir).join(out_fname);
        let final_path = files::create_output_fname_from_path(&output_path, &output_fmt);
        let partition_fmt = self.match_partition_fmt(&partition_fmt);
        let mut concat = ConcatHandler::new(&input_fmt, &final_path, &output_fmt, &partition_fmt);
        concat.concat_alignment(&mut files, &datatype);
    }

    pub fn convert_sequence(&self, output_fmt: String, sort: bool) {
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype();
        let mut files = self.find_input_files(&input_fmt);
        let output_fmt = self.match_output_fmt(&output_fmt);
        let output_path = Path::new(&self.output_dir);
        let mut concat = Converter::new(&input_fmt, &output_fmt, &datatype, sort);
        concat.convert(&mut files, &output_path);
    }

    pub fn parse_sequence_id(&self, is_map: bool) {
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype();
        let files = self.find_input_files(&input_fmt);
        let output_path = Path::new(&self.output_dir).with_extension("txt");
        let id = Id::new(&output_path, &input_fmt, &datatype);
        if !is_map {
            id.generate_id(&files);
        } else {
            let output_stem = output_path
                .file_stem()
                .expect("No output path")
                .to_str()
                .expect("Invalid output path");
            let output_fname = format!("{}_map", output_stem);
            let mapped_path = output_path
                .parent()
                .expect("No output path")
                .join(output_fname)
                .with_extension("txt");
            id.map_id(&files, &mapped_path);
        }
    }

    pub fn summarize_alignment(&self, output_prefix: String, interval: usize) {
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype();
        let mut files = self.find_input_files(&input_fmt);
        let output_path = Path::new(&self.output_dir);
        let mut summary = SeqStats::new(&input_fmt, &output_path, interval, &datatype);
        summary.summarize_all(&mut files, &Some(output_prefix));
    }

    pub fn translate_sequence(&self, table: String, reading_frame: usize, output_fmt: String) {
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype();
        let mut files = self.find_input_files(&input_fmt);
        let output_fmt = self.match_output_fmt(&output_fmt);
        let translation_table = self.match_translation_table(table);
        let output_path = Path::new(&self.output_dir);
        let translate = Translate::new(&translation_table, &input_fmt, &datatype, &output_fmt);
        translate.translate_all(&mut files, reading_frame, &output_path);
    }

    fn find_input_files(&self, input_fmt: &InputFmt) -> Vec<PathBuf> {
        if self.files.is_empty() {
            match self.dir_path {
                Some(ref path) => {
                    let path = Path::new(&path);
                    SeqFileFinder::new(path).find(&input_fmt)
                }
                None => panic!("No input files found"),
            }
        } else {
            self.files.iter().map(PathBuf::from).collect()
        }
    }

    fn check_file_count(&self, file_count: usize) {
        if file_count < 2 {
            panic!("At least two files are required for the analysis");
        }
    }

    fn match_translation_table(&self, table: String) -> GeneticCodes {
        table
            .parse::<GeneticCodes>()
            .expect("Invalid translation table")
    }

    fn match_input_fmt(&self) -> InputFmt {
        self.file_fmt
            .to_lowercase()
            .parse()
            .expect("Invalid input format")
    }

    fn match_output_fmt(&self, out_fmt_str: &str) -> OutputFmt {
        out_fmt_str
            .to_lowercase()
            .parse()
            .expect("Invalid output format")
    }

    fn match_partition_fmt(&self, partition_fmt: &str) -> PartitionFmt {
        partition_fmt
            .to_lowercase()
            .parse()
            .expect("Invalid partition format")
    }

    fn match_datatype(&self) -> DataType {
        self.datatype
            .to_lowercase()
            .parse::<DataType>()
            .expect("Invalid data type")
    }
}

#[flutter_rust_bridge::frb(sync)]
pub struct FastqServices {
    pub dir_path: Option<String>,
    pub files: Vec<String>,
    pub file_fmt: String,
    pub output_dir: String,
}

impl FastqServices {
    pub fn new() -> FastqServices {
        FastqServices {
            dir_path: None,
            files: Vec::new(),
            file_fmt: String::new(),
            output_dir: String::new(),
        }
    }

    pub fn summarize(&self, mode: String) {
        let input_fmt = self.match_input_fmt();
        let mut files = self.find_input_files(&input_fmt);
        let output_path = Path::new(&self.output_dir);
        let sum_mode = self.match_mode(&mode);
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
                    SeqReadFinder::new(path).find(&input_fmt)
                }
                None => panic!("No input files found"),
            }
        } else {
            self.files.iter().map(PathBuf::from).collect()
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
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

#[flutter_rust_bridge::frb(sync)]
pub fn init_logger(path: String) {
    let logger_path = Path::new(&path);
    logger::init_file_logger(&logger_path).expect("Failed to setup logger");
}

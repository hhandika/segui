use std::path::{Path, PathBuf};

use segul::handler::align::concat::ConcatHandler;
use segul::handler::align::convert::Converter;
use segul::handler::align::summarize::SeqStats;
use segul::handler::raw::summarize::RawSummaryHandler;
use segul::handler::sequence::translate::Translate;
use segul::helper::finder::Files;
use segul::helper::types::{DataType, GeneticCodes, InputFmt, RawReadFmt, SummaryMode};
use segul::helper::types::{OutputFmt, PartitionFmt};
use segul::helper::{alphabet, files};

pub fn show_dna_uppercase() -> String {
    alphabet::DNA_STR_UPPERCASE.to_string()
}

pub struct SegulServices {
    pub dir_path: Option<String>,
    pub files: Vec<String>,
    pub file_fmt: String,
    pub datatype: String,
    pub output_dir: String,
}

impl SegulServices {
    pub fn new() -> SegulServices {
        SegulServices {
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
        let mut concat = Converter::new(&input_fmt, &output_fmt, &datatype, sort);
        concat.convert(&mut files, Path::new(&self.output_dir));
    }

    pub fn summarize_alignment(&self, output_prefix: String, interval: usize) {
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype();
        let mut files = self.find_input_files(&input_fmt);
        let output = Path::new(&self.output_dir);
        let mut summary = SeqStats::new(&input_fmt, output, interval, &datatype);
        summary.summarize_all(&mut files, &Some(output_prefix));
    }

    pub fn translate_sequence(&self, table: String, reading_frame: usize, output_fmt: String) {
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype();
        let mut files = self.find_input_files(&input_fmt);
        let output_fmt = self.match_output_fmt(&output_fmt);
        let translation_table = self.match_translation_table(table);
        let translate = Translate::new(&translation_table, &input_fmt, &datatype, &output_fmt);
        translate.translate_all(&mut files, reading_frame, Path::new(&self.output_dir));
    }

    fn find_input_files(&self, input_fmt: &InputFmt) -> Vec<PathBuf> {
        if let Some(path) = &self.dir_path {
            let path = Path::new(&path);
            Files::new(path).find(&input_fmt)
        } else {
            if self.files.is_empty() {
                panic!("No input files found");
            } else {
                self.files.iter().map(PathBuf::from).collect()
            }
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

    pub fn summarize(&self, mode: String, lowmem: bool) {
        let input_fmt = self.match_input_fmt();
        let mut files = self.find_input_files(&input_fmt);
        let output = Path::new(&self.output_dir);
        let sum_mode = self.match_mode(&mode);
        let mut summary = RawSummaryHandler::new(&mut files, &input_fmt, &sum_mode, output);
        summary.summarize(lowmem);
    }

    fn match_input_fmt(&self) -> RawReadFmt {
        self.file_fmt
            .to_lowercase()
            .parse()
            .expect("Invalid input format")
    }

    fn match_mode(&self, mode: &str) -> SummaryMode {
        mode.to_lowercase().parse().expect("Invalid summary mode")
    }

    fn find_input_files(&self, input_fmt: &RawReadFmt) -> Vec<PathBuf> {
        if let Some(path) = &self.dir_path {
            let path = Path::new(&path);
            Files::new(path).find_raw_read(input_fmt)
        } else {
            if self.files.is_empty() {
                panic!("No input files found");
            } else {
                self.files.iter().map(PathBuf::from).collect()
            }
        }
    }
}

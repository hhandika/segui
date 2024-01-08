use std::path::{Path, PathBuf};

use segul::handler::align::concat::ConcatHandler;
use segul::handler::align::convert::Converter;
use segul::handler::align::summarize::SeqStats;
use segul::handler::sequence::id::Id;
use segul::handler::sequence::partition::PartConverter;
use segul::handler::sequence::translate::Translate;
use segul::helper::finder::SeqFileFinder;
use segul::helper::logger::init_file_logger;
use segul::helper::partition::construct_partition_path;
use segul::helper::types::{DataType, GeneticCodes, InputFmt};
use segul::helper::types::{OutputFmt, PartitionFmt};
use segul::helper::{alphabet, files};

pub fn show_dna_uppercase() -> String {
    alphabet::DNA_STR_UPPERCASE.to_string()
}

trait Sequence {
    fn match_datatype(&self, datatype: &str) -> DataType {
        datatype
            .to_lowercase()
            .parse::<DataType>()
            .expect("Invalid data type")
    }
}

trait Partition {
    fn match_partition_fmt(&self, partition_fmt: &str) -> PartitionFmt {
        partition_fmt
            .to_lowercase()
            .parse()
            .expect("Invalid partition format")
    }
}

pub struct SequenceServices {
    pub dir_path: Option<String>,
    pub files: Vec<String>,
    pub file_fmt: String,
    pub datatype: String,
    pub output_dir: String,
}

impl Sequence for SequenceServices {}
impl Partition for SequenceServices {}

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
        let output_path = PathBuf::from(&self.output_dir).join(out_fname);
        init_file_logger(Path::new(&self.output_dir)).expect("Failed to initialize logger");
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype(&self.datatype);
        let mut files = self.find_input_files(&input_fmt);
        let output_fmt = self.match_output_fmt(&out_fmt_str);
        self.check_file_count(files.len());
        let final_path = files::create_output_fname_from_path(&output_path, &output_fmt);
        let partition_fmt = self.match_partition_fmt(&partition_fmt);
        let mut concat = ConcatHandler::new(&input_fmt, &final_path, &output_fmt, &partition_fmt);
        concat.concat_alignment(&mut files, &datatype);
    }

    pub fn convert_sequence(&self, output_fmt: String, sort: bool) {
        let output_path = Path::new(&self.output_dir);
        init_file_logger(output_path).expect("Failed to initialize logger");
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype(&self.datatype);
        let files = self.find_input_files(&input_fmt);
        let output_fmt = self.match_output_fmt(&output_fmt);
        let mut concat = Converter::new(&input_fmt, &output_fmt, &datatype, sort);
        concat.convert(&files, output_path);
    }

    pub fn parse_sequence_id(&self, is_map: bool) {
        let output_path = Path::new(&self.output_dir).with_extension("txt");
        init_file_logger(Path::new(&self.output_dir)).expect("Failed to initialize logger");
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype(&self.datatype);
        let files = self.find_input_files(&input_fmt);

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
        let output_path = Path::new(&self.output_dir);
        init_file_logger(output_path).expect("Failed to initialize logger");
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype(&self.datatype);
        let mut files = self.find_input_files(&input_fmt);
        let mut summary = SeqStats::new(&input_fmt, output_path, interval, &datatype);
        summary.summarize_all(&mut files, &Some(output_prefix));
    }

    pub fn translate_sequence(&self, table: String, reading_frame: usize, output_fmt: String) {
        let output_path = Path::new(&self.output_dir);
        init_file_logger(output_path).expect("Failed to initialize logger");
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype(&self.datatype);
        let mut files = self.find_input_files(&input_fmt);
        let output_fmt = self.match_output_fmt(&output_fmt);
        let translation_table = self.match_translation_table(table);
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
}

pub struct PartitionServices {
    pub file_inputs: Vec<String>,
    pub input_part_fmt: String,
    pub output: String,
    pub output_part_fmt: String,
    pub datatype: String,
    pub is_uncheck: bool,
}

impl Sequence for PartitionServices {}
impl Partition for PartitionServices {}

impl PartitionServices {
    pub fn new() -> PartitionServices {
        PartitionServices {
            file_inputs: Vec::new(),
            input_part_fmt: String::new(),
            output: String::new(),
            output_part_fmt: String::new(),
            datatype: String::new(),
            is_uncheck: false,
        }
    }

    pub fn convert_partition(&self) {
        let output = Path::new(&self.output);
        init_file_logger(output).expect("Failed to initialize logger");
        let input_fmt = self.match_partition_fmt(&self.input_part_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let out_part_fmt = self.match_partition_fmt(&self.output_part_fmt);
        self.file_inputs.iter().map(Path::new).for_each(|input| {
            let output_path = construct_partition_path(input, &out_part_fmt);
            let converter = PartConverter::new(&output_path, &input_fmt, output, &out_part_fmt);
            converter.convert(&datatype, self.is_uncheck);
        });
    }
}

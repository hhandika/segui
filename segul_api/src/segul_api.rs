use std::path::{Path, PathBuf};

use segul::handler::concat::ConcatHandler;
use segul::handler::convert::Converter;
use segul::handler::summarize::SeqStats;
use segul::handler::translate::Translate;
use segul::helper::finder::Files;
use segul::helper::types::{DataType, GeneticCodes, InputFmt};
use segul::helper::types::{OutputFmt, PartitionFmt};
use segul::helper::{alphabet, filenames};

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
        let output_fmt = self.match_output_fmt(&out_fmt_str);
        let output_path = PathBuf::from(&self.output_dir).join(out_fname);
        let final_path = filenames::create_output_fname_from_path(&output_path, &output_fmt);
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

    pub fn translate_sequence(&self, table: usize, reading_frame: usize, output_fmt: String) {
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
            Files::new(path, &input_fmt).find()
        } else {
            if self.files.is_empty() {
                panic!("No input files found");
            } else {
                self.files.iter().map(PathBuf::from).collect()
            }
        }
    }

    fn match_translation_table(&self, table: usize) -> GeneticCodes {
        match table {
            1 => GeneticCodes::StandardCode,
            2 => GeneticCodes::VertMtDna,
            _ => unreachable!("Translation table is not supported {}", table),
        }
    }

    fn match_input_fmt(&self) -> InputFmt {
        match self.file_fmt.to_lowercase().as_str() {
            "fasta" => InputFmt::Fasta,
            "phylip" => InputFmt::Phylip,
            "nexus" => InputFmt::Nexus,
            _ => InputFmt::Fasta,
        }
    }

    fn match_output_fmt(&self, out_fmt_str: &str) -> OutputFmt {
        match out_fmt_str.to_lowercase().as_str() {
            "fasta" => OutputFmt::Fasta,
            "phylip" => OutputFmt::Phylip,
            "nexus" => OutputFmt::Nexus,
            "fasta interleaved" => OutputFmt::FastaInt,
            "phylip interleaved" => OutputFmt::NexusInt,
            "nexus interleaved" => OutputFmt::PhylipInt,
            _ => unreachable!("Output format is not supported {}", out_fmt_str),
        }
    }

    fn match_partition_fmt(&self, partition_fmt: &str) -> PartitionFmt {
        match partition_fmt.to_lowercase().as_str() {
            "charset" => PartitionFmt::Charset,
            "nexus" => PartitionFmt::Nexus,
            "raxml" => PartitionFmt::Raxml,
            _ => PartitionFmt::Nexus,
        }
    }

    fn match_datatype(&self) -> DataType {
        match self.datatype.to_lowercase().as_str() {
            "dna" => DataType::Dna,
            "amino acid" => DataType::Aa,
            "ignore" => DataType::Ignore,
            _ => DataType::Dna,
        }
    }
}

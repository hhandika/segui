use std::path::{Path, PathBuf};
use std::time::Instant;

use segul::handler::align::concat::ConcatHandler;
use segul::handler::align::convert::Converter;
use segul::handler::align::filter::{Params, SeqFilter};
use segul::handler::align::split::Splitter;
use segul::handler::align::summarize::SeqStats;
use segul::handler::sequence::extract::{Extract, ExtractOpts};
use segul::handler::sequence::id::Id;
use segul::handler::sequence::partition::PartConverter;
use segul::handler::sequence::remove::{Remove, RemoveOpts};
use segul::handler::sequence::rename::{Rename, RenameOpts};
use segul::handler::sequence::translate::Translate;
use segul::helper::files::{self, create_output_fname_from_path};
use segul::helper::finder::{IDs, SeqFileFinder};
use segul::helper::logger::{log_input_partition, AlignSeqLogger};
use segul::helper::partition::construct_partition_path;
use segul::helper::types::{DataType, GeneticCodes, InputFmt};
use segul::helper::types::{OutputFmt, PartitionFmt};
use segul::helper::{alphabet, utils};
use segul::parser::{delimited, txt};

const INPUT_DIRECTORY: Option<&str> = None;

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

    fn match_input_fmt(&self, input_fmt: &str) -> InputFmt {
        input_fmt
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

    fn find_input_input_files(
        &self,
        input_files: &[String],
        dir: Option<&str>,
        input_fmt: &InputFmt,
    ) -> Vec<PathBuf> {
        if input_files.is_empty() {
            match dir {
                Some(ref path) => {
                    let path = Path::new(&path);
                    SeqFileFinder::new(path).find(&input_fmt)
                }
                None => panic!("No input input_files found"),
            }
        } else {
            input_files.iter().map(PathBuf::from).collect()
        }
    }

    fn check_file_count(&self, file_count: usize) {
        if file_count < 2 {
            panic!("At least two input_files are required for the analysis");
        }
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
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
}

impl Sequence for SequenceServices {}
impl Partition for SequenceServices {}

impl SequenceServices {
    pub fn new() -> SequenceServices {
        SequenceServices {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
        }
    }

    pub fn convert_sequence(&self, output_fmt: String, sort: bool) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files =
            self.find_input_input_files(&self.input_files, INPUT_DIRECTORY, &input_fmt);
        let output_fmt = self.match_output_fmt(&output_fmt);
        let task = "Sequence Conversion";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let mut concat = Converter::new(&input_fmt, &output_fmt, &datatype, sort);
        concat.convert(&input_files, output_path);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    // TODO: handle output directory creation in the SEGUL API
    pub fn parse_sequence_id(&self, output_fname: String, is_map: bool) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir)
            .join(output_fname)
            .with_extension("txt");
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files =
            self.find_input_input_files(&self.input_files, INPUT_DIRECTORY, &input_fmt);
        let log = AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len());
        let id = Id::new(&input_fmt, &datatype, &output_path);
        if !is_map {
            let task = "Sequence ID parsing";
            log.log(task);
            id.generate_id(&input_files);
        } else {
            let task = "Sequence ID mapping";
            log.log(task);
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
            id.map_id(&input_files, &mapped_path);
        }
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    pub fn translate_sequence(&self, table: String, reading_frame: usize, output_fmt: String) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let mut input_files =
            self.find_input_input_files(&self.input_files, INPUT_DIRECTORY, &input_fmt);
        let output_fmt = self.match_output_fmt(&output_fmt);
        let translation_table = self.match_translation_table(table);
        let task = "Sequence Translation";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let translate = Translate::new(&translation_table, &input_fmt, &datatype, &output_fmt);
        translate.translate_all(&mut input_files, reading_frame, &output_path);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_translation_table(&self, table: String) -> GeneticCodes {
        table
            .parse::<GeneticCodes>()
            .expect("Invalid translation table")
    }
}

pub struct AlignmentServices {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
}

impl Sequence for AlignmentServices {}
impl Partition for AlignmentServices {}

impl AlignmentServices {
    pub fn new() -> AlignmentServices {
        AlignmentServices {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
        }
    }

    pub fn concat_alignment(&self, out_fname: String, out_fmt_str: String, partition_fmt: String) {
        let time = Instant::now();
        let output_path = PathBuf::from(&self.output_dir).join(out_fname);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let mut input_files = self.find_input_input_files(&self.input_files, None, &input_fmt);
        let output_fmt = self.match_output_fmt(&out_fmt_str);
        self.check_file_count(input_files.len());
        let final_path = create_output_fname_from_path(&output_path, &output_fmt);
        let partition_fmt = self.match_partition_fmt(&partition_fmt);
        let task = "Alignment Concatenation";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let mut concat = ConcatHandler::new(&input_fmt, &final_path, &output_fmt, &partition_fmt);
        concat.concat_alignment(&mut input_files, &datatype);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    pub fn summarize_alignment(&self, output_prefix: String, interval: usize) {
        let time = Instant::now();
        let output_path = PathBuf::from(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let mut input_files = self.find_input_input_files(&self.input_files, None, &input_fmt);
        let task = "Alignment Summary";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let mut summary = SeqStats::new(&input_fmt, &output_path, interval, &datatype);
        summary.summarize_all(&mut input_files, &Some(output_prefix));
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }
}

pub struct SplitAlignmentServices {
    pub input_file: String,
    pub input_fmt: String,
    pub datatype: String,
    // Input partition path
    pub input_partition: Option<String>,
    pub input_partition_fmt: String,
    pub output_dir: String,
    // Output file prefix
    pub prefix: Option<String>,
    pub output_fmt: String,
    pub is_uncheck: bool,
}

impl Sequence for SplitAlignmentServices {}
impl Partition for SplitAlignmentServices {}

impl SplitAlignmentServices {
    pub fn new() -> SplitAlignmentServices {
        SplitAlignmentServices {
            input_file: String::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            input_partition: None,
            input_partition_fmt: String::new(),
            output_dir: String::new(),
            prefix: None,
            output_fmt: String::new(),
            is_uncheck: false,
        }
    }

    pub fn split_alignment(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_path = Path::new(&self.input_file);
        let partition_fmt = self.match_partition_fmt(&self.input_partition_fmt);
        let output_fmt = self.match_output_fmt(&self.output_fmt);
        let task = "Alignment Splitting";
        AlignSeqLogger::new(None, &input_fmt, &datatype, 1).log(task);
        let input_partition_path = self.generate_input_partition_path();
        let split = Splitter::new(input_path, &datatype, &input_fmt, output_path, &output_fmt);
        split.split_alignment(
            &input_partition_path,
            &partition_fmt,
            &self.prefix,
            self.is_uncheck,
        );
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    // Assume the partition in the input file if none supplied.
    fn generate_input_partition_path(&self) -> PathBuf {
        match &self.input_partition {
            Some(path) => PathBuf::from(path),
            None => PathBuf::from(&self.input_file),
        }
    }
}

pub enum FilteringParams {
    MinTax(f64),
    AlnLen(usize),
    ParsInf(usize),
    PercInf(f64),
    TaxonAll(Vec<String>),
    None,
}

pub struct FilteringServices {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    pub is_concat: bool,
    pub params: FilteringParams,
    pub output_fmt: Option<String>,
    // Prefix when user wants to
    // concatenate the results
    pub prefix: Option<String>,
    // Output partition format
    pub partition_fmt: Option<String>,
}

impl Sequence for FilteringServices {}
impl Partition for FilteringServices {}

impl FilteringServices {
    pub fn new() -> FilteringServices {
        FilteringServices {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            params: FilteringParams::None,
            is_concat: false,
            output_fmt: None,
            prefix: None,
            partition_fmt: None,
        }
    }

    pub fn filter(&self) {
        let time = Instant::now();
        let output_path = PathBuf::from(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files =
            self.find_input_input_files(&self.input_files, INPUT_DIRECTORY, &input_fmt);
        self.check_file_count(input_files.len());
        let task = "Alignment Filtering";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let params = self.match_parameters(&input_files, &input_fmt, &datatype);
        let mut filter = SeqFilter::new(&input_files, &input_fmt, &datatype, &output_path, &params);

        if self.is_concat {
            let output_fmt =
                self.match_output_fmt(&self.output_fmt.as_ref().expect("No output format"));
            let partition_fmt = self
                .match_partition_fmt(&self.partition_fmt.as_ref().expect("No partition format"));

            let prefix = Path::new(self.prefix.as_ref().expect("No prefix"));
            let final_output_path = files::create_output_fname(&output_path, prefix, &output_fmt);
            filter.set_concat(&final_output_path, &output_fmt, &partition_fmt);
            filter.filter_aln();
        } else {
            filter.filter_aln();
        }

        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_parameters(
        &self,
        input_files: &[PathBuf],
        input_fmt: &InputFmt,
        datatype: &DataType,
    ) -> Params {
        self.log_info();
        match &self.params {
            FilteringParams::MinTax(percent) => {
                let taxon_count = IDs::new(input_files, input_fmt, datatype).id_unique().len();
                let min_taxa = self.count_min_tax(*percent, taxon_count);
                log::info!("{:18}: {}%", "Percent", percent * 100.0);
                log::info!("{:18}: {}\n", "Min tax", min_taxa);
                Params::MinTax(min_taxa)
            }
            FilteringParams::AlnLen(len) => {
                log::info!("{:18}: {} bp\n", "Min aln len", len);
                Params::AlnLen(*len)
            }
            FilteringParams::ParsInf(inf) => {
                log::info!("{:18}: {}\n", "Min pars. inf", inf);
                Params::ParsInf(*inf)
            }
            FilteringParams::PercInf(perc_inf) => {
                log::info!("{:18}: {}%\n", "% pars. inf", perc_inf * 100.0);
                Params::PercInf(*perc_inf)
            }
            FilteringParams::TaxonAll(taxon_id) => {
                log::info!("{:18}: {} taxa\n", "Taxon id", taxon_id.len());
                Params::TaxonAll(taxon_id.to_vec())
            }
            FilteringParams::None => unreachable!("Invalid params"),
        }
    }

    fn count_min_tax(&self, percent: f64, taxon_count: usize) -> usize {
        (percent * taxon_count as f64).floor() as usize
    }

    fn log_info(&self) {
        log::info!("{}", "Params");
    }
}

pub struct PartitionServices {
    pub input_files: Vec<String>,
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
            input_files: Vec::new(),
            input_part_fmt: String::new(),
            output: String::new(),
            output_part_fmt: String::new(),
            datatype: String::new(),
            is_uncheck: false,
        }
    }

    pub fn convert_partition(&self) {
        let time = Instant::now();
        let input_dir = None::<PathBuf>;
        let output = Path::new(&self.output);
        let input_fmt = self.match_partition_fmt(&self.input_part_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let out_part_fmt = self.match_partition_fmt(&self.output_part_fmt);

        log_input_partition(input_dir.as_deref(), self.input_files.len());
        self.input_files.iter().map(Path::new).for_each(|input| {
            log_input_partition(Some(input), self.input_files.len());
            let file_stem = self.extract_partition_fname(input);
            let output_path = self.create_final_output_path(output, &file_stem);
            let final_path = construct_partition_path(&output_path, &out_part_fmt);
            let converter = PartConverter::new(input, &input_fmt, &final_path, &out_part_fmt);
            converter.convert(&datatype, self.is_uncheck);
        });
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn extract_partition_fname(&self, input: &Path) -> String {
        input
            .file_stem()
            .expect("No input file stem")
            .to_str()
            .expect("Invalid input file stem")
            .to_string()
    }

    fn create_final_output_path(&self, output: &Path, file_stem: &str) -> PathBuf {
        output.join(file_stem)
    }
}

pub struct SequenceRemoval {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    pub output_fmt: String,
    pub remove_regex: Option<String>,
    pub remove_list: Option<Vec<String>>,
}

impl Sequence for SequenceRemoval {}

impl SequenceRemoval {
    pub fn new() -> SequenceRemoval {
        SequenceRemoval {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            output_fmt: String::new(),
            remove_regex: None,
            remove_list: None,
        }
    }

    pub fn remove_sequence(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files = self.find_input_input_files(&self.input_files, None::<&str>, &input_fmt);
        let output_fmt = self.match_output_fmt(&self.output_fmt);
        let remove_opts = self.match_removal_type();
        let task = "Sequence Removal";

        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let remove_handle = Remove::new(
            &input_fmt,
            &datatype,
            output_path,
            &output_fmt,
            &remove_opts,
        );
        remove_handle.remove(&input_files);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_removal_type(&self) -> RemoveOpts {
        log::info!("{}", "Params");
        if let Some(regex) = &self.remove_regex {
            log::info!("{:18}: {}\n", "Regex", "Options");
            log::info!("{:18}, {}\n", "Values", regex);
            RemoveOpts::Regex(regex.to_string())
        } else if let Some(list) = &self.remove_list {
            log::info!("{:18}: id", "Options");
            log::info!("{:18}, {:?}", "Values", list);
            RemoveOpts::Id(list.clone())
        } else {
            unimplemented!("Invalid removal type")
        }
    }
}

// Holder for FRB generated code.
// Parse later for rust input.
// The same as FilteringParams
// and SequenceExtractionParams
pub enum SequenceRenamingParams {
    // Tabulated file renaming
    RenameId(String),
    // Remove string
    RemoveStr(String),
    // Remove regex.
    // bool is for any string match
    RemoveRegex(String, bool),
    // Replace String
    ReplaceStr(String, String),
    // Replace regex
    ReplaceRegex(String, String, bool),
    None,
}

pub struct SequenceRenaming {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    pub output_fmt: String,
    pub params: SequenceRenamingParams,
}

impl Sequence for SequenceRenaming {}

impl SequenceRenaming {
    pub fn new() -> SequenceRenaming {
        SequenceRenaming {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            output_fmt: String::new(),
            params: SequenceRenamingParams::None,
        }
    }

    pub fn rename_sequence(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files = self.find_input_input_files(&self.input_files, None::<&str>, &input_fmt);
        let output_fmt = self.match_output_fmt(&self.output_fmt);
        let task = "Sequence Renaming";

        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let params = self.match_params();
        let rename_handle = Rename::new(&input_fmt, &datatype, output_path, &output_fmt, &params);
        rename_handle.rename(&input_files);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_params(&self) -> RenameOpts {
        match &self.params {
            SequenceRenamingParams::RenameId(path) => {
                log::info!("{:18}: {}\n", "Rename id", "Options");
                log::info!("{:18}, {:?}\n", "Path", path);
                let id_list = delimited::parse_delimited_text(Path::new(path));
                RenameOpts::RnId(id_list)
            }
            SequenceRenamingParams::RemoveStr(remove_str) => {
                log::info!("{:18}: {}\n", "Remove str", "Options");
                log::info!("{:18}, {}\n", "Values", remove_str);
                RenameOpts::RmStr(remove_str.clone())
            }
            SequenceRenamingParams::RemoveRegex(remove_regex, is_all_matches) => {
                log::info!("{:18}: {}\n", "Remove regex", "Options");
                log::info!("{:18}, {}\n", "Values", remove_regex);
                RenameOpts::RmRegex(remove_regex.clone(), *is_all_matches)
            }
            SequenceRenamingParams::ReplaceStr(old_str, new_str) => {
                log::info!("{:18}: {}\n", "Replace str", "Options");
                log::info!("{:18}, {}, {}\n", "Values", old_str, new_str);
                RenameOpts::RpStr(old_str.to_string(), new_str.to_string())
            }
            SequenceRenamingParams::ReplaceRegex(old_regex, new_regex, is_all_match) => {
                log::info!("{:18}: {}\n", "Replace regex", "Options");
                log::info!("{:18}, {}, {}\n", "Values", old_regex, new_regex);
                RenameOpts::RpRegex(old_regex.to_string(), new_regex.to_string(), *is_all_match)
            }
            SequenceRenamingParams::None => RenameOpts::None,
        }
    }
}

// A boiler plate to get FRB
// recognized the enum.
pub enum SequenceExtractionParams {
    Id(Vec<String>),
    File(String),
    Regex(String),
    None,
}
pub struct SequenceExtraction {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    pub output_fmt: String,
    pub params: SequenceExtractionParams,
}

impl Sequence for SequenceExtraction {}

impl SequenceExtraction {
    pub fn new() -> SequenceExtraction {
        SequenceExtraction {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            output_fmt: String::new(),
            params: SequenceExtractionParams::None,
        }
    }

    pub fn extract(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files = self.find_input_input_files(&self.input_files, None::<&str>, &input_fmt);
        let output_fmt = self.match_output_fmt(&self.output_fmt);
        let task = "Sequence Extraction";

        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let params = self.match_params();
        let extract_handle = Extract::new(&params, &input_fmt, &datatype);
        extract_handle.extract_sequences(&input_files, output_path, &output_fmt);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_params(&self) -> ExtractOpts {
        match &self.params {
            SequenceExtractionParams::Id(id) => {
                log::info!("{:18}: {:?}\n", "Regex", id);
                ExtractOpts::Id(id.to_vec())
            }
            SequenceExtractionParams::Regex(regex) => {
                log::info!("{:18}: {}\n", "Regex", regex);
                ExtractOpts::Regex(regex.to_string())
            }
            SequenceExtractionParams::File(file) => {
                log::info!("{:18}: {}\n", "File", file);
                let ids = self.parse_file(file);
                ExtractOpts::Id(ids)
            }
            SequenceExtractionParams::None => ExtractOpts::None,
        }
    }

    fn parse_file<P: AsRef<Path>>(&self, path: P) -> Vec<String> {
        txt::parse_text_file(path.as_ref())
    }
}

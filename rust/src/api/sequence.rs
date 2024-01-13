use std::path::{Path, PathBuf};
use std::time::Instant;

use segul::handler::align::concat::ConcatHandler;
use segul::handler::align::convert::Converter;
use segul::handler::align::filter::{Params, SeqFilter};
use segul::handler::align::split::Splitter;
use segul::handler::align::summarize::SeqStats;
use segul::handler::sequence::id::Id;
use segul::handler::sequence::partition::PartConverter;
use segul::handler::sequence::remove::{Remove, RemoveOpts};
use segul::handler::sequence::translate::Translate;
use segul::helper::files::create_output_fname_from_path;
use segul::helper::finder::{IDs, SeqFileFinder};
use segul::helper::logger::{log_input_partition, AlignSeqLogger};
use segul::helper::partition::construct_partition_path;
use segul::helper::types::{DataType, GeneticCodes, InputFmt};
use segul::helper::types::{OutputFmt, PartitionFmt};
use segul::helper::{alphabet, utils};

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
    pub dir: Option<String>,
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
            dir: None,
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
        }
    }

    pub fn convert_sequence(&self, output_fmt: String, sort: bool) {
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files =
            self.find_input_input_files(&self.input_files, self.dir.as_deref(), &input_fmt);
        let output_fmt = self.match_output_fmt(&output_fmt);
        let task = "Sequence Conversion";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let mut concat = Converter::new(&input_fmt, &output_fmt, &datatype, sort);
        concat.convert(&input_files, output_path);
    }

    // TODO: handle output directory creation in the SEGUL API
    pub fn parse_sequence_id(&self, output_fname: String, is_map: bool) {
        let output_path = Path::new(&self.output_dir)
            .join(output_fname)
            .with_extension("txt");
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files =
            self.find_input_input_files(&self.input_files, self.dir.as_deref(), &input_fmt);
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
    }

    pub fn translate_sequence(&self, table: String, reading_frame: usize, output_fmt: String) {
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let mut input_files =
            self.find_input_input_files(&self.input_files, self.dir.as_deref(), &input_fmt);
        let output_fmt = self.match_output_fmt(&output_fmt);
        let translation_table = self.match_translation_table(table);
        let task = "Sequence Translation";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let translate = Translate::new(&translation_table, &input_fmt, &datatype, &output_fmt);
        translate.translate_all(&mut input_files, reading_frame, &output_path);
    }

    fn match_translation_table(&self, table: String) -> GeneticCodes {
        table
            .parse::<GeneticCodes>()
            .expect("Invalid translation table")
    }
}

pub struct AlignmentServices {
    pub dir: Option<String>,
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
            dir: None,
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
        let mut input_files =
            self.find_input_input_files(&self.input_files, self.dir.as_deref(), &input_fmt);
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
        let output_path = PathBuf::from(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let mut input_files =
            self.find_input_input_files(&self.input_files, self.dir.as_deref(), &input_fmt);
        let task = "Alignment Summary";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let mut summary = SeqStats::new(&input_fmt, &output_path, interval, &datatype);
        summary.summarize_all(&mut input_files, &Some(output_prefix));
    }
}

pub struct SplitAlignmentServices {
    pub dir: Option<String>,
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
            dir: None,
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
    }

    // Assume the partition in the input file if none supplied.
    fn generate_input_partition_path(&self) -> PathBuf {
        match &self.input_partition {
            Some(path) => PathBuf::from(path),
            None => PathBuf::from(&self.input_file),
        }
    }
}

pub struct FilteringServices {
    pub dir: Option<String>,
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    pub is_concat: bool,
}

impl Sequence for FilteringServices {}
impl Partition for FilteringServices {}

impl FilteringServices {
    pub fn new() -> FilteringServices {
        FilteringServices {
            dir: None,
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            is_concat: false,
        }
    }

    pub fn filter_minimal_taxa(&self, percent: f64, taxon_count: Option<usize>) {
        let output_path = PathBuf::from(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files =
            self.find_input_input_files(&self.input_files, self.dir.as_deref(), &input_fmt);
        self.check_file_count(input_files.len());
        let task = "Alignment Filtering";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let taxon_count = self.count_taxa(&taxon_count, &input_files, &input_fmt, &datatype);
        let min_taxa = self.count_min_tax(percent, taxon_count);
        let params = Params::MinTax(min_taxa);
        self.log_min_taxa_param(min_taxa, taxon_count, percent);
        let mut filter = SeqFilter::new(&input_files, &input_fmt, &datatype, &output_path, &params);
        filter.filter_aln();
    }

    pub fn filter_minimal_length(&self, length: usize) {
        let output_path = PathBuf::from(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files =
            self.find_input_input_files(&self.input_files, self.dir.as_deref(), &input_fmt);
        self.check_file_count(input_files.len());
        let task = "Alignment Filtering";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let params = Params::AlnLen(length);
        self.log_other_params(&params);
        let mut filter = SeqFilter::new(&input_files, &input_fmt, &datatype, &output_path, &params);
        filter.filter_aln();
    }

    pub fn filter_parsimony_inf_count(&self, count: usize) {
        let output_path = PathBuf::from(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files =
            self.find_input_input_files(&self.input_files, self.dir.as_deref(), &input_fmt);
        self.check_file_count(input_files.len());
        let task = "Alignment Filtering";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let params = Params::ParsInf(count);
        self.log_other_params(&params);
        let mut filter = SeqFilter::new(&input_files, &input_fmt, &datatype, &output_path, &params);
        filter.filter_aln();
    }

    pub fn filter_percent_informative(&self, percent: f64) {
        let output_path = PathBuf::from(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files =
            self.find_input_input_files(&self.input_files, self.dir.as_deref(), &input_fmt);
        self.check_file_count(input_files.len());
        let task = "Alignment Filtering";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let params = Params::PercInf(percent);
        self.log_other_params(&params);
        let mut filter = SeqFilter::new(&input_files, &input_fmt, &datatype, &output_path, &params);
        filter.filter_aln();
    }

    fn count_taxa(
        &self,
        &taxon_count: &Option<usize>,
        input_files: &[PathBuf],
        input_fmt: &InputFmt,
        datatype: &DataType,
    ) -> usize {
        match taxon_count {
            Some(count) => count,
            None => IDs::new(input_files, input_fmt, datatype).id_unique().len(),
        }
    }

    fn count_min_tax(&self, percent: f64, taxon_count: usize) -> usize {
        (percent * taxon_count as f64).floor() as usize
    }

    fn log_min_taxa_param(&self, min_taxa: usize, taxon_count: usize, percent: f64) {
        self.log_info();
        log::info!("{:18}: {}", "Taxon count", taxon_count);
        log::info!("{:18}: {}%", "Percent", percent * 100.0);
        log::info!("{:18}: {}\n", "Min tax", min_taxa);
    }

    fn log_other_params(&self, params: &Params) {
        self.log_info();
        match params {
            Params::AlnLen(len) => log::info!("{:18}: {} bp\n", "Min aln len", len),
            Params::ParsInf(inf) => log::info!("{:18}: {}\n", "Min pars. inf", inf),
            Params::PercInf(perc_inf) => {
                log::info!("{:18}: {}%\n", "% pars. inf", perc_inf * 100.0)
            }
            Params::TaxonAll(taxon_id) => {
                log::info!("{:18}: {} taxa\n", "Taxon id", taxon_id.len())
            }
            _ => unreachable!("Invalid params"),
        }
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
        let input_dir = None::<PathBuf>;
        let output = Path::new(&self.output);
        let input_fmt = self.match_partition_fmt(&self.input_part_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let out_part_fmt = self.match_partition_fmt(&self.output_part_fmt);

        log_input_partition(input_dir.as_deref(), self.input_files.len());
        self.input_files.iter().map(Path::new).for_each(|input| {
            let output_path = construct_partition_path(input, &out_part_fmt);
            let converter = PartConverter::new(&output_path, &input_fmt, output, &out_part_fmt);
            converter.convert(&datatype, self.is_uncheck);
        });
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

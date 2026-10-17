use std::path::{Path, PathBuf};
use std::time::Instant;

use flutter_rust_bridge::frb;
use segul::core::align::concat::AlignmentConcatenation;
use segul::core::align::convert::AlignmentConversion;
use segul::core::align::distance::{AlignmentDistance, MatrixDiagonal, MatrixTriangle};
use segul::core::align::filter::{AlignmentFiltering, FilteringParameters};
use segul::core::align::partition::PartitionConverter;
use segul::core::align::split::AlignmentSplitting;
use segul::core::align::summarize::AlignmentSummary;
use segul::core::align::trim::{AlignmentTrimming, TrimmingParameters};
use segul::core::align::unalign::UnalignAlignment;
use segul::core::sequence::addition::SequenceAddition;
use segul::core::sequence::extract::{self, SeqExtractionParameters};
use segul::core::sequence::filter::{SeqFilteringParameters, SequenceFiltering};
use segul::core::sequence::id::SequenceID;
use segul::core::sequence::remove::{self, SeqRemovalParameters};
use segul::core::sequence::rename::{self, SeqRenamingParameters};
use segul::core::sequence::translate::SequenceTranslation;
use segul::core::sequence::transpose::SequenceTranspose;
use segul::helper::finder::{IDs, SeqFileFinder};
use segul::helper::logger::{log_input_partition, AlignSeqLogger};
use segul::helper::partition::construct_partition_path;
use segul::helper::types::{DataType, GeneticCodes, InputFmt};
use segul::helper::types::{OutputFmt, PartitionFmt};
use segul::helper::{alphabet, utils};
use segul::parser::{delimited, txt};
use segul::stats::distance::DistanceModel;

const INPUT_DIRECTORY: Option<&str> = None;

pub fn show_dna_uppercase() -> String {
    alphabet::DNA_STR_UPPERCASE.to_string()
}

trait Sequence {
    #[frb(ignore)]
    fn match_datatype(&self, datatype: &str) -> DataType {
        datatype
            .to_lowercase()
            .parse::<DataType>()
            .expect("Invalid data type")
    }

    #[frb(ignore)]
    fn match_input_fmt(&self, input_fmt: &str) -> InputFmt {
        input_fmt
            .to_lowercase()
            .parse()
            .expect("Invalid input format")
    }

    #[frb(ignore)]
    fn match_output_fmt(&self, out_fmt_str: &str) -> OutputFmt {
        out_fmt_str
            .to_lowercase()
            .parse()
            .expect("Invalid output format")
    }

    // For tasks that only write unaligned FASTA output.
    #[frb(ignore)]
    fn match_fasta_output_fmt(&self, out_fmt_str: &str) -> OutputFmt {
        match self.match_output_fmt(out_fmt_str) {
            fmt @ (OutputFmt::Fasta | OutputFmt::FastaInt) => fmt,
            _ => panic!("Only FASTA output is supported for this task"),
        }
    }

    #[frb(ignore)]
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

    #[frb(ignore)]
    fn check_file_count(&self, file_count: usize) {
        if file_count < 2 {
            panic!("At least two input_files are required for the analysis");
        }
    }
}

trait Partition {
    #[frb(ignore)]
    fn match_partition_fmt(&self, partition_fmt: &str) -> PartitionFmt {
        partition_fmt
            .to_lowercase()
            .parse()
            .expect("Invalid partition format")
    }
}

pub struct TranslationServices {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    pub output_fmt: String,
    pub table: String,
    pub reading_frame: usize,
}

impl Sequence for TranslationServices {}

impl TranslationServices {
    pub fn new() -> TranslationServices {
        TranslationServices {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            output_fmt: String::new(),
            table: String::new(),
            reading_frame: 1,
        }
    }

    pub fn translate_sequence(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let mut input_files =
            self.find_input_input_files(&self.input_files, INPUT_DIRECTORY, &input_fmt);
        let output_fmt = self.match_output_fmt(&self.output_fmt);
        let translation_table = self.match_translation_table(&self.table);
        let task = "Sequence Translation";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let translate =
            SequenceTranslation::new(&input_fmt, &translation_table, &datatype, &output_fmt);
        translate.translate(&mut input_files, self.reading_frame, &output_path);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    // Detect the reading frame of each file automatically.
    // Ignores the `reading_frame` field.
    pub fn translate_sequence_auto_frame(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files =
            self.find_input_input_files(&self.input_files, INPUT_DIRECTORY, &input_fmt);
        let output_fmt = self.match_output_fmt(&self.output_fmt);
        let translation_table = self.match_translation_table(&self.table);
        let task = "Sequence Translation (auto reading frame)";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let translate =
            SequenceTranslation::new(&input_fmt, &translation_table, &datatype, &output_fmt);
        translate.translate_all_autoframe(&input_files, output_path);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_translation_table(&self, table: &str) -> GeneticCodes {
        table
            .parse::<GeneticCodes>()
            .expect("Invalid translation table")
    }
}

pub struct SequenceConversionServices {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    pub output_fmt: String,
    pub sort: bool,
}

impl Sequence for SequenceConversionServices {}

impl SequenceConversionServices {
    pub fn new() -> SequenceConversionServices {
        SequenceConversionServices {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            output_fmt: String::new(),
            sort: false,
        }
    }

    pub fn convert_sequence(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files =
            self.find_input_input_files(&self.input_files, INPUT_DIRECTORY, &input_fmt);
        let output_fmt = self.match_output_fmt(&self.output_fmt);
        let task = "Sequence Conversion";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let concat = AlignmentConversion::new(&input_fmt, &output_fmt, &datatype, self.sort);
        concat.convert(&input_files, output_path);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }
}

pub struct IDExtractionServices {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    pub prefix: Option<String>,
    pub is_map: bool,
}

impl Sequence for IDExtractionServices {}

impl IDExtractionServices {
    pub fn new() -> IDExtractionServices {
        IDExtractionServices {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            prefix: None,
            is_map: false,
        }
    }

    pub fn extract_id(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files =
            self.find_input_input_files(&self.input_files, INPUT_DIRECTORY, &input_fmt);
        let task = "ID Extraction";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let id = SequenceID::new(
            &input_files,
            &input_fmt,
            &datatype,
            output_path,
            self.prefix.as_deref(),
        );
        if self.is_map {
            id.map_id();
        } else {
            id.get_unique();
        }

        let duration = time.elapsed();
        utils::print_execution_time(duration);
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

    pub fn concat_alignment(&self, prefix: String, out_fmt_str: String, partition_fmt: String) {
        let time = Instant::now();
        let output_dir = Path::new(&self.output_dir);
        let output_prefix = Path::new(&prefix);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let mut input_files = self.find_input_input_files(&self.input_files, None, &input_fmt);
        let output_fmt = self.match_output_fmt(&out_fmt_str);
        self.check_file_count(input_files.len());
        let partition_fmt = self.match_partition_fmt(&partition_fmt);
        let task = "Alignment Concatenation";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let mut concat = AlignmentConcatenation::new(
            &input_fmt,
            &output_dir,
            &output_fmt,
            &partition_fmt,
            output_prefix,
        );
        concat.concat(&mut input_files, &datatype);
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
        let mut summary = AlignmentSummary::new(&input_fmt, &output_path, interval, &datatype);
        summary.summarize_all(&mut input_files, Some(output_prefix).as_deref());
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    // Write a summary file for each locus instead of a combined summary.
    pub fn summarize_alignment_per_locus(&self, output_prefix: Option<String>) {
        let time = Instant::now();
        let output_path = PathBuf::from(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files = self.find_input_input_files(&self.input_files, None, &input_fmt);
        let task = "Per Locus Alignment Summary";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        // The interval only applies to the combined summary.
        let mut summary = AlignmentSummary::new(&input_fmt, &output_path, 5, &datatype);
        summary.summarize_locus(&input_files, output_prefix.as_deref());
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
        let split =
            AlignmentSplitting::new(input_path, &datatype, &input_fmt, output_path, &output_fmt);
        split.split(
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
    MaxAlnLen(usize),
    ParsInf(usize),
    MaxParsInf(usize),
    PercInf(f64),
    // Maximum proportion of missing data (0.0 - 1.0)
    MissingData(f64),
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
        let mut filter =
            AlignmentFiltering::new(&input_files, &input_fmt, &datatype, &output_path, &params);

        if self.is_concat {
            let output_fmt =
                self.match_output_fmt(&self.output_fmt.as_ref().expect("No output format"));
            let partition_fmt = self
                .match_partition_fmt(&self.partition_fmt.as_ref().expect("No partition format"));

            let prefix = Path::new(self.prefix.as_ref().expect("No prefix"));
            filter.set_concat(&output_fmt, &partition_fmt, prefix);
            filter.filter();
        } else {
            filter.filter();
        }

        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_parameters(
        &self,
        input_files: &[PathBuf],
        input_fmt: &InputFmt,
        datatype: &DataType,
    ) -> FilteringParameters {
        self.log_info();
        match &self.params {
            FilteringParams::MinTax(percent) => {
                let taxon_count = IDs::new(input_files, input_fmt, datatype).id_unique().len();
                let min_taxa = self.count_min_tax(*percent, taxon_count);
                log::info!("{:18}: {}%", "Percent", percent * 100.0);
                log::info!("{:18}: {}\n", "Min tax", min_taxa);
                FilteringParameters::MinTax(min_taxa)
            }
            FilteringParams::AlnLen(len) => {
                log::info!("{:18}: {} bp\n", "Min aln len", len);
                FilteringParameters::MinLen(*len)
            }
            FilteringParams::MaxAlnLen(len) => {
                log::info!("{:18}: {} bp\n", "Max aln len", len);
                FilteringParameters::MaxLen(*len)
            }
            FilteringParams::ParsInf(inf) => {
                log::info!("{:18}: {}\n", "Min pars. inf", inf);
                FilteringParameters::MinParsInf(*inf)
            }
            FilteringParams::MaxParsInf(inf) => {
                log::info!("{:18}: {}\n", "Max pars. inf", inf);
                FilteringParameters::MaxParsInf(*inf)
            }
            FilteringParams::MissingData(prop) => {
                log::info!("{:18}: {}%\n", "Max missing data", prop * 100.0);
                FilteringParameters::MissingData(*prop)
            }
            FilteringParams::PercInf(perc_inf) => {
                log::info!("{:18}: {}%\n", "% pars. inf", perc_inf * 100.0);
                FilteringParameters::PercInf(*perc_inf)
            }
            FilteringParams::TaxonAll(taxon_id) => {
                log::info!("{:18}: {} taxa\n", "Taxon id", taxon_id.len());
                FilteringParameters::TaxonAll(taxon_id.to_vec())
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
            let converter = PartitionConverter::new(input, &input_fmt, &final_path, &out_part_fmt);
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
        let remove_handle = remove::SequenceRemoval::new(
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

    fn match_removal_type(&self) -> SeqRemovalParameters {
        log::info!("{}", "Params");
        if let Some(regex) = &self.remove_regex {
            log::info!("{:18}: {}\n", "Regex", "Options");
            log::info!("{:18}, {}\n", "Values", regex);
            SeqRemovalParameters::Regex(regex.to_string())
        } else if let Some(list) = &self.remove_list {
            log::info!("{:18}: id", "Options");
            log::info!("{:18}, {:?}", "Values", list);
            SeqRemovalParameters::Id(list.clone())
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
        let rename_handle =
            rename::SequenceRenaming::new(&input_fmt, &datatype, output_path, &output_fmt, &params);
        rename_handle.rename(&input_files);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_params(&self) -> SeqRenamingParameters {
        match &self.params {
            SequenceRenamingParams::RenameId(path) => {
                log::info!("{:18}: {}\n", "Rename id", "Options");
                log::info!("{:18}, {:?}\n", "Path", path);
                let id_list = delimited::parse_delimited_text(Path::new(path));
                SeqRenamingParameters::RnId(id_list)
            }
            SequenceRenamingParams::RemoveStr(remove_str) => {
                log::info!("{:18}: {}\n", "Remove str", "Options");
                log::info!("{:18}, {}\n", "Values", remove_str);
                SeqRenamingParameters::RmStr(remove_str.clone())
            }
            SequenceRenamingParams::RemoveRegex(remove_regex, is_all_matches) => {
                log::info!("{:18}: {}\n", "Remove regex", "Options");
                log::info!("{:18}, {}\n", "Values", remove_regex);
                SeqRenamingParameters::RmRegex(remove_regex.clone(), *is_all_matches)
            }
            SequenceRenamingParams::ReplaceStr(old_str, new_str) => {
                log::info!("{:18}: {}\n", "Replace str", "Options");
                log::info!("{:18}, {}, {}\n", "Values", old_str, new_str);
                SeqRenamingParameters::RpStr(old_str.to_string(), new_str.to_string())
            }
            SequenceRenamingParams::ReplaceRegex(old_regex, new_regex, is_all_match) => {
                log::info!("{:18}: {}\n", "Replace regex", "Options");
                log::info!("{:18}, {}, {}\n", "Values", old_regex, new_regex);
                SeqRenamingParameters::RpRegex(
                    old_regex.to_string(),
                    new_regex.to_string(),
                    *is_all_match,
                )
            }
            SequenceRenamingParams::None => SeqRenamingParameters::None,
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
        let extract_handle = extract::SequenceExtraction::new(
            &input_fmt,
            &datatype,
            &params,
            output_path,
            &output_fmt,
        );
        extract_handle.extract(&input_files);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_params(&self) -> SeqExtractionParameters {
        match &self.params {
            SequenceExtractionParams::Id(id) => {
                log::info!("{:18}: {:?}\n", "Regex", id);
                SeqExtractionParameters::Id(id.to_vec())
            }
            SequenceExtractionParams::Regex(regex) => {
                log::info!("{:18}: {}\n", "Regex", regex);
                SeqExtractionParameters::Regex(regex.to_string())
            }
            SequenceExtractionParams::File(file) => {
                log::info!("{:18}: {}\n", "File", file);
                let ids = self.parse_file(file);
                SeqExtractionParameters::Id(ids)
            }
            SequenceExtractionParams::None => SeqExtractionParameters::None,
        }
    }

    fn parse_file<P: AsRef<Path>>(&self, path: P) -> Vec<String> {
        txt::parse_text_file(path.as_ref())
    }
}

pub struct AlignmentDistanceServices {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    // Distance model: p, jc69, k2p, tn93, or poisson
    pub model: String,
    // Matrix triangle: full, lower, or upper
    pub triangle: String,
    // Matrix diagonal: zero, blank, or max
    pub diagonal: String,
    pub prefix: Option<String>,
}

impl Sequence for AlignmentDistanceServices {}

impl AlignmentDistanceServices {
    pub fn new() -> AlignmentDistanceServices {
        AlignmentDistanceServices {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            model: String::from("p"),
            triangle: String::from("full"),
            diagonal: String::from("zero"),
            prefix: None,
        }
    }

    pub fn compute_distance(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let model = self.match_model();
        if !model.is_valid_for(&datatype) {
            panic!(
                "The {} model is not valid for {} data. Use p, jc69, k2p, or tn93 for DNA, \
                and p, jc69, or poisson for amino acid.",
                model, datatype
            );
        }
        let triangle = self
            .triangle
            .parse::<MatrixTriangle>()
            .expect("Invalid matrix triangle");
        let diagonal = self
            .diagonal
            .parse::<MatrixDiagonal>()
            .expect("Invalid matrix diagonal");
        let input_files = self.find_input_input_files(&self.input_files, None, &input_fmt);
        let task = "Pairwise Genetic Distance";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        AlignmentDistance::new(&input_fmt, &datatype, &model, output_path)
            .with_triangle(triangle)
            .with_diagonal(diagonal)
            .compute(&input_files, self.prefix.as_deref());
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_model(&self) -> DistanceModel {
        self.model
            .to_lowercase()
            .parse::<DistanceModel>()
            .expect("Invalid distance model")
    }
}

// Holder for FRB generated code.
// The same as FilteringParams.
pub enum TrimmingParams {
    // Maximum proportion of missing data per site (0.0 - 1.0)
    MissingData(f64),
    // Minimum parsimony informative count per site
    ParsInf(usize),
    None,
}

pub struct AlignmentTrimmingServices {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    pub output_fmt: String,
    pub params: TrimmingParams,
}

impl Sequence for AlignmentTrimmingServices {}

impl AlignmentTrimmingServices {
    pub fn new() -> AlignmentTrimmingServices {
        AlignmentTrimmingServices {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            output_fmt: String::new(),
            params: TrimmingParams::None,
        }
    }

    pub fn trim(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files = self.find_input_input_files(&self.input_files, None, &input_fmt);
        let output_fmt = self.match_output_fmt(&self.output_fmt);
        let task = "Alignment Trimming";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let params = self.match_params();
        let trim = AlignmentTrimming::new(
            &input_files,
            &input_fmt,
            &datatype,
            output_path,
            &output_fmt,
            &params,
        );
        trim.trim();
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_params(&self) -> TrimmingParameters {
        log::info!("{}", "Params");
        match &self.params {
            TrimmingParams::MissingData(prop) => {
                log::info!("{:18}: {}%\n", "Max missing data", prop * 100.0);
                TrimmingParameters::MissingData(*prop)
            }
            TrimmingParams::ParsInf(count) => {
                log::info!("{:18}: {}\n", "Min pars. inf", count);
                TrimmingParameters::ParsInf(*count)
            }
            TrimmingParams::None => panic!("No trimming parameter selected"),
        }
    }
}

pub struct UnalignmentServices {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    // fasta or fasta-int
    pub output_fmt: String,
}

impl Sequence for UnalignmentServices {}

impl UnalignmentServices {
    pub fn new() -> UnalignmentServices {
        UnalignmentServices {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            output_fmt: String::new(),
        }
    }

    pub fn unalign(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files = self.find_input_input_files(&self.input_files, None, &input_fmt);
        let output_fmt = self.match_fasta_output_fmt(&self.output_fmt);
        let task = "Alignment Unalignment";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let unalign = UnalignAlignment::new(
            &input_files,
            &input_fmt,
            &datatype,
            output_path,
            &output_fmt,
        );
        unalign.unalign();
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }
}

pub struct SequenceAdditionServices {
    // Files that contain the sequences to add
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    // Files that receive the sequences
    pub destination_files: Vec<String>,
    pub destination_fmt: String,
    pub output_dir: String,
    // fasta or fasta-int
    pub output_fmt: String,
    // Only write destination files that receive sequences
    pub is_added_only: bool,
}

impl Sequence for SequenceAdditionServices {}

impl SequenceAdditionServices {
    pub fn new() -> SequenceAdditionServices {
        SequenceAdditionServices {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            destination_files: Vec::new(),
            destination_fmt: String::new(),
            output_dir: String::new(),
            output_fmt: String::new(),
            is_added_only: false,
        }
    }

    // Add sequences to destination files with the same name.
    pub fn add_sequence(&self) {
        let time = Instant::now();
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let dest_fmt = self.match_input_fmt(&self.destination_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files = self.find_input_input_files(&self.input_files, None, &input_fmt);
        let dest_files: Vec<PathBuf> = self.destination_files.iter().map(PathBuf::from).collect();
        let output_fmt = self.match_fasta_output_fmt(&self.output_fmt);
        let output_path = Path::new(&self.output_dir);
        let task = "Sequence Addition";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        log::info!("{}", "Destination Files");
        log::info!("{:18}: {}\n", "File counts", dest_files.len());
        let add = SequenceAddition::new(
            &input_files,
            &input_fmt,
            &datatype,
            output_path,
            &output_fmt,
            self.is_added_only,
        );
        add.add(&dest_files, &dest_fmt);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    // Add every input sequence to the first destination file.
    pub fn add_sequence_to_single_file(&self, include_filename: bool) {
        let time = Instant::now();
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files = self.find_input_input_files(&self.input_files, None, &input_fmt);
        let dest_file = match self.destination_files.first() {
            Some(file) => PathBuf::from(file),
            None => panic!("No destination file selected"),
        };
        let output_fmt = self.match_fasta_output_fmt(&self.output_fmt);
        let output_path = Path::new(&self.output_dir);
        let task = "Sequence Addition";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let add = SequenceAddition::new(
            &input_files,
            &input_fmt,
            &datatype,
            output_path,
            &output_fmt,
            self.is_added_only,
        );
        add.add_single(&dest_file, include_filename);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }
}

// Holder for FRB generated code.
// The same as FilteringParams.
pub enum SequenceFilteringParams {
    // Minimum sequence length without gaps
    MinLength(usize),
    // Maximum sequence length without gaps
    MaxLength(usize),
    // Maximum proportion of gaps (0.0 - 1.0)
    MaxGap(f64),
    None,
}

pub struct SequenceFilteringServices {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    pub output_fmt: String,
    pub params: SequenceFilteringParams,
}

impl Sequence for SequenceFilteringServices {}

impl SequenceFilteringServices {
    pub fn new() -> SequenceFilteringServices {
        SequenceFilteringServices {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            output_fmt: String::new(),
            params: SequenceFilteringParams::None,
        }
    }

    pub fn filter_sequence(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files = self.find_input_input_files(&self.input_files, None, &input_fmt);
        let output_fmt = self.match_output_fmt(&self.output_fmt);
        let task = "Sequence Filtering";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        let params = self.match_params();
        let filter = SequenceFiltering::new(
            &input_files,
            &input_fmt,
            &datatype,
            output_path,
            &output_fmt,
            &params,
        );
        filter.filter();
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }

    fn match_params(&self) -> SeqFilteringParameters {
        log::info!("{}", "Params");
        match &self.params {
            SequenceFilteringParams::MinLength(len) => {
                log::info!("{:18}: {}\n", "Minimum length", len);
                SeqFilteringParameters::MinSequenceLength(*len)
            }
            SequenceFilteringParams::MaxLength(len) => {
                log::info!("{:18}: {}\n", "Maximum length", len);
                SeqFilteringParameters::MaxSequenceLength(*len)
            }
            SequenceFilteringParams::MaxGap(prop) => {
                log::info!("{:18}: {}%\n", "Max gaps", prop * 100.0);
                SeqFilteringParameters::PercentMaxGap(*prop)
            }
            SequenceFilteringParams::None => panic!("No filtering parameter selected"),
        }
    }
}

pub struct SequenceTransposeServices {
    pub input_files: Vec<String>,
    pub input_fmt: String,
    pub datatype: String,
    pub output_dir: String,
    // fasta or fasta-int
    pub output_fmt: String,
}

impl Sequence for SequenceTransposeServices {}

impl SequenceTransposeServices {
    pub fn new() -> SequenceTransposeServices {
        SequenceTransposeServices {
            input_files: Vec::new(),
            input_fmt: String::new(),
            datatype: String::new(),
            output_dir: String::new(),
            output_fmt: String::new(),
        }
    }

    pub fn transpose(&self) {
        let time = Instant::now();
        let output_path = Path::new(&self.output_dir);
        let input_fmt = self.match_input_fmt(&self.input_fmt);
        let datatype = self.match_datatype(&self.datatype);
        let input_files = self.find_input_input_files(&self.input_files, None, &input_fmt);
        let output_fmt = self.match_fasta_output_fmt(&self.output_fmt);
        let task = "Sequence Transposition";
        AlignSeqLogger::new(None, &input_fmt, &datatype, input_files.len()).log(task);
        SequenceTranspose::new(&input_fmt, &datatype, output_path, &output_fmt)
            .transpose(&input_files);
        let duration = time.elapsed();
        utils::print_execution_time(duration);
    }
}

#[cfg(test)]
mod test {
    use std::fs;

    use super::*;

    fn fixture_dir() -> PathBuf {
        Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("src")
            .join("tests")
    }

    fn alignment_files() -> Vec<String> {
        ["gene_1.fas", "gene_2.fas"]
            .iter()
            .map(|name| fixture_dir().join("alignments").join(name))
            .map(|path| path.to_string_lossy().into_owned())
            .collect()
    }

    // A fresh output directory under the system temp directory.
    fn output_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("segui-test-{}", name));
        if dir.exists() {
            fs::remove_dir_all(&dir).expect("Failed removing old test output");
        }
        dir
    }

    fn count_files(dir: &Path) -> usize {
        walk(dir).len()
    }

    fn walk(dir: &Path) -> Vec<PathBuf> {
        let mut files = Vec::new();
        for entry in fs::read_dir(dir).expect("Missing output directory") {
            let path = entry.expect("Invalid directory entry").path();
            if path.is_dir() {
                files.extend(walk(&path));
            } else {
                files.push(path);
            }
        }
        files
    }

    fn clean(dir: &Path) {
        fs::remove_dir_all(dir).expect("Failed removing test output");
    }

    #[test]
    fn test_compute_distance() {
        let output = output_dir("distance");
        let mut services = AlignmentDistanceServices::new();
        services.input_files = alignment_files();
        services.input_fmt = String::from("fasta");
        services.datatype = String::from("dna");
        services.output_dir = output.to_string_lossy().into_owned();
        services.model = String::from("k2p");
        services.triangle = String::from("lower");
        services.compute_distance();
        assert!(count_files(&output) >= 2);
        clean(&output);
    }

    #[test]
    #[should_panic(expected = "not valid for")]
    fn test_distance_rejects_aa_model_for_dna() {
        let mut services = AlignmentDistanceServices::new();
        services.input_files = alignment_files();
        services.input_fmt = String::from("fasta");
        services.datatype = String::from("dna");
        services.model = String::from("poisson");
        services.compute_distance();
    }

    #[test]
    fn test_trim_alignment() {
        let output = output_dir("trim");
        let mut services = AlignmentTrimmingServices::new();
        services.input_files = alignment_files();
        services.input_fmt = String::from("fasta");
        services.datatype = String::from("dna");
        services.output_dir = output.to_string_lossy().into_owned();
        services.output_fmt = String::from("fasta");
        services.params = TrimmingParams::MissingData(0.2);
        services.trim();
        // Two trimmed alignments and a trimming summary.
        assert_eq!(count_files(&output), 3);
        clean(&output);
    }

    #[test]
    fn test_unalign() {
        let output = output_dir("unalign");
        let mut services = UnalignmentServices::new();
        services.input_files = alignment_files();
        services.input_fmt = String::from("fasta");
        services.datatype = String::from("dna");
        services.output_dir = output.to_string_lossy().into_owned();
        services.output_fmt = String::from("fasta");
        services.unalign();
        let files = walk(&output);
        assert_eq!(files.len(), 2);
        let content: String = files
            .iter()
            .map(|file| fs::read_to_string(file).expect("Failed reading output"))
            .collect();
        assert!(!content.contains('-'));
        clean(&output);
    }

    #[test]
    #[should_panic(expected = "Only FASTA output")]
    fn test_unalign_rejects_nexus_output() {
        let mut services = UnalignmentServices::new();
        services.input_files = alignment_files();
        services.input_fmt = String::from("fasta");
        services.datatype = String::from("dna");
        services.output_fmt = String::from("nexus");
        services.unalign();
    }

    #[test]
    fn test_filter_sequence() {
        let output = output_dir("sequence-filter");
        let mut services = SequenceFilteringServices::new();
        services.input_files = alignment_files();
        services.input_fmt = String::from("fasta");
        services.datatype = String::from("dna");
        services.output_dir = output.to_string_lossy().into_owned();
        services.output_fmt = String::from("fasta");
        services.params = SequenceFilteringParams::MaxGap(0.2);
        services.filter_sequence();
        let content: String = walk(&output)
            .iter()
            .map(|file| fs::read_to_string(file).expect("Failed reading output"))
            .collect();
        // sample_c and sample_d have more than 20% gaps.
        assert!(content.contains("sample_a"));
        assert!(!content.contains("sample_c"));
        assert!(!content.contains("sample_d"));
        clean(&output);
    }

    #[test]
    fn test_transpose() {
        let output = output_dir("transpose");
        let mut services = SequenceTransposeServices::new();
        services.input_files = alignment_files();
        services.input_fmt = String::from("fasta");
        services.datatype = String::from("dna");
        services.output_dir = output.to_string_lossy().into_owned();
        services.output_fmt = String::from("fasta");
        services.transpose();
        // One file per sample: sample_a, sample_b, sample_c, and sample_d.
        assert_eq!(count_files(&output), 4);
        clean(&output);
    }

    #[test]
    fn test_add_sequence() {
        let output = output_dir("add");
        let destination = fixture_dir().join("destination").join("gene_1.fas");
        let mut services = SequenceAdditionServices::new();
        services.input_files = alignment_files();
        services.input_fmt = String::from("fasta");
        services.datatype = String::from("dna");
        services.destination_files = vec![destination.to_string_lossy().into_owned()];
        services.destination_fmt = String::from("fasta");
        services.output_dir = output.to_string_lossy().into_owned();
        services.output_fmt = String::from("fasta");
        services.is_added_only = true;
        services.add_sequence();
        let files = walk(&output);
        assert_eq!(files.len(), 1);
        let content = fs::read_to_string(&files[0]).expect("Failed reading output");
        assert!(content.contains("sample_x"));
        assert!(content.contains("sample_a"));
        clean(&output);
    }

    #[test]
    fn test_filter_alignment_max_length() {
        let output = output_dir("filter-max-len");
        let mut services = FilteringServices::new();
        services.input_files = alignment_files();
        services.input_fmt = String::from("fasta");
        services.datatype = String::from("dna");
        services.output_dir = output.to_string_lossy().into_owned();
        services.params = FilteringParams::MaxAlnLen(12);
        services.filter();
        let files = walk(&output);
        // Only gene_2 (12 bp) is at most 12 bp long.
        assert_eq!(files.len(), 1);
        assert!(files[0].to_string_lossy().contains("gene_2"));
        clean(&output);
    }
}

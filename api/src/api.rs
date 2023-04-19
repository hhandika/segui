use std::path::{Path, PathBuf};

use segul::handler::concat::ConcatHandler;
use segul::handler::convert::Converter;
use segul::helper::alphabet;
use segul::helper::finder::Files;
use segul::helper::types::{DataType, InputFmt};
use segul::helper::types::{OutputFmt, PartitionFmt};

pub fn show_dna_uppercase() -> String {
    alphabet::DNA_STR_UPPERCASE.to_string()
}

pub struct SegulApi {
    pub dir_path: String,
    pub file_fmt: String,
    pub datatype: String,
    pub output: String,
}

impl SegulApi {
    pub fn new() -> SegulApi {
        SegulApi {
            dir_path: String::new(),
            file_fmt: String::new(),
            datatype: String::new(),
            output: String::new(),
        }
    }

    pub fn concat_alignment(&self, output_fmt: String, partition_fmt: String) {
        let path = Path::new(&self.dir_path);
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype();
        let mut files = Files::new(path, &input_fmt).find();
        let output = self.set_output_ext(&output_fmt);
        let output_fmt = self.match_output_fmt(&output_fmt);
        let partition_fmt = self.match_partition_fmt(&partition_fmt);
        let mut concat = ConcatHandler::new(&input_fmt, &output, &output_fmt, &partition_fmt);
        concat.concat_alignment(&mut files, &datatype);
    }

    pub fn convert_sequence(&self, output_fmt: String, sort: bool) {
        let path = Path::new(&self.dir_path);
        let input_fmt = self.match_input_fmt();
        let datatype = self.match_datatype();
        let mut files = Files::new(path, &input_fmt).find();
        let output_fmt = self.match_output_fmt(&output_fmt);
        let mut concat = Converter::new(&input_fmt, &output_fmt, &datatype, sort);
        concat.convert(&mut files, Path::new(&self.output));
    }

    fn match_input_fmt(&self) -> InputFmt {
        match self.file_fmt.to_lowercase().as_str() {
            "fasta" => InputFmt::Fasta,
            "phylip" => InputFmt::Phylip,
            "nexus" => InputFmt::Nexus,
            _ => InputFmt::Fasta,
        }
    }

    fn match_output_fmt(&self, output_fmt: &str) -> OutputFmt {
        match output_fmt.to_lowercase().as_str() {
            "fasta" => OutputFmt::Fasta,
            "phylip" => OutputFmt::Phylip,
            "nexus" => OutputFmt::Nexus,
            "fasta interleaved" => OutputFmt::FastaInt,
            "phylip interleaved" => OutputFmt::NexusInt,
            "nexus interleaved" => OutputFmt::PhylipInt,
            _ => unreachable!("Output format is not supported"),
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

    fn set_output_ext(&self, output_fmt: &str) -> PathBuf {
        let ext = match output_fmt.to_lowercase().as_str() {
            "fasta" | "fasta interleaved" => String::from("fas"),
            "nexus" | "nexus interleaved" => String::from("nex"),
            "phylip" | "phylip interleaved" => String::from("phy"),
            _ => unreachable!("Output format is not supported"),
        };
        let output = PathBuf::from(&self.output);
        output.with_extension(ext)
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

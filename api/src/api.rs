use std::path::Path;

use segul::handler::concat::ConcatHandler;
use segul::helper::alphabet;
use segul::helper::finder::Files;
use segul::helper::types::OutputFmt;
use segul::helper::types::{DataType, InputFmt};

pub fn show_dna_uppercase() -> String {
    alphabet::DNA_STR_UPPERCASE.to_string()
}

pub fn concat_alignment(dir_path: String, file_fmt: String, datatype: String, output: String) {
    let path = Path::new(&dir_path);
    let input_fmt = match file_fmt.to_lowercase().as_str() {
        "fasta" => InputFmt::Fasta,
        "phylip" => InputFmt::Phylip,
        "nexus" => InputFmt::Nexus,
        _ => InputFmt::Fasta,
    };

    let datatype = match datatype.to_lowercase().as_str() {
        "dna" => DataType::Dna,
        "amino acid" => DataType::Aa,
        "ignore" => DataType::Ignore,
        _ => DataType::Dna,
    };

    let mut files = Files::new(path, &input_fmt).find();

    let mut concat = ConcatHandler::new(
        &input_fmt,
        Path::new(&output),
        &OutputFmt::Fasta,
        &segul::helper::types::PartitionFmt::Nexus,
    );
    concat.concat_alignment(&mut files, &datatype);
}

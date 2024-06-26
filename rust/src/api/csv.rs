//! Parse CSV into HashMap

use std::{
    collections::HashMap,
    fs::File,
    io::{BufRead, BufReader},
    path::Path,
};

use flutter_rust_bridge::frb;

use polars::{
    error::PolarsResult,
    frame::DataFrame,
    io::{csv::CsvReader, SerReader},
};

pub enum CsvSegulType {
    /// Locus summary from alignment summary
    LocusSummary,
    /// Taxon summary from alignment summary
    TaxonSummary,
    /// Whole read summary from raw read summary
    /// Add default settings
    WholeReadSummary,
    /// Per read summary from raw read summary
    /// When the complete setting is used.
    PerReadSummary,
    /// Contig summary from assembly summary
    ContigSummary,
}

const ID_COLOMN: [&str; 4] = ["locus", "taxon", "name", "path"];

trait PolarDataFrame {
    #[frb(ignore)]
    fn get_dataframe(&self, input_path: &Path) -> PolarsResult<DataFrame> {
        let df = CsvReader::from_path(input_path)?
            .infer_schema(None)
            .has_header(true)
            .finish()?;
        Ok(df)
    }
}

pub struct CsvSummaryServices {
    pub input_path: String,
    pub segul_type: CsvSegulType,
}

impl PolarDataFrame for CsvSummaryServices {}

impl CsvSummaryServices {
    pub fn new(input_path: String, segul_type: CsvSegulType) -> CsvSummaryServices {
        CsvSummaryServices {
            input_path,
            segul_type,
        }
    }

    pub fn get_line(&self) -> usize {
        let rdr = File::open(&self.input_path).expect("Error parsing file.");
        let buffer = BufReader::new(rdr);
        let line_count = buffer.lines().map_while(|ok| ok.ok()).count();
        line_count
    }

    pub fn get_column_names(&self) -> Vec<String> {
        let df: DataFrame = self
            .get_dataframe(Path::new(&self.input_path))
            .expect("Error parsing file.");
        // Filter column names that is not id column
        df.get_column_names()
            .iter()
            .map(|s| s.to_string())
            .filter(|s| !self.is_id_column_names(s))
            .collect()
    }

    pub fn parse_columns(&self, col_name: String) -> HashMap<String, String> {
        let col_names = self.match_type_id_column(col_name);
        let mut map = HashMap::new();
        let new_df = self
            .select_columns(&col_names)
            .expect("Error parsing file.");
        new_df.iter().for_each(|s| {
            let file = s.get(0).expect("Failed getting locus column").to_string();
            let num_reads = s.get(1).expect("Failed getting a column").to_string();
            map.insert(file, num_reads);
        });
        map
    }

    fn match_type_id_column(&self, col_name: String) -> Vec<String> {
        match self.segul_type {
            CsvSegulType::LocusSummary => Vec::from([String::from("locus"), col_name]),
            CsvSegulType::TaxonSummary => Vec::from([String::from("taxon"), col_name]),
            CsvSegulType::WholeReadSummary => Vec::from([String::from("file_name"), col_name]),
            CsvSegulType::ContigSummary => Vec::from([String::from("contig_name"), col_name]),
            _ => unreachable!("Invalid type"),
        }
    }

    fn select_columns(&self, col_names: &[String]) -> PolarsResult<DataFrame> {
        let df: DataFrame = self.get_dataframe(Path::new(&self.input_path))?;
        Ok(df.select(col_names)?)
    }

    fn is_id_column_names(&self, col_name: &str) -> bool {
        ID_COLOMN.contains(&col_name)
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_get_line() {
        let csv = CsvSummaryServices::new(
            String::from("tests/data/limited_oli_locus_summary.csv"),
            CsvSegulType::LocusSummary,
        );
        assert_eq!(csv.get_line(), 95);
    }
}

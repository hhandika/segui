//! Parse CSV into HashMap

use std::{
    collections::HashMap,
    fs::File,
    io::{BufRead, BufReader},
    path::Path,
};

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

trait PolarDataFrame {
    fn get_dataframe(&self, input_path: &Path) -> PolarsResult<DataFrame> {
        let df = CsvReader::from_path(input_path)?
            .infer_schema(None)
            .has_header(true)
            .finish()?;
        Ok(df)
    }
}

pub struct LocusSummaryServices {
    pub input_path: String,
}

impl PolarDataFrame for LocusSummaryServices {}

impl LocusSummaryServices {
    pub fn new(input_path: String) -> LocusSummaryServices {
        LocusSummaryServices { input_path }
    }

    pub fn get_line(&self) -> usize {
        let rdr = File::open(&self.input_path).expect("Error parsing file.");
        let buffer = BufReader::new(rdr);
        let line_count = buffer.lines().map_while(|ok| ok.ok()).count();
        line_count
    }

    pub fn parse_columns(&self, col_name: String) -> HashMap<String, usize> {
        let col_names = ["locus", &col_name];
        let mut map = HashMap::new();
        let new_df = self.select_columns(col_names).expect("Error parsing file.");
        new_df.iter().for_each(|s| {
            let file = s.get(0).expect("Failed getting locus column").to_string();
            let num_reads =
                self.parse_string_to_usize(&s.get(1).expect("Failed getting a column").to_string());
            map.insert(file, num_reads);
        });
        map
    }

    fn select_columns(&self, col_names: [&str; 2]) -> PolarsResult<DataFrame> {
        let df: DataFrame = self.get_dataframe(Path::new(&self.input_path))?;
        Ok(df.select(col_names)?)
    }

    fn parse_string_to_usize(&self, value: &str) -> usize {
        value.parse::<usize>().unwrap_or(0)
    }
}

use std::path::Path;

use segul_core::stats::align_report::{AlignReport, SiteTypeSummary};

/// Loads `alignment-report.json` for the interactive alignment report.
pub struct AlignReportServices {
    pub path: String,
}

impl AlignReportServices {
    pub fn new() -> AlignReportServices {
        AlignReportServices {
            path: String::new(),
        }
    }

    pub fn load(&self) -> anyhow::Result<AlignReportData> {
        let report = AlignReport::from_path(Path::new(&self.path))?;
        Ok(AlignReportData::from(&report))
    }
}

// Counts are sent as f64 so Dart charts can use them directly.
// They stay exact up to 2^53. Loci and taxa are sent in columns, so
// thousands of rows cross the bridge as a few typed lists.

pub struct AlignReportData {
    /// `dna` or `aa`.
    pub datatype: String,
    pub summary: AlignOverviewData,
    /// Share of taxa in percent, from 100 down, with the loci that have
    /// at least that share.
    pub completeness_percent: Vec<f64>,
    pub completeness_loci: Vec<f64>,
    pub char_names: Vec<String>,
    pub char_counts: Vec<f64>,
    pub loci: AlignLociData,
    pub taxa: AlignTaxaData,
}

pub struct AlignOverviewData {
    pub taxa: f64,
    pub loci: f64,
    pub sites: f64,
    pub chars: f64,
    pub missing: f64,
    pub prop_missing: f64,
    pub gc: Option<f64>,
    pub at: Option<f64>,
    pub min_sites: f64,
    pub max_sites: f64,
    pub mean_sites: f64,
    pub min_taxa: f64,
    pub max_taxa: f64,
    pub mean_taxa: f64,
    pub conserved: SiteTypeData,
    pub variable: SiteTypeData,
    pub informative: SiteTypeData,
}

pub struct SiteTypeData {
    pub loci: f64,
    pub prop_loci: f64,
    pub sites: f64,
    pub prop_sites: f64,
    pub min: f64,
    pub max: f64,
    pub mean: f64,
}

/// One value per locus in each column, in the order of `names`.
pub struct AlignLociData {
    pub names: Vec<String>,
    pub paths: Vec<String>,
    pub ntax: Vec<f64>,
    pub chars: Vec<f64>,
    pub sites: Vec<f64>,
    pub conserved: Vec<f64>,
    pub variable: Vec<f64>,
    pub informative: Vec<f64>,
    pub missing: Vec<f64>,
    pub prop_missing: Vec<f64>,
    /// DNA only.
    pub gc: Option<Vec<f64>>,
}

/// One value per taxon in each column, in the order of `names`.
pub struct AlignTaxaData {
    pub names: Vec<String>,
    pub loci: Vec<f64>,
    pub chars: Vec<f64>,
    pub missing: Vec<f64>,
    pub prop_missing: Vec<f64>,
    /// DNA only.
    pub gc: Option<Vec<f64>>,
}

impl From<&AlignReport> for AlignReportData {
    fn from(report: &AlignReport) -> Self {
        let s = &report.summary;
        let is_dna = report.datatype == "dna";
        let loci = &report.loci;
        let taxa = &report.taxa;
        AlignReportData {
            datatype: report.datatype.clone(),
            summary: AlignOverviewData {
                taxa: s.taxa as f64,
                loci: s.loci as f64,
                sites: s.sites as f64,
                chars: s.chars as f64,
                missing: s.missing as f64,
                prop_missing: s.prop_missing,
                gc: s.gc,
                at: s.at,
                min_sites: s.min_sites as f64,
                max_sites: s.max_sites as f64,
                mean_sites: s.mean_sites,
                min_taxa: s.min_taxa as f64,
                max_taxa: s.max_taxa as f64,
                mean_taxa: s.mean_taxa,
                conserved: SiteTypeData::from(&s.conserved),
                variable: SiteTypeData::from(&s.variable),
                informative: SiteTypeData::from(&s.informative),
            },
            completeness_percent: report
                .completeness
                .iter()
                .map(|c| c.percent as f64)
                .collect(),
            completeness_loci: report.completeness.iter().map(|c| c.loci as f64).collect(),
            char_names: report.chars.keys().cloned().collect(),
            char_counts: report.chars.values().map(|&c| c as f64).collect(),
            loci: AlignLociData {
                names: loci.iter().map(|l| l.name.clone()).collect(),
                paths: loci.iter().map(|l| l.path.clone()).collect(),
                ntax: loci.iter().map(|l| l.ntax as f64).collect(),
                chars: loci.iter().map(|l| l.chars as f64).collect(),
                sites: loci.iter().map(|l| l.sites as f64).collect(),
                conserved: loci.iter().map(|l| l.conserved as f64).collect(),
                variable: loci.iter().map(|l| l.variable as f64).collect(),
                informative: loci.iter().map(|l| l.informative as f64).collect(),
                missing: loci.iter().map(|l| l.missing as f64).collect(),
                prop_missing: loci.iter().map(|l| l.prop_missing).collect(),
                gc: is_dna.then(|| loci.iter().map(|l| l.gc.unwrap_or(0.0)).collect()),
            },
            taxa: AlignTaxaData {
                names: taxa.iter().map(|t| t.name.clone()).collect(),
                loci: taxa.iter().map(|t| t.loci as f64).collect(),
                chars: taxa.iter().map(|t| t.chars as f64).collect(),
                missing: taxa.iter().map(|t| t.missing as f64).collect(),
                prop_missing: taxa.iter().map(|t| t.prop_missing).collect(),
                gc: is_dna.then(|| taxa.iter().map(|t| t.gc.unwrap_or(0.0)).collect()),
            },
        }
    }
}

impl From<&SiteTypeSummary> for SiteTypeData {
    fn from(sites: &SiteTypeSummary) -> Self {
        SiteTypeData {
            loci: sites.loci as f64,
            prop_loci: sites.prop_loci,
            sites: sites.sites as f64,
            prop_sites: sites.prop_sites,
            min: sites.min as f64,
            max: sites.max as f64,
            mean: sites.mean,
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    const REPORT: &str = r#"{"datatype":"dna","summary":{"taxa":3,"loci":2,"sites":30,"chars":80,"missing":4,"prop_missing":0.05,"gc":0.4,"at":0.6,"nucleotides":76,"min_sites":10,"max_sites":20,"mean_sites":15.0,"min_taxa":2,"max_taxa":3,"mean_taxa":2.5,"conserved":{"loci":2,"prop_loci":1.0,"sites":20,"prop_sites":0.67,"min":8,"max":12,"mean":10.0},"variable":{"loci":2,"prop_loci":1.0,"sites":10,"prop_sites":0.33,"min":2,"max":8,"mean":5.0},"informative":{"loci":1,"prop_loci":0.5,"sites":3,"prop_sites":0.1,"min":0,"max":3,"mean":1.5}},"completeness":[{"percent":100,"loci":1},{"percent":95,"loci":2}],"chars":{"-":4,"A":40,"C":36},"loci":[{"path":"a/l1.fas","name":"l1","ntax":2,"chars":20,"sites":10,"conserved":8,"variable":2,"informative":0,"missing":0,"prop_missing":0.0,"gc":0.5,"at":0.5},{"path":"a/l2.fas","name":"l2","ntax":3,"chars":60,"sites":20,"conserved":12,"variable":8,"informative":3,"missing":4,"prop_missing":0.067,"gc":0.35,"at":0.65}],"taxa":[{"name":"x","loci":2,"chars":30,"missing":0,"prop_missing":0.0,"gc":0.4,"at":0.6}]}"#;

    #[test]
    fn test_report_columns() {
        let report = AlignReport::from_json(REPORT).unwrap();
        let data = AlignReportData::from(&report);
        assert_eq!(data.loci.names, vec!["l1", "l2"]);
        assert_eq!(data.loci.sites, vec![10.0, 20.0]);
        assert_eq!(data.loci.gc, Some(vec![0.5, 0.35]));
        assert_eq!(data.taxa.loci, vec![2.0]);
        assert_eq!(data.completeness_percent, vec![100.0, 95.0]);
        assert_eq!(data.char_names, vec!["-", "A", "C"]);
        assert_eq!(data.summary.informative.sites, 3.0);
    }
}

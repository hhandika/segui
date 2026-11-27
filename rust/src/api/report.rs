use std::fs;
use std::path::{Path, PathBuf};
use std::sync::{OnceLock, RwLock};

use flutter_rust_bridge::frb;
use segul_core::report::methods::{render_methods_from_path, MethodsFormat};
use segul_core::report::paths::resolve_portable_path;
use segul_core::report::replay::{replay_report, replay_workflow, ReplayOptions};
use segul_core::report::verify::{verify_report, FileVerifyResult, FileVerifyStatus, VerifyScope};
use segul_core::report::workflow::WorkflowRecipe;
use segul_core::report::{ChecksumMode, FrontendInfo, ReportContext, RunReport};

const DEFAULT_SEGUI_VERSION: &str = "1.2.1";

static REPORT_CONFIG: OnceLock<RwLock<(Option<ChecksumMode>, String)>> = OnceLock::new();

fn config_lock() -> &'static RwLock<(Option<ChecksumMode>, String)> {
    REPORT_CONFIG.get_or_init(|| RwLock::new((None, DEFAULT_SEGUI_VERSION.to_string())))
}

/// Update active SEGUI checksum mode (`none`, `outputs`, `inputs`, `all`) and app version.
pub fn set_report_config(checksum_mode: String, app_version: String) -> anyhow::Result<()> {
    let parsed: ChecksumMode = checksum_mode.parse().map_err(anyhow::Error::msg)?;
    let mut guard = config_lock()
        .write()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    guard.0 = Some(parsed);
    if !app_version.trim().is_empty() {
        guard.1 = app_version.trim().to_string();
    }
    Ok(())
}

/// Build a `ReportContext` using the currently configured GUI checksum mode and version.
#[frb(ignore)]
pub(crate) fn current_report_context() -> ReportContext {
    let guard = config_lock()
        .read()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    let mode = ChecksumMode::resolve(guard.0);
    ReportContext::new(FrontendInfo::gui(guard.1.clone()), mode)
}

/// Summary view of a v2 `RunReport` exposed across the Flutter Rust Bridge.
pub struct RunReportSummary {
    pub schema_version: u32,
    pub kind: String,
    pub kind_label: String,
    pub frontend_name: String,
    pub frontend_version: String,
    pub segul_core_version: String,
    pub timestamp_utc: String,
    pub elapsed_ms: u64,
    pub os: String,
    pub arch: String,
    pub threads: usize,
    pub checksum_mode: String,
    pub source_mode: String,
    pub base_dir: String,
    pub output_dir: String,
    pub primary_inputs: Vec<ReportFileDto>,
    pub auxiliary_inputs: Vec<ReportAuxFileDto>,
    pub outputs: Vec<ReportOutputFileDto>,
    pub parent_reports: Vec<ParentReportDto>,
    pub parameters_json: String,
    pub has_statistics: bool,
}

/// Input file entry recorded inside `report.json`.
pub struct ReportFileDto {
    pub path: String,
    pub size_bytes: u64,
    pub sha256: Option<String>,
}

/// Auxiliary input file entry recorded inside `report.json`.
pub struct ReportAuxFileDto {
    pub role: String,
    pub path: String,
    pub size_bytes: u64,
    pub sha256: Option<String>,
}

/// Output file entry recorded inside `report.json`.
pub struct ReportOutputFileDto {
    pub role: String,
    pub path: String,
    pub size_bytes: u64,
    pub sha256: Option<String>,
}

/// Parent report lineage reference recorded inside `report.json`.
pub struct ParentReportDto {
    pub path: String,
    pub kind: String,
    pub report_sha256: Option<String>,
    pub matched_files: Vec<String>,
}

/// Result of verifying recorded SHA-256 digests and sizes in `report.json`.
pub struct VerifyReportDto {
    pub report_path: String,
    pub scope: String,
    pub passed: bool,
    pub checked: usize,
    pub ok: usize,
    pub mismatched: usize,
    pub missing: usize,
    pub unchecked: usize,
    pub inputs: Vec<VerifyFileDto>,
    pub auxiliary: Vec<VerifyFileDto>,
    pub outputs: Vec<VerifyFileDto>,
    pub parents: Vec<VerifyFileDto>,
}

/// Verification outcome for a single recorded file.
pub struct VerifyFileDto {
    pub role: Option<String>,
    pub path: String,
    pub resolved_path: String,
    pub expected_size_bytes: u64,
    pub actual_size_bytes: Option<u64>,
    pub status: String,
    pub detail: Option<String>,
}

/// Parsed replay payload for hydrating a SEGUI tool form from `report.json`.
pub struct ReplaySpecDto {
    pub kind: String,
    pub base_dir: String,
    pub primary_paths: Vec<String>,
    pub auxiliary_roles: Vec<String>,
    pub auxiliary_paths: Vec<String>,
    pub parameters_json: String,
    pub output_dir: String,
}

/// Operations on unified `report.json` and `segul-workflow.json` files.
pub struct RunReportServices {}

impl RunReportServices {
    /// Inspect a v2 `report.json` file and return its provenance, manifests, and parameters.
    pub fn inspect(report_path: String) -> anyhow::Result<RunReportSummary> {
        let report = RunReport::from_path(Path::new(&report_path))?;
        let parameters_json = serde_json::to_string_pretty(&report.parameters)?;
        let source_mode = serde_json::to_value(report.inputs.source_mode)?
            .as_str()
            .unwrap_or("files")
            .to_string();
        Ok(RunReportSummary {
            schema_version: report.schema_version,
            kind: report.kind.to_string(),
            kind_label: report.kind.label().to_string(),
            frontend_name: report.run.frontend.name,
            frontend_version: report.run.frontend.version,
            segul_core_version: report.run.segul_core_version,
            timestamp_utc: report.run.timestamp_utc,
            elapsed_ms: report.run.elapsed_ms,
            os: report.run.platform.os,
            arch: report.run.platform.arch,
            threads: report.run.platform.threads,
            checksum_mode: report.run.checksum_mode.to_string(),
            source_mode,
            base_dir: report.inputs.base_dir,
            output_dir: report.outputs.output_dir,
            primary_inputs: report
                .inputs
                .primary
                .into_iter()
                .map(|f| ReportFileDto {
                    path: f.path,
                    size_bytes: f.size_bytes,
                    sha256: f.sha256,
                })
                .collect(),
            auxiliary_inputs: report
                .inputs
                .auxiliary
                .into_iter()
                .map(|a| ReportAuxFileDto {
                    role: a.role,
                    path: a.path,
                    size_bytes: a.size_bytes,
                    sha256: a.sha256,
                })
                .collect(),
            outputs: report
                .outputs
                .files
                .into_iter()
                .map(|o| ReportOutputFileDto {
                    role: o.role,
                    path: o.path,
                    size_bytes: o.size_bytes,
                    sha256: o.sha256,
                })
                .collect(),
            parent_reports: report
                .run
                .parent_reports
                .into_iter()
                .map(|p| ParentReportDto {
                    path: p.path,
                    kind: p.kind.to_string(),
                    report_sha256: p.sha256,
                    matched_files: p.matched_files,
                })
                .collect(),
            parameters_json,
            has_statistics: report.statistics.is_some(),
        })
    }

    /// Verify SHA-256 checksums and file sizes recorded in `report_path`.
    pub fn verify(
        report_path: String,
        scope: String,
        input_dir: Option<String>,
        output_dir: Option<String>,
    ) -> anyhow::Result<VerifyReportDto> {
        let parsed_scope: VerifyScope = scope.parse().map_err(anyhow::Error::msg)?;
        let res = verify_report(
            Path::new(&report_path),
            input_dir.as_deref().map(Path::new),
            output_dir.as_deref().map(Path::new),
            parsed_scope,
        )?;
        Ok(VerifyReportDto {
            report_path: res.report_path,
            scope: res.scope.to_string(),
            passed: res.passed,
            checked: res.checked,
            ok: res.ok,
            mismatched: res.mismatched,
            missing: res.missing,
            unchecked: res.unchecked,
            inputs: res.inputs.into_iter().map(map_verify_entry).collect(),
            auxiliary: res.auxiliary.into_iter().map(map_verify_entry).collect(),
            outputs: res.outputs.into_iter().map(map_verify_entry).collect(),
            parents: res.parents.into_iter().map(map_verify_entry).collect(),
        })
    }

    /// Resolve recorded paths and parameters from `report_path` so SEGUI can pre-fill a tool form.
    pub fn load_replay_spec(report_path: String) -> anyhow::Result<ReplaySpecDto> {
        let report_file = Path::new(&report_path);
        let report = RunReport::from_path(report_file)?;
        let base = resolve_portable_path(Path::new("."), &report.inputs.base_dir);
        let primary_paths = report
            .inputs
            .primary
            .iter()
            .map(|f| {
                resolve_portable_path(&base, &f.path)
                    .to_string_lossy()
                    .into_owned()
            })
            .collect();
        let mut auxiliary_roles = Vec::with_capacity(report.inputs.auxiliary.len());
        let mut auxiliary_paths = Vec::with_capacity(report.inputs.auxiliary.len());
        for aux in &report.inputs.auxiliary {
            auxiliary_roles.push(aux.role.clone());
            auxiliary_paths.push(
                resolve_portable_path(&base, &aux.path)
                    .to_string_lossy()
                    .into_owned(),
            );
        }
        let parameters_json = serde_json::to_string_pretty(&report.parameters)?;
        Ok(ReplaySpecDto {
            kind: report.kind.to_string(),
            base_dir: base.to_string_lossy().into_owned(),
            primary_paths,
            auxiliary_roles,
            auxiliary_paths,
            parameters_json,
            output_dir: resolve_portable_path(Path::new("."), &report.outputs.output_dir)
                .to_string_lossy()
                .into_owned(),
        })
    }

    /// Replay a `report.json` or `segul-workflow.json` into `output_dir`, returning the new report.
    pub fn replay(
        report_path: String,
        output_dir: String,
        input_dir: Option<String>,
        checksum_mode: Option<String>,
        verify_inputs: bool,
    ) -> anyhow::Result<String> {
        let ctx = current_report_context();
        let parsed_checksum = checksum_mode
            .as_deref()
            .map(|s| s.parse::<ChecksumMode>().map_err(anyhow::Error::msg))
            .transpose()?;
        let opts = ReplayOptions {
            input_base: input_dir.map(PathBuf::from),
            output_dir: Some(PathBuf::from(&output_dir)),
            verify_inputs,
            checksum_mode: Some(parsed_checksum.unwrap_or(ctx.checksum_mode)),
            frontend: ctx.frontend,
        };
        let path = Path::new(&report_path);
        if RunReport::is_run_report_file(path) {
            let new_report = replay_report(path, &opts)?;
            let prefix = extract_prefix(new_report.typed_parameters().ok());
            Ok(
                segul_core::report::report_path(Path::new(&output_dir), prefix.as_deref())
                    .to_string_lossy()
                    .into_owned(),
            )
        } else {
            let reports = replay_workflow(path, &opts)?;
            let last_dir = reports
                .last()
                .map(|r| resolve_portable_path(Path::new("."), &r.outputs.output_dir))
                .unwrap_or_else(|| PathBuf::from(&output_dir));
            let prefix = reports
                .last()
                .and_then(|r| extract_prefix(r.typed_parameters().ok()));
            Ok(
                segul_core::report::report_path(&last_dir, prefix.as_deref())
                    .to_string_lossy()
                    .into_owned(),
            )
        }
    }

    /// Export a multi-step `segul-workflow.json` by walking `parent_reports` from `report_path`.
    pub fn export_workflow(
        report_path: String,
        output_path: String,
        name: Option<String>,
    ) -> anyhow::Result<String> {
        let recipe = WorkflowRecipe::from_report_chain(Path::new(&report_path), name.as_deref())?;
        recipe.write(Path::new(&output_path))?;
        Ok(output_path)
    }

    /// Export a `segul-workflow.json` from an ordered list of `report.json` paths.
    pub fn export_workflow_from_reports(
        report_paths: Vec<String>,
        output_path: String,
        name: Option<String>,
    ) -> anyhow::Result<String> {
        let paths: Vec<PathBuf> = report_paths.into_iter().map(PathBuf::from).collect();
        let recipe = WorkflowRecipe::from_report_paths(&paths, name.as_deref())?;
        recipe.write(Path::new(&output_path))?;
        Ok(output_path)
    }

    /// Render publication-ready Methods text (Markdown or plain text) from `report_path`.
    pub fn export_methods(
        report_path: String,
        format: String,
        include_chain: bool,
        output_path: Option<String>,
    ) -> anyhow::Result<String> {
        let fmt: MethodsFormat = format.parse().map_err(anyhow::Error::msg)?;
        let text = render_methods_from_path(Path::new(&report_path), include_chain, fmt)?;
        if let Some(out) = output_path {
            let out_file = Path::new(&out);
            if let Some(parent) = out_file.parent() {
                if !parent.as_os_str().is_empty() {
                    fs::create_dir_all(parent)?;
                }
            }
            fs::write(out_file, &text)?;
        }
        Ok(text)
    }
}

fn map_verify_entry(entry: FileVerifyResult) -> VerifyFileDto {
    let (status, detail) = match entry.status {
        FileVerifyStatus::Ok => (String::from("ok"), None),
        FileVerifyStatus::Unchecked => (String::from("unchecked"), None),
        FileVerifyStatus::Missing => (String::from("missing"), Some(String::from("File missing"))),
        FileVerifyStatus::Mismatch { expected, actual } => (
            String::from("mismatch"),
            Some(format!("Expected {expected}, got {actual}")),
        ),
        FileVerifyStatus::SizeMismatch { expected, actual } => (
            String::from("size_mismatch"),
            Some(format!("Expected {expected} bytes, got {actual}")),
        ),
    };
    VerifyFileDto {
        role: entry.role,
        path: entry.path,
        resolved_path: entry.resolved_path,
        expected_size_bytes: entry.expected_size_bytes,
        actual_size_bytes: entry.actual_size_bytes,
        status,
        detail,
    }
}

fn extract_prefix(params: Option<segul_core::report::TaskParameters>) -> Option<String> {
    use segul_core::report::TaskParameters::*;
    match params? {
        AlignSummary(p) => p.prefix,
        AlignDistance(p) => p.prefix,
        AlignConcat(p) => p.prefix,
        AlignFilter(p) => p.prefix,
        AlignSplit(p) => p.prefix,
        ContigSummary(p) => p.prefix,
        ReadSummary(p) => p.prefix,
        MafSummary(p) => p.prefix,
        MafConvert(p) => p.prefix,
        SequenceId(p) => p.prefix,
        _ => None,
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use crate::api::contig::ContigServices;
    use crate::api::progress::RunMonitor;

    #[test]
    fn test_report_inspect_verify_replay_and_exports() {
        let tmp = std::env::temp_dir().join("segui-test-report-api");
        let _ = fs::remove_dir_all(&tmp);
        let out1 = tmp.join("run1");
        let out2 = tmp.join("run2");
        fs::create_dir_all(&out1).unwrap();

        set_report_config(String::from("all"), String::from("1.2.1")).unwrap();

        let contig_fixture = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("src")
            .join("tests");
        let mut contig_svc = ContigServices::new();
        contig_svc.files = vec![contig_fixture
            .join("alignments")
            .join("gene_1.fas")
            .to_string_lossy()
            .into_owned()];
        contig_svc.file_fmt = String::from("fasta");
        contig_svc.output_dir = out1.to_string_lossy().into_owned();
        let report_path = contig_svc.summarize(None, &RunMonitor::new()).unwrap();

        let summary = RunReportServices::inspect(report_path.clone()).unwrap();
        assert_eq!(summary.schema_version, 2);
        assert_eq!(summary.frontend_name, "segui");
        assert_eq!(summary.checksum_mode, "all");

        let verified =
            RunReportServices::verify(report_path.clone(), String::from("all"), None, None)
                .unwrap();
        assert!(verified.passed);

        let replayed = RunReportServices::replay(
            report_path.clone(),
            out2.to_string_lossy().into_owned(),
            None,
            Some(String::from("all")),
            true,
        )
        .unwrap();
        assert!(Path::new(&replayed).is_file());

        let wf_path = tmp.join("segul-workflow.json");
        RunReportServices::export_workflow(
            report_path.clone(),
            wf_path.to_string_lossy().into_owned(),
            Some(String::from("segui-test")),
        )
        .unwrap();
        assert!(wf_path.is_file());

        let md =
            RunReportServices::export_methods(report_path, String::from("markdown"), true, None)
                .unwrap();
        assert!(md.contains("SEGUL"));
        let _ = fs::remove_dir_all(&tmp);
    }
}

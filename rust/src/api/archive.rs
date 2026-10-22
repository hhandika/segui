use flate2::write::GzEncoder;
use flate2::Compression;
use segul::writer::archive::Archive;
use std::fs::File;
use std::io::{self, BufReader, BufWriter, Write};
use std::path::{Path, PathBuf};

pub struct ArchiveServices {
    pub output_path: String,
    pub input_files: Vec<String>,
}

impl ArchiveServices {
    pub fn new() -> ArchiveServices {
        ArchiveServices {
            output_path: String::new(),
            input_files: Vec::new(),
        }
    }

    pub fn zip(&self) {
        let output_path = Path::new(&self.output_path);
        let input_files = self
            .input_files
            .iter()
            .map(PathBuf::from)
            .collect::<Vec<PathBuf>>();

        let zip = Archive::new(output_path, &input_files);
        zip.zip().expect("Failed to zip files");
    }
}

/// Archive format for exporting files.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ExportFormat {
    /// A zip archive, readable on any operating system.
    Zip,
    /// A gzip-compressed tar archive.
    TarGz,
}

/// Bundles files into one archive. Entries keep their paths relative to
/// the deepest folder the input files share, so files with the same name
/// in different folders stay apart.
pub struct ExportServices {
    pub output_path: String,
    pub input_files: Vec<String>,
    pub format: ExportFormat,
}

impl ExportServices {
    pub fn write(&self) -> anyhow::Result<()> {
        if self.input_files.is_empty() {
            anyhow::bail!("No files to export");
        }
        let entries = self.entries()?;
        let output = File::create(&self.output_path)?;
        match self.format {
            ExportFormat::Zip => Self::write_zip(output, &entries),
            ExportFormat::TarGz => Self::write_tar_gz(output, &entries),
        }
    }

    #[cfg(test)]
    fn new(output_path: String, input_files: Vec<String>, format: ExportFormat) -> Self {
        Self {
            output_path,
            input_files,
            format,
        }
    }

    /// Pairs each input file with its name inside the archive.
    fn entries(&self) -> anyhow::Result<Vec<(PathBuf, String)>> {
        let files: Vec<PathBuf> = self.input_files.iter().map(PathBuf::from).collect();
        let root = Self::common_parent(&files);
        files
            .into_iter()
            .map(|file| {
                let relative = root
                    .as_deref()
                    .and_then(|root| file.strip_prefix(root).ok())
                    .map(Path::to_path_buf)
                    .or_else(|| file.file_name().map(PathBuf::from))
                    .ok_or_else(|| anyhow::anyhow!("Invalid file path: {}", file.display()))?;
                // Archive entries always use forward slashes.
                let name = relative
                    .components()
                    .map(|part| part.as_os_str().to_string_lossy())
                    .collect::<Vec<_>>()
                    .join("/");
                Ok((file, name))
            })
            .collect()
    }

    /// Deepest folder that holds every file, if any.
    fn common_parent(files: &[PathBuf]) -> Option<PathBuf> {
        let mut root = files.first()?.parent()?.to_path_buf();
        for file in &files[1..] {
            while !file.starts_with(&root) {
                root = root.parent()?.to_path_buf();
            }
        }
        Some(root)
    }

    fn write_zip(output: File, entries: &[(PathBuf, String)]) -> anyhow::Result<()> {
        let mut archive = zip::ZipWriter::new(output);
        let options = zip::write::FileOptions::default()
            .compression_method(zip::CompressionMethod::Deflated)
            .large_file(true);
        for (file, name) in entries {
            archive.start_file(name.as_str(), options)?;
            let mut reader = BufReader::new(File::open(file)?);
            io::copy(&mut reader, &mut archive)?;
        }
        archive.finish()?;
        Ok(())
    }

    fn write_tar_gz(output: File, entries: &[(PathBuf, String)]) -> anyhow::Result<()> {
        let encoder = GzEncoder::new(BufWriter::new(output), Compression::default());
        let mut archive = tar::Builder::new(encoder);
        for (file, name) in entries {
            archive.append_path_with_name(file, name)?;
        }
        archive.into_inner()?.finish()?.flush()?;
        Ok(())
    }
}

/// Extracts a zip or gzip-compressed tar archive into a folder. Entries
/// that would land outside the folder, hidden files, and macOS metadata
/// are skipped.
pub struct ExtractServices {
    pub input_path: String,
    pub output_dir: String,
}

impl ExtractServices {
    /// Extracts the archive and returns the number of files written.
    pub fn extract(&self) -> anyhow::Result<u32> {
        let input = Path::new(&self.input_path);
        let output_dir = Path::new(&self.output_dir);
        std::fs::create_dir_all(output_dir)?;
        let name = input
            .file_name()
            .map(|name| name.to_string_lossy().to_lowercase())
            .unwrap_or_default();
        if name.ends_with(".zip") {
            Self::extract_zip(input, output_dir)
        } else if name.ends_with(".tar.gz") || name.ends_with(".tgz") {
            Self::extract_tar_gz(input, output_dir)
        } else {
            anyhow::bail!(
                "Unsupported archive: {}. Use .zip or .tar.gz",
                input.display()
            )
        }
    }

    fn extract_zip(input: &Path, output_dir: &Path) -> anyhow::Result<u32> {
        let mut archive = zip::ZipArchive::new(BufReader::new(File::open(input)?))?;
        let mut count = 0;
        for index in 0..archive.len() {
            let mut entry = archive.by_index(index)?;
            if entry.is_dir() {
                continue;
            }
            let Some(relative) = entry.enclosed_name().map(Path::to_path_buf) else {
                continue;
            };
            if let Some(target) = Self::target_path(output_dir, &relative) {
                Self::write_entry(&mut entry, &target)?;
                count += 1;
            }
        }
        Ok(count)
    }

    fn extract_tar_gz(input: &Path, output_dir: &Path) -> anyhow::Result<u32> {
        let decoder = flate2::read::GzDecoder::new(BufReader::new(File::open(input)?));
        let mut archive = tar::Archive::new(decoder);
        let mut count = 0;
        for entry in archive.entries()? {
            let mut entry = entry?;
            if !entry.header().entry_type().is_file() {
                continue;
            }
            let relative = entry.path()?.into_owned();
            if let Some(target) = Self::target_path(output_dir, &relative) {
                Self::write_entry(&mut entry, &target)?;
                count += 1;
            }
        }
        Ok(count)
    }

    /// Joins a relative entry path to the output folder. Returns `None` for
    /// entries that escape the folder, hidden files, or macOS metadata.
    fn target_path(output_dir: &Path, relative: &Path) -> Option<PathBuf> {
        let mut target = output_dir.to_path_buf();
        for component in relative.components() {
            match component {
                std::path::Component::Normal(part) => {
                    let part = part.to_string_lossy();
                    if part.starts_with('.') || part == "__MACOSX" {
                        return None;
                    }
                    target.push(part.as_ref());
                }
                std::path::Component::CurDir => continue,
                _ => return None,
            }
        }
        if target == output_dir {
            return None;
        }
        Some(target)
    }

    fn write_entry(reader: &mut impl io::Read, target: &Path) -> anyhow::Result<()> {
        if let Some(parent) = target.parent() {
            std::fs::create_dir_all(parent)?;
        }
        let mut writer = BufWriter::new(File::create(target)?);
        io::copy(reader, &mut writer)?;
        writer.flush()?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Read;

    struct TempDir {
        path: PathBuf,
    }

    impl TempDir {
        fn new(name: &str) -> Self {
            let path = std::env::temp_dir().join(format!("segui-{}-{}", name, std::process::id()));
            std::fs::create_dir_all(&path).expect("Failed creating temp dir");
            Self { path }
        }

        fn write(&self, parts: &[&str], content: &str) -> String {
            let path = parts
                .iter()
                .fold(self.path.clone(), |path, part| path.join(part));
            std::fs::create_dir_all(path.parent().expect("File has a parent"))
                .expect("Failed creating folder");
            std::fs::write(&path, content).expect("Failed writing file");
            path.to_string_lossy().into_owned()
        }
    }

    impl Drop for TempDir {
        fn drop(&mut self) {
            let _ = std::fs::remove_dir_all(&self.path);
        }
    }

    fn input_files(dir: &TempDir) -> Vec<String> {
        vec![
            dir.write(&["out", "loci", "a.nex"], "alpha"),
            dir.write(&["out", "other", "a.nex"], "beta"),
            dir.write(&["out", "concat.nex"], "gamma"),
        ]
    }

    #[test]
    fn test_export_zip_keeps_folders() {
        let dir = TempDir::new("export-zip");
        let output = dir.path.join("export.zip");
        let services = ExportServices::new(
            output.to_string_lossy().into_owned(),
            input_files(&dir),
            ExportFormat::Zip,
        );
        services.write().expect("Failed exporting zip");

        let mut archive =
            zip::ZipArchive::new(File::open(&output).expect("Zip exists")).expect("Valid zip");
        let mut names: Vec<String> = archive.file_names().map(String::from).collect();
        names.sort();
        assert_eq!(names, vec!["concat.nex", "loci/a.nex", "other/a.nex"]);
        let mut content = String::new();
        archive
            .by_name("other/a.nex")
            .expect("Entry exists")
            .read_to_string(&mut content)
            .expect("Readable entry");
        assert_eq!(content, "beta");
    }

    #[test]
    fn test_export_tar_gz_keeps_folders() {
        let dir = TempDir::new("export-tar-gz");
        let output = dir.path.join("export.tar.gz");
        let services = ExportServices::new(
            output.to_string_lossy().into_owned(),
            input_files(&dir),
            ExportFormat::TarGz,
        );
        services.write().expect("Failed exporting tar.gz");

        let decoder = flate2::read::GzDecoder::new(File::open(&output).expect("Archive exists"));
        let mut archive = tar::Archive::new(decoder);
        let mut entries: Vec<(String, String)> = archive
            .entries()
            .expect("Readable archive")
            .map(|entry| {
                let mut entry = entry.expect("Readable entry");
                let name = entry
                    .path()
                    .expect("Entry path")
                    .to_string_lossy()
                    .into_owned();
                let mut content = String::new();
                entry
                    .read_to_string(&mut content)
                    .expect("Readable content");
                (name, content)
            })
            .collect();
        entries.sort();
        assert_eq!(
            entries,
            vec![
                ("concat.nex".to_string(), "gamma".to_string()),
                ("loci/a.nex".to_string(), "alpha".to_string()),
                ("other/a.nex".to_string(), "beta".to_string()),
            ]
        );
    }

    #[test]
    fn test_export_single_file_uses_its_name() {
        let dir = TempDir::new("export-single");
        let file = dir.write(&["out", "loci", "a.nex"], "alpha");
        let services = ExportServices::new(String::new(), vec![file], ExportFormat::Zip);
        let entries = services.entries().expect("Valid entries");
        assert_eq!(entries[0].1, "a.nex");
    }

    #[test]
    fn test_export_without_files_fails() {
        let services = ExportServices::new(String::new(), Vec::new(), ExportFormat::TarGz);
        assert!(services.write().is_err());
    }

    fn read_tree(dir: &Path) -> Vec<(String, String)> {
        let mut files = Vec::new();
        let mut stack = vec![dir.to_path_buf()];
        while let Some(current) = stack.pop() {
            for entry in std::fs::read_dir(&current).expect("Readable folder") {
                let path = entry.expect("Readable entry").path();
                if path.is_dir() {
                    stack.push(path);
                } else {
                    let name = path
                        .strip_prefix(dir)
                        .expect("Inside folder")
                        .components()
                        .map(|part| part.as_os_str().to_string_lossy().into_owned())
                        .collect::<Vec<_>>()
                        .join("/");
                    let content = std::fs::read_to_string(&path).expect("Readable file");
                    files.push((name, content));
                }
            }
        }
        files.sort();
        files
    }

    fn expected_tree() -> Vec<(String, String)> {
        vec![
            ("concat.nex".to_string(), "gamma".to_string()),
            ("loci/a.nex".to_string(), "alpha".to_string()),
            ("other/a.nex".to_string(), "beta".to_string()),
        ]
    }

    fn round_trip(name: &str, archive_name: &str, format: ExportFormat) {
        let dir = TempDir::new(name);
        let archive = dir.path.join(archive_name);
        ExportServices::new(
            archive.to_string_lossy().into_owned(),
            input_files(&dir),
            format,
        )
        .write()
        .expect("Failed exporting archive");
        let output = dir.path.join("extracted");
        let services = ExtractServices {
            input_path: archive.to_string_lossy().into_owned(),
            output_dir: output.to_string_lossy().into_owned(),
        };
        let count = services.extract().expect("Failed extracting archive");
        assert_eq!(count, 3);
        assert_eq!(read_tree(&output), expected_tree());
    }

    #[test]
    fn test_extract_zip_round_trip() {
        round_trip("extract-zip", "data.zip", ExportFormat::Zip);
    }

    #[test]
    fn test_extract_tar_gz_round_trip() {
        round_trip("extract-tar-gz", "data.tar.gz", ExportFormat::TarGz);
    }

    #[test]
    fn test_extract_skips_unsafe_and_hidden_entries() {
        let dir = TempDir::new("extract-unsafe");
        let archive = dir.path.join("unsafe.zip");
        let mut writer = zip::ZipWriter::new(File::create(&archive).expect("Archive created"));
        let options = zip::write::FileOptions::default();
        for name in [
            "../escape.nex",
            "__MACOSX/a.nex",
            ".hidden.nex",
            "keep/a.nex",
        ] {
            writer.start_file(name, options).expect("Entry started");
            writer.write_all(b"data").expect("Entry written");
        }
        writer.finish().expect("Archive finished");

        let output = dir.path.join("extracted");
        let services = ExtractServices {
            input_path: archive.to_string_lossy().into_owned(),
            output_dir: output.to_string_lossy().into_owned(),
        };
        assert_eq!(services.extract().expect("Extracted"), 1);
        assert_eq!(
            read_tree(&output),
            vec![("keep/a.nex".to_string(), "data".to_string())]
        );
        assert!(!dir.path.join("escape.nex").exists());
    }

    #[test]
    fn test_target_path_rejects_parent_and_absolute() {
        let output = Path::new("out");
        assert!(ExtractServices::target_path(output, Path::new("../a.nex")).is_none());
        let absolute: PathBuf = std::env::temp_dir().join("a.nex");
        assert!(ExtractServices::target_path(output, &absolute).is_none());
        assert_eq!(
            ExtractServices::target_path(output, Path::new("loci/a.nex")),
            Some(output.join("loci").join("a.nex"))
        );
    }

    #[test]
    fn test_extract_unsupported_extension_fails() {
        let services = ExtractServices {
            input_path: "data.rar".to_string(),
            output_dir: std::env::temp_dir()
                .join(format!("segui-extract-rar-{}", std::process::id()))
                .to_string_lossy()
                .into_owned(),
        };
        assert!(services.extract().is_err());
        let _ = std::fs::remove_dir_all(&services.output_dir);
    }
}

use segul::writer::archive::Archive;
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

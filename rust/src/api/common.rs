use std::path::Path;

use segul::helper::logger::init_file_logger;

pub fn init_logger(log_dir: String) {
    init_file_logger(Path::new(&log_dir)).expect("Failed to initialize logger");
}

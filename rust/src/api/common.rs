use std::path::Path;

use segul::helper::logger;

#[flutter_rust_bridge::frb(sync)]
pub fn init_logger(path: String) {
    let logger_path = Path::new(&path);
    logger::init_file_logger(&logger_path).expect("Failed to setup logger");
}

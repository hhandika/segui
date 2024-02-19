use std::path::Path;

use segul::helper::{logger, utils};

const LOG_FILE: &str = "segul";

pub fn init_logger(log_dir: String) {
    // Get date
    let current_date = chrono::Local::now().format("%Y-%m-%d").to_string();
    let file = format!("{}_{}.log", LOG_FILE, current_date);
    let log_path = Path::new(&log_dir).join(file);
    logger::init_file_logger(&log_path).expect("Failed to initialize logger");
}

pub fn get_api_version() -> String {
    utils::get_crate_version()
}

use std::path::PathBuf;

use anyhow::Result;
use songbook::song_library::lib_functions::get_files_in_dir;


#[flutter_rust_bridge::frb(sync)]
pub fn read_directory(path_str: Option<String>) -> Result<(Vec<String>, Vec<String>)> {
    let mut dirs: Vec<String> = Vec::new();
    let mut files: Vec<String> = Vec::new();
    let mut path: Option<PathBuf> = None;
    if let Some(p) = path_str {
        path = Some(PathBuf::from(p));
    }

    let (paths, _current_path) = get_files_in_dir(path.as_deref())?;
    for (_, p) in paths {
        if let Some(s) = p.to_str() {
            if p.is_dir() {
                dirs.push(s.to_string());
            } else {
                files.push(s.to_string());
            }
        }
    }


    Ok( (dirs, files) )
}

#[flutter_rust_bridge::frb(sync)]
pub fn init_library(app_data_dir: String) {
    std::env::set_var("APP_DATA_DIR", app_data_dir);
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

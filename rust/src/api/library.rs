use std::path::PathBuf;

use anyhow::{Result, anyhow};
use songbook::song_library::lib_functions::*;
use songbook::song_library::*;
use songbook::{Song, Metadata};


#[flutter_rust_bridge::frb(sync)]
pub fn read_directory(path_str: Option<String>) -> Result<(Vec<String>, Vec<String>, String)> {
    let mut dirs: Vec<String> = Vec::new();
    let mut files: Vec<String> = Vec::new();
    let mut path: Option<PathBuf> = None;
    if let Some(p) = path_str {
        path = Some(PathBuf::from(p));
    }

    let (paths, current_path) = get_files_in_dir(path.as_deref())?;
    for (_, p) in paths {
        if let Some(s) = p.to_str() {
            if p.is_dir() {
                dirs.push(s.to_string());
            } else {
                files.push(s.to_string());
            }
        }
    }

    let c_path = if let Some(s) = current_path.to_str() {
        s.to_string()
    } else {
        return Err(anyhow!("Cannot get current path"));
    };


    Ok( (dirs, files, c_path) )
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_directory(path_str: String) -> Result<()> {
    let path = PathBuf::from(path_str);
    mkdir(&path)?;

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn remove_from_library(path_str: String) -> Result<()> {
    let path = PathBuf::from(path_str);
    rm(&path)?;

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn move_file_or_dir(input_path_str: String, output_path_str: String) -> Result<()> {
    let i_path = PathBuf::from(input_path_str);
    let o_path = PathBuf::from(output_path_str);
    mv(&i_path, &o_path)?;

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn add_new_song(
    artist: String,
    title: String,
    text: String,
    path_str: String
) -> Result<()> {
    let path = PathBuf::from(path_str);
    let song = {
        let (blocks, chord_list) = songbook::file_reader::txt_reader::read_from_txt(&text);
        let metadata = Metadata {
            artist,
            title,
            key: None,
            capo: None,
            autoscroll_speed: None,
        };
        let mut s = Song { blocks, chord_list, metadata, notes: None };
        s.detect_key();

        s
    };

    save(&song, &path)?;

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn existence_check(path_str: String) -> bool {
    let path = PathBuf::from(path_str);
    
    path.exists()
}


#[flutter_rust_bridge::frb(sync)]
pub fn get_forbidden_chars() -> Vec<char> {
    FORBIDDEN_CHARS.into()
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

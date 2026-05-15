use std::path::PathBuf;
use std::collections::HashMap;

use anyhow::{Result, anyhow};
use songbook::song_library::lib_functions::*;
use songbook::song_library::*;
use songbook::{Song, Metadata};



const LIB_BACKUP_NAME: &str = "lib_backup.zip";
const SETTINGS_BACKUP_NAME: &str = "settings.txt";
const BACKGROUND_BACKUP_NAME: &str = "background_image";
const FONTS_BACKUP_DIR_NAME: &str = "fonts";

#[flutter_rust_bridge::frb(sync)]
pub fn export_backup(
    output_path_str: String,
    settings: HashMap<String, String>,
    fonts_path: Option<String>,
    background_path: Option<String>,
) -> Result<()> {
    use std::fs;
    use std::io::{self, Write, Read};
    use songbook::song_library;
    use zip::{
        write::FileOptions,
        ZipWriter,
    };

    let output_path = PathBuf::from(output_path_str);

    let base_path = if let Some(p) = get_base_path() {
        p.join("songbook")
    } else {
        return Err(anyhow!("Cannot get base path!"));
    };
    let temp_dir = base_path.join("temp");
    fs::create_dir_all(&temp_dir)?;

    let library_backup = temp_dir.join(LIB_BACKUP_NAME);
    song_library::export_backup(&library_backup)?;

    let settings_backup = temp_dir.join(SETTINGS_BACKUP_NAME);
    let file = fs::File::create(&settings_backup)?;
    let mut writer = io::BufWriter::new(file);
    for (key, value) in settings {
        writeln!(writer, "{key} {value}")?;
    }
    writer.flush()?;


    let file = fs::File::create(output_path)?;
    let mut zip = ZipWriter::new(file);
    let mut buffer = Vec::new();

    zip.start_file::<_, ()>(LIB_BACKUP_NAME, FileOptions::default())?;
    let mut file = fs::File::open(library_backup)?;
    file.read_to_end(&mut buffer)?;
    zip.write_all(&buffer)?;
    buffer.clear();

    zip.start_file::<_, ()>(SETTINGS_BACKUP_NAME, FileOptions::default())?;
    let mut file = fs::File::open(settings_backup)?;
    file.read_to_end(&mut buffer)?;
    zip.write_all(&buffer)?;
    buffer.clear();

    if let Some(background_path_str) = background_path {
        let background_path = PathBuf::from(background_path_str);

        zip.start_file::<_, ()>(BACKGROUND_BACKUP_NAME, FileOptions::default())?;
        let mut file = fs::File::open(background_path)?;
        file.read_to_end(&mut buffer)?;
        zip.write_all(&buffer)?;
        buffer.clear();
    }

    if let Some(dir) = fonts_path {
        let fonts_dir = PathBuf::from(dir);
        let parent_dir = if let Some(dir) =
            fonts_dir.parent() { dir }
            else { return Err(anyhow!("Cannot get parent dir for fonts!")) };
        zip.add_directory::<_, ()>(FONTS_BACKUP_DIR_NAME, FileOptions::default())?;
        for entry in fs::read_dir(&fonts_dir)? {
            let path = entry?.path();
            if !path.is_file() { continue }

            let font_name = path
                .strip_prefix(&parent_dir)?
                .to_string_lossy();

            zip.start_file::<_, ()>(font_name, FileOptions::default())?;
            let mut file = fs::File::open(path)?;
            file.read_to_end(&mut buffer)?;
            zip.write_all(&buffer)?;
            buffer.clear();
        }
    }
    

    zip.finish()?;
    fs::remove_dir_all(&temp_dir)?;


    Ok(())
}
#[flutter_rust_bridge::frb(sync)]
pub fn import_backup(
    backup_path_str: String,
    fonts_path_str: String,
    background_path_str: String,
) -> Result<HashMap<String, String>> {
    use std::fs::{self, File};
    use std::io::{Write, Read};
    use zip::ZipArchive;
    use songbook::song_library;

    let backup = PathBuf::from(backup_path_str);
    let fonts_dir = PathBuf::from(fonts_path_str);
    let background_path = PathBuf::from(background_path_str);

    let mut settings = HashMap::new();

    let base_path = if let Some(p) = get_base_path() {
        p.join("songbook")
    } else {
        return Err(anyhow!("Cannot get base path!"));
    };
    let temp_dir = base_path.join("temp_dir");
    fs::create_dir_all(&temp_dir)?;

    let temp_fonts_dir = temp_dir.join(FONTS_BACKUP_DIR_NAME);
    let temp_background_path = temp_dir.join(BACKGROUND_BACKUP_NAME);
    let temp_lib_backup_path = temp_dir.join(LIB_BACKUP_NAME);


    let file = File::open(backup)?;
    let mut archive = ZipArchive::new(file)?;
    let mut buffer = Vec::new();

    {
        let mut settings_entry = archive.by_name(SETTINGS_BACKUP_NAME)?;
        let mut settings_buffer = String::new();
        settings_entry.read_to_string(&mut settings_buffer)?;
        for line in settings_buffer.lines() {
            if let Some(key_end_index) = line.find(" ") {
                let key = line[..key_end_index].trim().to_string();
                let value = line[key_end_index..].trim().to_string();
                settings.insert(key, value);
            }
        }
    }

    {
        let mut lib_backup_entry = archive.by_name(LIB_BACKUP_NAME)?;
        let mut output_file = File::create(&temp_lib_backup_path)?;
        lib_backup_entry.read_to_end(&mut buffer)?;
        output_file.write_all(&buffer)?;
        buffer.clear();
    }

    if let Ok(mut background_entry) = archive.by_name(BACKGROUND_BACKUP_NAME) {
        let mut output_file = File::create(&temp_background_path)?;
        background_entry.read_to_end(&mut buffer)?;
        output_file.write_all(&buffer)?;
        buffer.clear();
    }

    let mut temp_fonts_paths: Vec<(PathBuf, String)> = Vec::new();
    for i in 0..archive.len() {
        let mut entry = archive.by_index(i)?;
        let entry_name = entry.name().to_string();
        if entry_name.starts_with(FONTS_BACKUP_DIR_NAME) {
            let file_name: String = if let Some(name) =
                PathBuf::from(entry_name).file_name().and_then(|n| n.to_str()) { name.to_string() }
                else { continue };
            if file_name.is_empty() && entry.is_dir() { continue }

            let output_path = temp_fonts_dir.join(&file_name);
            if !temp_fonts_dir.exists() {
                fs::create_dir(&temp_fonts_dir)?;
            }
            if entry.is_file() {
                let mut output_file = File::create(&output_path)?;
                entry.read_to_end(&mut buffer)?;
                output_file.write_all(&buffer)?;
                buffer.clear();

                temp_fonts_paths.push((output_path, file_name));
            }
        }
    }


    if temp_fonts_dir.exists() {
        if fonts_dir.exists() {
            fs::remove_dir_all(&fonts_dir)?;
        }
        fs::create_dir_all(&fonts_dir)?;
        for (font_path, font_name) in temp_fonts_paths {
            let output_path = fonts_dir.join(font_name);
            fs::copy(font_path, output_path)?;
        }
        fs::remove_dir_all(temp_fonts_dir)?;
    }

    if temp_background_path.exists() {
        fs::copy(&temp_background_path, background_path)?;
        fs::remove_file(temp_background_path)?;
    }


    song_library::import_backup(&temp_lib_backup_path)?;
    fs::remove_dir_all(&temp_dir)?;


    Ok(settings)
}

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
pub fn search(path_str: String, query: String) -> Result<Vec<String>> {
    let path = PathBuf::from(path_str);
    let search_results: Vec<(String, PathBuf)> = find_in(&path, &query)?;
    let mut out_paths: Vec<String> = Vec::new();
    for (_file_name, path) in search_results {
        if let Some(s) = path.to_str() {
            out_paths.push(s.to_string());
        }
    }

    return Ok(out_paths)
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
pub fn copy_file_or_dir(input_path_str: String, output_path_str: String) -> Result<()> {
    let i_path = PathBuf::from(input_path_str);
    let o_path = PathBuf::from(output_path_str);
    cp(&i_path, &o_path)?;

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn copy_path_list_in(paths_str: Vec<String>, out_dir_str: String) -> Result<()> {
    for i in paths_str {
        copy_file_or_dir(i, out_dir_str.clone())?;
    }

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn move_path_list_in(paths_str: Vec<String>, out_dir_str: String) -> Result<()> {
    for i in paths_str {
        move_file_or_dir(i, out_dir_str.clone())?;
    }

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
            show_options: None,
        };
        let mut s = Song { blocks, chord_list, metadata, notes: None };
        s.detect_key();

        s
    };

    save(&song, &path)?;

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn import_song(mut song: crate::api::song::SimpleSong, dir_path: String) -> Result<()> {
    let song = song.get_mut_song();
    let current_dir = PathBuf::from(dir_path);
    let song_name = 
        get_without_forbidden_chars( format!("{} - {}", song.metadata.artist, song.metadata.title));
    let mut song_path = current_dir.join(&song_name);
    let mut counter = 0;
    while song_path.exists() {
        counter += 1;
        song_path = current_dir.join(format!("{} ({})", song_name, counter));
    }
    if song.metadata.key == None {
        song.detect_key();
    }

    save(&song, &song_path)?;

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

use std::path::Path;
use std::fs::{self, File};
use std::io::{self, BufWriter, BufReader};

use anyhow::Result;
use zip::{
    write::FileOptions,
    ZipWriter,
    ZipArchive,
};


pub fn export_backup(out_path: &Path) -> Result<()> {
    let base_path = if let Some(p) = super::get_base_path() { p } else {
        return Err(anyhow::anyhow!("Cannot get base path!"));
    };
    let lib_path = base_path.join(super::LIBRARY_NAME);
    let fingerings_path = base_path.join(super::FINGERINGS_NAME);


    let file = File::create(out_path)?;
    let mut zip = ZipWriter::new(file);

    add_in_zip_recursive(&mut zip, &base_path, &lib_path)?;


    super::check_fingerings(&fingerings_path)?;
    let rel_fing_path = fingerings_path.strip_prefix(base_path)?;
    let fing_file_name = rel_fing_path.to_string_lossy();
    zip.start_file::<_, ()>(fing_file_name, FileOptions::default())?;

    let file = File::open(&fingerings_path)?;
    let mut reader = BufReader::new(file);
    io::copy(&mut reader, &mut zip)?;


    zip.finish()?;

    Ok(())
}
fn add_in_zip_recursive(
    zip: &mut ZipWriter<File>,
    base_path: &Path,
    current_path: &Path
) -> Result<()> {
    for entry in fs::read_dir(current_path)? {
        let path = entry?.path();
        let rel_path = path.strip_prefix(base_path)?;
        if path.is_dir() {
            let dir_name = rel_path.to_string_lossy();
            if !dir_name.is_empty() {
                zip.add_directory::<_, ()>(
                    format!("{}/", dir_name),
                    FileOptions::default(),
                )?;
            }

            add_in_zip_recursive(zip, base_path, &path)?;
        } else if path.is_file() {
            let file_name = rel_path.to_string_lossy();
            zip.start_file::<_, ()>(file_name, FileOptions::default())?;

            let file = File::open(&path)?;
            let mut reader = BufReader::new(file);
            io::copy(&mut reader, zip)?;
        }
    }

    Ok(())
}

pub fn import_backup(path: &Path) -> Result<()> {
    let base_path = if let Some(p) = super::get_base_path() { p } else {
        return Err(anyhow::anyhow!("Cannot get base path!"));
    };
    let lib_path = base_path.join(super::LIBRARY_NAME);
    let fingerings_path = base_path.join(super::FINGERINGS_NAME);

    let temp_dir = base_path.join("temp");
    fs::create_dir_all(&temp_dir)?;

    extract_zip(path, &temp_dir)?;

    let temp_fingerings = temp_dir.join(super::FINGERINGS_NAME);
    let temp_lib = temp_dir.join(super::LIBRARY_NAME);

    if fingerings_path.is_dir() {
        fs::remove_dir_all(&fingerings_path)?;
    } else if fingerings_path.is_file() {
        fs::remove_file(&fingerings_path)?;
    } fs::rename(&temp_fingerings, &fingerings_path)?;
    super::check_fingerings(&fingerings_path)?;
    
    if lib_path.is_dir() {
        fs::remove_dir_all(&lib_path)?;
    } fs::rename(&temp_lib, &lib_path)?;

    fs::remove_dir_all(&temp_dir)?;


    Ok(())
}
fn extract_zip(archive_path: &Path, output_dir: &Path) -> Result<()> {
    let file = File::open(archive_path)?;
    let mut archive = ZipArchive::new(file)?;

    for i in 0..archive.len() {
        let mut entry = archive.by_index(i)?;
        let entry_name = entry.name().to_string();

        let output_path = output_dir.join(&entry_name);
        if entry.is_dir() {
            fs::create_dir_all(&output_path)?;
        } else if entry.is_file() {
            if let Some(parent) = output_path.parent() {
                fs::create_dir_all(parent)?;
            }

            let output_file = File::create(output_path)?;
            let mut writer = BufWriter::new(output_file);
            io::copy(&mut entry, &mut writer)?;
        }
    }

    Ok(())
}

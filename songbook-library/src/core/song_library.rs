pub mod lib_functions;

use std::path::{PathBuf, Path};
use std::fs::{self, File};
use std::io::{BufWriter, BufReader, Read, Write, Error, ErrorKind, stdout};
use std::process::{Command, Stdio};

use include_dir::{include_dir, Dir};
use anyhow::Result;
use crossterm::{
    execute,
    style::{Color, Print, ResetColor, SetForegroundColor}
};
use zip::{
    write::FileOptions,
    ZipWriter,
    ZipArchive,
};

use crate::{Song, Fingering};


pub const FORBIDDEN_CHARS: [char; 9] = ['<', '>', ':', '/', '\\', '|', '?', '*', '`'];



pub fn init() -> Result<()> {
    let assets: Dir<'_> = include_dir!("$CARGO_MANIFEST_DIR/assets");
    if let Some(mut path) = get_base_path() {
        path.push("songbook");
        if !path.exists() { fs::create_dir_all(&path)? }
        assets.extract(&path)?;
        Ok(())
    } else {
        Err(anyhow::anyhow!("Cannot init first launch"))
    }
}

pub fn show(
    song_path: &Path,
    key: Option<crate::Key>,
    chords: bool,     // show chords
    rhythm: bool,     // show rhythm
    fingerings: bool, // show fingerings
    notes: bool,      // show notes
    is_colored: bool
) -> Result<()> {
    let mut path = get_lib_path()?;
    path = path.join(song_path);

    let file = File::open(path)?;
    let reader = BufReader::new(file);
    let mut song: Song = serde_yaml::from_reader(reader)?;
    if let Some(k) = key {
        if let Some(mut m_key) = song.metadata.key {
            while m_key.get_note() != k.get_note() {
                song.transpose(1);
                m_key = song.metadata.key.unwrap();
            }
        } else { println!("Add a key before transposing, try 'songbook edit <song_name>'") }
    }

    song.metadata.show_options = 
        Some( crate::song::ShowOptions { chords, rhythm, notes, fingerings } );

    let text =
        if is_colored {
            song.get_colored()
        } else {
            song.get_song_as_text()
        };
    print(&text)?;


    Ok(())
}


pub fn edit(added_path: &Path) -> Result<()> {
    let mut path = get_lib_path()?;
    path = path.join(added_path);
    if !path.exists() {
        return Err( Error::new(ErrorKind::NotFound, "There's no such file!").into() )
    }

    let file = File::open(&path)?;
    let reader = BufReader::new(file);
    let mut song: Song = serde_yaml::from_reader(reader)?;

    let mut text = song.get_for_editing();
    text = edit::edit(text)?;
    song.change_from_edited_str(&text);

    let file = File::create(path)?;
    let writer = BufWriter::new(file);

    serde_yaml::to_writer(writer, &song)?;


    Ok(())
}


pub fn add(song: &Song) -> Result<()> {
    let mut path = get_lib_path()?;
    if !path.exists() { fs::create_dir_all(&path)? }

    let song_name = get_without_forbidden_chars(
        format!("{} - {}", song.metadata.artist, song.metadata.title)
    );
    path.push(&song_name);
    path = get_free_path(path, &song_name);

    let file = File::create(path)?;
    let writer = BufWriter::new(file);

    serde_yaml::to_writer(writer, &song)?;


    Ok(())
}


pub fn export_backup(out_path: &Path) -> Result<()> {
    let base_path = if let Some(p) = get_base_path() {
        p.join("songbook")
    } else {
        return Err(anyhow::anyhow!("Cannot get base path!"));
    };
    let lib_path = base_path.join("library");
    let fingerings_path = base_path.join("fingerings");


    let file = File::create(out_path)?;
    let mut zip = ZipWriter::new(file);

    add_in_zip_recursive(&mut zip, &base_path, &lib_path)?;
    add_in_zip_recursive(&mut zip, &base_path, &fingerings_path)?;
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

            let mut file = File::open(&path)?;
            let mut buffer = Vec::new();
            file.read_to_end(&mut buffer)?;
            zip.write_all(&buffer)?;
        }
    }

    Ok(())
}

pub fn import_backup(path: &Path) -> Result<()> {
    let base_path = if let Some(p) = get_base_path() {
        p.join("songbook")
    } else {
        return Err(anyhow::anyhow!("Cannot get base path!"));
    };
    let lib_path = base_path.join("library");
    let fingerings_path = base_path.join("fingerings");

    let temp_dir = base_path.join("temp");
    fs::create_dir_all(&temp_dir)?;

    extract_zip(path, &temp_dir)?;

    let temp_fingerings_dir = temp_dir.join("fingerings");
    let temp_lib_dir = temp_dir.join("library");

    fs::remove_dir_all(&fingerings_path)?;
    fs::rename(&temp_fingerings_dir, &fingerings_path)?;
    
    fs::remove_dir_all(&lib_path)?;
    fs::rename(&temp_lib_dir, &lib_path)?;

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

            let mut output_file = File::create(output_path)?;
            let mut buffer = Vec::new();
            entry.read_to_end(&mut buffer)?;
            output_file.write_all(&buffer)?;
        }
    }

    Ok(())
}


pub fn sort() -> Result<()> {
    let path = get_lib_path()?;
    recursive_sort(&path, &path)?;
    loop {
        if !remove_empty_folders(&path)? { break }
    }

    Ok(())
}
fn recursive_sort(path: &Path, lib_path: &Path) -> Result<()> {
    for entry in fs::read_dir(&path)? {
        let entry = entry?;
        if entry.path().is_dir() { recursive_sort(&entry.path(), lib_path)?; continue }

        let file = File::open(entry.path())?;
        let reader = BufReader::new(file);
        let song: Song = serde_yaml::from_reader(reader)?;

        let artist = get_without_forbidden_chars(song.metadata.artist.clone());
        let title = get_without_forbidden_chars(song.metadata.title.clone());
        let mut new_path = lib_path.join(&artist);
        if !new_path.exists() { fs::create_dir_all(&new_path)? }
        new_path = new_path.join(&title);
        let is_the_same = if new_path != entry.path() {
            new_path = get_free_path(new_path, &title);
            false
        } else { true };

        let file = File::create(&new_path)?;
        let writer = BufWriter::new(file);
        serde_yaml::to_writer(writer, &song)?;

        if !is_the_same {
            fs::remove_file(entry.path())?;
        }
    }

    Ok(())
}
fn remove_empty_folders(path: &Path) -> Result<bool> {
    let mut is_something_deleted = false;
    for entry in fs::read_dir(path)? {
        let entry = entry?;
        let current_path = entry.path();
        if current_path.is_file() { continue }

        if current_path.is_dir() {
            if fs::read_dir(&current_path)?.next().is_none() {
                fs::remove_dir(&current_path)?;
                is_something_deleted = true;
            } else {
                let is_del = remove_empty_folders(&current_path)?;
                if !is_something_deleted { is_something_deleted = is_del }
            }
        }
    }

    return Ok(is_something_deleted)
}


pub fn rm(added_path: &Path) -> Result<()> {
    let mut path = get_lib_path()?;
    path = path.join(added_path);

    if path.exists() {
        if path.is_file() { fs::remove_file(path)? }
        else if path.is_dir() { fs::remove_dir_all(path)? }
    } else {
        return Err( Error::new(
            ErrorKind::NotFound,
            format!("There's no such path: {:#?}", added_path)
        ).into())
    }

    Ok(())
}


pub fn mv(input_path: &Path, output_path: &Path) -> Result<()> {
    let path = get_lib_path()?;
    let i_path = path.join(input_path);
    if !i_path.exists() {
        return Err( Error::new(
            ErrorKind::NotFound,
            format!("There's no such path: {:#?}", input_path)
        ).into())
    }

    let mut o_path = path.join(output_path);
    if let Some(name) = i_path.file_name().and_then(|n| n.to_str()) {
        if o_path.is_dir() { o_path = o_path.join(name) }
        o_path = get_free_path(o_path, name);

        fs::rename(i_path, o_path)?;
    }

    Ok(())
}


pub fn cp(input_path: &Path, output_path: &Path) -> Result<()> {
    let path = get_lib_path()?;
    let i_path = path.join(input_path);
    if !i_path.exists() {
        return Err( Error::new(
            ErrorKind::NotFound,
            format!("There's no such path: {:#?}", input_path)
        ).into())
    }

    let mut o_path = path.join(output_path);
    if let Some(name) = i_path.file_name().and_then(|n| n.to_str()) {
        if o_path.is_dir() { o_path = o_path.join(name) }
        o_path = get_free_path(o_path, name);

        if i_path != o_path {
            if i_path.is_dir() {
                cp_recursive(&i_path, &o_path)?;
            } else {
                fs::copy(i_path, o_path)?;
            }
        }
    }

    Ok(())
}
fn cp_recursive(in_dir: &Path, out_dir: &Path) -> Result<()> {
    fs::create_dir_all(out_dir)?;
    for entry in fs::read_dir(in_dir)? {
        let entry = entry?;
        let path = entry.path();
        let out = out_dir.join(
            if let Some(n) = path.file_name() { n } else { continue }
        );
        if path.is_dir() {
            cp_recursive(&path, &out)?;
        } else {
            fs::copy(path, out)?;
        }
    }

    Ok(())
}


pub fn ls(added_path: Option<&Path>) -> Result<()> {
    let mut path = get_lib_path()?;
    if let Some(p) = added_path { path = path.join(p) }
    if !path.exists() {
        return Err( Error::new(ErrorKind::NotFound, "There's no such dir!").into() )
    }

    for entry in fs::read_dir(path)? {
        let entry = entry?;
        if let Some(name) = entry.file_name().to_str() {
            if entry.path().is_dir() {
                execute!(
                    stdout(),
                    SetForegroundColor(Color::Blue),
                    Print(name),
                    Print("\n"),
                    ResetColor
                )?;
            } else {
                println!("{}", name);
            }
        }
    }

    Ok(())
}


pub fn tree(added_path: Option<&Path>) -> Result<()> {
    let mut path = get_lib_path()?;
    if let Some(p) = added_path { path = path.join(p) }
    if !path.is_dir() {
        return Err( Error::new(ErrorKind::NotFound, "There's no such dir!").into() )
    }

    recursive_tree(&path, 1, false)?;

    Ok(())
}

fn recursive_tree(dir: &Path, indent: usize, is_parent_last: bool) -> Result<()> {
    if let Some(name) = dir.file_name().and_then(|f| f.to_str()) {
        println!("{}", name);
    }

    let last = if let Some(entry) = fs::read_dir(dir)?.last() { entry?.path() }
    else { return Ok(()) };

    for entry in fs::read_dir(dir)? {
        let entry = entry?;
        let is_last = entry.path() == last;
        if let Some(name) = entry.file_name().to_str() {
            if indent > 1 {
                if is_parent_last {
                    print!("{}", "    ".repeat(indent - 1));
                } else {
                    print!("{}", "│   ".repeat(indent - 1));
                }
            }

            if is_last {
                print!("└── ");
            } else {
                print!("├── ");
            }

            if entry.path().is_dir() {
                recursive_tree(&entry.path(), indent + 1, is_last)?;
            } else {
                println!("{}", name);
            }
        }
    }

    Ok(())
}


pub fn mkdir(added_path: &Path) -> Result<()> {
    let mut path = get_lib_path()?;
    path = path.join(added_path);

    if path.exists() {
         
        return Err( Error::new(
            ErrorKind::AlreadyExists, 
            format!("{:#?} is already exists!", added_path)
        ).into())
    }

    fs::create_dir_all(path)?;

    Ok(())
}

pub fn add_fingering(fing: &Fingering) -> Result<(), Box<dyn std::error::Error>> {
    let mut path: PathBuf = get_base_path()
        .ok_or("Cannot get path for data!")?;
    path.push("songbook");
    path.push("fingerings");
    if !path.exists() { fs::create_dir_all(&path)? }

    let fing_name = get_without_forbidden_chars(
        fing.get_title()
            .ok_or("Cannot get the fingering title!")?
    );
    path.push(&fing_name);

    let file = File::create(path)?;
    let writer = BufWriter::new(file);

    serde_yaml::to_writer(writer, &fing)?;

    
    Ok(())
}

pub fn get_fingering(chord_name: &str) -> Result<Option<Fingering>, Box<dyn std::error::Error>> {
    let mut path: PathBuf = get_base_path()
        .ok_or("Cannot get path for data!")?;
    path.push("songbook");
    path.push("fingerings");
    path.push(&chord_name);
    
    if !path.exists() { return Ok(None) }

    let file = File::open(path)?;
    let reader = BufReader::new(file);
    let fing: Fingering = serde_yaml::from_reader(reader)?;

    
    Ok(Some(fing))
}


fn print(text: &str) -> Result<()> {
    if let Ok(mut child) = Command::new("less").arg("-R").stdin(Stdio::piped()).spawn() {
        if let Some(mut stdin) = child.stdin.take() {
            stdin.write_all(text.as_bytes())?;
        }
        child.wait()?;
    } else {
        println!("{text}");
    }

    Ok(())
}

pub fn get_without_forbidden_chars(text: String) -> String {
    text.chars().map(|c|
        if FORBIDDEN_CHARS.iter().any(|f| *f == c) { '_' }
        else { c }
    ).collect()
}

pub fn get_free_path(mut path: PathBuf, name: &str) -> PathBuf {
    let mut counter = 1;
    while path.exists() {
        path.set_file_name(&format!("{}({})", name, counter));
        counter += 1;
    }

    return path
}

pub fn get_lib_path() -> Result<PathBuf> {
    if let Some(mut path) = get_base_path() {
        path.push("songbook");
        path.push("library");

        Ok(path)
    }
    else { Err( Error::new(ErrorKind::NotFound, "Cannot get data directory!").into() ) }
}


pub fn get_base_path() -> Option<PathBuf> {
    #[cfg(not(target_os = "android"))]
    return dirs::data_dir();

    #[cfg(target_os = "android")]
    if let Ok(p) = get_local_data_dir() { Some(p) }
    else { None }
}


#[cfg(target_os = "android")]
fn get_local_data_dir() -> Result<PathBuf> {
    let path_str = std::env::var("APP_DATA_DIR")?;
    return Ok(PathBuf::from(path_str))
}

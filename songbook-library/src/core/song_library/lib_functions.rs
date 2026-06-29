use std::path::{PathBuf, Path};
use std::fs::{self, File};
use std::io::{Error, ErrorKind, BufReader, BufWriter};

use anyhow::Result;

use crate::Song;
use crate::song_library::get_lib_path;


// returns files in directory(file_name, file_path) and directory
pub fn get_files_in_dir(added_path: Option<&Path>) -> Result<(Vec<(String, PathBuf)>, PathBuf)> {
    let mut path = get_lib_path()?;
    if !path.exists() { super::init()? }

    if let Some(p) = added_path { path = path.join(p) }
    if !path.exists() {
        return Err( Error::new(ErrorKind::NotFound, "There's no such dir!").into() )
    }

    let mut buf_for_sorting = Vec::new();
    let mut files = Vec::new();
    for entry in fs::read_dir(&path)? {
        let entry = entry?;
        if let Some(name) = entry.file_name().to_str() {
            if entry.path().is_dir() {
                let name = format!("📁{}", name);
                files.push( (name, entry.path()) );
            }
            else {
                let name = name.to_string();
                buf_for_sorting.push( (name, entry.path()) );
            };
        }
    }
    files.sort();
    buf_for_sorting.sort();

    files.extend(buf_for_sorting);
    Ok( (files, path) )
}


pub fn get_song(song_path: &Path) -> Result<Song> {
    let mut path = get_lib_path()?;
    path = path.join(song_path);

    let file = File::open(path)?;
    let reader = BufReader::new(file);
    let song: Song = serde_yaml::from_reader(reader)?;

    Ok(song)
}


pub fn save(song: &Song, path: &Path) -> Result<()> {
    let file = File::create(path)?;
    let writer = BufWriter::new(file);

    serde_yaml::to_writer(writer, song)?;

    Ok(())
}


pub fn edit(song: &mut Song) -> Result<()> {
    let help_msg = get_help_msg();
    let mut text = String::new();
    text.push_str(&help_msg);
    text.push_str("\n\n\n");

    text.push_str(&song.get_for_editing());
    text = edit::edit(text)?;
    song.change_from_edited_str(&text);

    Ok(())
}

pub fn find(query: &str) -> Result<Vec<(String, PathBuf)>> {
    let path = get_lib_path()?;
    let mut files = Vec::new();
    recursive_find(&path, &mut files, query)?;

    return Ok(files)
}

pub fn find_in(path: &Path, query: &str) -> Result<Vec<(String, PathBuf)>> {
    let mut files = Vec::new();
    recursive_find(path, &mut files, query)?;

    return Ok(files)
}

fn recursive_find(dir: &Path, files: &mut Vec<(String, PathBuf)>, query: &str) -> Result<()> {
    for entry in fs::read_dir(dir)? {
        let path = entry?.path();
        if path.is_dir() {
            recursive_find(&path, files, query)?;
        } else if let Some(name) = path.file_name().and_then(|n: &std::ffi::OsStr| n.to_str())
            && name.to_lowercase().contains(&query.to_lowercase())
                { files.push( (name.to_string(), path.to_path_buf()) ) }
    }

    Ok(())
}

pub fn get_help_msg() -> String {
    use crate::{
        METADATA_START,
        METADATA_END,
        SONG_TITLE_SYMBOL,
        SONG_ARTIST_SYMBOL,
        SONG_KEY_SYMBOL,
        SONG_CAPO_SYMBOL,
        SONG_AUTOSCROLL_SPEED_SYMBOL,
        SONG_SHOW_OPTIONS_SYMBOL,

        BLOCK_START,
        BLOCK_END,
        TITLE_SYMBOL,
        CHORDS_LINE_SYMBOL,
        NOTE_LINE_SYMBOL,
        EMPTY_LINE_SYMBOL,
        PLAIN_TEXT_START,
        PLAIN_TEXT_END,
        TAB_START_SYMBOL,
        TAB_END_SYMBOL,

        CHORDS_SYMBOL,
        RHYTHM_SYMBOL,
        TEXT_SYMBOL,

        SONG_NOTE_START_SYMBOL,
        SONG_NOTE_END_SYMBOL,
        BLOCK_NOTE_SYMBOL
    };

    format!(
r#"==================Help==================
 {METADATA_START} - Start of metadata block
 {METADATA_END} - End of metadata block
 {SONG_TITLE_SYMBOL} - Song's title
 {SONG_ARTIST_SYMBOL} - Song's artist
 {SONG_KEY_SYMBOL} - Song's key
 {SONG_CAPO_SYMBOL} - Song's capo
 {SONG_AUTOSCROLL_SPEED_SYMBOL} - Autoscroll speed (in milliseconds)
 {SONG_SHOW_OPTIONS_SYMBOL} - Show options (chords - c, rhythm - r, notes - n, fingerings - f)

 {BLOCK_START} - Start of block (verse, chorus, bridge, etc.)
 {BLOCK_END} - End of block
 {TITLE_SYMBOL} - Block's title
 {CHORDS_LINE_SYMBOL} - For lines only with chords
 {NOTE_LINE_SYMBOL} - For notes
 {EMPTY_LINE_SYMBOL} - For empty lines
 {PLAIN_TEXT_START} - Start of a text block (useful if you have some cites in song or something like this)
 {PLAIN_TEXT_END} - End of text a block
 {TAB_START_SYMBOL} - Start of a tab
 {TAB_END_SYMBOL} - End of a tab

 {CHORDS_SYMBOL} - Line with chords for text
 {RHYTHM_SYMBOL} - Line with rhythm highlighting
 {TEXT_SYMBOL} - Text line

 {SONG_NOTE_START_SYMBOL} - Start of song's note
 {SONG_NOTE_END_SYMBOL} - End of song's note

 {BLOCK_NOTE_SYMBOL} - Notes for some block in song (for example you need to play chorus twice)
========================================"#
    )
}

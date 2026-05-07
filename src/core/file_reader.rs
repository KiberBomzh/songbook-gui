pub mod txt_reader;
pub mod chordpro_reader;
pub mod sbp_reader; // SongbookPro



use std::path::Path;
use std::io::Read;
use std::fs;
use crate::{Song, Metadata};
use anyhow::Result;
use zip::ZipArchive;


impl Song {
    pub fn from_txt(file_path: &Path, title: &str, artist: &str) -> Result<Self> {
        let (blocks, chord_list) = txt_reader::read_from_txt(
            &fs::read_to_string(file_path)?
        );
        let metadata = Metadata {
            artist: artist.to_string(),
            title: title.to_string(),
            key: None,
            capo: None,
            autoscroll_speed: None,
            show_options: None,
        };
        let mut song = Self { blocks, chord_list, metadata, notes: None };
        song.detect_key();


        Ok(song)
    }

    pub fn from_chordpro(file_path: &Path) -> Result<Self> {
        let (metadata, blocks, chord_list) = chordpro_reader::read_from_chordpro(
            &fs::read_to_string(file_path)?
        );
        let metadata = metadata.expect("Cannot read metadata(title or artist)!");
        Ok( Self { blocks, chord_list, metadata, notes: None } )
    }

    pub fn from_sbp(file_path: &Path) -> Result<Vec<Self>> {
        let file = fs::File::open(file_path)?;
        let mut archive = ZipArchive::new(file)?;

        let mut json_file = archive.by_name("dataFile.txt")?;
        let mut content = String::new();
        json_file.read_to_string(&mut content)?;

        sbp_reader::read_from_sbp(&content[3..])
    }
}

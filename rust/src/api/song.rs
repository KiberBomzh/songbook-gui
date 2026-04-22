use std::path::PathBuf;

use songbook::song_library::lib_functions::*;
pub use songbook::song::block::{Block, Line};
pub use songbook::Song;

use anyhow::Result;


pub struct SimpleSong {
    song: Song,
    path: String,
}

impl SimpleSong {
    #[flutter_rust_bridge::frb(sync)]
    pub fn open(path_str: String) -> Result<Self> {
        let path = PathBuf::from(&path_str);
        let song = get_song(&path)?;
        Ok(Self {
            song,
            path: path_str
        } )
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn from_chordpro(path_str: String) -> Result<Self> {
        Ok( Self{
            song: Song::from_chordpro(&PathBuf::from(path_str))?,
            path: String::new(),
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn from_songbookpro(path_str: String) -> Result<Vec<Self>> {
        let mut new_songs = Vec::new();
        let songs: Vec<Song> = Song::from_sbp(&PathBuf::from(path_str))?;
        for song in songs {
            new_songs.push(
                Self { song, path: String::new() }
            );
        }

        Ok(new_songs)
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn save(&self) -> Result<()> {
        let path = PathBuf::from(&self.path);
        save(&self.song, &path)?;

        Ok(())
    }


    #[flutter_rust_bridge::frb(sync)]
    pub fn transpose(&mut self, steps: i32) {
        self.song.transpose(steps);
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn set_capo(&mut self, capo: u8) {
        if let Some(song_capo) = self.song.metadata.capo {
            let song_capo: i32 = song_capo.into();
            let capo: i32 = capo.into();
            self.transpose(capo - song_capo);
        } else {
            self.transpose(capo.into());
        }

        self.song.metadata.capo =
            if capo == 0 { None }
            else { Some(capo) };
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn set_autoscroll_speed(&mut self, new_speed: u64) {
        self.song.metadata.autoscroll_speed = Some(new_speed)
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn set_show_options(&mut self,
        chords: bool,
        rhythm: bool,
        notes: bool,
        fingerings: bool
    ) {
        self.song.metadata.show_options = Some(
            songbook::song::ShowOptions { chords, rhythm, notes, fingerings }
        );
    }


    #[flutter_rust_bridge::frb(sync)]
    pub fn as_text(&self) -> String {
        self.song.get_song_as_text()
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_blocks(&self) -> Vec<SimpleBlock> {
        let mut blocks = Vec::new();
        for block in &self.song.blocks {
            blocks.push( SimpleBlock::new(block) );
        }

        return blocks
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_notes(&self) -> Option<String> {
        self.song.notes.clone()
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_artist(&self) -> String {
        self.song.metadata.artist.clone()
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_title(&self) -> String {
        self.song.metadata.title.clone()
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_key(&self) -> Option<String> {
        let key = self.song.metadata.key?;
        let mut s = String::new();

        if let Some(capo) = self.song.metadata.capo{
            let key_without_capo = key.transpose(-(capo.try_into().ok()?));
            s.push_str(&format!("{key_without_capo}/({key})"));
        } else {
            s = key.to_string();
        }


        Some(s)
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_capo(&self) -> Option<u8> {
        self.song.metadata.capo
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_autoscroll_speed(&self) -> Option<u64> {
        self.song.metadata.autoscroll_speed
    } // in milliseconds per line

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_show_options(&self) -> (bool, bool, bool, bool) {
        self.song.metadata.get_show_options()
    } // chords, rhythm, notes, fingerings


    #[flutter_rust_bridge::frb(sync)]
    pub fn get_for_editing(&self) -> String {
        self.song.get_for_editing()
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn change_from_edited(&mut self, s: String) -> Result<()> {
        self.song.change_from_edited_str(&s);
        self.save()?;

        Ok(())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn detect_key(&mut self) {
        self.song.detect_key();
    }


    pub fn get_mut_song(&mut self) -> &mut Song {
        &mut self.song
    }
}


pub struct SimpleBlock {
    pub title: Option<String>,
    pub lines: Vec<SimpleLine>,
    pub notes: Option<String>
}

impl SimpleBlock {
    pub fn new(block: &Block) -> Self {
        let mut lines = Vec::new();
        for line in &block.lines {
            let l = match line {
                Line::TextBlock(row) => {
                    let (chords, rhythm, text) = row.get_strings();

                    SimpleLine::Row(chords, rhythm, text)
                },
                Line::ChordsLine(chords) => {
                    let mut s = String::new();
                    let mut is_first = true;
                    for c in chords {
                        if is_first {
                            is_first = false;
                        } else {
                            s.push(' ');
                        }

                        s.push_str(&c.text);
                    }

                    SimpleLine::ChordsLine(s)
                },
                Line::PlainText(text) => SimpleLine::PlainText(text.clone()),
                Line::Tab(tab) => SimpleLine::Tab(tab.clone()),
                Line::EmptyLine => SimpleLine::EmptyLine
            };
            lines.push(l);
        }

        Self {
            title: block.title.clone(),
            lines,
            notes: block.notes.clone(),
        }
    }
}

pub enum SimpleLine {
    Row(String, String, String),
    ChordsLine(String),
    PlainText(String),
    Tab(String),
    EmptyLine
}


#[flutter_rust_bridge::frb(sync)]
pub fn get_editor_help_msg() -> String {
    let help = get_help_msg();

    let res: String = help
        .lines()
        .enumerate()
        .map(|(i, l)|
            if i != 0 && i != help.lines().count() - 1 { l.to_string() + "\n" } else { String::new() }
        ).collect();

    return res.trim().to_string()
}

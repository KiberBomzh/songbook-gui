use std::path::PathBuf;

use songbook::song_library::lib_functions::get_song;
pub use songbook::song::block::{Block, Line};
pub use songbook::Song;

use anyhow::Result;


pub struct SimpleSong {
    song: Song,
}

impl SimpleSong {
    #[flutter_rust_bridge::frb(sync)]
    pub fn empty() -> Self {
        Self { song: Song::new("", "") }
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn open(path_str: String) -> Result<Self> {
        let path = PathBuf::from(path_str);
        let song = get_song(&path)?;
        Ok(Self { song } )
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn as_text(&self) -> String {
        self.song.get_song_as_text(true, true, false, true)
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_blocks(&self) -> Vec<SimpleBlock> {
        let mut blocks = Vec::new();
        for block in &self.song.blocks {
            blocks.push( SimpleBlock::new(block) );
        }

        return blocks
    }
}


pub struct SimpleBlock {
    pub title: Option<String>,
    pub lines: Vec<String>,
    pub notes: Option<String>
}

impl SimpleBlock {
    pub fn new(block: &Block) -> Self {
        let mut lines = Vec::new();
        for line in &block.lines {
            let s = match line {
                Line::TextBlock(row) => row.to_string(true, true),
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

                    s
                },
                Line::PlainText(text) => text.clone(),
                Line::Tab(tab) => tab.clone(),
                Line::EmptyLine => String::new()
            };
            lines.push(s);
        }

        Self {
            title: block.title.clone(),
            lines,
            notes: block.notes.clone(),
        }
    }
}

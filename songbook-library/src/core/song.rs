pub mod block;
pub mod row;
pub mod chord;

use serde::{Serialize, Deserialize};
use crossterm::style::Stylize;

use crate::Fingering;
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
    STANDART_TUNING,
    
    TITLE_COLOR,
    NOTES_COLOR,

    SONG_NOTE_START_SYMBOL,
    SONG_NOTE_END_SYMBOL,

    KEYS
};
use crate::{Note, Key};
use crate::sum_text_in_fingerings;
use crate::song::chord::Chord;
use crate::song::block::{Block, Line};
use crate::song::row::ChordPosition;


#[derive(Serialize, Deserialize, Debug)]
pub struct Song {
    pub metadata: Metadata,
    pub chord_list: Vec<Chord>,
    pub blocks: Vec<Block>,
    pub notes: Option<String> // Заметки по песне в общем
}
// Тональности:
// Am - C
// A#m - C#
// Bm - D
// Cm - D#
// C#m - E
// Dm - F
// D#m - F#
// Em - G
// Fm - G#
// F#m - A
// Gm - A#
// G#m - B

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Metadata {
    pub title: String,
    pub artist: String,
    pub key: Option<Key>,
    pub capo: Option<u8>,
    pub autoscroll_speed: Option<u64>, // in milliseconds
    pub show_options: Option<ShowOptions>,
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy)]
pub struct ShowOptions {
    pub chords: bool,
    pub rhythm: bool,
    pub notes: bool,
    pub fingerings: bool,
}


impl Metadata {
    fn get_for_editing(&self, s: &mut String) {
        s.push_str(METADATA_START);
        s.push('\n');


        s.push_str(SONG_TITLE_SYMBOL);
        s.push_str(&self.title);
        s.push('\n');

        s.push_str(SONG_ARTIST_SYMBOL);
        s.push_str(&self.artist);
        s.push('\n');

        s.push_str(SONG_KEY_SYMBOL);
        if let Some(key) = self.key {
            s.push_str(&key.to_string())
        }
        s.push('\n');

        s.push_str(SONG_CAPO_SYMBOL);
        if let Some(capo) = self.capo {
            s.push_str(&capo.to_string())
        }
        s.push('\n');

        s.push_str(SONG_AUTOSCROLL_SPEED_SYMBOL);
        if let Some(speed) = self.autoscroll_speed {
            s.push_str(&speed.to_string())
        }
        s.push('\n');

        if let Some(opt) = self.show_options {
            s.push_str(SONG_SHOW_OPTIONS_SYMBOL);
            if opt.chords { s.push_str("c ") }
            if opt.rhythm { s.push_str("r ") }
            if opt.notes { s.push_str("n ") }
            if opt.fingerings { s.push_str("f ") }
            s.push('\n');
        }


        s.push_str(METADATA_END);
        s.push('\n');

        s.push('\n');
        s.push('\n');
    }

    fn change_from_edited_str(&mut self, text: &str) {
        let mut title = String::new();
        let mut artist = String::new();
        let mut key: Option<Key> = None;
        let mut capo: Option<u8> = None;
        let mut autoscroll_speed: Option<u64> = None;
        let mut opts: Option<ShowOptions> = None;
        for line in text.lines() {
            if line.starts_with(SONG_TITLE_SYMBOL) {
                title = line[SONG_TITLE_SYMBOL.len()..].trim().to_string();
            } else if line.starts_with(SONG_ARTIST_SYMBOL) {
                artist = line[SONG_ARTIST_SYMBOL.len()..].trim().to_string();
            } else if line.starts_with(SONG_KEY_SYMBOL) {
                let k = line[SONG_KEY_SYMBOL.len()..].trim();
                key = Key::new(k);
            } else if line.starts_with(SONG_CAPO_SYMBOL) {
                if let Ok(c) = line[SONG_CAPO_SYMBOL.len()..].trim().parse::<u8>() {
                    capo = Some(c)
                }
            } else if line.starts_with(SONG_AUTOSCROLL_SPEED_SYMBOL) {
                if let Ok(s) = line[SONG_AUTOSCROLL_SPEED_SYMBOL.len()..].trim().parse::<u64>() {
                    autoscroll_speed = Some(s)
                }
            } else if line.starts_with(SONG_SHOW_OPTIONS_SYMBOL) {
                let opts_str = line[SONG_SHOW_OPTIONS_SYMBOL.len()..].trim();
                opts = Some( ShowOptions {
                    chords: opts_str.contains('c'),
                    rhythm: opts_str.contains('r'),
                    notes: opts_str.contains('n'),
                    fingerings: opts_str.contains('f'),
                });
            }
        }

        if !title.is_empty() { self.title = title }
        if !artist.is_empty() { self.artist = artist }
        self.key = key;
        self.capo = capo;
        self.autoscroll_speed = autoscroll_speed;
        self.show_options = opts;
    }

    pub fn get_show_options(&self) -> (bool, bool, bool, bool) {
        if let Some(opt) = self.show_options {
            (opt.chords, opt.rhythm, opt.notes, opt.fingerings)
        } else {
            (true, true, true, false)
        }
    }
}


impl Song {
    pub fn new(title: &str, artist: &str) -> Self {
        Self {
            metadata: Metadata {
                title: title.to_string(), 
                artist: artist.to_string(),
                key: None,
                capo: None,
                autoscroll_speed: None,
                show_options: None,
            },
            chord_list: Vec::new(),
            blocks: Vec::new(),
            notes: None
        }
    }

    pub fn get_song_as_text(&self) -> String {
        let (chords, _rhythm, notes, fingerings) = self.metadata.get_show_options();
        let mut s = String::new();


        if !self.metadata.artist.is_empty() && !self.metadata.title.is_empty() {
            s.push_str( &format!("{} - {}", self.metadata.artist, self.metadata.title) );
            s.push_str("\n\n");
        }

        if let Some(n) = &self.notes && notes {
            s.push_str(n);
            s.push('\n');
        }

        if chords && fingerings {
            let fings = self.get_fingerings();
            
            if let Some(text) = sum_text_in_fingerings(&fings, None) {
                s.push_str(&text);
            }
        }

        s.push_str(&self.to_string());


        return s
    }

    pub fn print(&self) {
        println!("{}", self.get_song_as_text());
    }

    pub fn to_string(&self) -> String {
        let (chords, rhythm, notes, _fingerings) = self.metadata.get_show_options();

        let mut s = String::new();
        let mut is_first = true;
        for block in &self.blocks {
            if is_first { is_first = false }
            else { s.push('\n') }

            if let Some(title) = &block.title {
                if !is_first && !title.is_empty() { s.push('\n') }
                s.push_str(&title);
                s.push(' ');
            }
            if let Some(n) = &block.notes && notes {
                if !is_first && block.title.is_none() { s.push('\n') }
                s.push_str(n);
            }
            if !block.lines.is_empty() { s.push('\n') }

            let mut is_first_line = true;
            for line in &block.lines {
                if is_first_line { is_first_line = false }
                else { s.push('\n') }
                match line {
                    Line::TextBlock(row) => s.push_str(&row.to_string(chords, rhythm)),
                    Line::ChordsLine(cs) => if chords {
                        for chord in cs {
                            s.push_str(&chord.text);
                            s.push(' ');
                        }
                    },
                    Line::PlainText(text) => s.push_str(text),
                    Line::Tab(text) => s.push_str(text),
                    Line::EmptyLine => {}
                }
            }
        }

        return s
    }

    pub fn get_colored(&self) -> String {
        let (chords, rhythm, notes, fingerings) = self.metadata.get_show_options();

        let mut s = String::new();
        if !self.metadata.artist.is_empty() && !self.metadata.title.is_empty() {
            s.push_str(& format!("{} - {}\n\n", self.metadata.artist, self.metadata.title));
        }

        if let Some(n) = &self.notes && notes {
            for line in n.lines() {
                s.push_str( &format!("{}\n", line.with(NOTES_COLOR)) );
            }
        }

        if chords && fingerings {
            let fings = self.get_fingerings();
            
            if let Some(text) = sum_text_in_fingerings(&fings, None) {
                s.push_str(&text);
            }
        }
        
        let mut is_first = true;
        for block in &self.blocks {
            if is_first { is_first = false }
            else { s.push('\n') }

            if let Some(title) = &block.title {
                if !is_first && !title.is_empty() { s.push('\n') }
                s.push_str(&format!("{}", title.clone().with(TITLE_COLOR)));
                s.push(' ');
            }
            if let Some(n) = &block.notes && notes {
                if !is_first && block.title.is_none() { s.push('\n') }
                s.push_str(&format!("{}", n.clone().with(NOTES_COLOR)));
            }
            if !block.lines.is_empty() { s.push('\n') }
            
            let mut is_first_line = true;
            for line in &block.lines {
                if is_first_line { is_first_line = false }
                else { s.push('\n') }
                line.get_colored(&mut s, chords, rhythm);
            }
        }
        
        return s
    }

    pub fn detect_key(&mut self) -> Note {
        let this_keys: Vec<Note> = self.chord_list
            .iter()
            .map(|c| c.get_keynote() )
            .collect();

        let total: f32 = this_keys.len() as f32;
        let mut key: Option<Key> = None;
        let mut similarity: f32 = 0.0; // Значение в процентах

        for key_block in KEYS {
            let keynote = key_block[0];
            let mut matches = 0.0;
            for key in &this_keys {
                if key_block.iter().any(|k| k == key) {
                    matches += 1.0
                }
            }
            let this_precent: f32 = (matches * 100.0) / total;
            if this_precent > similarity {
                similarity = this_precent;
                key = Some(Key::from_note(keynote));
            }
        }

        self.metadata.key = key;
        if let Some(k) = key {
            k.get_note()
        } else {
            Note::C
        }
    }

    pub fn transpose(&mut self, steps: i32) {
        if let Some(key) = self.metadata.key {
            self.metadata.key = Some(key.transpose(steps))
        }
        for chord in &mut self.chord_list { *chord = chord.transpose(steps) }
        for block in &mut self.blocks {
            for line in &mut block.lines {
                match line {
                    Line::TextBlock(row) => {
                        if let Some(chords) = &mut row.chords {
                            for chord in chords {
                                match chord {
                                    ChordPosition::UpBeat(chord) => *chord = chord.transpose(steps),
                                    ChordPosition::OnIndex{chord, ..} => *chord = chord.transpose(steps)
                                }
                            }
                        }
                    },
                    Line::ChordsLine(chords) =>
                        chords.iter_mut().for_each(|c| *c = c.transpose(steps)),
                    _ => {}
                }
            }
        }
    }

    pub fn get_fingerings(&self) -> Vec<Fingering> {
        let mut fings = Vec::new();
        
        #[cfg(not(feature = "song_library"))]
        for f in self.get_all_fingerings() {
            fings.push(f[0].clone());
        }
        
        #[cfg(feature = "song_library")]
        for chord in &self.chord_list {
            if let Ok(Some(f)) = crate::song_library::get_fingering(&chord.text) {
                fings.push(f)
            } else {
                fings.push( chord.get_fingerings(&STANDART_TUNING)[0].clone() )
            }
        }

        return fings
    }

    pub fn get_all_fingerings(&self) -> Vec<Vec<Fingering>> {
        let mut fings = Vec::new();
        for chord in &self.chord_list {
            fings.push(chord.get_fingerings(&STANDART_TUNING));
        }

        return fings
    }

    pub fn get_for_editing(&self) -> String {
        let mut s = String::new();

        self.metadata.get_for_editing(&mut s);


        if let Some(n) = &self.notes {
            s.push_str(SONG_NOTE_START_SYMBOL);
            s.push('\n');

            s.push_str(n);
            s.push('\n');

            s.push_str(SONG_NOTE_END_SYMBOL);
            s.push('\n');

            s.push('\n');
        }

        let mut is_first = true;
        for block in &self.blocks {
            if is_first { is_first = false }
            else { s.push_str("\n\n") }
            block.get_for_editing(&mut s);
        }

        return s
    }

    pub fn generate_rhythm_from_chords(&mut self) {
        for block in &mut self.blocks {
            for line in &mut block.lines {
                if let Line::TextBlock(row) = line {
                    row.generate_rhythm_from_chords();
                }
            }
        }
    }

    pub fn change_from_edited_str(&mut self, text: &str) {
        let mut blocks: Vec<Block> = Vec::new();
        let mut metadata_text = String::new();

        let mut block_buf = String::new();
        let mut is_in_block = false;

        let mut note_buf = String::new();
        let mut is_in_note = false;

        let mut is_in_metadata = false;
        for line in text.lines() {
            if line.starts_with(SONG_NOTE_START_SYMBOL) {
                is_in_note = true;
            } else if line.starts_with(SONG_NOTE_END_SYMBOL) {
                is_in_note = false;
            } else if is_in_note {
                if !note_buf.is_empty() {
                    note_buf.push('\n')
                }
                note_buf.push_str(line);

            } else if line.starts_with(BLOCK_START) { is_in_block = true }
            else if line.starts_with(BLOCK_END) {
                is_in_block = false;
                blocks.push( Block::from_edited(&block_buf) );
                block_buf.clear();
            } else if is_in_block { block_buf.push_str(line); block_buf.push('\n'); }

            else if line.starts_with(METADATA_START) { is_in_metadata = true }
            else if line.starts_with(METADATA_END) {
                is_in_metadata = false;
                self.metadata.change_from_edited_str(&metadata_text);
            } else if is_in_metadata {
                metadata_text.push_str(line);
                metadata_text.push('\n');
            }
        }


        self.notes = if note_buf.is_empty() { None } else { Some(note_buf) };
        self.blocks = blocks;
        self.chord_list = self.get_chord_list();
    }

    fn get_chord_list(&self) -> Vec<Chord> {
        let mut list = Vec::new();
        for block in &self.blocks {
            for line in &block.lines {
                match line {
                    Line::TextBlock(row) => {
                        if let Some(chords) = &row.chords {
                            for chord in chords {
                                match chord {
                                    ChordPosition::UpBeat(chord) => if list.iter().all(|c| c != chord) {
                                        list.push(chord.clone());
                                    },
                                    ChordPosition::OnIndex{chord, ..} => if list.iter().all(|c| c != chord) {
                                        list.push(chord.clone());
                                    },
                                }
                            }
                        }
                    },
                    Line::ChordsLine(chords) => for chord in chords {
                        if list.iter().all(|c| c != chord) {
                            list.push(chord.clone());
                        }
                    },
                    _ => {}
                }
            }
        }

        return list;
    }
}

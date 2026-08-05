pub mod block;
pub mod row;
pub mod chord;

use std::fmt;
use std::collections::{HashSet, BTreeSet, BTreeMap};
use serde::{Serialize, Deserialize};

#[cfg(feature = "colored")]
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
    SONG_AUTOSCROLL_DELAY_SYMBOL,
    SONG_SHOW_OPTIONS_SYMBOL,
    SONG_TAGS_SYMBOL,
    SONG_FINGERINGS_START,
    SONG_FINGERINGS_END,

    BLOCK_START,
    BLOCK_END,
    STANDART_TUNING,
    
    SONG_NOTE_START_SYMBOL,
    SONG_NOTE_END_SYMBOL,

    KEYS
};
use crate::{Note, Key};
use crate::sum_text_in_fingerings;
use crate::song::chord::Chord;
use crate::song::block::{Block, Line};
use crate::song::row::ChordPosition;

#[cfg(feature = "colored")]
use crate::{TITLE_COLOR, NOTES_COLOR, CHORDS_COLOR};


#[derive(Serialize, Deserialize, Debug)]
pub struct Song {
    pub metadata: Metadata,
    pub chord_list: HashSet<Chord>,
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
    pub autoscroll_delay: Option<u64>, // in seconds
    pub show_options: Option<ShowOptions>,
    pub tags: Option<BTreeSet<String>>, // in Option for compatibility
    pub fingerings: Option<BTreeMap<Chord, Fingering>>
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy)]
pub struct ShowOptions {
    pub chords: bool,
    pub rhythm: bool,
    pub notes: bool,
    pub fingerings: bool,
}


impl Metadata {
    pub fn new(title: String, artist: String) -> Self{
        Self {
            title,
            artist,
            key: None,
            capo: None,
            autoscroll_speed: None,
            autoscroll_delay: None,
            show_options: None,
            tags: None,
            fingerings: None,
        }
    }

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

        s.push_str(SONG_AUTOSCROLL_DELAY_SYMBOL);
        if let Some(delay) = self.autoscroll_delay {
            s.push_str(&delay.to_string())
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

        if let Some(tags) = &self.tags {
            s.push_str(SONG_TAGS_SYMBOL);
            s.push_str(&
                tags.iter().enumerate()
                .map(|(i, t)| {
                    if i == 0 {
                        t.clone()
                    } else {
                        ", ".to_string() + t
                    }
                }).collect::<String>()
            );
            s.push('\n');
        }

        if let Some(fingerings) = &self.fingerings {
            s.push_str(SONG_FINGERINGS_START);
            s.push('\n');
            for (chord, fingering) in fingerings {
                s.push_str(&chord.to_string());
                s.push('\t');
                
                s.push_str(&fingering.get_for_editing());
                s.push('\n');
            }
            s.push_str(SONG_FINGERINGS_END);
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
        let mut autoscroll_delay: Option<u64> = None;
        let mut opts: Option<ShowOptions> = None;
        let mut tags: BTreeSet<String> = BTreeSet::new();

        let mut fingerings_lines = String::new();
        let mut is_in_fingerings = false;
        for line in text.lines() {
            if line.starts_with(SONG_FINGERINGS_END) {
                is_in_fingerings = false;
            } else if line.starts_with(SONG_FINGERINGS_START) {
                is_in_fingerings = true;
            } else if is_in_fingerings {
                fingerings_lines.push_str(line);
                fingerings_lines.push('\n');

            } else if line.starts_with(SONG_TITLE_SYMBOL) {
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
            } else if line.starts_with(SONG_AUTOSCROLL_DELAY_SYMBOL) {
                if let Ok(d) = line[SONG_AUTOSCROLL_DELAY_SYMBOL.len()..].trim().parse::<u64>() {
                    autoscroll_delay = Some(d)
                }
            } else if line.starts_with(SONG_SHOW_OPTIONS_SYMBOL) {
                let opts_str = line[SONG_SHOW_OPTIONS_SYMBOL.len()..].trim();
                opts = Some( ShowOptions {
                    chords: opts_str.contains('c'),
                    rhythm: opts_str.contains('r'),
                    notes: opts_str.contains('n'),
                    fingerings: opts_str.contains('f'),
                });
            } else if line.starts_with(SONG_TAGS_SYMBOL) {
                let tags_str = line[SONG_TAGS_SYMBOL.len()..].trim();
                for tag in tags_str.split(", ") {
                    if tag.trim().is_empty() { continue };
                    tags.insert(tag.to_string());
                }
            }
        }

        if !title.is_empty() { self.title = title }
        if !artist.is_empty() { self.artist = artist }
        self.key = key;
        self.capo = capo;
        self.autoscroll_speed = autoscroll_speed;
        self.autoscroll_delay = autoscroll_delay;
        self.show_options = opts;
        self.tags = if tags.is_empty() { None } else { Some(tags) };
        self.parse_fingerings(fingerings_lines);
    }
    fn parse_fingerings(&mut self, s: String) {
        if s.is_empty() {
            self.fingerings = None;
            return;
        }

        let mut fingerings = BTreeMap::new();
        for line in s.lines() {
            if let Some(i) = line.find('\t') {
                let chord = 
                    if let Some(c) = Chord::new(&line[..i]) { c } else { continue };

                let mut strings = ["x"; super::STRINGS];
                for (i, c) in line[i + 1..].split_whitespace().enumerate() {
                    if i > strings.len() - 1 { break }
                    strings[i] = c;
                }
                let fingering = 
                    if let Some(f) = 
                        Fingering::from(
                            strings,
                            Some(line[..i].to_string())
                        ) { f } else { continue };

                fingerings.insert(chord, fingering);
            }
        }

        self.fingerings = if fingerings.is_empty() {
            None
        } else {
            Some(fingerings)
        };
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
            metadata: Metadata::new(title.to_string(), artist.to_string()),
            chord_list: HashSet::new(),
            blocks: Vec::new(),
            notes: None
        }
    }


    #[cfg(feature = "colored")]
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
        let mut last_block_key = self.metadata.key;
        for block in &self.blocks {
            // is key changed
            let (key, is_modulation) = if chords {
                let key = 
                    if block.key.is_some() { block.key }
                    else { self.metadata.key };

                let m = last_block_key != key;
                last_block_key = key;


                (key, m)
            } else { (None, false) };

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
            if let Some(k) = key && chords && is_modulation {
                s.push_str(&format!("\n{} {}",
                        "Key:".to_string().with(NOTES_COLOR),
                        k.to_string().with(CHORDS_COLOR)
                    ));
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
        let is_flat = if let Some(key) = self.metadata.key {
            let new_key = key.transpose(steps);
            self.metadata.key = Some(new_key);
            new_key.is_flat()
        } else { false };

        self.chord_list = self.chord_list.iter().map(|c| c.transpose(steps, is_flat)).collect();
        for block in &mut self.blocks {
            let is_flat = if let Some(key) = block.key {
                let new_key = key.transpose(steps);
                block.key = Some(new_key);
                new_key.is_flat()
            } else { is_flat };
            for line in &mut block.lines {
                match line {
                    Line::TextBlock(row) => {
                        if let Some(chords) = &mut row.chords {
                            for chord in chords {
                                match chord {
                                    ChordPosition::UpBeat(chord) => *chord = chord.transpose(steps, is_flat),
                                    ChordPosition::OnIndex{chord, ..} => *chord = chord.transpose(steps, is_flat)
                                }
                            }
                        }
                    },
                    Line::ChordsLine(chords) =>
                        chords.iter_mut().for_each(|c| *c = c.transpose(steps, is_flat)),
                    _ => {}
                }
            }
        }
    }

    pub fn get_fingerings(&self) -> Vec<Fingering> {
        let mut fings: Vec<Fingering> = Vec::new();
        
        #[cfg(not(feature = "song_library"))]
        for f in self.get_all_fingerings() {
            fings.push(f[0].clone());
        }
        
        #[cfg(feature = "song_library")]
        for chord in &self.chord_list {
            if let Some(fingerings) = &self.metadata.fingerings
            && let Some(f) = fingerings.get(chord) {
                fings.push(f.clone())
            } else if let Ok(Some(f)) = crate::song_library::get_fingering(&chord.to_string()) {
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

    fn get_chord_list(&self) -> HashSet<Chord> {
        let mut set = HashSet::new();
        for block in &self.blocks {
            for line in &block.lines {
                match line {
                    Line::TextBlock(row) => {
                        if let Some(chords) = &row.chords {
                            for chord in chords {
                                match chord {
                                    ChordPosition::UpBeat(chord) => {
                                        set.insert(chord.clone());
                                    },
                                    ChordPosition::OnIndex{chord, ..} => {
                                        set.insert(chord.clone());
                                    },
                                }
                            }
                        }
                    },
                    Line::ChordsLine(chords) => for chord in chords {
                        set.insert(chord.clone());
                    },
                    _ => {}
                }
            }
        }

        return set;
    }


    // yes, I broke the compatibility again
    pub fn chord_fix(&mut self) -> bool {
        if self.chord_list.iter().next().is_none_or(|c| c.compatibility_check()) {
            return false;
        }


        self.chord_list = self.chord_list.iter().map(|c| {
            let mut chord = c.clone();
            chord.compatibility_fix();
            chord
        } ).collect::<HashSet<Chord>>();

        for block in self.blocks.iter_mut() {
            for line in block.lines.iter_mut() {
                match line {
                    Line::TextBlock(row) => {
                        if let Some(chords) = &mut row.chords {
                            for chord in chords.iter_mut() {
                                match chord {
                                    ChordPosition::UpBeat(chord) => chord.compatibility_fix(),
                                    ChordPosition::OnIndex{chord, ..} => chord.compatibility_fix(),
                                };
                            }
                        }
                    },
                    Line::ChordsLine(chords) => for chord in chords {
                        chord.compatibility_fix();
                    },
                    _ => {}
                }
            }
        }


        true
    }
}

impl fmt::Display for Song {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let (chords, rhythm, notes, fingerings) = self.metadata.get_show_options();
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


        let mut is_first = true;
        let mut last_block_key = self.metadata.key;
        for block in &self.blocks {
            // is key changed
            let (key, is_modulation) = if chords {
                let key = 
                    if block.key.is_some() { block.key }
                    else { self.metadata.key };

                let m = last_block_key != key;
                last_block_key = key;


                (key, m)
            } else { (None, false) };

            if is_first { is_first = false }
            else { s.push('\n') }

            if let Some(title) = &block.title {
                if !is_first && !title.is_empty() { s.push('\n') }
                s.push_str(title);
                s.push(' ');
            }
            if let Some(n) = &block.notes && notes {
                if !is_first && block.title.is_none() { s.push('\n') }
                s.push_str(n);
            }
            if let Some(k) = key && chords && is_modulation {
                s.push_str(&format!("\nKey: {}", k));
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
                            s.push_str(&chord.to_string());
                            s.push(' ');
                        }
                    },
                    Line::NoteLine(text) => if notes {
                        s.push_str(text);
                    } else { s.pop(); },
                    Line::PlainText(text) => s.push_str(text),
                    Line::Tab(text) => s.push_str(text),
                    Line::EmptyLine => {}
                }
            }
        }


        write!(f, "{s}")
    }
}

use serde::{Serialize, Deserialize};
use crossterm::style::Stylize;

use crate::song::row::Row;
use crate::song::chord::Chord;
use crate::{
    BLOCK_START,
    BLOCK_END,
    TITLE_SYMBOL,
    CHORDS_SYMBOL,
    RHYTHM_SYMBOL,
    TEXT_SYMBOL,
    EMPTY_LINE_SYMBOL,
    CHORDS_LINE_SYMBOL,
    PLAIN_TEXT_START,
    PLAIN_TEXT_END,
    TAB_START_SYMBOL,
    TAB_END_SYMBOL,
    BLOCK_NOTE_SYMBOL,
    
    CHORDS_COLOR
};


#[derive(Serialize, Deserialize, Debug)]
pub struct Block {
    pub title: Option<String>,
    pub lines: Vec<Line>,
    pub notes: Option<String>
}

#[derive(Serialize, Deserialize, Debug, PartialEq)]
pub enum Line {
    TextBlock(Row),
    ChordsLine(Vec<Chord>),
    PlainText(String),
    Tab(String),
    EmptyLine
}

impl Line {
    pub fn get_colored(
        &self,
        s: &mut String,
        needs_chords: bool,
        needs_rhythm: bool
    ) {
        match self {
            Line::TextBlock(row) => row.get_colored(s, needs_chords, needs_rhythm),
            Line::ChordsLine(chords) => if needs_chords {
                let mut c = String::new();
                for chord in chords {
                    c.push_str(&chord.text);
                    c.push(' ');
                }
                s.push_str(&format!("{}", c.with(CHORDS_COLOR)));
                s.push('\n');
            },
            Line::PlainText(text) => s.push_str(&text),
            Line::Tab(text) => s.push_str(&text),
            Line::EmptyLine => s.push('\n')
        }
    }
}

impl Block {
    pub fn get_for_editing(&self, s: &mut String) {
        s.push_str(BLOCK_START);

        if let Some(title) = &self.title {
            s.push('\n');
            s.push_str(TITLE_SYMBOL);
            s.push_str(&title);
        }
        if let Some(n) = &self.notes {
            s.push('\n');
            s.push_str(BLOCK_NOTE_SYMBOL);
            s.push_str(n);
        }
        if !self.lines.is_empty() { s.push('\n') }

        let mut is_first_row = true;
        for line in &self.lines {
            if is_first_row { is_first_row = false }
            else { s.push('\n') }
            match line {
                Line::TextBlock(row) => row.get_for_editing(s),
                Line::ChordsLine(chords) => {
                    s.push_str(CHORDS_LINE_SYMBOL);
                    for chord in chords {
                        s.push_str(&chord.text);
                        s.push(' ');
                    }
                    s.push('\n');
                },
                Line::PlainText(text) => {
                    s.push_str(PLAIN_TEXT_START);
                    s.push('\n');
                    
                    s.push_str(text);
                    s.push('\n');
                    
                    s.push_str(PLAIN_TEXT_END);
                    s.push('\n');
                },
                Line::Tab(text) => {
                    s.push_str(TAB_START_SYMBOL);
                    s.push('\n');
                    
                    s.push_str(text);
                    s.push('\n');
                    
                    s.push_str(TAB_END_SYMBOL);
                    s.push('\n');
                },
                Line::EmptyLine =>  {
                    s.push_str(EMPTY_LINE_SYMBOL);
                    s.push('\n');
                }
            }
        }

        if !s.ends_with('\n') { s.push('\n') }
        s.push_str(BLOCK_END);
        s.push('\n');
    }

    pub fn from_edited(text: &str) -> Self {
        let mut title: Option<String> = None;
        let mut notes: Option<String> = None;
        let mut lines: Vec<Line> = Vec::new();


        let mut is_plain_text = false;
        let mut plain_text_buf = String::new();

        let mut is_tab = false;
        let mut tab_buf = String::new();

        
        let mut row_buf = String::new();
        for line in text.lines() {
            if line.starts_with(PLAIN_TEXT_END) {
                is_plain_text = false;
                lines.push( Line::PlainText(plain_text_buf) );
                plain_text_buf = String::new();
            } else if is_plain_text {
                if !plain_text_buf.is_empty() {
                    plain_text_buf.push('\n');
                }
                plain_text_buf.push_str(line);
            } else if line.starts_with(PLAIN_TEXT_START) {
                is_plain_text = true;
            
            } else if line.starts_with(TAB_END_SYMBOL) {
                is_tab = false;
                lines.push( Line::Tab(tab_buf) );
                tab_buf = String::new();
            } else if is_tab {
                if !tab_buf.is_empty() {
                    tab_buf.push('\n');
                }
                tab_buf.push_str(line);
            } else if line.starts_with(TAB_START_SYMBOL) {
                is_tab = true;

            } else if line.starts_with(TITLE_SYMBOL) {
                let t = line[TITLE_SYMBOL.len()..].trim().to_string();
                if !t.is_empty() { title = Some(t) }
            } else if line.starts_with(BLOCK_NOTE_SYMBOL) {
                let n = line[BLOCK_NOTE_SYMBOL.len()..].trim().to_string();
                if !n.is_empty() { notes = Some(n) }
            } else if line.starts_with(EMPTY_LINE_SYMBOL) {
                lines.push(Line::EmptyLine);
            } else if line.starts_with(CHORDS_LINE_SYMBOL) {
                let mut chords: Vec<Chord> = Vec::new();
                for maybe_chord in line.split_whitespace() {
                    if let Some(chord) = Chord::new(maybe_chord) {
                        chords.push(chord);
                    }
                }
                lines.push( Line::ChordsLine(chords) );
            } else if line.starts_with(CHORDS_SYMBOL) || line.starts_with(RHYTHM_SYMBOL) {
                row_buf.push_str(line);
                row_buf.push('\n');
            } else if line.starts_with(TEXT_SYMBOL) {
                row_buf.push_str(line);
                lines.push( Line::TextBlock(Row::from_edited(&row_buf)) );
                row_buf.clear();
            }
        }

        return Self { title, lines, notes }
    }
}

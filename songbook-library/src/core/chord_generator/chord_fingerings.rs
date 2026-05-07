use std::collections::BTreeMap;
use serde::{Serialize, Deserialize};
use crossterm::terminal::size;

use crate::chord_generator::chord_fingerings::StringState::*;
use crate::chord_generator::STRINGS;


#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
pub struct Fingering {
    title: Option<String>,
    fret_num: u8,
    chord_size: u8,
    strings: [StringState; STRINGS],
    bars: Option<BTreeMap<u8, u8>> // лад - верхушка баррэ 
}                                  // (баррэ начинается всегда с первой струны)

#[derive(Serialize, Deserialize, Debug, Copy, Clone, PartialEq)]
pub enum StringState {
    Open,
    Muted,
    FrettedOn(u8)
}

impl Fingering {
    pub fn new(strings: [StringState; STRINGS], title: Option<String>) -> Option<Self> {
        let mut fret_num: u8 = 25;
        for s in &strings {
            if let FrettedOn(f) = s {
                if *f < fret_num { fret_num = *f }
            }
        }

        let mut chord_size: u8 = 0;
        for s in &strings {
            if let FrettedOn(f) = s {
                let current_size: u8 = (f + 1) - fret_num;
                if chord_size < current_size { chord_size = current_size }
            }
        }

        let mut bars = BTreeMap::new();
        let mut already_fretted = Vec::new();
        for fret in 0..chord_size {
            let fret = fret + fret_num;
            let mut bar_head: Option<u8> = None;
            let mut string_counter: u8 = 0;
            let mut fretted_counter = 0;
            for s in &strings {
                match s {
                    FrettedOn(f) => if *f == fret {
                        if already_fretted.iter().all(|string| *string > string_counter)
                        || already_fretted.is_empty() || fret == fret_num {
                            bar_head = Some(string_counter);
                        } else {
                            bar_head = None;
                            break
                        }
                        already_fretted.push(string_counter);
                        fretted_counter += 1;
                    },
                    Open => {
                        bar_head = None;
                        break
                    },
                    Muted => {}
                }
                string_counter += 1;
            }
            if let Some(h) = bar_head && fretted_counter > 1 { bars.insert(fret, h); }
        }

        let mut fretted = 0;
        for fret in 0..chord_size {
            let fret = fret + fret_num;
            if let Some(_) = bars.get(&fret) { continue }
            for s in &strings {
                if let FrettedOn(f) = s && *f == fret {
                    fretted += 1;
                }
            }
        }

        if fretted + bars.len() > 4 { return None }
        Some( Self {
            title,
            fret_num,
            chord_size,
            strings,
            bars: if bars.is_empty() { None } else { Some(bars) }
        } )
    }

    pub fn get_text(&self) -> String {
        let mut text = String::new();

        let strings: Vec<&StringState> = self.strings.iter().rev().collect();
        // нулевой проход для отрисовки вначале открытых и заглушенных струн
        for s in &strings {
            text.push_str(match s {
                Open => "O ",
                Muted => "X ",
                FrettedOn(_) => "  "
            })
        }
        text.push_str( &format!("  \n{}   ",
                if self.fret_num - 1 == 0 { "=".repeat(11) }
                else { "-".repeat(11) }));
        text.push('\n');

        let mut fret_counter = self.fret_num;
        for i in 0..self.chord_size {
            let current_fret = i + self.fret_num;
            text.push_str( &"| ".repeat(6) );
            text.push_str("  ");

            text.push('\n');
            let is_bar: bool;
            if let Some(bars) = &self.bars {
                if let Some(bar_head) = bars.get(&current_fret) {
                    let bar: usize = (bar_head + 1).into();
                    text.push_str( &"| ".repeat(STRINGS - bar) );
                    text.push_str( &">>".repeat(bar - 1) );
                    text.push_str("> ");
                    is_bar = true;
                } else { is_bar = false }
            } else { is_bar = false }

            if !is_bar {
                for s in &strings {
                    text.push_str(&
                        if let FrettedOn(f) = s && *f == (current_fret) {
                            "o ".to_string()
                        } else { "| ".to_string() }
                    )
                }
            }

            text.push_str(&fret_counter.to_string());
            if fret_counter < 10 { text.push(' ') }
            text.push('\n');

            text.push_str( &"| ".repeat(6) );
            text.push_str("  \n");

            text.push_str( &"-".repeat(11) );
            text.push_str("   ");
            if (i + 1) < self.chord_size { text.push('\n') }

            fret_counter += 1;
        }

        // длина каждой строки 14 символов
        return text
    }
    
    pub fn get_title(&self) -> Option<String> {
        self.title.clone()
    }
}

pub fn sum_text_in_fingerings(fingerings: &Vec<Fingering>, width: Option<usize>) -> Option<String> {
    let width = if let Some(width) = width { width }
    else { <u16 as Into<usize>>::into(
        if let Ok( (cols, _rows) ) = size() { cols } else { return None }
    )};

    let indent: usize = 5;
    let line_width: usize = 14;
    let fingerings_in_line: usize = width / (line_width + indent);

    let mut s = String::new();

    let mut fing_blocks = Vec::new();
    let mut buf: Vec<Vec<String>> = Vec::new();
    let mut counter = 0;
    for f in fingerings {
        counter += 1;
        if counter >= fingerings_in_line {
            counter = 0;
            fing_blocks.push(buf);
            buf = Vec::new();
        }

        let title = if let Some(title) = &f.title {
            if title.len() > 4 {
                title.to_string() + &" ".repeat(line_width - title.len())
            } else {
                let left_part_width = ( line_width - title.len() ) / 2 - title.len();
                let right_part_width = line_width - left_part_width - title.len();
            
                " ".repeat(left_part_width) + title + &" ".repeat(right_part_width)
            }
        }
        else { " ".repeat(line_width) };

        let mut fing = Vec::new();
        fing.push(title);

        for line in f.get_text().lines() {
            fing.push(line.to_string());
        }

        buf.push(fing);
    }
    if !buf.is_empty() { fing_blocks.push(buf) }

    for block in &fing_blocks {
        let mut max_lines = 0;
        for f in block {
            if max_lines < f.len() { max_lines = f.len() }
        }
        
        let left_indent = (  width - ( block.len() * (line_width + indent) )  ) / 2;


        for line_num in 0..max_lines {
            s.push_str( &" ".repeat(left_indent) );
            for f in block {
                s.push_str(&
                    if let Some(line) = f.get(line_num) { line.clone() }
                    else { " ".repeat(line_width) },
                );

                s.push_str( &" ".repeat(indent) );
            }
            s.push('\n');
        }
        s.push_str("\n\n");
    }
    
    return Some(s)
}

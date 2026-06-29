use serde::{Serialize, Deserialize};
use crossterm::style::Stylize;

use crate::song::chord::Chord;
use crate::{
    CHORDS_SYMBOL,
    RHYTHM_SYMBOL,
    TEXT_SYMBOL,
    
    CHORDS_COLOR,
    RHYTHM_COLOR
};


#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
pub enum Beat {
    OnIndex{ index: usize, symbol: char },
    UpBeat(char)
}

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
pub enum ChordPosition {
    OnIndex{ index: usize, chord: Chord },
    UpBeat(Chord)
}

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
pub struct Row {
    pub rhythm: Option<Vec<Beat>>,
    pub chords: Option<Vec<ChordPosition>>, // позиция в строке - аккорд
    pub text: Option<String>
}

impl Row {
    pub fn to_string(&self, needs_chords: bool, needs_rhythm: bool) -> String {
        let mut s = String::new();
        let (chords, rhythm, text) = self.get_strings();
        if needs_chords || needs_rhythm {
            if needs_chords && !chords.is_empty() {
                s.push_str(&chords);
                s.push('\n');
            }

            if needs_rhythm && !rhythm.is_empty() {
                s.push_str(&rhythm);
                s.push('\n');
            }
        }


        if !text.is_empty() {
            s.push_str(&text);
        }


        return s
    }


    pub fn get_colored(&self, s: &mut String, chords: bool, rhythm: bool) {
        let (chords_line, rhythm_line, text) = self.get_strings();

        if !chords_line.is_empty() && chords {
            s.push_str(&format!("{}", chords_line.with(CHORDS_COLOR)));
            s.push('\n');
        }

        if !rhythm_line.is_empty() && rhythm {
            s.push_str(&format!("{}", rhythm_line.with(RHYTHM_COLOR)));
            s.push('\n');
        }

        if !text.is_empty() {
            s.push_str(&text);
        }
    }


    pub fn get_for_editing(&self, s: &mut String) {
        let (mut chords_line, mut rhythm_line, text) = self.get_strings();

        let mut max_len = text.chars().count();
        let chords_len = chords_line.chars().count();
        let rhythm_len = rhythm_line.chars().count();
        if chords_len > max_len { max_len = chords_len }
        if rhythm_len > max_len { max_len = rhythm_len }

        chords_line.push_str( &" ".repeat(max_len - chords_len) );
        rhythm_line.push_str( &" ".repeat(max_len - rhythm_len) );

        
        s.push_str(CHORDS_SYMBOL);
        s.push_str(&chords_line);
        s.push('\n');
        
        s.push_str(RHYTHM_SYMBOL);
        s.push_str(&rhythm_line);
        s.push('\n');

        s.push_str(TEXT_SYMBOL);
        s.push_str(&text);
        s.push('\n');
    }

    pub fn from_edited(text: &str) -> Self {
        let mut chord_line = String::new();
        let mut rhythm_line = String::new();
        let mut text_line = String::new();

        for line in text.lines() {
            if line.starts_with(CHORDS_SYMBOL) {
                chord_line.push_str(&line[CHORDS_SYMBOL.len()..])
            } else if line.starts_with(RHYTHM_SYMBOL) {
                rhythm_line.push_str(&line[RHYTHM_SYMBOL.len()..])
            } else if line.starts_with(TEXT_SYMBOL) {
                text_line.push_str(&line[TEXT_SYMBOL.len()..])
            }
        }

        let whitespaces = {
            let mut counter = 0;
            for c in text_line.chars() {
                if c == ' ' { counter += 1 }
                else { break }
            }

            counter
        };


        return Self {
            chords: chords_from_edited(&chord_line, whitespaces),
            rhythm: rhythm_from_edited(&rhythm_line, whitespaces),
            text: if text_line.is_empty() { None } else { Some(text_line.trim().to_string()) },
        }
    }

    pub fn generate_rhythm_from_chords(&mut self) {
        if let Some(chords) = &self.chords {
            if self.rhythm.is_some() { return }

            let mut rhythm = Vec::new();
            for chord in chords {
                match chord {
                    ChordPosition::UpBeat(_) =>
                        rhythm.push( Beat::UpBeat('↓') ),
                    ChordPosition::OnIndex{ index, .. } =>
                        rhythm.push( Beat::OnIndex{ index: *index, symbol: '↓' } )
                }
            }

            if !rhythm.is_empty() { self.rhythm = Some(rhythm) }
        }
    }
    
    
    pub fn get_strings(&self) -> (String, String, String) {
        let mut chord_string = String::new();
        let mut rhythm_string = String::new();
        let mut text_string = String::new();
        
        if self.text.is_none() {
            if let Some(chords) = &self.chords {
                for chord in chords {
                    match chord {
                        ChordPosition::UpBeat(chord) => {
                            chord_string.push_str(&chord.text);
                            chord_string.push(' ');
                        }
                        ChordPosition::OnIndex { chord, .. } => {
                            chord_string.push_str(&chord.text);
                            chord_string.push(' ');
                        }
                    }
                }
            }
            if let Some(beats) = &self.rhythm {
                for beat in beats {
                    match beat {
                        Beat::UpBeat(symbol) => {
                            chord_string.push(*symbol);
                            chord_string.push(' ');
                        }
                        Beat::OnIndex { symbol, .. } => {
                            chord_string.push(*symbol);
                            chord_string.push(' ');
                        }
                    }
                }
            }
            
            return (chord_string, rhythm_string, text_string)
        }
        
        
        
        // Если есть текст
        // Если есть аккорды
        if let Some(chords) = &self.chords {
            let text = self.text.as_ref().unwrap();
            let mut whitespaces_for_chords = 0;
            // Пары аккорд - отрывок текста после него
            let mut pairs: Vec<(usize, Chord, String)> = Vec::new();
            let mut text_in_start = String::new();
            let mut is_first = true;
            for (i, chord) in chords.iter().enumerate() {
                match chord {
                    ChordPosition::UpBeat(chord) => {
                        whitespaces_for_chords += 1 + chord.text.chars().count();
                        chord_string.push_str(&chord.text);
                        chord_string.push(' ');
                    },
                    ChordPosition::OnIndex { index, chord } => {
                        if *index > 0 && text_in_start.is_empty() && is_first {
                            text_in_start = text.chars().take(*index).collect::<String>();
                        }
                        if is_first { is_first = false }
                        
                        let index_new = if is_first {
                            index + text_in_start.chars().count()
                        } else {
                            *index
                        };
                        
                        let slice_for_chord = if let Some(ChordPosition::OnIndex {index: next_index, .. }) = chords.get(i + 1) {
                            text.chars().skip(index_new).take(next_index - index_new).collect::<String>()
                        } else {
                            text.chars().skip(index_new).collect::<String>()
                            
                        };
                        pairs.push((*index, chord.clone(), slice_for_chord));
                    }
                }
            }
            
            if let Some(beats) = &self.rhythm {
                let mut whitespaces_for_beats = 0;
                let mut added_indent = 0;
                let mut start_for_indexed_beats = None;
                for beat in beats {
                    match beat {
                        Beat::UpBeat(symbol) => {
                            whitespaces_for_beats += 1 + 1; // Символ + пробел
                            rhythm_string.push(*symbol);
                            rhythm_string.push(' ');
                        },
                        Beat::OnIndex { index, symbol } => {
                            let dif = index.saturating_sub(added_indent);
                            rhythm_string.push_str(&" ".repeat(dif));
                            rhythm_string.push(*symbol);
                            rhythm_string.push(' ');
                            added_indent += dif + 2;
                            if start_for_indexed_beats.is_none() {
                                start_for_indexed_beats = Some(index)
                            }
                        }
                    }
                }
                
                if whitespaces_for_beats > whitespaces_for_chords {
                    let dif = whitespaces_for_beats - whitespaces_for_chords;
                    chord_string.push_str( &" ".repeat(dif) );

                    whitespaces_for_chords = whitespaces_for_beats;
                } else {
                    if let Some(index) = start_for_indexed_beats {
                        rhythm_string.insert_str(*index, &" ".repeat(whitespaces_for_chords - whitespaces_for_beats) );
                    }
                }
            }
            
            text_string.push_str( &" ".repeat(whitespaces_for_chords) );
            // Если все аккорды UpBeat то без этого не захватывает текст вообще
            if is_first && text_in_start.is_empty() && pairs.is_empty() {
                text_in_start = text.clone()
            }
            text_string.push_str( &text_in_start );
            
            if chord_string.is_empty() {
                chord_string.push_str( &" ".repeat(whitespaces_for_chords) );
            }
            chord_string.push_str( &" ".repeat(text_in_start.chars().count()) );
            
            let mut added_indent_in_rhythm = 0;
            for (index, (index_before, chord, slice)) in pairs.iter().enumerate() {
                chord_string.push_str(&chord.text);

                if slice.chars().count() <= chord.text.chars().count() {
                    if let Some((next_index_before, _, next_slice)) = pairs.get(index + 1) {
                        chord_string.push(' ');
                        text_string.push_str(slice);
                        
                        if !slice.ends_with(" ") && !next_slice.starts_with(" ") && !next_slice.is_empty() {
                            text_string.push_str( &"-".repeat(chord.text.chars().count() - slice.chars().count() + 1) );
                        } else {
                            text_string.push_str( &" ".repeat(chord.text.chars().count() - slice.chars().count() + 1) );
                        }

                        let i = index_before + whitespaces_for_chords + added_indent_in_rhythm;

                        #[allow(clippy::collapsible_if)]
                        if !rhythm_string.is_empty() && next_index_before - index_before <= chord.text.chars().count() {
                            if let Some(i) = rhythm_string
                                .char_indices()
                                .nth(i + 1)
                                .map(|(i, _)| i) 
                            {
                                rhythm_string.insert(i, ' ');
                                added_indent_in_rhythm += 1;
                            }
                        }


                        let i = chord_string.len() - chord.text.len() - 1;
                        chord_string.insert_str(i, &" ".repeat((index_before + whitespaces_for_chords).saturating_sub(i)));
                    } else { // last pair
                        let i = chord_string.len() - chord.text.len();
                        chord_string.insert_str(i, &" ".repeat((index_before + whitespaces_for_chords).saturating_sub(i)));
                        // saturating_sub здесь не просто так

                        text_string.push_str(slice);
                    }
                } else {
                    chord_string.push_str( &" ".repeat(slice.chars().count() - chord.text.chars().count()) );
                    text_string.push_str(slice);
                }
            }
            
            
            return (chord_string, rhythm_string, text_string)
        }
        
        
        
        // Если аккордов нет но есть ритм
        if let Some(beats) = &self.rhythm {
            let mut whitespaces = 0;
            let mut added_indent = 0;
            for beat in beats {
                match beat {
                    Beat::UpBeat(symbol) => {
                        whitespaces += 1 + 1; // Символ + пробел
                        rhythm_string.push(*symbol);
                        rhythm_string.push(' ');
                    },
                    Beat::OnIndex { index, symbol } => {
                        let dif = index.saturating_sub(added_indent);
                        rhythm_string.push_str(&" ".repeat(dif));
                        rhythm_string.push(*symbol);
                        rhythm_string.push(' ');
                        added_indent += dif + 2;
                    }
                }
            }
            
            text_string.push_str( &" ".repeat(whitespaces) );
            text_string.push_str(self.text.as_ref().unwrap());
            
            return (chord_string, rhythm_string, text_string)
        }
        
        
        // Если только текст
        if let Some(text) = &self.text && text_string.is_empty() {
            text_string.push_str(text)
        }
        return (chord_string, rhythm_string, text_string)
    }
}


fn chords_from_edited(line: &str, whitespaces: usize) -> Option<Vec<ChordPosition>> {
    if line.trim().is_empty() {
        return None;
    }


    let mut chords: Vec<ChordPosition> = Vec::new();

    let line = line.to_string() + " ";
    let mut chord = String::new();
    let mut indent = 0;
    for i in line.chars() {
        indent += 1;
        if i != ' ' {
            chord.push(i);
            continue
        } else if chord.is_empty() { continue }


        if let Some(c) = Chord::new(&chord) {
            let index = indent - 1 - chord.chars().count();
            if whitespaces > index {
                chords.push(ChordPosition::UpBeat(c))
            } else {
                chords.push( ChordPosition::OnIndex {index: (index - whitespaces), chord: c} )
            }
        }

        chord.clear();
    }


    if chords.is_empty() { None }
    else { Some(chords) }
}
fn rhythm_from_edited(line: &str, whitespaces: usize) -> Option<Vec<Beat>> {
    if line.trim().is_empty() {
        return None;
    }


    let mut beats: Vec<Beat> = Vec::new();
    for (i, c) in line.chars().enumerate() {
        if c != ' ' { beats.push(
            if whitespaces > i {
                Beat::UpBeat(c)
            } else {
                Beat::OnIndex {index: (i - whitespaces), symbol: c}
            }
        ) }
    }

    if beats.is_empty() { None }
    else { Some(beats) }
}


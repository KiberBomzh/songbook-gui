use std::fmt;

use serde::{Serialize, Deserialize};
use crate::Note;
use crate::Note::*;
use crate::Fingering;
use crate::STRINGS;
use crate::chord_generator::get_fingerings;



#[derive(Serialize, Deserialize, Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
enum ChordType {
    Norm,
    Power,
    Sixth,
    SixthMinus,
    Seventh,
    MajSeventh,
    Nineth,
    Eleventh,
    Thirteenth
}

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
enum FifthState {
    Dim,
    Norm,
    Aug
}

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
enum SusOrAdd {
    No,
    Sus2,
    Sus4,
    Sus4Plus,
    Add2,
    Add4
}


#[derive(Serialize, Deserialize, Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Chord {
    text: String,
    keynote: Note,
    flat: Option<bool>, // in Option for compatibility
    minor: bool,
    chord_type: ChordType,
    fifth_state: FifthState,
    sus_or_add: SusOrAdd,
}

impl Chord {
    pub fn new(text: &str) -> Option<Self> {
        let (keynote, key_text) = match text {
            text if text.starts_with("A#") || text.starts_with("Bb") => (ASharp, &text[..2]),
            text if text.starts_with("C#") || text.starts_with("Db") => (CSharp, &text[..2]),
            text if text.starts_with("D#") || text.starts_with("Eb") => (DSharp, &text[..2]),
            text if text.starts_with("F#") || text.starts_with("Gb") => (FSharp, &text[..2]),
            text if text.starts_with("G#") || text.starts_with("Ab") => (GSharp, &text[..2]),
            text if text.starts_with('A') =>  (A, &text[..1]),
            text if text.starts_with('B') =>  (B, &text[..1]),
            text if text.starts_with('C') =>  (C, &text[..1]),
            text if text.starts_with('D') =>  (D, &text[..1]),
            text if text.starts_with('E') =>  (E, &text[..1]),
            text if text.starts_with('F') =>  (F, &text[..1]),
            text if text.starts_with('G') =>  (G, &text[..1]),
            _ => return None
        };

        let text = text[key_text.len()..].to_string();
        let minor = text.starts_with('m') && !text.starts_with("maj");
        let flat = Some(key_text.ends_with('b'));

        let fifth_state =
            if text.contains("aug") ||
                text.contains("5#") ||
                text.contains("5+") ||
                text.contains("+5") { FifthState::Aug }

            else if text.contains("dim") ||
                text.contains("5b") ||
                text.contains("5-") ||
                text.contains("-5") { FifthState::Dim }

            else { FifthState::Norm };


        let sus_or_add =
            // если третью ступень поднять ещё выше
            if text.starts_with("sus4+") ||
                text.starts_with("sus4#") { SusOrAdd::Sus4Plus }

            else if text.starts_with("sus2") { SusOrAdd::Sus2 }
            else if text.starts_with("sus4") { SusOrAdd::Sus4 }
            else if text.contains("add2") { SusOrAdd::Add2 }
            else if text.contains("add4") { SusOrAdd::Add4 }
            else { SusOrAdd::No };


        if text == "5" {
            return Some( Self { text, keynote, flat, fifth_state, sus_or_add, 
                minor: false,
                chord_type: ChordType::Power,
            } )
        } else if text.contains("9") {
            return Some( Self { text, keynote, minor, flat, fifth_state, sus_or_add,
                chord_type: ChordType::Nineth
            } )
        } else if text.contains("11") {
            return Some( Self { text, keynote, minor, flat, fifth_state, sus_or_add,
                chord_type: ChordType::Eleventh
            } )
        } else if text.contains("13") {
            return Some( Self { text, keynote, minor, flat, fifth_state, sus_or_add,
                chord_type: ChordType::Thirteenth
            } )
        } else if text.contains("maj") {
            return Some( Self { text, keynote, minor, flat, fifth_state, sus_or_add,
                chord_type: ChordType::MajSeventh
            } )
        } else if text.contains('7') {
            return Some( Self { text, keynote, minor, flat, fifth_state, sus_or_add,
                chord_type: ChordType::Seventh
            } )
        } else if text.contains("6-") || text.contains("6b") {
            return Some( Self { text, keynote, minor, flat, fifth_state, sus_or_add,
                chord_type: ChordType::SixthMinus
            } )
        } else if text.contains('6') {
            return Some( Self { text, keynote, minor, flat, fifth_state, sus_or_add,
                chord_type: ChordType::Sixth
            } )
        } else {
            return Some( Self { text, keynote, minor, flat, fifth_state, sus_or_add,
                chord_type: ChordType::Norm
            } )
        }
    }

    pub fn get_keynote(&self) -> Note {
        self.keynote
    }

    pub fn get_fingerings(&self, tuning: &[Note; STRINGS]) -> Vec<Fingering> {
        let mut notes: Vec<Note> = Vec::new();
        let key = self.keynote;
        // добавление первой ступени
        notes.push(key);


        // третья ступень
        if self.chord_type == ChordType::Power {
            notes.push( key.transpose(7) );
            return get_fingerings( tuning, &notes, Some(self.text.clone()) )
        }
        
        if self.sus_or_add == SusOrAdd::Sus2 {
            notes.push( key.transpose(2) );
        } else if self.sus_or_add == SusOrAdd::Sus4 {
            notes.push( key.transpose(5) );
        } else if self.sus_or_add == SusOrAdd::Sus4Plus {
            notes.push( key.transpose(6) );
        } else if self.minor {
            notes.push( key.transpose(3) );
        } else {
            notes.push( key.transpose(4) );
        }


        // пятая ступень
        match self.fifth_state {
            FifthState::Dim => notes.push( key.transpose(6) ),
            FifthState::Norm => notes.push( key.transpose(7) ),
            FifthState::Aug => notes.push( key.transpose(8) )
        }


        // дополнительные ноты
        if self.sus_or_add == SusOrAdd::Add2 {
            notes.push( key.transpose(2) );
        } else if self.sus_or_add == SusOrAdd::Add4 {
            notes.push( key.transpose(5) );
        } else if self.chord_type != ChordType::Norm {
            match self.chord_type {
                ChordType::SixthMinus => notes.push( key.transpose(8) ),
                ChordType::Sixth => notes.push( key.transpose(9) ),
                ChordType::Seventh => notes.push( key.transpose(10) ),
                ChordType::MajSeventh => notes.push( key.transpose(11) ),
                ChordType::Nineth => {
                    notes.push( key.transpose(2) );
                    notes.push( key.transpose(10) );
                },
                ChordType::Eleventh => {
                    notes.push( key.transpose(2) );
                    notes.push( key.transpose(5) );
                    notes.push( key.transpose(10) );
                },

                ChordType::Thirteenth => {
                    notes.push( key.transpose(2) );
                    notes.push( key.transpose(5) );
                    notes.push( key.transpose(9) );
                    notes.push( key.transpose(10) );
                },
                _ => {}

            }
        }


        return get_fingerings( tuning, &notes, Some(self.to_string()) )
    }

    pub fn transpose(&self, steps: i32, is_flat: bool) -> Self {
        let steps = steps % 12;
        if steps == 0 { return self.clone() }
        let mut chord = self.clone();
        chord.flat = Some(is_flat);

        if steps > 0 {
            for _ in 0..steps { chord.keynote.increase() }
        } else if steps < 0 {
            for _ in steps..0 { chord.keynote.decrease() }
        }

        return chord
    }


    fn keynote_in_text_check(&self) -> bool {
        !self.text.starts_with(&self.keynote.to_string()) &&
        !self.text.starts_with(&self.keynote.to_string_flat())
    }
    fn flat_check(&self) -> bool {
        self.flat.is_some()
    }
    pub fn compatibility_check(&self) -> bool {
        self.keynote_in_text_check() && self.flat_check()
    }
    pub fn compatibility_fix(&mut self) -> bool {
        if self.compatibility_check() {
            return false
        }

        if !self.keynote_in_text_check() {
            self.text = self.text[self.keynote.to_string().len()..].to_string();
        }

        if !self.flat_check() {
            self.flat = Some(false);
        }


        true
    }
}

impl fmt::Display for Chord {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let is_sharp_only = std::env::var(crate::SHARP_ONLY).is_ok_and(|var| var == "1");
        let key = 
            if let Some(f) = self.flat && f && !is_sharp_only {
                self.keynote.to_string_flat()
            } else {
                self.keynote.to_string()
            };
        write!(f, "{}{}", key, self.text)
    }
}

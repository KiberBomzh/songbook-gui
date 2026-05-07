use serde::{Serialize, Deserialize};
use crate::Note;
use crate::Note::*;
use crate::Fingering;
use crate::STRINGS;
use crate::chord_generator::get_fingerings;



#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
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

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
enum FifthState {
    Dim,
    Norm,
    Aug
}

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
enum SusOrAdd {
    No,
    Sus2,
    Sus4,
    Sus4Plus,
    Add2,
    Add4
}


#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
pub struct Chord {
    pub text: String,
    keynote: Note,
    minor: bool,
    chord_type: ChordType,
    fifth_state: FifthState,
    sus_or_add: SusOrAdd,
}

impl Chord {
    pub fn new(text: &str) -> Option<Self> {
        let (keynote, key_text) = match text {
            text if text.starts_with("A#") || text.starts_with("Bb") => (ASharp, "A#"),
            text if text.starts_with("C#") || text.starts_with("Db") => (CSharp, "C#"),
            text if text.starts_with("D#") || text.starts_with("Eb") => (DSharp, "D#"),
            text if text.starts_with("F#") || text.starts_with("Gb") => (FSharp, "F#"),
            text if text.starts_with("G#") || text.starts_with("Ab") => (GSharp, "G#"),
            text if text.starts_with('A') =>  (A, "A"),
            text if text.starts_with('B') =>  (B, "B"),
            text if text.starts_with('C') =>  (C, "C"),
            text if text.starts_with('D') =>  (D, "D"),
            text if text.starts_with('E') =>  (E, "E"),
            text if text.starts_with('F') =>  (F, "F"),
            text if text.starts_with('G') =>  (G, "G"),
            _ => return None
        };

        let text_after_key = &text[key_text.len()..];
        let text = text.to_string();
        let minor = text_after_key.starts_with('m') && !text_after_key.starts_with("maj");

        let fifth_state =
            if text_after_key.contains("aug") ||
                text_after_key.contains("5#") ||
                text_after_key.contains("5+") ||
                text_after_key.contains("+5") { FifthState::Aug }

            else if text_after_key.contains("dim") ||
                text_after_key.contains("5b") ||
                text_after_key.contains("5-") ||
                text_after_key.contains("-5") { FifthState::Dim }

            else { FifthState::Norm };


        let sus_or_add =
            // если третью ступень поднять ещё выше
            if text_after_key.starts_with("sus4+") ||
                text_after_key.starts_with("sus4#") { SusOrAdd::Sus4Plus }

            else if text_after_key.starts_with("sus2") { SusOrAdd::Sus2 }
            else if text_after_key.starts_with("sus4") { SusOrAdd::Sus4 }
            else if text_after_key.contains("add2") { SusOrAdd::Add2 }
            else if text_after_key.contains("add4") { SusOrAdd::Add4 }
            else { SusOrAdd::No };


        if text_after_key == "5" {
            return Some( Self { text, keynote, fifth_state, sus_or_add, 
                minor: false,
                chord_type: ChordType::Power,
            } )
        } else if text_after_key.contains("9") {
            return Some( Self { text, keynote, minor, fifth_state, sus_or_add,
                chord_type: ChordType::Nineth
            } )
        } else if text_after_key.contains("11") {
            return Some( Self { text, keynote, minor, fifth_state, sus_or_add,
                chord_type: ChordType::Eleventh
            } )
        } else if text_after_key.contains("13") {
            return Some( Self { text, keynote, minor, fifth_state, sus_or_add,
                chord_type: ChordType::Thirteenth
            } )
        } else if text_after_key.contains("maj") {
            return Some( Self { text, keynote, minor, fifth_state, sus_or_add,
                chord_type: ChordType::MajSeventh
            } )
        } else if text_after_key.contains('7') {
            return Some( Self { text, keynote, minor, fifth_state, sus_or_add,
                chord_type: ChordType::Seventh
            } )
        } else if text_after_key.contains("6-") || text_after_key.contains("6b") {
            return Some( Self { text, keynote, minor, fifth_state, sus_or_add,
                chord_type: ChordType::SixthMinus
            } )
        } else if text_after_key.contains('6') {
            return Some( Self { text, keynote, minor, fifth_state, sus_or_add,
                chord_type: ChordType::Sixth
            } )
        } else {
            return Some( Self { text, keynote, minor, fifth_state, sus_or_add,
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


        return get_fingerings( tuning, &notes, Some(self.text.clone()) )
    }

    pub fn transpose(&self, steps: i32) -> Self {
        let steps = steps % 12;
        if steps == 0 { return self.clone() }
        let mut chord = self.clone();

        if steps > 0 {
            for _ in 0..steps { chord.do_step_right() }
        } else if steps < 0 {
            for _ in steps..0 { chord.do_step_left() }
        }

        return chord
    }

    fn do_step_right(&mut self) {
        (self.keynote, self.text) = match self.keynote {
            A =>      (ASharp, format!("A#{}", &self.text[1..]) ),
            ASharp => (B, format!("B{}", &self.text[2..]) ),
            B =>      (C, format!("C{}", &self.text[1..]) ),
            C =>      (CSharp, format!("C#{}", &self.text[1..]) ),
            CSharp => (D, format!("D{}", &self.text[2..]) ),
            D =>      (DSharp, format!("D#{}", &self.text[1..]) ),
            DSharp => (E, format!("E{}", &self.text[2..]) ),
            E =>      (F, format!("F{}", &self.text[1..]) ),
            F =>      (FSharp, format!("F#{}", &self.text[1..]) ),
            FSharp => (G, format!("G{}", &self.text[2..]) ),
            G =>      (GSharp, format!("G#{}", &self.text[1..]) ),
            GSharp => (A, format!("A{}", &self.text[2..]) )
        }
    }
    fn do_step_left(&mut self) {
        (self.keynote, self.text) = match self.keynote {
            A =>      (GSharp, format!("G#{}", &self.text[1..]) ),
            ASharp => (A, format!("A{}", &self.text[2..]) ),
            B =>      (ASharp, format!("A#{}", &self.text[1..]) ),
            C =>      (B, format!("B{}", &self.text[1..]) ),
            CSharp => (C, format!("C{}", &self.text[2..]) ),
            D =>      (CSharp, format!("C#{}", &self.text[1..]) ),
            DSharp => (D, format!("D{}", &self.text[2..]) ),
            E =>      (DSharp, format!("D#{}", &self.text[1..]) ),
            F =>      (E, format!("E{}", &self.text[1..]) ),
            FSharp => (F, format!("F{}", &self.text[2..]) ),
            G =>      (FSharp, format!("F#{}", &self.text[1..]) ),
            GSharp => (G, format!("G{}", &self.text[2..]) )
        }
    }
}

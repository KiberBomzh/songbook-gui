pub mod chord_fingerings;

use crate::Note::{self, *};
use crate::chord_generator::chord_fingerings::{Fingering, StringState};
use crate::chord_generator::chord_fingerings::StringState::*;


pub const STRINGS: usize = 6;
const MAX_CHORD_SIZE: u8 = 4;


pub fn get_fingerings(
    tuning: &[Note; STRINGS],
    notes: &Vec<Note>,
    title: Option<String>
) -> Vec<Fingering> {
    let fret = get_fretboard(tuning);
    let mut fingerings: Vec<Fingering> = Vec::new();
    // добавить ещё минимальные варианты, где все дублированые или сложные ноты выбрасываются
    for i in 0..12 {
        if let Some(string_state) = generate_from_fret(&fret, notes, i, true, true) {
            if let Some(fing) = Fingering::new(string_state, title.clone()) {
                if fingerings.iter().all(|f| *f != fing) {
                    fingerings.push(fing)
                }
            }
        }
        if let Some(string_state) = generate_from_fret(&fret, notes, i, true, false) {
            if let Some(fing) = Fingering::new(string_state, title.clone()) {
                if fingerings.iter().all(|f| *f != fing) {
                    fingerings.push(fing)
                }
            }
        }
    }

    return fingerings
}

pub fn get_fretboard(tuning: &[Note; STRINGS]) -> [[Note; 25]; STRINGS] {
    let mut fretboard = [[A; 25]; STRINGS];
    for (index, note) in tuning.iter().enumerate() {
        let mut note = note.clone();
        for n in &mut fretboard[index] {
            *n = note;
            note.increase();
        }
    }

    return fretboard
}


fn generate_from_fret(
    fretboard: &[[Note; 25]; STRINGS],
    notes: &Vec<Note>, // first is keynote
    from_fret: u8,
    right_bass: bool,
    is_open: bool
) -> Option<[StringState; STRINGS]> {
    let mut string_state = [Muted; STRINGS];
    for (index, string) in fretboard.iter().enumerate() {
        let mut fret_counter: u8 = 0;
        for (fret_num, fret) in string.iter().enumerate() {
            let fret_num = fret_num.try_into().unwrap();
            if fret_num == 0 && notes.iter().any(|n| n == fret) {
                string_state[index] = Open
            }

            if fret_num < from_fret { continue }
            if fret_counter < MAX_CHORD_SIZE { fret_counter += 1 } else { break }
            if fret_num != 0 && notes.iter().any(|n| n == fret) {
                if is_open {
                    if string_state[index] == Muted { string_state[index] = FrettedOn(fret_num) }
                } else { string_state[index] = FrettedOn(fret_num) }
                break;
            }
        }
    }

    // бас соответствующий тонике
    if right_bass {
        let bass = notes[0];

        for (i, s) in string_state.iter_mut().rev().enumerate() {
            if *s == Muted { continue }

            let string_num = get_reversed_string_num(i);

            if let Some(note) = get_note_from_position(fretboard, *s, string_num) {
                if note != bass { *s = Muted }
                else { break }
            }
        }
    }

    // все ноты глухие
    if string_state.iter().all(|s| *s == Muted) { return None }

    // присутствуют ли все ноты
    if notes.len() < 5 {
        if !notes.iter().all(|n|
            string_state.iter().enumerate().any(|(i, s)|
                get_note_from_position(fretboard, *s, i) == Some(*n)
            )
        ) { return None }
    } else {
        let mut important_notes = Vec::new();
        important_notes.push(notes[0]);
        important_notes.push(notes[1]);
        important_notes.push( notes[notes.len() - 1] );
        important_notes.push( notes[notes.len() - 2] );

        if !important_notes.iter().all(|n|
            string_state.iter().enumerate().any(|(i, s)|
                get_note_from_position(fretboard, *s, i) == Some(*n)
            )
        ) { return None }
    }

    return Some(string_state)
}

fn get_note_from_position(
    fretboard: &[[Note; 25]; STRINGS],
    position: StringState,
    string_num: usize
) -> Option<Note> {
    match position {
        Muted => None,
        Open => Some(fretboard[string_num][0]),
        FrettedOn(f) => Some(fretboard[string_num][<u8 as Into<usize>>::into(f)])
    }
}

fn get_reversed_string_num(i: usize) -> usize {
    for (index, value) in (0..STRINGS).rev().enumerate() {
        if i == value { return index }
    }

    i
}

use flutter_rust_bridge::frb;
use anyhow::Result;
pub use songbook::{
    Note,
    Key,
    STANDART_TUNING,
    chord_generator::{
        self,
        chord_fingerings::{Fingering, StringState},
    },
    song_library,
};



#[frb(sync)]
pub fn get_fingerings_for_chord(chord: String) -> Vec<SimpleFingering> {
    let chord = songbook::song::chord::Chord::new(&chord).unwrap();

    chord.get_fingerings(&STANDART_TUNING)
        .iter()
        .map(|f| SimpleFingering { fingering: f.clone() })
        .collect()
}

#[frb(sync)]
pub fn set_fingering_global(fingering: &SimpleFingering) -> Result<()> {
    song_library::add_fingering(&fingering.fingering)?;

    Ok(())
}

#[frb(sync)]
pub fn get_fretboard(tuning: [SimpleNote; 6]) -> [[SimpleNote; 25]; 6] {
    let inner_tuning = tuning.map(|s| s.note);
    let inner_fretboard = chord_generator::get_fretboard(&inner_tuning);

    inner_fretboard.map(|s| s.map(|n| SimpleNote {note: n}) )
}

#[frb(sync)]
pub fn set_sharp_only(is_sharp_only: bool) {
    let value = if is_sharp_only { "1" } else { "0" };
    std::env::set_var("SONGBOOK_SHARP_ONLY", value)
}

#[frb(sync)]
pub fn get_standart_tuning() -> [SimpleNote; 6] {
    STANDART_TUNING.map(|n| SimpleNote { note: n })
}

#[frb(sync)]
pub fn get_all_keys() -> Vec<SimpleKey> {
    let c = Key::new("C").unwrap();
    let am = Key::new("Am").unwrap();
    let mut keys = Vec::new();

    for i in 0..12 {
        keys.push(
            SimpleKey { key: c.transpose(i * 7) }
        );

        keys.push(
            SimpleKey { key: am.transpose(i * 7) }
        );
    }


    keys
}


pub struct SimpleNote {
    note: Note,
}

impl SimpleNote {
    #[frb(sync)]
    pub fn to_string(&self) -> String {
        self.note.to_string()
    }
}

pub struct SimpleKey {
    pub key: Key,
}

impl SimpleKey {
    #[frb(sync)]
    pub fn to_string(&self) -> String {
        self.key.to_string()
    }

    #[frb(sync)]
    pub fn from_string(s: String) -> Option<Self> {
        Some( Self {
            key: Key::new(&s)?
        } )
    }

    #[frb(sync)]
    pub fn transpose(&mut self, steps: i32) {
        self.key = self.key.transpose(steps)
    }

    #[frb(sync)]
    pub fn is_minor(&self) -> bool {
        self.key.is_minor()
    }
}

pub struct SimpleFingering {
    fingering: Fingering
}
impl SimpleFingering {
    #[frb(sync)]
    pub fn from_string(fingering: String, chord: String) -> Option<Self> {
        let mut strings = [StringState::Muted; 6];
        for (i, f) in fingering.split(' ').enumerate() {
            match f {
                c if c == "x" => {},
                c if c == "0" => strings[i] = StringState::Open,
                c => {
                    let fret_num = c.parse::<u8>().unwrap();
                    strings[i] = StringState::FrettedOn(fret_num);
                }
            }
        }
        
        Some( Self {
            fingering: Fingering::new(strings, Some(chord))?
        })
    }

    #[frb(sync)]
    pub fn to_string(&self) -> String {
        self.fingering.to_string()
    }
}

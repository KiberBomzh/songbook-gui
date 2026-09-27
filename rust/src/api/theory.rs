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
pub fn text_to_chord_pro(s: &String) -> String {
    use songbook::file_reader::txt_reader::is_line_chords;


    let mut chord_pro = String::new();

    let mut chord_line = String::new();
    for line in s.lines() {
        if !line.trim().is_empty() && is_line_chords(line) {
            chord_line = line.to_string();
        } else {
            if chord_line.trim().is_empty() {
                chord_pro.push_str(line);
                chord_pro.push('\n');
            } else {
                let line = if line.is_empty() {
                    " ".repeat(chord_line.len())
                } else { line.to_string() };
                let mut l = String::new();

                let mut chord_chars = chord_line.chars();
                let mut text_chars = line.chars();

                let mut in_bracets = false;
                let mut text_buf = String::new();
                loop {
                    let c = chord_chars.next();
                    let t = text_chars.next();
                    if c.is_none() && t.is_none() {
                        if in_bracets {
                            l.push(']');

                            l.push_str(&text_buf);
                            text_buf.clear();
                        }
                        break;
                    }

                    if c.is_some_and(|c_ch| !c_ch.is_whitespace()) {
                        if !in_bracets {
                            in_bracets = true;
                            l.push('[');
                        }

                        l.push(c.unwrap());
                    } else if in_bracets {
                        l.push(']');
                        in_bracets = false;

                        l.push_str(&text_buf);
                        text_buf.clear();
                    }

                    if let Some(t_ch) = t {
                        if in_bracets {
                            text_buf.push(t_ch);
                        } else {
                            l.push(t_ch);
                        }
                    }
                }

                chord_line.clear();
                l.push('\n');

                chord_pro.push_str(&l);
            }
        }
    }

    if !chord_line.trim().is_empty() {
        let mut s = String::new();
        let mut in_bracets = false;
        let mut chord_len: usize = 0;
        for ch in chord_line.chars() {
            if ch.is_whitespace() {
                if in_bracets {
                    s.push(']');
                    in_bracets = false;

                    s.push_str(&" ".repeat(chord_len + 1));
                    chord_len = 0;
                }
            } else {
                if !in_bracets {
                    s.push('[');
                    in_bracets = true;
                }
                chord_len += 1;
            }

            s.push(ch);
        }
        if in_bracets {
            s.push(']');
        }

        chord_pro.push_str(&s);
    }


    chord_pro
}
#[frb(sync)]
pub fn chord_pro_to_text(s: &String) -> String {
    let mut text = String::new();
    for line in s.lines() {
        if !(line.contains("[") && line.contains("]")) {
            text.push_str(line);
            text.push('\n');
        } else {
            let mut chords_line = String::new();
            let mut text_line = String::new();
            let mut in_bracets = false;
            let mut chord_indent: u8 = 0;
            for ch in line.chars() {
                match ch {
                    '[' if !in_bracets => {
                        in_bracets = true;
                    },

                    ']' if in_bracets => {
                        in_bracets = false;
                    },

                    c => if in_bracets {
                        chords_line.push(c);
                        chord_indent += 1;
                    } else {
                        if chord_indent > 0 {
                            chord_indent -= 1;
                        } else {
                            chords_line.push(' ');
                        }

                        text_line.push(c);
                    }
                }
            }


            text.push_str(&chords_line);
            text.push('\n');
            text.push_str(&text_line);
            text.push('\n');
        }
    }


    text
}

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
    std::env::set_var(songbook::SHARP_ONLY, value)
}
#[frb(sync)]
pub fn get_sharp_only() -> Option<bool> {
    Some(
        std::env::var(songbook::SHARP_ONLY).ok()? == "1"
    )
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
    pub fingering: Fingering
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

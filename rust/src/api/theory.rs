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

    fn process_only_chords(line: &str) -> String {
        let mut s = String::new();
        let mut in_bracets = false;
        for ch in line.chars() {
            if ch.is_whitespace() {
                if in_bracets {
                    s.push(']');
                    in_bracets = false;
                }
            } else {
                if !in_bracets {
                    s.push('[');
                    in_bracets = true;
                }
            }

            s.push(ch);
        }
        if in_bracets {
            s.push(']');
        }


        s
    }
    fn process_chords_and_text(chord_line: &str, text: &str) -> String {
        let mut s = String::new();

        let mut chord_chars = chord_line.chars();
        let mut text_chars = text.chars();

        let mut in_bracets = false;
        let mut text_buf = String::new();
        loop {
            let c = chord_chars.next();
            let t = text_chars.next();
            if c.is_none() && t.is_none() {
                if in_bracets {
                    s.push(']');

                    s.push_str(&text_buf);
                    text_buf.clear();
                }
                break;
            }

            if c.is_some_and(|c_ch| !c_ch.is_whitespace()) {
                if !in_bracets {
                    in_bracets = true;
                    s.push('[');
                }

                s.push(c.unwrap());
            } else if in_bracets {
                s.push(']');
                in_bracets = false;

                s.push_str(&text_buf);
                text_buf.clear();
            }

            if let Some(t_ch) = t {
                if in_bracets {
                    text_buf.push(t_ch);
                } else {
                    s.push(t_ch);
                }
            }
        }


        s
    }


    let mut chord_pro = String::new();

    let mut lines = s.lines();
    while let Some(line) = lines.next() {
        if !line.trim().is_empty() && is_line_chords(line) {
            let chord_line = line;
            if let Some(next_line) = lines.next() {
                if next_line.trim().is_empty() {
                    chord_pro.push_str(&process_only_chords(chord_line));
                    chord_pro.push('\n');

                    chord_pro.push_str(next_line);
                    chord_pro.push('\n');
                } else {
                    chord_pro.push_str(&process_chords_and_text(chord_line, next_line));
                    chord_pro.push('\n');
                }
            } else {
                chord_pro.push_str(&process_only_chords(chord_line));
                chord_pro.push('\n');
            }
        } else {
            chord_pro.push_str(line);
            chord_pro.push('\n');
        }
    }


    chord_pro
}
#[frb(sync)]
pub fn chord_pro_to_text(s: &String) -> String {
    fn is_line_has_only_chords(line: &str) -> bool {
        let mut only_chords = true;

        let mut chars = line.chars();
        while let Some(c) = chars.next() {
            if c == '[' {
                while let Some(n_c) = chars.next() {
                    if n_c == ']' {
                        break
                    }
                }
            } else if !c.is_whitespace() {
                only_chords = false;
                break
            }
        }


        only_chords
    }

    let mut text = String::new();
    for line in s.lines() {
        if !(line.contains("[") && line.contains("]")) {
            text.push_str(line);
            text.push('\n');
        } else {
            if is_line_has_only_chords(line) {
                text.push_str(&
                    line
                        .replace("][", " ")
                        .replace(&['[', ']'], "")
                );
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

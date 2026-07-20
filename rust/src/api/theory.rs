use flutter_rust_bridge::frb;
pub use songbook::{
    Note,
    Key,
    STANDART_TUNING,
    chord_generator,
};



#[frb(sync)]
pub fn get_fretboard(tuning: [SimpleNote; 6]) -> [[SimpleNote; 25]; 6] {
    let inner_tuning = tuning.map(|s| s.note);
    let inner_fretboard = chord_generator::get_fretboard(&inner_tuning);

    inner_fretboard.map(|s| s.map(|n| SimpleNote {note: n}) )
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
        self.note.get_text()
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

use flutter_rust_bridge::frb;
use songbook::{
    Note,
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


pub struct SimpleNote {
    note: Note,
}

impl SimpleNote {
    #[frb(sync)]
    pub fn to_string(&self) -> String {
            self.note.get_text()
    }
}

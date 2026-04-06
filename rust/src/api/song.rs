use std::path::PathBuf;

use songbook::song_library::lib_functions::get_song;

use anyhow::Result;


#[flutter_rust_bridge::frb(sync)]
pub fn get_song_as_string(path_str: String) -> Result<String> {
    let path = PathBuf::from(path_str);
    let song = get_song(&path)?;
    let song_str = song.get_song_as_text(true, true, false, true);
    Ok(song_str)
}

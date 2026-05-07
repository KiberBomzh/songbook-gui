use std::path::PathBuf;
use std::fs;
use std::str::FromStr;
use serde::{Serialize, Deserialize};
use anyhow::Result;
use ratatui::style::Color;


const FOCUS_COLOR: Color = Color::LightGreen;
const UNFOCUS_COLOR: Color = Color::DarkGray;
const DIRECTORIES_COLOR: Color = Color::Blue;
const SONGS_COLOR: Color = Color::White;

const TITLE_COLOR: Color = Color::Green;
const CHORDS_COLOR: Color = Color::Cyan;
const RHYTHM_COLOR: Color = Color::Yellow;
const NOTES_COLOR: Color = Color::DarkGray;
const TEXT_COLOR: Color = Color::White;



#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Config {
    pub colors: Colors
}

impl Config{
    pub fn new() -> Self {
        if let Ok(config) = Self::from_file() {
            return config
        } else {
            Self { colors: Colors::default() }
        }
    }

    fn from_file() -> Result<Self> {
        let path = Self::get_config_path().ok_or(anyhow::anyhow!("Cannot get config path!"))?;
        let content = fs::read_to_string(path)?;

        let config: Config = toml::from_str(&content)?;
        return Ok(config)
    }

    fn get_config_path() -> Option<PathBuf> {
        let mut path = dirs::config_dir()?;
        path.push("songbook");
        path.push("config.toml");
        if !path.is_file() { return None }
        return Some(path)
    }
}


#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Colors {
    focus: String,
    unfocus: String,
    directories: String,
    songs: String,
    song: Song
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct Song {
    title: String,
    chords: String,
    rhythm: String,
    notes: String,
    text: String
}
// Доступные цвета в Ratatui
// Black
// Red
// Green
// Yellow
// Blue
// Magenta
// Cyan
// Gray
// DarkGray
// LightRed
// LightGreen
// LightYellow
// LightBlue
// LightMagenta
// LightCyan
// White
// Rgb

impl Default for Colors {
    fn default() -> Self {
        Self {
            focus: FOCUS_COLOR.to_string(),
            unfocus: UNFOCUS_COLOR.to_string(),
            directories: DIRECTORIES_COLOR.to_string(),
            songs: SONGS_COLOR.to_string(),
            song: Song {
                title: TITLE_COLOR.to_string(),
                chords: CHORDS_COLOR.to_string(),
                rhythm: RHYTHM_COLOR.to_string(),
                notes: NOTES_COLOR.to_string(),
                text: TEXT_COLOR.to_string(),
            }
        }
    }
}

impl Colors {
    pub fn get_focus_color(&self) -> Color {
        if let Ok(color) = Self::get_color(&self.focus) { color }
        else { FOCUS_COLOR }
    }

    pub fn get_unfocus_color(&self) -> Color {
        if let Ok(color) = Self::get_color(&self.unfocus) { color }
        else { UNFOCUS_COLOR }
    }

    pub fn get_directories_color(&self) -> Color {
        if let Ok(color) = Self::get_color(&self.directories) { color }
        else { DIRECTORIES_COLOR }
    }

    pub fn get_songs_color(&self) -> Color {
        if let Ok(color) = Self::get_color(&self.songs) { color }
        else { SONGS_COLOR }
    }

    pub fn get_title_color(&self) -> Color {
        if let Ok(color) = Self::get_color(&self.song.title) { color }
        else { TITLE_COLOR }
    }

    pub fn get_chords_color(&self) -> Color {
        if let Ok(color) = Self::get_color(&self.song.chords) { color }
        else { CHORDS_COLOR }
    }

    pub fn get_rhythm_color(&self) -> Color {
        if let Ok(color) = Self::get_color(&self.song.rhythm) { color }
        else { RHYTHM_COLOR }
    }

    pub fn get_notes_color(&self) -> Color {
        if let Ok(color) = Self::get_color(&self.song.notes) { color }
        else { NOTES_COLOR }
    }

    pub fn get_text_color(&self) -> Color {
        if let Ok(color) = Self::get_color(&self.song.text) { color }
        else { TEXT_COLOR }
    }

    fn get_color(color_str: &str) -> Result<Color> {
        if color_str.starts_with("rgb") {
            let rgb = &color_str[4..color_str.len() - 1];
            if let [r, g, b] = rgb
                .split(",")
                .map(|s| s.trim().parse::<u8>().unwrap_or(255))
                .collect::<Vec<u8>>()
                .as_slice()
            {
                Ok(Color::Rgb(*r, *g, *b))
            } else { Err(anyhow::anyhow!("Cannot get color!")) }
        } else if color_str.starts_with("#") {
            let hex = &color_str[1..];
            let mut rgb: [u8; 3] = [255; 3];
            let mut current_color: usize = 0;
            let mut color_buf = String::new();
            for c in hex.chars() {
                if color_buf.len() < 2 {
                    color_buf.push(c);
                } else {
                    if current_color < 3 {
                        rgb[current_color] = u8::from_str_radix(&color_buf, 16)?;
                        color_buf.clear();
                        current_color += 1;
                    } else { break }
                }
            }

            let [r, g, b] = rgb;
            return Ok(Color::Rgb(r, g, b))
        } else {
            Ok(Color::from_str(color_str)?)
        }
    }
}


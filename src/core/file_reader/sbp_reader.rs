use crate::song::{
    Song,
    Metadata,
    block::{Block, Line},
    row::{Row, ChordPosition},
    chord::Chord
};
use crate::{Key, Note};
use anyhow::Result;


#[derive(serde::Deserialize, Debug)]
struct SongbookPro {
    songs: Vec<SbpSong>,
}

#[allow(non_snake_case)]
#[derive(serde::Deserialize, Debug)]
struct SbpSong {
    author: String,
    name: String,
    content: String,
    key: u8,
    KeyShift: u8,
    Capo: u8,
    NotesText: String,
}


pub fn read_from_sbp(file_content: &str) -> Result<Vec<Song>> {
    let sbp: SongbookPro = serde_json::from_str(file_content)?;
    let mut songs: Vec<Song> = Vec::new();
    for song in &sbp.songs {
        let ( metadata, notes ) = convert_metadata(song);
        let ( blocks, chord_list ) = convert_content(&song.content);
        let mut s = Song { metadata, chord_list, blocks, notes };
        if song.KeyShift > 0 { s.transpose(song.KeyShift.into()) }
        songs.push(s);
    }

    Ok(songs)
}


fn convert_metadata(song: &SbpSong) -> ( Metadata, Option<String> ) {
    let key = match song.key {
        0 => Some( Key { keynote: Note::A, is_minor: false } ),
        1 => Some( Key { keynote: Note::ASharp, is_minor: false } ),
        2 => Some( Key { keynote: Note::B, is_minor: false } ),
        3 => Some( Key { keynote: Note::C, is_minor: false } ),
        4 => Some( Key { keynote: Note::CSharp, is_minor: false } ),
        5 => Some( Key { keynote: Note::D, is_minor: false } ),
        6 => Some( Key { keynote: Note::DSharp, is_minor: false } ),
        7 => Some( Key { keynote: Note::E, is_minor: false } ),
        8 => Some( Key { keynote: Note::F, is_minor: false } ),
        9 => Some( Key { keynote: Note::FSharp, is_minor: false } ),
        10 => Some( Key { keynote: Note::G, is_minor: false } ),
        11 => Some( Key { keynote: Note::GSharp, is_minor: false } ),

        12 => Some( Key { keynote: Note::A, is_minor: true } ),
        13 => Some( Key { keynote: Note::ASharp, is_minor: true } ),
        14 => Some( Key { keynote: Note::B, is_minor: true } ),
        15 => Some( Key { keynote: Note::C, is_minor: true } ),
        16 => Some( Key { keynote: Note::CSharp, is_minor: true } ),
        17 => Some( Key { keynote: Note::D, is_minor: true } ),
        18 => Some( Key { keynote: Note::DSharp, is_minor: true } ),
        19 => Some( Key { keynote: Note::E, is_minor: true } ),
        20 => Some( Key { keynote: Note::F, is_minor: true } ),
        21 => Some( Key { keynote: Note::FSharp, is_minor: true } ),
        22 => Some( Key { keynote: Note::G, is_minor: true } ),
        23 => Some( Key { keynote: Note::GSharp, is_minor: true } ),

        _ => None
    };

    ( Metadata {
        title: song.name.clone(),
        artist: song.author.clone(),
        key,
        capo: if song.Capo > 0 { Some( song.Capo ) } else { None },
        autoscroll_speed: None,
        show_options: None,
    },
    if song.NotesText.is_empty() { None }
    else { Some( song.NotesText.clone() ) } )
}

fn convert_content(content: &str) -> ( Vec<Block>, Vec<Chord> ) {
    let mut blocks = Vec::new();
    let mut chord_list = Vec::new();

    let mut title = String::new();
    let mut notes = String::new();

    let mut tab = String::new();
    let mut in_tab = false;

    let mut lines: Vec<Line> = Vec::new();
    for line in content.lines() {
        if line.starts_with("{c:") {
            while lines.last() == Some(&Line::EmptyLine) {
                lines.pop();
            }
            if !title.is_empty() || !notes.is_empty() || !lines.is_empty() {
                blocks.push( Block {
                    title: if title.is_empty() { None } else { Some(title) },
                    lines,
                    notes: if notes.is_empty() { None } else { Some(notes) }
                });
                title = String::new();
                notes = String::new();
                lines = Vec::new();
            }

            if let Some(end) = line.find("}") {
                title = line[3..end].trim().to_string()
            } else {
                lines.push(Line::PlainText(line.trim().to_string()))
            }

        } else if line.starts_with("(") && line.ends_with(")") {
            if let Some(end) = line.find(")") {
                if !notes.is_empty() { notes.push('\n') }
                notes.push_str(&line[1..end])
            } else {
                lines.push(Line::PlainText(line.trim().to_string()))
            }

        } else if line.starts_with("{sot}") {
            in_tab = true;
        } else if line.starts_with("{eot}") {
            in_tab = false;
            lines.push( Line::Tab(tab) );
            tab = String::new();
        } else if in_tab {
            if !tab.is_empty() {
                tab.push('\n');
            }
            tab.push_str(line);

        } else if line.trim().is_empty() {
            lines.push(Line::EmptyLine)
        } else if line.contains("[") && line.contains("]") {
            lines.push( unwrap_line_with_chords(line, &mut chord_list) )
        } else {
            lines.push(Line::PlainText(line.trim().to_string()))
        }
    }
    // Последний блок
    while lines.last() == Some(&Line::EmptyLine) {
        lines.pop();
    }
    if !title.is_empty() || !notes.is_empty() || !lines.is_empty() {
        blocks.push( Block {
            title: if title.is_empty() { None } else { Some(title) },
            lines,
            notes: if notes.is_empty() { None } else { Some(notes) }
        });
    }

    return ( blocks, chord_list )
}


fn unwrap_line_with_chords(line: &str, chord_list: &mut Vec<Chord>) -> Line {
    let mut text = String::new();
    let mut chords: Vec<ChordPosition> = Vec::new();

    let mut in_chord = false;
    let mut chord_text = String::new();
    let mut index: usize = 0;
    for c in line.trim().chars() {
        if c == '[' {
            in_chord = true;
        } else if c == ']' {
            in_chord = false;
            if let Some(chord) = Chord::new(&chord_text) {
                if chord_list.iter().all(|ch| *ch != chord) { chord_list.push(chord.clone()) }
                chords.push(ChordPosition::OnIndex {index: index, chord: chord} );
            }
            chord_text.clear();
        } else if in_chord {
            chord_text.push(c)
        } else {
            index += 1;
            text.push(c);
        }
    }

    if text.trim().is_empty() {
        Line::ChordsLine(
            chords.into_iter()
            .map(|cp| match cp {
                ChordPosition::OnIndex{ chord, .. } => chord,
                ChordPosition::UpBeat(chord) => chord
            })
            .collect())
    } else {
        Line::TextBlock( Row {
            text: Some(text),
            chords: Some(chords),
            rhythm: None
        })
    }
}

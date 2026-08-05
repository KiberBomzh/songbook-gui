use std::collections::HashSet;
use scraper::{Html, Selector};

use crate::song::{
    Metadata,
    Song,
    block::{Block, Line},
    row::{Row, ChordPosition},
    chord::Chord
};
use crate::file_reader::txt_reader::is_line_chords;



pub fn parse(html: &str) -> Option<crate::Song> {
    let document = Html::parse_document(html);
    
    let metadata = parse_metadata(&document)?;
    let (blocks, chord_list) = parse_text(&document)?;
    let notes = parse_notes(&document);

    
    return Some(Song { blocks, chord_list, metadata, notes })
}

fn parse_notes(document: &Html) -> Option<String> {
    let notes_selector = Selector::parse(r#"pre.b-podbor__comment"#).ok()?;
    let notes = document
        .select(&notes_selector)
        .next()?
        .text()
        .collect::<Vec<_>>()
        .join("");

    if notes.trim().is_empty() {
        None
    } else {
        Some(notes)
    }
}

fn parse_metadata(document: &Html) -> Option<Metadata> {
    let title_selector = Selector::parse(r#"span[itemprop="name"]"#).ok()?;
    let artist_selector = Selector::parse(r#"span[itemprop="byArtist"]"#).ok()?;

    let title = document
        .select(&title_selector)
        .next()?
        .text()
        .collect::<Vec<_>>()
        .join("");

    let artist = document
        .select(&artist_selector)
        .next()?
        .text()
        .collect::<Vec<_>>()
        .join("");

    Some( Metadata::new( title.to_string(), artist.to_string()) )
}

fn parse_text(document: &Html) -> Option<(Vec<Block>, HashSet<Chord>)> {
    const NOTE_MARK: &str = "{temp_note_line}: ";
    let text_selector = Selector::parse(r#"pre[itemprop="chordsBlock"]"#).ok()?;
    let text = document
        .select(&text_selector)
        .next()?
        .text()
        .collect::<Vec<_>>()
        .join("")
        .replace("[", "\n")
        .replace("]:/*", &format!("\n{NOTE_MARK}"))
        .replace("]:", "\n")
        .replace("/*", &format!("\n{NOTE_MARK}"))
        .replace("*/", "\n");


    let mut blocks: Vec<Block> = Vec::new();
    let mut chord_list: HashSet<Chord> = HashSet::new();

    let mut title = String::new();
    let mut lines: Vec<Line> = Vec::new();
    let mut chords: Vec<ChordPosition> = Vec::new();
    let mut last_line_is_chords = false;
    let mut last_line_was_empty = true;

    for line in text.lines() {
        let line = line.to_string();
        if line.starts_with(NOTE_MARK) {
            lines.push(Line::NoteLine(line[NOTE_MARK.len()..].to_string()));
            last_line_was_empty = false;
            last_line_is_chords = false;

            continue
        }

        if line.is_empty() {
            last_line_was_empty = true;
            if !lines.is_empty() || last_line_is_chords || !title.is_empty() {
                if last_line_is_chords && !chords.is_empty() {
                    lines.push(
                        Line::ChordsLine(chords.iter().map(|p| match p {
                            ChordPosition::OnIndex { index: _, chord } => chord.clone(),
                            ChordPosition::UpBeat(chord) => chord.clone(),
                        }).collect::<Vec<Chord>>())
                    );
                }

                blocks.push(Block {
                    title: if title.is_empty() { None } else { Some(title) },
                    lines,
                    notes: None,
                    key: None,
                });

                title = String::new();
                lines = Vec::new();
                chords = Vec::new();
                last_line_is_chords = false
            }

            continue
        };

        if is_line_chords(&line) && !last_line_is_chords {
            last_line_is_chords = true;

            let line = line + " ";
            let mut chord = String::new();
            let mut indent = 0;
            for i in line.chars() {
                if i == ' ' {
                    if !chord.is_empty() {
                        if let Some(c) = Chord::new(&chord) {
                            chords.push( ChordPosition::OnIndex{ index: ( indent - chord.chars().count() ), chord: c.clone() } );
                            chord_list.insert(c);
                        }

                        chord.clear();
                    }
                    indent += 1;
                    continue
                }

                chord.push(i);
                indent += 1;
            }

        } else if last_line_is_chords {
            if chords.is_empty() {
                lines.push(Line::TextBlock(Row {
                    chords: None,
                    text: Some(line),
                    rhythm: None
                }));
            } else {
                lines.push(Line::TextBlock(Row {
                    chords: Some(chords),
                    text: Some(line),
                    rhythm: None
                }));
                chords = Vec::new();
            }
            last_line_is_chords = false;
        } else if last_line_was_empty {
            title = line;
        } else {
            lines.push(Line::TextBlock(Row { chords: None, text: Some(line), rhythm: None }));
        }

        last_line_was_empty = false;
    }

    // Последний block
    if !chords.is_empty() {
        lines.push(
            Line::ChordsLine(chords.iter().map(|p| match p {
                ChordPosition::OnIndex { index: _, chord } => chord.clone(),
                ChordPosition::UpBeat(chord) => chord.clone(),
            }).collect::<Vec<Chord>>())
        );
    }
    if !lines.is_empty() {
        blocks.push(Block {
            title: if title.is_empty() { None } else { Some(title) },
            lines,
            notes: None,
            key: None,
        });
    }

    return Some((blocks, chord_list))
}

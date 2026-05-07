use crate::song::{
    Metadata,
    block::{Block, Line},
    row::{Row, ChordPosition},
    chord::Chord
};


pub fn read_from_chordpro(text: &str) -> (Option<Metadata>, Vec<Block>, Vec<Chord>) {
    let mut blocks: Vec<Block> = Vec::new();
    let mut chord_list: Vec<Chord> = Vec::new();
    
    
    let block_starts = [
        "{start_of_verse",
        "{sov",
        
        "{start_of_chorus",
        "{soc",
        
        "{start_of_bridge",
        "{sob"
    ];
    
    let block_ends = [
        "{end_of_verse",
        "{eov",
        
        "{end_of_chorus",
        "{eoc",
        
        "{end_of_bridge",
        "{eob"
    ];
    
    
    let mut title = String::new();
    let mut artist = String::new();
    let mut key_text = String::new();
    
    let mut bnote = String::new();
    let mut is_in_block = false;
    let mut block_lines: Vec<Line> = Vec::new();
    let mut block_title = String::new();

    let mut tab_buf = String::new();
    let mut is_in_tab = false;

    for line in text.lines() {
        if block_ends.iter().any(|end| line.starts_with(end)) {
            is_in_block = false;
            blocks.push( Block {
                title: if block_title.is_empty() { None } else { Some(block_title) },
                lines: block_lines,
                notes: None
            } );
            
            block_title = String::new();
            block_lines = Vec::new();
        } else if is_in_block {
            read_line(line, &mut block_lines, &mut chord_list);
        } else if block_starts.iter().any(|start| line.starts_with(start)) {
            is_in_block = true;
            if let Some(start_index) = line.find(":") {
                let line_after_start = &line[start_index + 1..];
                if let Some(end_index) = line_after_start.find("}") {
                    block_title = line_after_start[..end_index].trim().to_string()
                }
            }
        
        
        } else if line.starts_with("{sot}") || line.starts_with("{start_of_tab}") {
            is_in_tab = true;
        } else if line.starts_with("{eot}") || line.starts_with("{end_of_tab}") {
            is_in_tab = false;
            block_lines.push( Line::Tab(tab_buf) );
            tab_buf = String::new();
        } else if is_in_tab {
            if !tab_buf.is_empty() {
                tab_buf.push('\n');
            }
            tab_buf.push_str(line);


        } else if line.starts_with("{title:") || line.starts_with("{t:") {
            if let Some(end_index) = line.find("}") {
                title = if line.starts_with("{t:") {
                    line[3..end_index].trim()
                } else {
                    line[7..end_index].trim()
                }.to_string();
            }
        
        } else if line.starts_with("{artist:") {
            if let Some(end_index) = line.find("}") {
                artist = line[8..end_index].trim().to_string()
            }
        } else if line.starts_with("{subtitle:") {
            if let Some(end_index) = line.find("}") {
                artist = line[10..end_index].trim().to_string()
            }
        } else if line.starts_with("{st:") {
            if let Some(end_index) = line.find("}") {
                artist = line[4..end_index].trim().to_string()
            }
        
        } else if line.starts_with("{key:") {
            if let Some(end_index) = line.find("}") {
                key_text = line[5..end_index].trim().to_string()
            }


        } else if line.starts_with("{comment:") || line.starts_with("{c:") {
            if let Some(end_index) = line.find("}") {
                bnote = if line.starts_with("{c:") {
                    line[3..end_index].trim()
                } else {
                    line[9..end_index].trim()
                }.to_string();
            }
        
        
        } else if line.is_empty() && !block_lines.is_empty() {
            blocks.push( Block {
                title: if block_title.is_empty() { None } else { Some(block_title) },
                lines: block_lines,
                notes: if bnote.is_empty() { None } else { Some(bnote) }
            } );
            
            bnote = String::new();
            block_title = String::new();
            block_lines = Vec::new();
        } else {
            read_line(line, &mut block_lines, &mut chord_list);
        }
    }

    // Последний block
    if !block_lines.is_empty() {
        blocks.push( Block {
            title: if block_title.is_empty() { None } else { Some(block_title) },
            lines: block_lines,
            notes: None
        } );
    }

    
    return ( 
        if !title.is_empty() && !artist.is_empty() { Some( Metadata {
            title,
            artist,
            key: crate::Key::new(&key_text),
            capo: None,
            autoscroll_speed: None,
            show_options: None,
        } ) } else { None },
        blocks,
        chord_list
    )
}


fn read_line(text: &str, lines: &mut Vec<Line>, chord_list: &mut Vec<Chord>) {
    if text.is_empty() && lines.is_empty() {
        return
    }
    
    
    let mut chords: Vec<ChordPosition> = Vec::new();
    let mut row_text = String::new();
    
    let mut index: usize = 0;
    let mut is_chord = false;
    let mut current_chord = String::new();
    for c in text.chars() {
        match c {
            ']' => {
                is_chord = false;
                if let Some(chord) = Chord::new(&current_chord) {
                    if chord_list.iter().all(|c| *c != chord) {
                        chord_list.push(chord.clone())
                    }
                    chords.push(ChordPosition::OnIndex{index, chord});
                }
                current_chord.clear();
            },
            '[' => is_chord = true,
            c if is_chord => current_chord.push(c),
            c => {
                index += 1;
                row_text.push(c);
            }
        }
    }
    
    lines.push(
        if !row_text.trim().is_empty() && !chords.is_empty() {
            Line::TextBlock( Row {
                chords: Some(chords),
                rhythm: None,
                text: Some(row_text)
            })
        } else if !row_text.trim().is_empty() {
            Line::PlainText(row_text)
        } else if !chords.is_empty() {
            Line::ChordsLine(
                chords.iter()
                .map(|c| match c {
                    ChordPosition::OnIndex{chord, ..} => chord.clone(),
                    ChordPosition::UpBeat(chord) => chord.clone()
                })
                .collect::<Vec<Chord>>()
            )
        } else {
            Line::EmptyLine
        }
    );
}

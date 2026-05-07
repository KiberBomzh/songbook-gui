use crate::song::{
    block::{Block, Line},
    row::{Row, ChordPosition},
    chord::Chord
};


pub fn read_from_txt(txt: &str) -> (Vec<Block>, Vec<Chord>) {
    let mut blocks: Vec<Block> = Vec::new();
    let mut chord_list: Vec<Chord> = Vec::new();

    let mut title = String::new();
    let mut rows: Vec<Row> = Vec::new();
    let mut chords = Vec::new();
    let mut last_line_is_chords = false;
    let mut last_line_was_empty = true;
    for line in txt.lines() {
        let line = line.to_string();
        if line.is_empty() {
            last_line_was_empty = true;
            if !rows.is_empty() {
                blocks.push(Block {
                    title: if title.is_empty() { None } else { Some(title) },
                    lines: rows.iter().map(|r| Line::TextBlock(r.clone())).collect(),
                    notes: None
                });
                title = String::new();
                rows.clear();
            } else if last_line_is_chords {
                if !chords.is_empty() {
                    blocks.push(Block {
                        title: if title.is_empty() { None } else { Some(title) },
                        lines: vec!(Line::TextBlock(
                                Row { chords: Some(chords), text: None, rhythm: None }),
                        ),
                        notes: None
                    });
                    title = String::new();
                    chords = Vec::new();
                    last_line_is_chords = false
                }
            } else if !title.is_empty() {
                blocks.push(Block {
                    title: Some(title),
                    lines: vec!(Line::EmptyLine),
                    notes: None
                });
                title = String::new();
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
                            if chord_list.iter().all(|chord| *chord != c) {
                                chord_list.push(c);
                            }
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
                rows.push(Row { chords: None, text: Some(line), rhythm: None });
            } else {
                rows.push(Row { chords: Some(chords), text: Some(line), rhythm: None });
                chords = Vec::new();
            }
            last_line_is_chords = false;
        } else if last_line_was_empty {
            title = line;
        } else {
            rows.push(Row { chords: None, text: Some(line), rhythm: None });
        }

        last_line_was_empty = false;
    }

    // Последний block
    if !rows.is_empty() {
        blocks.push(Block {
            title: if title.is_empty() { None } else { Some(title) },
            lines: rows.iter().map(|r| Line::TextBlock(r.clone())).collect(),
            notes: None
        });
    }

    return (blocks, chord_list)
}

fn is_line_chords(line: &str) -> bool {
    let words: Vec<&str> = line.split_whitespace().collect();
    let chords = ["A", "B", "C", "D", "E", "F", "G"];

    if !words.iter().all(|w| chords.iter().any(|c| w.starts_with(*c))) {
        return false
    }
    
    // Проверка по второй букве
    let allowed_second_chars = ['m', '+', '-', '5', '6', '7', '9', '1', 's', 'a', '#', 'b'];
    for word in words {
        // Если в слове есть вторая буква то проверить что она есть в списке разрешенных
        if let Some(second_char) = word.chars().nth(1) {
            if !allowed_second_chars.iter().any(|c| *c == second_char) {
                return false
            }
        }
    }
    
    return true
}

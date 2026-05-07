use ratatui::Frame;
use ratatui::layout::{Constraint, Layout};
use ratatui::widgets::{Block, Paragraph, List, ListItem, Table, Row};
use ratatui::prelude::*;
use Constraint::{Percentage, Fill, Length};

use super::{
    song_formater,
    Focus,
    App,
};


impl App {
    pub fn draw_main_screen(&mut self, frame: &mut Frame) {
        let horizontal = if self.hide_lib {
            Layout::horizontal([Percentage(0), Percentage(100)])
        } else {
            Layout::horizontal([Percentage(25), Percentage(75)])
        };
        let [lib_area, song_area] = horizontal.areas(frame.area());


        let focus_color = self.config.colors.get_focus_color();
        let unfocus_color = self.config.colors.get_unfocus_color();
        let directories_color = self.config.colors.get_directories_color();
        let songs_color = self.config.colors.get_songs_color();
        let title_color = self.config.colors.get_title_color();
        let chords_color = self.config.colors.get_chords_color();
        let rhythm_color = self.config.colors.get_rhythm_color();
        let notes_color = self.config.colors.get_notes_color();
        let text_color = self.config.colors.get_text_color();


        let mut items: Vec<ListItem> = Vec::new();
        for (name, path) in &self.lib_list {
            let mut style = Style::new();
            if path.is_dir() { style = style.fg(directories_color); }
            else if path.is_file() { style = style.fg(songs_color); }
            if let Some(c_path) = &self.cutted_path && c_path == path { style = style.dim(); }
            if let Some(c_path) = &self.copied_path && c_path == path { style = style.green(); }
            if self.selected_paths.iter().any(|p| p == path) {
                match self.action_with_selected_paths {
                    super::ActionWithSelectedPaths::Cp => style = style.green(),
                    super::ActionWithSelectedPaths::Mv => style = style.dim(),
                    super::ActionWithSelectedPaths::Nothing => style = style.bold(),
                }
            }
            items.push(ListItem::new(name.as_str()).style(style));
        }

        if !self.hide_lib {
            let list = List::new(items)
                .highlight_style(Style::new())
                .highlight_symbol("->")
                .block(
                    Block::bordered().title(
                        self.current_dir
                            .file_name()
                            .and_then(|n| n.to_str())
                            .unwrap_or("library")
                        )

                        .border_style(if self.focus == Focus::Library {
                            Style::new().fg(focus_color)
                        } else {
                            Style::new().fg(unfocus_color)
                        })
                );
            frame.render_stateful_widget(list, lib_area, &mut self.lib_list_state);
        }


        let song_block = Block::bordered()
            .border_style(if self.focus == Focus::Song {
                Style::new().fg(focus_color)
            } else {
                Style::new().fg(unfocus_color)
            });
        let inner_song_area = song_block.inner(song_area);

        let title: String;
        let title_top: String;
        let song = if let Some((song, _p)) = &self.current_song {
            title = format!("{} - {}", song.metadata.artist, song.metadata.title);

            let mut t_top_buf = String::new();
            if let Some(key) = &song.metadata.key {
                t_top_buf.push_str("Key: ");
                t_top_buf.push_str(&if let Some(capo) = &song.metadata.capo {
                    format!("{}/({})",
                        key.transpose(0 - <u8 as Into<i32>>::into(*capo)).to_string(),
                        key.to_string()
                    )
                } else {
                    key.to_string()
                });
            }
            if let Some(capo) = &song.metadata.capo {
                if !t_top_buf.is_empty() { t_top_buf.push_str(", ") }
                t_top_buf.push_str("Capo: ");
                t_top_buf.push_str(&capo.to_string());
            }
            title_top = t_top_buf;



            let height = <u16 as Into<usize>>::into(inner_song_area.height);
            let width = <u16 as Into<usize>>::into(inner_song_area.width);
            self.song_area_height = Some(height);
            self.song_area_width = Some(width);

            let (p, lines, columns) = song_formater::get_as_paragraph(
                &song,
                width,
                self.show_chords,
                self.show_rhythm,
                self.show_fingerings,
                self.show_notes,
                [title_color, chords_color, rhythm_color, notes_color, text_color]
            );

            self.scroll_y_max = lines.saturating_sub(height);
            self.scroll_x_max = columns.saturating_sub(width);

            p.scroll( (self.scroll_y, self.scroll_x) )
        } else {
            title = "Nothing to show".to_string();
            title_top = String::new();
            Paragraph::default()
        }.block(
            song_block
                .title(title)
                .title_top(Line::from(title_top).right_aligned())
                .title_bottom(Line::from(self.long_command.as_str()).right_aligned())
                .title_bottom(Line::from(
                    if self.autoscroll { self.autoscroll_speed.as_millis().to_string() + "ms" }
                    else { String::new() }
                ))
        );
        frame.render_widget(song, song_area);
    }



    pub fn draw_help_screen(&mut self, frame: &mut Frame) {
        let rows = [
            Row::new(vec![
                Line::default(),
                Line::from("Library").centered(),
                Line::default()
            ]),
            Row::new(vec![
                Line::default(),
                Line::from("---------").centered(),
                Line::default()
            ]),

            Row::new(vec![
                Line::from("j, Down"),
                Line::default(),
                Line::from("Go down")
            ]),

            Row::new(vec![
                Line::from("k, Up"),
                Line::default(),
                Line::from("Go up")
            ]),

            Row::new(vec![
                Line::from("h, Left, Backspace"),
                Line::default(),
                Line::from("Go back")
            ]),

            Row::new(vec![
                Line::from("l, Right, Enter"),
                Line::default(),
                Line::from("Open dir/song")
            ]),

            Row::new(vec![
                Line::from("c"),
                Line::default(),
                Line::from("Copy dir/song")
            ]),

            Row::new(vec![
                Line::from("x"),
                Line::default(),
                Line::from("Cut dir/song")
            ]),

            Row::new(vec![
                Line::from("p"),
                Line::default(),
                Line::from("Paste dir/song")
            ]),

            Row::new(vec![
                Line::from("Space"),
                Line::default(),
                Line::from("Multiple select")
            ]),

            Row::new(vec![
                Line::from("S"),
                Line::default(),
                Line::from("Sort all songs")
            ]),

            Row::new(vec![
                Line::from("D"),
                Line::default(),
                Line::from("Delete dir/song")
            ]),

            Row::new(vec![
                Line::from("N(dir name)"),
                Line::default(),
                Line::from("Create dir")
            ]),

            Row::new(vec![
                Line::from("R(new name)"),
                Line::default(),
                Line::from("Rename dir/song")
            ]),

            Row::new(vec![
                Line::from("F(find query)"),
                Line::default(),
                Line::from("Find")
            ]),

            Row::new(vec![
                Line::from("A(e/t/c/s)"),
                Line::default(),
                Line::from("Add song")
            ]),
            Row::new(vec!["", " ", ""]),


            Row::new(vec![
                Line::default(),
                Line::from("Song").centered(),
                Line::default()
            ]),
            Row::new(vec![
                Line::from(""),
                Line::from("------").centered(),
                Line::from("")
            ]),

            Row::new(vec![
                Line::from("j, Down"),
                Line::default(),
                Line::from("Scroll down")
            ]),

            Row::new(vec![
                Line::from("k, Up"),
                Line::default(),
                Line::from("Scroll up")
            ]),

            Row::new(vec![
                Line::from("h, Left"),
                Line::default(),
                Line::from("Scroll left")
            ]),

            Row::new(vec![
                Line::from("l, Right"),
                Line::default(),
                Line::from("Scroll right")
            ]),

            Row::new(vec![
                Line::from("J, PageDown"),
                Line::default(),
                Line::from("Scroll page down")
            ]),

            Row::new(vec![
                Line::from("K, PageUp"),
                Line::default(),
                Line::from("Scroll page up")
            ]),

            Row::new(vec![
                Line::from("Home"),
                Line::default(),
                Line::from("Scroll to start")
            ]),

            Row::new(vec![
                Line::from("End"),
                Line::default(),
                Line::from("Scroll to end")
            ]),

            Row::new(vec![
                Line::from("c"),
                Line::default(),
                Line::from("Toggle chords")
            ]),

            Row::new(vec![
                Line::from("r"),
                Line::default(),
                Line::from("Toggle rhythm")
            ]),

            Row::new(vec![
                Line::from("f"),
                Line::default(),
                Line::from("Toggle fingerings")
            ]),

            Row::new(vec![
                Line::from("n"),
                Line::default(),
                Line::from("Toggle notes")
            ]),

            Row::new(vec![
                Line::from(";"),
                Line::default(),
                Line::from("Toggle lib")
            ]),

            Row::new(vec![
                Line::from("e"),
                Line::default(),
                Line::from("Edit song")
            ]),

            Row::new(vec![
                Line::from("R"),
                Line::default(),
                Line::from("Generate rhythm")
            ]),

            Row::new(vec![
                Line::from("a"),
                Line::default(),
                Line::from("Toggle autoscroll")
            ]),

            Row::new(vec![
                Line::from("h, Left"),
                Line::default(),
                Line::from("- autoscroll speed")
            ]),

            Row::new(vec![
                Line::from("l, Right"),
                Line::default(),
                Line::from("+ autoscroll speed")
            ]),

            Row::new(vec![
                Line::from("S(speed)"),
                Line::default(),
                Line::from("Set autoscroll speed")
            ]),

            Row::new(vec![
                Line::from("T(+/-num)"),
                Line::default(),
                Line::from("Transpose song")
            ]),

            Row::new(vec![
                Line::from("C(fret num)"),
                Line::default(),
                Line::from("Set capo")
            ]),

        ];

        let width = [Length(20), Fill(1), Length(20)];
        let table = Table::new(rows, width)
            .row_highlight_style(Style::new().reversed())
            .block(Block::bordered().title(Line::from(" Help ").centered()));


        frame.render_stateful_widget(table, frame.area(), &mut self.help_table_state);
    }
}

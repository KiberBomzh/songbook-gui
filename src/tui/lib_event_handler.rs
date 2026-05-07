use std::time::Duration;
use anyhow::Result;

use crossterm::event::{KeyEvent, KeyCode};
use rfd::FileDialog;

use songbook::song_library::lib_functions::*;
use songbook::Song;

use super::{Focus, DEFAULT_AUTOSCROLL_SPEED, App};



impl App {
    pub fn handle_lib_key_event(&mut self, key_event: KeyEvent) -> Result<()> {
        use super::ActionWithSelectedPaths::*;

        match key_event.code {
            KeyCode::Char('N') |
            KeyCode::Char('R') |
            KeyCode::Char('F') |
            KeyCode::Char('A') => {
                self.is_long_command = true;
                if let KeyCode::Char(c) = key_event.code {
                    self.long_command.push(c)
                }
            },

            KeyCode::Char(' ') => if let Some(selected) = self.lib_list_state.selected() {
                let (_name, path) = &self.lib_list[selected];
                self.selected_paths.push(path.clone());
                self.cutted_path = None;
                self.copied_path = None;
            },

            KeyCode::Char('x') => {
                if !self.selected_paths.is_empty() {
                    self.action_with_selected_paths =
                        if self.action_with_selected_paths != Mv { Mv } else { Nothing };
                } else if let Some(selected) = self.lib_list_state.selected() {
                    let (_name, path) = &self.lib_list[selected];
                    self.cutted_path = Some(path.to_path_buf());
                    self.copied_path = None;
                }
            },
            KeyCode::Char('c') => {
                if !self.selected_paths.is_empty() {
                    self.action_with_selected_paths =
                        if self.action_with_selected_paths != Cp { Cp } else { Nothing };
                } else if let Some(selected) = self.lib_list_state.selected() {
                    let (_name, path) = &self.lib_list[selected];
                    self.copied_path = Some(path.to_path_buf());
                    self.cutted_path = None;
                }
            },
            KeyCode::Char('p') => {
                if let Some(path) = &self.cutted_path {
                    songbook::song_library::mv(path, &self.current_dir)?;
                    self.cutted_path = None;
                }
                if let Some(path) = &self.copied_path {
                    songbook::song_library::cp(path, &self.current_dir)?;
                    self.copied_path = None;
                }
                if !self.selected_paths.is_empty() {
                    match self.action_with_selected_paths {
                        Cp => for p in &self.selected_paths {
                            songbook::song_library::cp(p, &self.current_dir)?;
                        },
                        Mv => for p in &self.selected_paths {
                            songbook::song_library::mv(p, &self.current_dir)?;
                        },
                        Nothing => {}
                    }

                    self.selected_paths.clear();
                    self.action_with_selected_paths = Nothing;
                }
                self.update_lib_list()?;
            },

            KeyCode::Char('j') | KeyCode::Down => self.lib_list_state.select_next(),
            KeyCode::Char('k') | KeyCode::Up => self.lib_list_state.select_previous(),
            KeyCode::Char('l') | KeyCode::Right | KeyCode::Enter => {
                if let Some(selected) = self.lib_list_state.selected() {
                    let (_name, path) = &self.lib_list[selected];
                    if path.is_dir() {
                        if let Some(c_path) = &self.cutted_path {
                            if path == c_path { return Ok(()) }
                        }
                        if let Some(c_path) = &self.copied_path {
                            if path == c_path { return Ok(()) }
                        }
                        if self.selected_paths.iter().any(|p| p == path) {
                            return Ok(())
                        }
                        self.last_dirs.push(self.current_dir.clone());
                        (self.lib_list, self.current_dir) = get_files_in_dir( Some(&path) )?;
                        self.lib_list_state.select_first();
                    } else if path.is_file() {
                        if let Ok(song) = get_song(&path) {
                            self.focus = Focus::Song;
                            self.scroll_y = 0;
                            self.scroll_x = 0;
                            self.autoscroll = false;
                            self.autoscroll_speed = if let Some(speed) = song.metadata.autoscroll_speed {
                                Duration::from_millis(speed)
                            } else {
                                DEFAULT_AUTOSCROLL_SPEED
                            };
                            (self.show_chords, self.show_rhythm, self.show_notes, self.show_fingerings)
                                = song.metadata.get_show_options();

                            self.current_song = Some( (song, path.to_path_buf()) );
                        }
                    }
                }
            },
            KeyCode::Char('h') | KeyCode::Left | KeyCode::Backspace => {
                (self.lib_list, self.current_dir) =
                    get_files_in_dir( self.last_dirs.pop().as_deref() )?;
                self.lib_list_state.select_first();
            },


            KeyCode::Char('S') => {
                songbook::song_library::sort()?;
                self.last_dirs.clear();
                (self.lib_list, self.current_dir) = get_files_in_dir(None)?;
                self.lib_list_state.select_first();
            },

            KeyCode::Char('D') => {
                if let Some(selected) = self.lib_list_state.selected() {
                    let (_name, path) = &self.lib_list[selected];
                    songbook::song_library::rm(path)?;
                    self.update_lib_list()?;
                }
            },
            _ => {}
        }


        if let Some( (_s, path) ) = &self.current_song {
            if !path.is_file() { self.current_song = None }
        }

        Ok(())
    }


    pub fn handle_long_command_in_library(&mut self) -> Result<()> {
        let command = if let Some(c) = self.long_command.chars().next() { c }
            else { return Ok(()) };
        let command_data: String = self.long_command.chars().skip(1).collect();
        if command_data.is_empty() { return Ok(()) }
        match command {
            'N' => {
                songbook::song_library::mkdir(
                    &self.current_dir.join(command_data)
                )?;
                self.update_lib_list()?;
            },
            'R' => {
                if let Some(selected) = self.lib_list_state.selected() {
                    let (_name, path) = &self.lib_list[selected];
                    let parent_path = if let Some(p) = path.parent() { p }
                        else { &self.current_dir };
                    songbook::song_library::mv(path, &parent_path.join(command_data))?;
                    self.update_lib_list()?;
                }
            },
            'F' => {
                self.current_dir = songbook::song_library::get_lib_path()?;
                self.lib_list = find(&command_data)?;
            },
            'A' => {
                let subcommand = if let Some(c) = command_data.chars().nth(0) { c }
                    else { return Ok(()) };
                let meta: Option<(String, String)> = if let [artist, title, ..] =
                    command_data
                        .chars()
                        .skip(1)
                        .collect::<String>()
                        .split(" - ")
                        .collect::<Vec<&str>>()
                        .as_slice() { Some( (artist.trim().to_string(), title.trim().to_string()) ) }
                        else { None };

                let song: Option<Song> = match subcommand {
                    'e' => if let Some( (artist, title) ) = meta {
                        Some(Song::new(&title, &artist))
                    } else { None },
                    't' => if let Some( (artist, title) ) = meta {
                        if let Some(file) = FileDialog::new()
                            .add_filter("text", &["txt"])
                            .pick_file() {
                            Some(Song::from_txt(&file, &title, &artist)?)
                        } else { None }
                    } else { None },
                    'c' => {
                        if let Some(file) = FileDialog::new()
                            .add_filter("text", &["chordpo", "cho"])
                            .pick_file() {
                            let mut song = Song::from_chordpro(&file)?;
                            if let Some( (artist, title) ) = meta {
                                song.metadata.title = title;
                                song.metadata.artist = artist;
                            }

                            Some(song)
                        } else { None }
                    },
                    's' => {
                        if let Some(file) = FileDialog::new() .pick_file() {
                            let songs = Song::from_sbp(&file)?;
                            for s in songs {
                                songbook::song_library::add(&s)?;
                            }
                            self.update_lib_list()?;

                            None
                        } else { None }
                    },
                    _ => None
                };

                
                if let Some(s) = &song {
                    songbook::song_library::add(s)?;
                    self.update_lib_list()?;
                }
            },
            _ => {}
        }

        Ok(())
    }
}

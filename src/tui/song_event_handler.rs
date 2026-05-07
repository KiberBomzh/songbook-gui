use std::time::{Instant, Duration};
use anyhow::Result;

use ratatui::{DefaultTerminal};
use crossterm::event::{KeyEvent, KeyCode};

use songbook::song_library::lib_functions::*;
use super::App;



impl App {
    pub fn handle_song_key_event(
        &mut self,
        key_event: KeyEvent,
        terminal: &mut DefaultTerminal,
        is_song_changed: &mut bool
    ) -> Result<()> {
        if let Some( (_, _) ) = &self.current_song {
        } else { return Ok(()) }

        match key_event.code {
            KeyCode::Char('T') | KeyCode::Char('C') => {
                self.is_long_command = true;
                if let KeyCode::Char(c) = key_event.code {
                    self.long_command.push(c)
                }
            },
            KeyCode::Char('S') if self.autoscroll => {
                self.is_long_command = true;
                self.long_command.push('S')
            },


            KeyCode::Char('h') | KeyCode::Left if self.autoscroll =>
                if self.autoscroll_speed.as_millis() > 0 {
                    self.autoscroll_speed =
                        self.autoscroll_speed.saturating_sub(Duration::from_millis(50));
            },

            KeyCode::Char('l') | KeyCode::Right if self.autoscroll => {
                self.autoscroll_speed += Duration::from_millis(50);
            },


            KeyCode::Char('j') | KeyCode::Down =>
                if self.scroll_y_max > self.scroll_y.into() { self.scroll_y += 1 },

            KeyCode::Char('k') | KeyCode::Up =>
                self.scroll_y = self.scroll_y.saturating_sub(1),

            KeyCode::Char('l') | KeyCode::Right =>
                if self.scroll_x_max > self.scroll_x.into() { self.scroll_x += 1 },

            KeyCode::Char('h') | KeyCode::Left =>
                self.scroll_x = self.scroll_x.saturating_sub(1),


            KeyCode::Char('J') | KeyCode::PageDown => {
                if let Some(height) = self.song_area_height {
                    let height: u16 = height.try_into()?;
                    if self.scroll_y_max > (self.scroll_y + height).into() {
                        self.scroll_y += height;
                    } else if self.scroll_y_max > self.scroll_y.into() {
                        self.scroll_y = self.scroll_y_max.try_into()?;
                    }
                }
            },
            KeyCode::Char('K') | KeyCode::PageUp => {
                if let Some(height) = self.song_area_height {
                    self.scroll_y = self.scroll_y.saturating_sub(height.try_into()?);
                }
            },

            KeyCode::Home => self.scroll_y = 0,
            KeyCode::End => self.scroll_y = self.scroll_y_max.try_into()?,


            KeyCode::Char('c') => {
                if self.show_chords {
                    self.show_chords = false
                } else {
                    self.show_chords = true
                }
            },
            KeyCode::Char('r') => {
                if self.show_rhythm {
                    self.show_rhythm = false
                } else {
                    self.show_rhythm = true
                }
            },
            KeyCode::Char('f') => {
                if self.show_fingerings {
                    self.show_fingerings = false
                } else {
                    self.show_fingerings = true
                }
            },
            KeyCode::Char('n') => {
                if self.show_notes {
                    self.show_notes = false
                } else {
                    self.show_notes = true
                }
            },
            
            KeyCode::Char(';') => self.switch_lib(),

            KeyCode::Char('a') =>
                if self.autoscroll { self.autoscroll = false }
                else { self.autoscroll = true; self.last_scroll_time = Instant::now() },


            KeyCode::Char('e') => {
                if let Some( (song, _path) ) = &mut self.current_song {
                    ratatui::restore();
                    edit(song)?;
                    self.autoscroll_speed = if let Some(speed) = song.metadata.autoscroll_speed {
                        Duration::from_millis(speed)
                    } else {
                        super::DEFAULT_AUTOSCROLL_SPEED
                    };

                    (self.show_chords, self.show_rhythm, self.show_notes, self.show_fingerings) =
                        song.metadata.get_show_options();

                    *is_song_changed = true;
                    *terminal = ratatui::init();
                    self.scroll_y = 0;
                    self.scroll_x = 0;
                }
            },
            KeyCode::Char('R') => {
                if let Some( (song, _path) ) = &mut self.current_song {
                    song.generate_rhythm_from_chords();
                    *is_song_changed = true;
                }
            }
            _ => {}
        }

        Ok(())
    }

    pub fn handle_long_command_in_song(
        &mut self,
        is_song_changed: &mut bool
    ) -> Result<()> {
        let song = if let Some( (song, _p) ) = &mut self.current_song { song }
            else { return Ok(()) };

        let command = if let Some(c) = self.long_command.chars().next() { c }
            else { return Ok(()) };
        let command_data: String = self.long_command.chars().skip(1).collect();
        match command {
            'T' => {
                let steps: i32 = if let Ok(s) = command_data.parse() { s }
                    else { return Ok(()) };
                song.transpose(steps);
                *is_song_changed = true;
            },

            'C' => if let Ok(capo) = command_data.parse::<u8>() {
                if let Some(song_capo) = song.metadata.capo {
                    let song_capo: i32 = song_capo.into();
                    let capo: i32 = capo.into();
                    song.transpose(capo - song_capo);
                } else {
                    song.transpose(capo.into());
                }
                song.metadata.capo =
                    if capo == 0 { None }
                    else { Some(capo) };
                *is_song_changed = true;
            },

            'S' if self.autoscroll => {
                if let Ok(speed) = command_data.parse::<u64>() {
                    self.autoscroll_speed = Duration::from_millis(speed)
                }
            },

            _ => {}
        }

        Ok(())
    }
}

mod song_formater;
mod config;
mod song_event_handler;
mod lib_event_handler;
mod screen_painter;


use std::path::PathBuf;
use std::time::{Instant, Duration};
use anyhow::Result;

use ratatui::{DefaultTerminal, Frame};
use ratatui::widgets::{ListState, TableState};

use crossterm::event::{Event, KeyEvent, KeyCode};

use songbook::song_library::lib_functions::*;
use songbook::Song;

use config::Config;


const DEFAULT_AUTOSCROLL_SPEED: Duration = Duration::from_millis(2500);



pub fn main() -> Result<()> {
    let mut terminal = ratatui::init();
    let mut app = App::new()?;
    let app_result = app.run(&mut terminal);

    ratatui::restore();

    return app_result
}


#[derive(PartialEq)]
enum Focus {
    Library,
    Song
}

#[derive(PartialEq)]
enum Screen {
    Main,
    Help
}

#[derive(PartialEq)]
enum ActionWithSelectedPaths {
    Cp,
    Mv,
    Nothing
}

struct App {
    exit: bool,
    config: Config,

    focus: Focus,
    current_screen: Screen,
    hide_lib: bool,

    is_long_command: bool,
    long_command: String,

    help_table_state: TableState,

    lib_list_state: ListState,
    lib_list: Vec<(String, PathBuf)>,
    current_dir: PathBuf,
    last_dirs: Vec<PathBuf>,
    cutted_path: Option<PathBuf>,
    copied_path: Option<PathBuf>,
    selected_paths: Vec<PathBuf>,
    action_with_selected_paths: ActionWithSelectedPaths,

    current_song: Option<(Song, PathBuf)>,
    song_area_height: Option<usize>,
    song_area_width: Option<usize>,
    show_chords: bool,
    show_rhythm: bool,
    show_fingerings: bool,
    show_notes: bool,

    scroll_y: u16,
    scroll_x: u16,
    scroll_y_max: usize,
    scroll_x_max: usize,

    autoscroll: bool,
    autoscroll_speed: Duration,
    last_scroll_time: Instant
}

impl App {
    pub fn new() -> Result<Self> {
        let (lib_list, current_dir) = get_files_in_dir(None)?;

        Ok( Self {
            exit: false,
            config: Config::new(),
            focus: Focus::Library,
            current_screen: Screen::Main,
            hide_lib: false,
            is_long_command: false,
            long_command: String::new(),
            help_table_state: TableState::new().with_selected(Some(0)),
            lib_list_state: ListState::default().with_selected(Some(0)),
            lib_list,
            current_dir,
            last_dirs: Vec::new(),
            cutted_path: None,
            copied_path: None,
            selected_paths: Vec::new(),
            action_with_selected_paths: ActionWithSelectedPaths::Nothing,
            current_song: None,
            song_area_height: None,
            song_area_width: None,
            show_chords: true,
            show_rhythm: true,
            show_fingerings: false,
            show_notes: true,
            scroll_y: 0,
            scroll_x: 0,
            scroll_y_max: 0,
            scroll_x_max: 0,
            autoscroll: false,
            autoscroll_speed: DEFAULT_AUTOSCROLL_SPEED,
            last_scroll_time: Instant::now()
        })
    }
    fn run(&mut self, terminal: &mut DefaultTerminal) -> Result<()> {
        while !self.exit {
            terminal.draw(|frame| self.draw(frame))?;
            self.update_scroll();
            if crossterm::event::poll(Duration::from_millis(10))? {
                match crossterm::event::read()? {
                    Event::Key(key_event) => self.handle_key_event(key_event, terminal)?,
                    _ => {}
                }
            }
        }

        Ok(())
    }

    fn draw(&mut self, frame: &mut Frame) {
        match self.current_screen {
            Screen::Main => self.draw_main_screen(frame),
            Screen::Help => self.draw_help_screen(frame),
        }
    }

    fn handle_key_event(&mut self, key_event: KeyEvent, terminal: &mut DefaultTerminal) -> Result<()> {
        match self.current_screen {
            Screen::Main => self.handle_main_key_event(key_event, terminal)?,
            Screen::Help => self.handle_help_key_event(key_event)?,
        }
        Ok(())
    }

    fn handle_main_key_event(&mut self, key_event: KeyEvent, terminal: &mut DefaultTerminal) -> Result<()> {
        let mut is_song_changed = false;
        if key_event.kind.is_press() {
            match key_event.code {
                KeyCode::F(1) => self.current_screen = Screen::Help,


                KeyCode::Char(c) if self.is_long_command => self.long_command.push(c),
                KeyCode::Backspace if self.is_long_command => {
                    self.long_command.pop();
                    if self.long_command.is_empty() { self.is_long_command = false }
                },
                KeyCode::Enter if self.is_long_command => {
                    if !self.long_command.is_empty() {
                        match self.focus {
                            Focus::Library => self.handle_long_command_in_library()?,
                            Focus::Song => self.handle_long_command_in_song(&mut is_song_changed)?
                        }
                    }

                    self.is_long_command = false;
                    self.long_command.clear();
                },
                _ if self.is_long_command => {},


                KeyCode::Char('q') => self.exit = true,
                KeyCode::Tab => if !self.hide_lib { self.switch_focus() },
                _ => {
                    match self.focus {
                        Focus::Library => self.handle_lib_key_event(key_event)?,
                        Focus::Song => self.handle_song_key_event(key_event, terminal, &mut is_song_changed)?
                    }
                }
            }
        }

        if let Some( (song, _p) ) = &mut self.current_song {
            if let Some(speed) = song.metadata.autoscroll_speed &&
                Duration::from_millis(speed) == self.autoscroll_speed {
            } else {
                if let Ok(new_speed) = self.autoscroll_speed.as_millis().try_into() {
                    is_song_changed = true;
                    song.metadata.autoscroll_speed = Some(new_speed);
                }
            }


            let (c, r, n, f) = song.metadata.get_show_options();
            if 
                self.show_chords != c ||
                self.show_rhythm != r ||
                self.show_notes != n ||
                self.show_fingerings != f
            {
                is_song_changed = true;
                song.metadata.show_options = Some(
                    songbook::song::ShowOptions {
                        chords: self.show_chords,
                        rhythm: self.show_rhythm,
                        notes: self.show_notes,
                        fingerings: self.show_fingerings,
                    }
                );
            }
        }


        if is_song_changed {
            if let Some( (song, path) ) = &self.current_song {
                save(song, path)?;
            }
        }

        Ok(())
    }

    fn handle_help_key_event(&mut self, key_event: KeyEvent) -> Result<()> {
        if key_event.kind.is_press() {
            match key_event.code {
                KeyCode::Esc => self.current_screen = Screen::Main,
                KeyCode::Char('j') | KeyCode::Down => self.help_table_state.select_next(),
                KeyCode::Char('k') | KeyCode::Up => self.help_table_state.select_previous(),
                _ => {},
            }
        }
        Ok(())
    }



    fn update_scroll(&mut self) {
        if !self.autoscroll { return }
        if self.last_scroll_time.elapsed() < self.autoscroll_speed { return }

        if self.scroll_y_max > self.scroll_y.into() {
            self.scroll_y += 1;
            self.last_scroll_time = Instant::now();
        } else { self.autoscroll = false }
    }

    fn switch_focus(&mut self) {
        self.focus = match self.focus {
            Focus::Library => Focus::Song,
            Focus::Song => Focus::Library
        }
    }

    fn switch_lib(&mut self) {
        if self.hide_lib {
            self.hide_lib = false;
            self.focus = Focus::Library;
        } else {
            self.hide_lib = true
        }
    }

    fn update_lib_list(&mut self) -> Result<()> {
        (self.lib_list, self.current_dir) = get_files_in_dir( Some(&self.current_dir) )?;
        Ok(())
    }
}

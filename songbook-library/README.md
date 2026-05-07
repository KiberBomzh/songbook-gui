# Description
This is a programm for storing songs, songbook in short words.
It use its own system for storing chords, not a chordpro format
(yes, i love to reinvent the wheel),
and not only chords, also you can mark stressed syllables with some symbols
(as a dot or some numbers or whatever you want, only one symbol per mark).
Also there's some notes (and a little bit of other stuff)


Written in pure Rust.

# Installation
Download latest release [here](https://github.com/KiberBomzh/songbook-tui/releases/latest).

Or if you have Rust:
```
cargo install songbook --features tui
```

# TUI
- `F1` - Open help screen
- `Esc` - Close help screen
- `q` - Quit

## Library
### Short commands
- `j`, `Up` - Go up
- `k`, `Down` - Go down
- `h`, `Left`, `Backspace` - Go back
- `l`, `Right`, `Enter` - Open a song/dir
- `Space` - Multiple select songs/dirs for copying/moving them after
- `c` - Copy a song
- `x` - Cut a song/dir
- `p` - Paste a song/dir
- `S` - The same as a command `sort` in CLI
- `D` - Delete a song/dir

### Long commands
- `N`(dir name) - Create a new dir with (dir name)
- `R`(new name) - Rename current song/dir with (new name)
- `F`(find query) - Find (find query)
- `A`(`e` Artist - Title/`t` Artist - Title/`c`) - Add new song to library
    - `e` - the same as a command `add empty`, needs Artist - Title
    - `t` - the same as a command `add from-text`, needs Artist - Title
    - `c` - the same as a command `add from-chordpro`
    - `s` - the same as a command `add from-sbp`


## Song
### Short commands
- `j`, `Up` - Scorll up
- `k`, `Down` - Scroll down
- `h`, `Left` - Scroll left
- `l`, `Right` - Scroll right
- `J`, `PageDown` - Scroll page down
- `K`, `PageUp` - Scroll page up
- `Home` - Scroll to the start
- `End` - Scroll to the end
- `c` - Toggle chords
- `r` - Toggle rhythm
- `f` - Toggle fingerings
- `n` - Toggle notes
- `;` - Toggle library
- `e` - Edit song in your text editor
- `R` - Generate rhythm from chords
- `a` - Toggle autoscroll
    - `h`, `Left` - Decrease autoscroll speed
    - `l`, `Right` - Increase autoscroll speed


### Long commands
- `S`(speed) - Set autoscroll speed, only when autoscroll is on
- `T`(num) - Transpose a song to a given num, examples: T7, T-4, T+10
- `C`(fret num) - Transpose a song to a capo, examples: C7, C0, C2

>*A long command ends when you hit an Enter*

# CLI
## Commands
- `init` - create a directory for storing songs. Paths for all platforms you can find [here](https://docs.rs/dirs/latest/dirs/fn.data_dir.html)
- `fret -t TUNING` - print guitar fretboard for a given tuning
- `circle-of-fifth`, `cof` - print circle of fifth (not a circle)
- `chord CHORD` - print fingering for a given chord
- `fingering` - set your fingering for a chord
    - `-c, --chord CHORD` - chord name
    - `-f, --fingering FINGERING` - fingering for chord, example for Am: 0 1 2 2 0 x

- `show` `path/to/song/`(relative to library) - show a song
    - `-k, --key` `KEY` - transpose a song to a given key
    - `-c, --chords` - show chords
    - `-r, --rhythm` - show rhythm marks
    - `-f, --fingerings` - show fingerings for chords
    - `-n, --notes` - show notes
    - `--colored`

- `edit` `path/to/song/`(relative to library) - edit a song
- `add` - add new song to the library
    - `empty` `-a` Artist `-t` Title
    - `from-txt` `-a` Artist `-t` Title `path/to/file.txt`
    - `from-chordpro` `path/to/chordpro/song`
    - `from-sbp` `path/to/song.sbp` - add song(s) from SongbookPro format
    >*Also works with SongbookPro backups(you can add all your libary just with one command*

- `sort` - sort songs in the library, will songs in next struct lib/Artist/Title
- `rm` - remove a file or a directory
- `mv` - move files or dirs somewhere
- `ls` - show files in a directory
- `tree` - show library as a tree
- `mkdir` - create a directory

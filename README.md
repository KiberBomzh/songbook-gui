# Description
An app for songs and song's chords.
Core is written in rust. GUI is written with flutter.

**The project is still under active development so it can have some bugs!**

![](https://img.shields.io/endpoint?url=https://apt.izzysoft.de/fdroid/api/v1/shield/com.kiber_bomzh.songbook&label=IzzyOnDroid)
[![IzzyOnDroid Yearly Downloads](https://img.shields.io/badge/dynamic/json?url=https://dlstats.izzyondroid.org/iod-stats-collector/stats/basic/yearly/rolling.json&query=$.['com.kiber_bomzh.songbook']&label=IzzyOnDroid%20yearly%20downloads)](https://apt.izzysoft.de/packages/com.kiber_bomzh.songbook)
[![RB Status](https://shields.rbtlog.dev/simple/com.kiber_bomzh.songbook)](https://shields.rbtlog.dev/com.kiber_bomzh.songbook)
[<img src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroidButtonGreyBorder_nofont.png" height="80" alt="Get it at IzzyOnDroid">](https://apt.izzysoft.de/packages/com.kiber_bomzh.songbook)

# Main features
- All songs are just Yaml files in folders (for Android library root folder is Android/data/com.kiber_bomzh.songbook/files/songbook/library, for Windows and Linux look [here](https://docs.rs/dirs/latest/dirs/fn.data_dir.html))
- There's versions for Windows, Linux and Android and their data is fully compatible
- Strong data typing for content of a song (Song is a list of Blocks and each Block has an optional title, an optional note and a list of lines. And each line can be: Row, Tab, PlainText, ChordsLine, NoteLine, EmptyLine)
- Powerful song editor (maybe it's a little weird but you'll get used to it)
- Autoscroll
- Key transposition
- Capo support
- App theming (accent color, custom fonts, custom colors for each song element, custom background image for the app and other settings)

# Types

## Song
Song has a note (one or many lines), list of Blocks and the following metadata:
- Title (required)
- Artist (required)
- Key
- Capo
- Autoscroll speed
- Autoscroll delay
- Show options (chords, rhythm, notes, fingerings)
- Tags
- Fingerings (local, for the song)

## Block
Block can have a note (one line), a title, a key and list of Lines.

## Line
Line can be any of the following types:

### Row
Row has three lines in the following order (from top to bottom):
- Chords
- Rhythm
- Text
Any of these lines can be empty, and you can hide chords and rhythm via metadata (show options).

### ChordsLine
This Line is only for chords. Any other text isn't allowed!

### NoteLine
This Line type is useful if you have some notes for certain part of a song.
It can have only one line of text.

### PlainText
This type can be used for quotes or other things that contain only plain text.
It can have many lines of text.

### Tab
As you can guess this Line type is for tabs. You can write here what you want and as you want.
In fact it's almost the same thing as PlainText.

### EmptyLine
Just empty line. That's all.


# Screenshots
![](fastlane/metadata/android/en-US/images/phoneScreenshots/01.jpg)
![](fastlane/metadata/android/en-US/images/phoneScreenshots/02.jpg)
![](fastlane/metadata/android/en-US/images/phoneScreenshots/03.jpg)
![](fastlane/metadata/android/en-US/images/phoneScreenshots/04.jpg)
![](fastlane/metadata/android/en-US/images/phoneScreenshots/05.jpg)
![](fastlane/metadata/android/en-US/images/phoneScreenshots/06.jpg)
![](fastlane/metadata/android/en-US/images/phoneScreenshots/07.jpg)
![](fastlane/metadata/android/en-US/images/phoneScreenshots/08.jpg)
![](fastlane/metadata/android/en-US/images/phoneScreenshots/09.jpg)
![](fastlane/metadata/android/en-US/images/phoneScreenshots/10.jpg)

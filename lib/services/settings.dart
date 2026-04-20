import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


// keys
const String IS_DARK_THEME = 'is_dark_theme';
const String COLOR_ACCENT = 'color_accent';
const String EDITOR_FONT_SIZE = 'editor_font_size';
const String SONG_FONT_SIZE = 'song_font_size';
const String CHORDS_COLOR = 'chords_color';
const String RHYTHM_COLOR = 'rhythm_color';
const String TEXT_COLOR = 'text_color';
const String NOTES_COLOR = 'notes_color';
const String TITLE_COLOR = 'title_color';
const String BACKGROUND_COLOR = 'background_color';
const String LINE_WRAP_IN_SONG = 'line_wrap_in_song';


class SettingsProvider extends ChangeNotifier {
	bool? _isDarkTheme;
	String _colorAccent = 'blue';
	double _editorFontSize = 14;
	double _songFontSize = 14;
	String? _chordsColor;
	String? _rhythmColor;
	String? _textColor;
	String? _notesColor;
	String? _titleColor;
	String? _backgroundColor;
	bool _lineWrapInSong = true;

	ThemeMode get themeMode {
		if (_isDarkTheme != null) {
			if (_isDarkTheme!) {
				return ThemeMode.dark;
			} else {
				return ThemeMode.light;
			}
		} else {
			return ThemeMode.system;
		}
	}
	Color get colorAccent => _stringToColor(_colorAccent) ?? Colors.blue;
	double get editorFontSize => _editorFontSize;
	double get songFontSize => _songFontSize;
	bool get lineWrapInSong => _lineWrapInSong;

	Color chordsColor(BuildContext context) =>
		_stringToColor(_chordsColor) ?? Theme.of(context).colorScheme.primary;

	Color rhythmColor(BuildContext context) =>
		_stringToColor(_rhythmColor) ?? Theme.of(context).colorScheme.tertiary;
	
	Color textColor(BuildContext context) =>
		_stringToColor(_textColor) ?? Theme.of(context).colorScheme.onSurface;

	Color notesColor(BuildContext context) =>
		_stringToColor(_notesColor) ?? Theme.of(context).colorScheme.onSurfaceVariant;

	Color titleColor(BuildContext context) =>
		_stringToColor(_titleColor) ?? Theme.of(context).colorScheme.secondary;

	Color backgroundColor(BuildContext context) =>
		_stringToColor(_backgroundColor) ?? Theme.of(context).colorScheme.surface;


	TextStyle chordsStyle(BuildContext context) => TextStyle(
		color: chordsColor(context),
		fontFamily: 'JetBrainsMono',
		fontSize: _songFontSize,
	);

	TextStyle rhythmStyle(BuildContext context) => TextStyle(
		color: rhythmColor(context),
		fontFamily: 'JetBrainsMono',
		fontSize: _songFontSize,
	);

	TextStyle textStyle(BuildContext context) => TextStyle(
		color: textColor(context),
		fontFamily: 'JetBrainsMono',
		fontSize: _songFontSize,
	);
	TextStyle notesStyle(BuildContext context) => TextStyle(
		color: notesColor(context),
		fontSize: _songFontSize / 1.2,
	);
	TextStyle titleStyle(BuildContext context) => TextStyle(
		color: titleColor(context),
		fontSize: _songFontSize * 1.5,
	);


	SettingsProvider() {
		_loadAllSettings();
	}


	void _loadAllSettings() {
		_isDarkTheme = Preferences.getBool(IS_DARK_THEME);
		_colorAccent = Preferences.getString(COLOR_ACCENT) ?? 'blue';
		_editorFontSize = Preferences.getDouble(EDITOR_FONT_SIZE) ?? 14;
		_songFontSize = Preferences.getDouble(SONG_FONT_SIZE) ?? 14;
		_chordsColor = Preferences.getString(CHORDS_COLOR);
		_rhythmColor = Preferences.getString(RHYTHM_COLOR);
		_textColor = Preferences.getString(TEXT_COLOR);
		_notesColor = Preferences.getString(NOTES_COLOR);
		_titleColor = Preferences.getString(TITLE_COLOR);
		_backgroundColor = Preferences.getString(BACKGROUND_COLOR);
		_lineWrapInSong = Preferences.getBool(LINE_WRAP_IN_SONG) ?? true;

		notifyListeners();
	}

	Future<void> setThemeMode(ThemeMode value) async {
		final isDark = switch (value) {
			ThemeMode.dark => true,
			ThemeMode.light => false,
			ThemeMode.system => null
		};


		_isDarkTheme = isDark;
		if (isDark != null) {
			await Preferences.setBool(IS_DARK_THEME, isDark!);
		} else {
			await Preferences.remove(IS_DARK_THEME);
		}

		notifyListeners();
	}

	Future<void> setColorAccent(String value) async {
		_colorAccent = value;
		await Preferences.setString(COLOR_ACCENT, value);

		notifyListeners();
	}

	Future<void> setEditorFontSize(double value) async {
		_editorFontSize = value;
		await Preferences.setDouble(EDITOR_FONT_SIZE, value);

		notifyListeners();
	}

	Future<void> setSongFontSize(double value) async {
		_songFontSize = value;
		await Preferences.setDouble(SONG_FONT_SIZE, value);

		notifyListeners();
	}

	Future<void> setChordsColor(String? value) async {
		_chordsColor = value;
		if (value != null)
			await Preferences.setString(CHORDS_COLOR, value!);
		else
			await Preferences.remove(CHORDS_COLOR);

		notifyListeners();
	}

	Future<void> setRhythmColor(String? value) async {
		_rhythmColor = value;
		if (value != null)
			await Preferences.setString(RHYTHM_COLOR, value!);
		else
			await Preferences.remove(RHYTHM_COLOR);

		notifyListeners();
	}

	Future<void> setTextColor(String? value) async {
		_textColor = value;
		if (value != null)
			await Preferences.setString(TEXT_COLOR, value!);
		else
			await Preferences.remove(TEXT_COLOR);

		notifyListeners();
	}

	Future<void> setNotesColor(String? value) async {
		_notesColor = value;
		if (value != null)
			await Preferences.setString(NOTES_COLOR, value!);
		else
			await Preferences.remove(NOTES_COLOR);

		notifyListeners();
	}

	Future<void> setTitleColor(String? value) async {
		_titleColor = value;
		if (value != null)
			await Preferences.setString(TITLE_COLOR, value!);
		else
			await Preferences.remove(TITLE_COLOR);

		notifyListeners();
	}

	Future<void> setBackgroundColor(String? value) async {
		_backgroundColor = value;
		if (value != null)
			await Preferences.setString(BACKGROUND_COLOR, value!);
		else
			await Preferences.remove(BACKGROUND_COLOR);

		notifyListeners();
	}

	Future<void> setLineWrapInSong(bool value) async {
		_lineWrapInSong = value;
		await Preferences.setBool(LINE_WRAP_IN_SONG, value);

		notifyListeners();
	}
	


	Future<void> resetToDefault() async {
		await Preferences.clear();
		_loadAllSettings();
	}


	Color? _stringToColor(String? colorStr) {
		if (colorStr == null) {
			return null;
		}

		if (colorStr!.startsWith('#')) {
			return Color(int.parse(colorStr!.substring(1), radix: 16));
		}

		return switch (colorStr) {
			'red' => Colors.red,
			'pink' => Colors.pink,
			'purple' => Colors.purple,
			'deepPurple' => Colors.deepPurple,
			'indigo' => Colors.indigo,
			'blue' => Colors.blue,
			'lightBlue' => Colors.lightBlue,
			'cyan' => Colors.cyan,
			'green' => Colors.green,
			'lightGreen' => Colors.lightGreen,
			'lime' => Colors.lime,
			'yellow' => Colors.yellow,
			'amber' => Colors.amber,
			'orange' => Colors.orange,
			'deepOrange' => Colors.deepOrange,
			'brown' => Colors.brown,
			_ => null
		};
	}
}

class Preferences {
	static SharedPreferences? _prefs;

	static Future<void> init() async {
		_prefs = await SharedPreferences.getInstance();
	}


	static Future<void> setString(String key, String value) async {
		await _prefs?.setString(key, value);
	}
	static String? getString(String key) {
		return _prefs?.getString(key);
	}

	static Future<void> setInt(String key, int value) async {
		await _prefs?.setInt(key, value);
	}
	static int? getInt(String key) {
		return _prefs?.getInt(key);
	}

	static Future<void> setDouble(String key, double value) async {
		await _prefs?.setDouble(key, value);
	}
	static double? getDouble(String key) {
		return _prefs?.getDouble(key);
	}

	static Future<void> setBool(String key, bool value) async {
		await _prefs?.setBool(key, value);
	}
	static bool? getBool(String key) {
		return _prefs?.getBool(key);
	}

	static Future<void> remove(String key) async {
		await _prefs?.remove(key);
	}


	static Future<void> clear() async {
		await _prefs?.clear();
	}
}

import 'dart:io';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';


// keys
const String IS_DARK_THEME = 'is_dark_theme';
const String IS_AMOLED = 'is_amoled';
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
const String FINGERING_SIZE_IN_SONG = 'fingering_size_in_song';
const String BACKGROUND_OPACITY = 'background_opacity';


// fingering as string
const String FINGERING_SIZE__SMALL = 'FingeringSize_small';
const String FINGERING_SIZE__MEDIUM = 'FingeringSize_medium';
const String FINGERING_SIZE__BIG = 'FingeringSize_big';

enum FingeringSize {
	small,
	medium,
	big;

	String to_string() {
		return switch (this) {
			FingeringSize.small => FINGERING_SIZE__SMALL,
			FingeringSize.medium => FINGERING_SIZE__MEDIUM,
			FingeringSize.big => FINGERING_SIZE__BIG
		};
	}
	static FingeringSize? from_string(String? value) {
		return switch (value) {
			FINGERING_SIZE__SMALL => FingeringSize.small,
			FINGERING_SIZE__MEDIUM => FingeringSize.medium,
			FINGERING_SIZE__BIG => FingeringSize.big,
			_ => null
		};
	}


	String display() {
		return switch(this) {
			FingeringSize.small => 'Small',
			FingeringSize.medium => 'Medium',
			FingeringSize.big => 'Big',
		};
	}
}


class SettingsProvider extends ChangeNotifier {
	bool? _isDarkTheme;
	bool _isAmoled = false;
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
	String? _fingeringSizeInSong;
	File? _backgroundImage;
	double _backgroundOpacity = 1.0;

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

	FingeringSize get fingeringSizeInSong {
		return FingeringSize.from_string(_fingeringSizeInSong) ?? FingeringSize.medium;
	}

	bool get isAmoled => _isAmoled;
	Color get colorAccent => _stringToColor(_colorAccent) ?? Colors.blue;
	double get editorFontSize => _editorFontSize;
	double get songFontSize => _songFontSize;
	bool get lineWrapInSong => _lineWrapInSong;
	File? get backgroundImage => _backgroundImage;
	double get backgroundOpacity => _backgroundOpacity;

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

	Color backgroundColor(BuildContext context) {
		final color = _stringToColor(_backgroundColor);
		if (color != null) {
			return color!;
		} else if (_backgroundOpacity == 1.0) {
			return Theme.of(context).colorScheme.surface;
		} else {
			return Color(0x00000000);
		}
	}


	TextStyle chordsStyle(BuildContext context) => TextStyle(
		color: chordsColor(context),
		fontFamily: 'JetBrainsMono',
		fontSize: _songFontSize,
		fontWeight: .bold,
	);

	TextStyle rhythmStyle(BuildContext context) => TextStyle(
		color: rhythmColor(context),
		fontFamily: 'JetBrainsMono',
		fontSize: _songFontSize,
		fontWeight: .bold,
	);

	TextStyle textStyle(BuildContext context) => TextStyle(
		color: textColor(context),
		fontFamily: 'JetBrainsMono',
		fontSize: _songFontSize,
	);
	TextStyle notesStyle(BuildContext context) => TextStyle(
		color: notesColor(context),
		fontSize: _songFontSize * 0.9,
	);
	TextStyle titleStyle(BuildContext context) => TextStyle(
		color: titleColor(context),
		fontSize: _songFontSize * 1.5,
		fontWeight: .bold,
	);
	TextStyle fingeringsStyle() {
		final size = switch (fingeringSizeInSong) {
			FingeringSize.small => _songFontSize * 0.5,
			FingeringSize.medium => _songFontSize * 0.75,
			FingeringSize.big => _songFontSize,
		};

		return TextStyle(
			fontSize: size,
			fontFamily: 'CascadiaMono',
		);
	}
	TextStyle fingeringsTitleStyle() {
		final size = switch (fingeringSizeInSong) {
			FingeringSize.small => _songFontSize * 0.75,
			FingeringSize.medium => _songFontSize,
			FingeringSize.big => _songFontSize * 1.25,
		};

		return TextStyle(
			fontSize: size,
		);
	}


	SnackBarThemeData snackBarTheme() => SnackBarThemeData(
		shape: RoundedRectangleBorder(
			borderRadius: .vertical(top: Radius.circular(10)),
		),
		elevation: 4,
	);

	ColorScheme lightColorScheme() => ColorScheme.fromSeed(
		brightness: .light,
		seedColor: colorAccent,
	);
	ColorScheme darkColorScheme() => ColorScheme.fromSeed(
		brightness: .dark,
		seedColor: colorAccent,
	);
	ColorScheme amoledColorScheme() => darkColorScheme().copyWith(
		surface: Color(0xFF000000),
		surfaceContainer: Color(0xFF151515),
		surfaceVariant: Color(0xFF333333),
	);

	ThemeData ligthTheme() {
		final colorScheme = lightColorScheme();
		final surface = colorScheme.surface.withOpacity(_backgroundOpacity);


		return ThemeData(
			useMaterial3: true,
			colorScheme: colorScheme.copyWith(surface: surface),
			snackBarTheme: snackBarTheme(),
		);
	}
	ThemeData darkTheme() {
		final colorScheme = _isAmoled
			? amoledColorScheme()
			: darkColorScheme();
		final surface = colorScheme.surface.withOpacity(_backgroundOpacity);
		final surfaceContainer = colorScheme.surfaceContainer.withOpacity(_calculateOpacity());
		final surfaceVariant = colorScheme.surfaceVariant.withOpacity(_calculateOpacity());


		return ThemeData(
			useMaterial3: true,
			colorScheme: colorScheme.copyWith(
				surface: surface,
				surfaceContainer: surfaceContainer,
				surfaceVariant: surfaceVariant,
			),
			snackBarTheme: snackBarTheme(),
		);
	}


	SettingsProvider() {
		_loadAllSettings();
	}


	void _loadAllSettings() async {
		_isDarkTheme = Preferences.getBool(IS_DARK_THEME);
		_isAmoled = Preferences.getBool(IS_AMOLED) ?? false;
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
		_fingeringSizeInSong = Preferences.getString(FINGERING_SIZE_IN_SONG);
		_backgroundOpacity = Preferences.getDouble(BACKGROUND_OPACITY) ?? 1.0;

		await _loadBackgroundImage();


		notifyListeners();
	}
	Future<void> _loadBackgroundImage() async {
		final dir = await getApplicationSupportDirectory();
		final savedFile = File(dir.path + '/background_img');
		if (savedFile.existsSync()) {
			_backgroundImage = savedFile;
		}
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

	Future<void> setAmoled(bool value) async {
		_isAmoled = value;
		await Preferences.setBool(IS_AMOLED, value);

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
	
	Future<void> setFingeringSizeInSong(FingeringSize value) async {
		_fingeringSizeInSong = value.to_string();
		await Preferences.setString(FINGERING_SIZE_IN_SONG, _fingeringSizeInSong!);

		notifyListeners();
	}
	
	Future<void> setBackgroundOpacity(double value) async {
		_backgroundOpacity = value;
		await Preferences.setDouble(BACKGROUND_OPACITY, value);

		notifyListeners();
	}

	Future<void> setBackgroundImage() async {
		PaintingBinding.instance.imageCache.clear();
		PaintingBinding.instance.imageCache.clearLiveImages();

		final FilePickerResult? result = await FilePicker.pickFiles(
			type: FileType.image,
		);

		if (result != null && result.files.single.path != null) {
			final dir = await getApplicationSupportDirectory();
			final savedPath = dir.path + '/background_img';

			await File(result.files.single.path!).copy(savedPath);
			_backgroundImage = File(savedPath);

			notifyListeners();
		}
	}
	Future<void> resetBackgroundImage() async {
		await _backgroundImage?.delete();
		_backgroundImage = null;

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

	double _calculateOpacity() {
		final opacity = _backgroundOpacity + ((_backgroundOpacity + 0.2) * 0.25);
		if (opacity > 1)
			return _backgroundOpacity;
		else
			return opacity;
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

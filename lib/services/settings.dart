import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:songbook/src/rust/api/library.dart' as rust_lib;


// keys
const String IS_DARK_THEME = 'is_dark_theme';
const String IS_AMOLED = 'is_amoled';
const String COLOR_ACCENT = 'color_accent';
const String EDITOR_FONT_SIZE = 'editor_font_size';
const String EDITOR_FONT_FAMILY = 'editor_font_family';
const String SONG_FONT_SIZE = 'song_font_size';
const String SONG_FONT_FAMILY = 'song_font_family';
const String TITLE_FONT_FAMILY = 'title_font_family';
const String IS_TITLE_BOLD = 'is_title_bold';
const String IS_TITLE_ITALIC = 'is_title_italic';
const String NOTES_FONT_FAMILY = 'notes_font_family';
const String IS_NOTES_BOLD = 'is_notes_bold';
const String IS_NOTES_ITALIC = 'is_notes_italic';
const String FINGERINGS_FONT_FAMILY = 'fingerings_font_family';
const String IS_FINGERINGS_BOLD = 'is_fingerings_bold';
const String IS_FINGERINGS_ITALIC = 'is_fingerings_italic';
const String TAB_FONT_FAMILY = 'tab_font_family';
const String IS_TAB_BOLD = 'is_tab_bold';
const String IS_TAB_ITALIC = 'is_tab_italic';
const String PLAIN_TEXT_FONT_FAMILY = 'plain_text_font_family';
const String IS_PLAIN_TEXT_BOLD = 'is_plain_text_bold';
const String IS_PLAIN_TEXT_ITALIC = 'is_plain_text_italic';
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

const List<String> FONT_FAMILIES = [
	'JetBrainsMono',
	'CascadiaMono',
	'VictorMono',
	'Lilex',
	'RobotoMono',
	'FiraCode',
	'PTMono',
];


class SettingsProvider extends ChangeNotifier {
	Map<String, File> _customFonts = {};

	bool? _isDarkTheme;
	bool _isAmoled = false;
	String _colorAccent = 'blue';
	double _editorFontSize = 14;
	String _editorFontFamily = 'CascadiaMono';
	double _songFontSize = 14;
	String _songFontFamily = 'JetBrainsMono';


	String? _titleFontFamily;
	bool _isTitleBold = true;
	bool _isTitleItalic = false;

	String? _notesFontFamily;
	bool _isNotesBold = false;
	bool _isNotesItalic = false;

	String? _fingeringsFontFamily;
	bool _isFingeringsBold = true;
	bool _isFingeringsItalic = false;

	String? _tabFontFamily;
	bool _isTabBold = true;
	bool _isTabItalic = false;

	String? _plainTextFontFamily;
	bool _isPlainTextBold = false;
	bool _isPlainTextItalic = false;


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
	String get editorFontFamily => _editorFontFamily;

	double get songFontSize => _songFontSize;
	String get songFontFamily => _songFontFamily;


	String get titleFontFamily => _titleFontFamily ?? _songFontFamily;
	bool get isTitleBold => _isTitleBold;
	bool get isTitleItalic => _isTitleItalic;
	bool get isTitleStyleNull => (
		_titleFontFamily == null &&
		_isTitleBold == true &&
		_isTitleItalic == false
	);

	String get notesFontFamily => _notesFontFamily ?? _songFontFamily;
	bool get isNotesBold => _isNotesBold;
	bool get isNotesItalic => _isNotesItalic;
	bool get isNotesStyleNull => (
		_notesFontFamily == null &&
		_isNotesBold == false &&
		_isNotesItalic == false
	);

	String get fingeringsFontFamily => _fingeringsFontFamily ?? _songFontFamily;
	bool get isFingeringsBold => _isFingeringsBold;
	bool get isFingeringsItalic => _isFingeringsItalic;
	bool get isFingeringsStyleNull => (
		_fingeringsFontFamily == null &&
		_isFingeringsBold == true &&
		_isFingeringsItalic == false
	);

	String get tabFontFamily => _tabFontFamily ?? _songFontFamily;
	bool get isTabBold => _isTabBold;
	bool get isTabItalic => _isTabItalic;
	bool get isTabStyleNull => (
		_tabFontFamily == null &&
		_isTabBold == true &&
		_isTabItalic == false
	);

	String get plainTextFontFamily => _plainTextFontFamily ?? _songFontFamily;
	bool get isPlainTextBold => _isPlainTextBold;
	bool get isPlainTextItalic => _isPlainTextItalic;
	bool get isPlainTextStyleNull => (
		_plainTextFontFamily == null &&
		_isPlainTextBold == false &&
		_isPlainTextItalic == false
	);

	bool get lineWrapInSong => _lineWrapInSong;
	File? get backgroundImage => _backgroundImage;
	double get backgroundOpacity => _backgroundOpacity;
	List<String> get customFontFamilies => _customFonts.keys.toList();

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
		fontFamily: _songFontFamily,
		fontSize: _songFontSize,
		fontWeight: .bold,
	);

	TextStyle rhythmStyle(BuildContext context) => TextStyle(
		color: rhythmColor(context),
		fontFamily: _songFontFamily,
		fontSize: _songFontSize,
		fontWeight: .bold,
	);

	TextStyle textStyle(BuildContext context) => TextStyle(
		color: textColor(context),
		fontFamily: _songFontFamily,
		fontSize: _songFontSize,
	);
	TextStyle notesStyle(BuildContext context) => TextStyle(
		color: notesColor(context),
		fontSize: _songFontSize * 0.9,
		fontFamily: _notesFontFamily,
		fontWeight: _isNotesBold
			? .bold
			: .normal,
		fontStyle: _isNotesItalic
			? .italic
			: .normal,
	);
	TextStyle titleStyle(BuildContext context) => TextStyle(
		color: titleColor(context),
		fontSize: _songFontSize * 1.5,
		fontFamily: _titleFontFamily,
		fontWeight: _isTitleBold
			? .bold
			: .normal,
		fontStyle: _isTitleItalic
			? .italic
			: .normal,
	);
	TextStyle fingeringsStyle() {
		final size = switch (fingeringSizeInSong) {
			FingeringSize.small => _songFontSize * 0.5,
			FingeringSize.medium => _songFontSize * 0.75,
			FingeringSize.big => _songFontSize,
		};

		return TextStyle(
			fontSize: size,
			fontFamily: _fingeringsFontFamily ?? _songFontFamily,
			fontWeight: _isFingeringsBold
				? .bold
				: .normal,
			fontStyle: _isFingeringsItalic
				? .italic
				: .normal,
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
	TextStyle tabStyle(BuildContext context) => TextStyle(
		color: textColor(context),
		fontFamily: _tabFontFamily ?? _songFontFamily,
		fontSize: _songFontSize,
		fontWeight: _isTabBold
			? .bold
			: .normal,
		fontStyle: _isTabItalic
			? .italic
			: .normal,
	);
	TextStyle plainTextStyle(BuildContext context) => TextStyle(
		color: textColor(context),
		fontFamily: _plainTextFontFamily ?? _songFontFamily,
		fontSize: _songFontSize,
		fontWeight: _isPlainTextBold
			? .bold
			: .normal,
		fontStyle: _isPlainTextItalic
			? .italic
			: .normal,
	);
	TextStyle editorStyle() => TextStyle(
		fontFamily: _editorFontFamily,
		fontSize: _editorFontSize,
	);


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
		_editorFontFamily = Preferences.getString(EDITOR_FONT_FAMILY) ?? 'CascadiaMono';
		_songFontSize = Preferences.getDouble(SONG_FONT_SIZE) ?? 14;
		_songFontFamily = Preferences.getString(SONG_FONT_FAMILY) ?? 'JetBrainsMono';
		_titleFontFamily = Preferences.getString(TITLE_FONT_FAMILY);
		_isTitleBold = Preferences.getBool(IS_TITLE_BOLD) ?? true;
		_isTitleItalic = Preferences.getBool(IS_TITLE_ITALIC) ?? false;
		_notesFontFamily = Preferences.getString(NOTES_FONT_FAMILY);
		_isNotesBold = Preferences.getBool(IS_NOTES_BOLD) ?? false;
		_isNotesItalic = Preferences.getBool(IS_NOTES_ITALIC) ?? false;
		_fingeringsFontFamily = Preferences.getString(FINGERINGS_FONT_FAMILY);
		_isFingeringsBold = Preferences.getBool(IS_FINGERINGS_BOLD) ?? true;
		_isFingeringsItalic = Preferences.getBool(IS_FINGERINGS_ITALIC) ?? false;
		_tabFontFamily = Preferences.getString(TAB_FONT_FAMILY);
		_isTabBold = Preferences.getBool(IS_TAB_BOLD) ?? true;
		_isTabItalic = Preferences.getBool(IS_TAB_ITALIC) ?? false;
		_plainTextFontFamily = Preferences.getString(PLAIN_TEXT_FONT_FAMILY);
		_isPlainTextBold = Preferences.getBool(IS_PLAIN_TEXT_BOLD) ?? false;
		_isPlainTextItalic = Preferences.getBool(IS_PLAIN_TEXT_ITALIC) ?? false;
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
		await _loadFonts();


		notifyListeners();
	}

	Future<void> _loadBackgroundImage() async {
		final dir = await getApplicationSupportDirectory();
		final savedFile = File(dir.path + '/background_img');
		if (savedFile.existsSync()) {
			_backgroundImage = savedFile;
		}
	}

	Future<void> _loadFonts() async {
		final dir = await getApplicationSupportDirectory();
		final fontsDir = Directory(dir.path + '/fonts');
		if (fontsDir.existsSync()) {
			final files = fontsDir.listSync();
			for (final file in files) {
				if (file is File && (file.path.endsWith('.ttf') || file.path.endsWith('.otf')) ) {
					await _loadFontFromFile(file);
				}
			}
		}
	}
	Future<void> _loadFontFromFile(File fontFile) async {
		final fontFamily = fontFile.uri.pathSegments.last.replaceAll(RegExp(r'\.(ttf|otf)$'), '');
		final uniqueId = 'font_' + _customFonts.length.toString();

		final fontLoader = FontLoader(uniqueId);
		fontLoader.loadFont(await fontFile.readAsBytes(), fontFamily);
		await fontLoader.load();

		_customFonts[fontFamily] = fontFile;
	}
	Future<void> addNewCustomFont() async {
		FilePickerResult? result = await FilePicker.pickFiles(
			type: FileType.custom,
			allowedExtensions: ['ttf', 'otf'],
			allowMultiple: true,
		);
		if (result == null)
			return;

		for (final file in result.files) {
			if (file.path != null) {
				final sourceFile = File(file.path!);

				final dir = await getApplicationSupportDirectory();
				final fontsDir = Directory(dir.path + '/fonts');

				if (!fontsDir.existsSync()) {
					await fontsDir.create(recursive: true);
				}


				final savedFile = File(fontsDir.path + '/' + file.name);
				await sourceFile.copy(savedFile.path);

				await _loadFontFromFile(savedFile);
			}
		}
	}
	Future<void> removeCustomFont(String fontFamily) async {
		final fontFile = _customFonts[fontFamily];
		if (fontFile != null) {
			if (fontFile.existsSync())
				await fontFile.delete();

			_customFonts.remove(fontFamily);
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

	Future<void> setEditorFontFamily(String value) async {
		_editorFontFamily = value;
		await Preferences.setString(EDITOR_FONT_FAMILY, value);

		notifyListeners();
	}

	Future<void> setSongFontSize(double value) async {
		_songFontSize = value;
		await Preferences.setDouble(SONG_FONT_SIZE, value);

		notifyListeners();
	}

	Future<void> setSongFontFamily(String value) async {
		_songFontFamily = value;
		await Preferences.setString(SONG_FONT_FAMILY, value);

		notifyListeners();
	}

	Future<void> setTitleFontFamily(String value) async {
		_titleFontFamily = value;
		await Preferences.setString(TITLE_FONT_FAMILY, value);

		notifyListeners();
	}

	Future<void> setIsTitleBold(bool value) async {
		_isTitleBold = value;
		await Preferences.setBool(IS_TITLE_BOLD, value);

		notifyListeners();
	}

	Future<void> setIsTitleItalic(bool value) async {
		_isTitleItalic = value;
		await Preferences.setBool(IS_TITLE_ITALIC, value);

		notifyListeners();
	}

	Future<void> setNotesFontFamily(String value) async {
		_notesFontFamily = value;
		await Preferences.setString(NOTES_FONT_FAMILY, value);

		notifyListeners();
	}

	Future<void> setIsNotesBold(bool value) async {
		_isNotesBold = value;
		await Preferences.setBool(IS_NOTES_BOLD, value);

		notifyListeners();
	}

	Future<void> setIsNotesItalic(bool value) async {
		_isNotesItalic = value;
		await Preferences.setBool(IS_NOTES_ITALIC, value);

		notifyListeners();
	}

	Future<void> setFingeringsFontFamily(String value) async {
		_fingeringsFontFamily = value;
		await Preferences.setString(FINGERINGS_FONT_FAMILY, value);

		notifyListeners();
	}

	Future<void> setIsFingeringsBold(bool value) async {
		_isFingeringsBold = value;
		await Preferences.setBool(IS_FINGERINGS_BOLD, value);

		notifyListeners();
	}

	Future<void> setIsFingeringsItalic(bool value) async {
		_isFingeringsItalic = value;
		await Preferences.setBool(IS_FINGERINGS_ITALIC, value);

		notifyListeners();
	}

	Future<void> setTabFontFamily(String value) async {
		_tabFontFamily = value;
		await Preferences.setString(TAB_FONT_FAMILY, value);

		notifyListeners();
	}

	Future<void> setIsTabBold(bool value) async {
		_isTabBold = value;
		await Preferences.setBool(IS_TAB_BOLD, value);

		notifyListeners();
	}

	Future<void> setIsTabItalic(bool value) async {
		_isTabItalic = value;
		await Preferences.setBool(IS_TAB_ITALIC, value);

		notifyListeners();
	}

	Future<void> setPlainTextFontFamily(String value) async {
		_plainTextFontFamily = value;
		await Preferences.setString(PLAIN_TEXT_FONT_FAMILY, value);

		notifyListeners();
	}

	Future<void> setIsPlainTextBold(bool value) async {
		_isPlainTextBold = value;
		await Preferences.setBool(IS_PLAIN_TEXT_BOLD, value);

		notifyListeners();
	}

	Future<void> setIsPlainTextItalic(bool value) async {
		_isPlainTextItalic = value;
		await Preferences.setBool(IS_PLAIN_TEXT_ITALIC, value);

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
		final FilePickerResult? result = await FilePicker.pickFiles(
			type: FileType.image,
		);

		if (result != null && result.files.single.path != null) {
			await resetBackgroundImage();
			PaintingBinding.instance.imageCache.clear();
			PaintingBinding.instance.imageCache.clearLiveImages();

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

	Future<void> resetCustomFonts() async {
		final dir = await getApplicationSupportDirectory();
		final fontsDir = Directory(dir.path + '/fonts');
		if (!fontsDir.existsSync())
			return;

		await fontsDir.delete(recursive: true);
		_customFonts = {};
	}

	Future<void> resetTitleStyle() async {
		_titleFontFamily = null;
		await Preferences.remove(TITLE_FONT_FAMILY);

		_isTitleBold = true;
		await Preferences.remove(IS_TITLE_BOLD);

		_isTitleItalic = false;
		await Preferences.remove(IS_TITLE_ITALIC);


		notifyListeners();
	}
	Future<void> resetNotesStyle() async {
		_notesFontFamily = null;
		await Preferences.remove(NOTES_FONT_FAMILY);

		_isNotesBold = false;
		await Preferences.remove(IS_NOTES_BOLD);

		_isNotesItalic = false;
		await Preferences.remove(IS_NOTES_ITALIC);


		notifyListeners();
	}
	Future<void> resetFingeringsStyle() async {
		_fingeringsFontFamily = null;
		await Preferences.remove(FINGERINGS_FONT_FAMILY);

		_isFingeringsBold = true;
		await Preferences.remove(IS_FINGERINGS_BOLD);

		_isFingeringsItalic = false;
		await Preferences.remove(IS_FINGERINGS_ITALIC);


		notifyListeners();
	}
	Future<void> resetTabStyle() async {
		_tabFontFamily = null;
		await Preferences.remove(TAB_FONT_FAMILY);

		_isTabBold = true;
		await Preferences.remove(IS_TAB_BOLD);

		_isTabItalic = false;
		await Preferences.remove(IS_TAB_ITALIC);


		notifyListeners();
	}
	Future<void> resetPlainTextStyle() async {
		_plainTextFontFamily = null;
		await Preferences.remove(PLAIN_TEXT_FONT_FAMILY);

		_isPlainTextBold = false;
		await Preferences.remove(IS_PLAIN_TEXT_BOLD);

		_isPlainTextItalic = false;
		await Preferences.remove(IS_PLAIN_TEXT_ITALIC);

		notifyListeners();
	}


	Future<bool> exportBackup() async {
		final dir = await getApplicationSupportDirectory();
		final tempBackup = File(dir.path + '/backup.zip');
		final settings = _exportAllSettingsToMap();

		String? fontsPath;
		if (!_customFonts.isEmpty) {
			fontsPath = dir.path + '/fonts';
		}

		String? backgroundPath = _backgroundImage?.path;

		rust_lib.exportBackup(
			outputPathStr: tempBackup.path,
			settings: settings,
			fontsPath: fontsPath,
			backgroundPath: backgroundPath,
		);


		final now = DateTime.now();
		final String date = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
		String? outputPath = await FilePicker.saveFile(
			dialogTitle: 'Save backup as...',
			fileName: 'songbook_backup_$date.zip',
			bytes: (Platform.isAndroid)
				? await tempBackup.readAsBytes()
				: null,
		);
		if (outputPath == null) {
			await tempBackup.delete();
			return false;
		} else {
			if (Platform.isAndroid) {
				await tempBackup.delete();
			} else {
				await tempBackup.rename(outputPath!);
			}
		}

		return true;
	}
	Map<String, String> _exportAllSettingsToMap() {
		Map<String, String> settings = {};

		settings[IS_DARK_THEME] = _isDarkTheme.toString();
		settings[IS_AMOLED] = _isAmoled.toString();
		settings[COLOR_ACCENT] = _colorAccent;
		settings[EDITOR_FONT_SIZE] = _editorFontSize.toString();
		settings[EDITOR_FONT_FAMILY] = _editorFontFamily;
		settings[SONG_FONT_SIZE] = _songFontSize.toString();
		settings[SONG_FONT_FAMILY] = _songFontFamily;

		if (_titleFontFamily != null)
			settings[TITLE_FONT_FAMILY] = _titleFontFamily!;
		settings[IS_TITLE_BOLD] = _isTitleBold.toString();
		settings[IS_TITLE_ITALIC] = _isTitleItalic.toString();

		if (_notesFontFamily != null)
			settings[NOTES_FONT_FAMILY] = _notesFontFamily!;
		settings[IS_NOTES_BOLD] = _isNotesBold.toString();
		settings[IS_NOTES_ITALIC] = _isNotesItalic.toString();

		if (_fingeringsFontFamily != null)
			settings[FINGERINGS_FONT_FAMILY] = _fingeringsFontFamily!;
		settings[IS_FINGERINGS_BOLD] = _isFingeringsBold.toString();
		settings[IS_FINGERINGS_ITALIC] = _isFingeringsItalic.toString();

		if (_tabFontFamily != null)
			settings[TAB_FONT_FAMILY] = _tabFontFamily!;
		settings[IS_TAB_BOLD] = _isTabBold.toString();
		settings[IS_TAB_ITALIC] = _isTabItalic.toString();

		if (_plainTextFontFamily != null)
			settings[PLAIN_TEXT_FONT_FAMILY] = _plainTextFontFamily!;
		settings[IS_PLAIN_TEXT_BOLD] = _isPlainTextBold.toString();
		settings[IS_PLAIN_TEXT_ITALIC] = _isPlainTextItalic.toString();

		if (_chordsColor != null)
			settings[CHORDS_COLOR] = _chordsColor!;

		if (_rhythmColor != null)
			settings[RHYTHM_COLOR] = _rhythmColor!;

		if (_textColor != null)
			settings[TEXT_COLOR] = _textColor!;

		if (_notesColor != null)
			settings[NOTES_COLOR] = _notesColor!;

		if (_titleColor != null)
			settings[TITLE_COLOR] = _titleColor!;

		if (_backgroundColor != null)
			settings[BACKGROUND_COLOR] = _backgroundColor!;

		settings[LINE_WRAP_IN_SONG] = _lineWrapInSong.toString();

		if (_fingeringSizeInSong != null)
			settings[FINGERING_SIZE_IN_SONG] = _fingeringSizeInSong!;

		settings[BACKGROUND_OPACITY] = _backgroundOpacity.toString();

		return settings;
	}

	Future<bool> importBackup() async {
		final FilePickerResult? result = await FilePicker.pickFiles(
			type: FileType.custom,
			allowedExtensions: ['zip'],
		);
		if (result == null || result.files.single.path == null)
			return false;

		final String backupPath = result.files.single.path!;

		final dir = await getApplicationSupportDirectory();
		final fontsPath = dir.path + '/fonts';
		final backgroundImagePath = dir.path + '/background_img';
		final settings = rust_lib.importBackup(
			backupPathStr: backupPath,
			fontsPathStr: fontsPath,
			backgroundPathStr: backgroundImagePath,
		);
		await _importAllSettingsFromMap(settings);
		return true;
	}
	Future<void> _importAllSettingsFromMap(Map<String, String> settings) async {
		_isDarkTheme = _boolFromString(settings[IS_DARK_THEME]);
		if (_isDarkTheme != null)
			await Preferences.setBool(IS_DARK_THEME, _isDarkTheme!);
		else
			await Preferences.remove(IS_DARK_THEME);


		_isAmoled = _boolFromString(settings[IS_AMOLED]) ?? false;
		await Preferences.setBool(IS_AMOLED, _isAmoled);
		

		_colorAccent = settings[COLOR_ACCENT] ?? 'blue';
		await Preferences.setString(COLOR_ACCENT, _colorAccent);


		_editorFontSize = _doubleFromString(settings[EDITOR_FONT_SIZE]) ?? 14;
		await Preferences.setDouble(EDITOR_FONT_SIZE, _editorFontSize);


		_editorFontFamily = settings[EDITOR_FONT_FAMILY] ?? 'CascadiaMono';
		await Preferences.setString(EDITOR_FONT_FAMILY, _editorFontFamily);


		_songFontSize = _doubleFromString(settings[SONG_FONT_SIZE]) ?? 14;
		await Preferences.setDouble(SONG_FONT_SIZE, _songFontSize);


		_songFontFamily = settings[SONG_FONT_FAMILY] ?? 'JetBrainsMono';
		await Preferences.setString(SONG_FONT_FAMILY, _songFontFamily);


		_titleFontFamily = settings[TITLE_FONT_FAMILY];
		if (_titleFontFamily != null)
			await Preferences.setString(TITLE_FONT_FAMILY, _titleFontFamily!);
		else
			await Preferences.remove(TITLE_FONT_FAMILY);


		_isTitleBold = _boolFromString(settings[IS_TITLE_BOLD]) ?? true;
		await Preferences.setBool(IS_TITLE_BOLD, _isTitleBold);


		_isTitleItalic = _boolFromString(settings[IS_TITLE_ITALIC]) ?? false;
		await Preferences.setBool(IS_TITLE_ITALIC, _isTitleItalic);


		_notesFontFamily = settings[NOTES_FONT_FAMILY];
		if (_notesFontFamily != null)
			await Preferences.setString(NOTES_FONT_FAMILY, _notesFontFamily!);
		else
			await Preferences.remove(NOTES_FONT_FAMILY);


		_isNotesBold = _boolFromString(settings[IS_NOTES_BOLD]) ?? false;
		await Preferences.setBool(IS_NOTES_BOLD, _isNotesBold);


		_isNotesItalic = _boolFromString(settings[IS_NOTES_ITALIC]) ?? false;
		await Preferences.setBool(IS_NOTES_ITALIC, _isNotesItalic);


		_fingeringsFontFamily = settings[FINGERINGS_FONT_FAMILY];
		if (_fingeringsFontFamily != null)
			await Preferences.setString(FINGERINGS_FONT_FAMILY, _fingeringsFontFamily!);
		else
			await Preferences.remove(FINGERINGS_FONT_FAMILY);


		_isFingeringsBold = _boolFromString(settings[IS_FINGERINGS_BOLD]) ?? true;
		await Preferences.setBool(IS_FINGERINGS_BOLD, _isFingeringsBold);


		_isFingeringsItalic = _boolFromString(settings[IS_FINGERINGS_ITALIC]) ?? false;
		await Preferences.setBool(IS_FINGERINGS_ITALIC, _isFingeringsItalic);


		_tabFontFamily = settings[TAB_FONT_FAMILY];
		if (_tabFontFamily != null)
			await Preferences.setString(TAB_FONT_FAMILY, _tabFontFamily!);
		else
			await Preferences.remove(TAB_FONT_FAMILY);


		_isTabBold = _boolFromString(settings[IS_TAB_BOLD]) ?? true;
		await Preferences.setBool(IS_TAB_BOLD, _isTabBold);


		_isTabItalic = _boolFromString(settings[IS_TAB_ITALIC]) ?? false;
		await Preferences.setBool(IS_TAB_ITALIC, _isTabItalic);


		_plainTextFontFamily = settings[PLAIN_TEXT_FONT_FAMILY];
		if (_plainTextFontFamily != null)
			await Preferences.setString(PLAIN_TEXT_FONT_FAMILY, _plainTextFontFamily!);
		else
			await Preferences.remove(PLAIN_TEXT_FONT_FAMILY);


		_isPlainTextBold = _boolFromString(settings[IS_PLAIN_TEXT_BOLD]) ?? false;
		await Preferences.setBool(IS_PLAIN_TEXT_BOLD, _isPlainTextBold);


		_isPlainTextItalic = _boolFromString(settings[IS_PLAIN_TEXT_ITALIC]) ?? false;
		await Preferences.setBool(IS_PLAIN_TEXT_ITALIC, _isPlainTextItalic);


		_chordsColor = settings[CHORDS_COLOR];
		if (_chordsColor != null)
			await Preferences.setString(CHORDS_COLOR, _chordsColor!);
		else
			await Preferences.remove(CHORDS_COLOR);


		_rhythmColor = settings[RHYTHM_COLOR];
		if (_rhythmColor != null)
			await Preferences.setString(RHYTHM_COLOR, _rhythmColor!);
		else
			await Preferences.remove(RHYTHM_COLOR);


		_textColor = settings[TEXT_COLOR];
		if (_textColor != null)
			await Preferences.setString(TEXT_COLOR, _textColor!);
		else
			await Preferences.remove(TEXT_COLOR);


		_notesColor = settings[NOTES_COLOR];
		if (_notesColor != null)
			await Preferences.setString(NOTES_COLOR, _notesColor!);
		else
			await Preferences.remove(NOTES_COLOR);


		_titleColor = settings[TITLE_COLOR];
		if (_titleColor != null)
			await Preferences.setString(TITLE_COLOR, _titleColor!);
		else
			await Preferences.remove(TITLE_COLOR);


		_backgroundColor = settings[BACKGROUND_COLOR];
		if (_backgroundColor != null)
			await Preferences.setString(BACKGROUND_COLOR, _backgroundColor!);
		else
			await Preferences.remove(BACKGROUND_COLOR);


		_lineWrapInSong = _boolFromString(settings[LINE_WRAP_IN_SONG]) ?? true;
		await Preferences.setBool(LINE_WRAP_IN_SONG, _lineWrapInSong);


		_fingeringSizeInSong = settings[FINGERING_SIZE_IN_SONG];
		if (_fingeringSizeInSong != null)
			await Preferences.setString(FINGERING_SIZE_IN_SONG, _fingeringSizeInSong!);
		else
			await Preferences.remove(FINGERING_SIZE_IN_SONG);


		_backgroundOpacity = _doubleFromString(settings[BACKGROUND_OPACITY]) ?? 1.0;
		await Preferences.setDouble(BACKGROUND_OPACITY, _backgroundOpacity);


		notifyListeners();
	}
	bool? _boolFromString(String? value) {
		if (value == 'true') {
			return true;
		} else if (value == 'false') {
			return false;
		} else {
			return null;
		}
	}
	double? _doubleFromString(String? value) {
		if (value == null)
			return null;
		else
			return double.tryParse(value!);
	}



	Future<void> resetToDefault() async {
		await resetBackgroundImage();
		await resetCustomFonts();
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:restart_app/restart_app.dart';

import 'package:songbook/main.dart';
import 'package:songbook/services/preferences.dart';
import 'package:songbook/src/rust/api/library.dart' as rust_lib;
import 'package:songbook/src/rust/api/theory.dart' as rust_theory;
import 'package:songbook/l10n/app_localizations.dart';


// keys
const String TITLE_COLOR = 'title_color';
const String TITLE_FONT_FAMILY = 'title_font_family';
const String IS_TITLE_BOLD = 'is_title_bold';
const String IS_TITLE_ITALIC = 'is_title_italic';

const String NOTES_COLOR = 'notes_color';
const String NOTES_FONT_FAMILY = 'notes_font_family';
const String IS_NOTES_BOLD = 'is_notes_bold';
const String IS_NOTES_ITALIC = 'is_notes_italic';

const String FINGERINGS_COLOR = 'fingerings_color';
const String FINGERINGS_FONT_FAMILY = 'fingerings_font_family';
const String IS_FINGERINGS_BOLD = 'is_fingerings_bold';
const String IS_FINGERINGS_ITALIC = 'is_fingerings_italic';

const String TAB_COLOR = 'tab_color';
const String TAB_FONT_FAMILY = 'tab_font_family';
const String IS_TAB_BOLD = 'is_tab_bold';
const String IS_TAB_ITALIC = 'is_tab_italic';

const String PLAIN_TEXT_COLOR = 'plain_text_color';
const String PLAIN_TEXT_FONT_FAMILY = 'plain_text_font_family';
const String IS_PLAIN_TEXT_BOLD = 'is_plain_text_bold';
const String IS_PLAIN_TEXT_ITALIC = 'is_plain_text_italic';


const String BACKGROUND_COLOR = 'background_color';
const String TEXT_COLOR = 'text_color';
const String CHORDS_COLOR = 'chords_color';
const String RHYTHM_COLOR = 'rhythm_color';

const String IS_DARK_THEME = 'is_dark_theme';
const String IS_AMOLED = 'is_amoled';
const String COLOR_ACCENT = 'color_accent';
const String EDITOR_FONT_SIZE = 'editor_font_size';
const String EDITOR_FONT_FAMILY = 'editor_font_family';
const String SONG_FONT_SIZE = 'song_font_size';
const String SONG_FONT_FAMILY = 'song_font_family';
const String SHARP_ONLY = 'sharp_only';
const String LINE_WRAP_IN_SONG = 'line_wrap_in_song';
const String FINGERING_SIZE_IN_SONG = 'fingering_size_in_song';
const String BACKGROUND_OPACITY = 'background_opacity';
const String LANGUAGE = 'language';
const String ANDROID_CUSTOM_LIB_PATH = 'android_custom_lib_path';

const Map<String, String> LANGUAGES = {
	'en': 'English',
	'ru': 'Русский',
    'uk': 'Українська'
};


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


	String display(BuildContext context) {
		return switch(this) {
			FingeringSize.small => AppLocalizations.of(context)!.fingeringsSizeSmall,
			FingeringSize.medium => AppLocalizations.of(context)!.fingeringsSizeMedium,
			FingeringSize.big => AppLocalizations.of(context)!.fingeringsSizeBig,
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

class SettingsColor {
	String? str;
	final String key;
	final Color Function(BuildContext) withContext;

	SettingsColor({
		this.str,
		required this.key,
		required this.withContext,
	});

	bool isNull() => Preferences.getString(key) == null;

	Color? get() => _stringToColor(str);
	Future<void> set(String? value) async {
		str = value;
		if (value != null)
			await Preferences.setString(key, value);
		else
			await Preferences.remove(key);
	}

	void load() => str = Preferences.getString(key);

	void export(Map<String, String> settings) {
		if (str != null)
			settings[key] = str!;
	}
	Future<void> import(Map<String, String> settings) async {
		await set(settings[key]);
	}
}

class FontStyle {
	final SettingsColor color;
	String? fontFamily;
	bool bold;
	bool italic;

	final bool defaultBold;
	final bool defaultItalic;

	final String fontFamilyKey;
	final String boldKey;
	final String italicKey;

	FontStyle({
		required this.color,
		required this.fontFamily,
		required this.bold,
		required this.italic,
		required this.defaultBold,
		required this.defaultItalic,
		required this.fontFamilyKey,
		required this.boldKey,
		required this.italicKey,
	});

	bool isNull() {
		return (
			fontFamily == null
				&&
			bold == defaultBold
				&&
			italic == defaultItalic
				&&
			color.isNull()
		);
	}

	Future<void> setFontFamily(String value) async {
		fontFamily = value;
		await Preferences.setString(fontFamilyKey, value);
	}
	Future<void> setBold(bool value) async {
		bold = value;
		await Preferences.setBool(boldKey, value);
	}
	Future<void> setItalic(bool value) async {
		italic = value;
		await Preferences.setBool(italicKey, value);
	}

	Future<void> reset() async {
		fontFamily = null;
		await Preferences.remove(fontFamilyKey);

		bold = defaultBold;
		await Preferences.remove(boldKey);

		italic = defaultItalic;
		await Preferences.remove(italicKey);

		await color.set(null);
	}

	void load() {
		fontFamily = Preferences.getString(fontFamilyKey);
		bold = Preferences.getBool(boldKey) ?? defaultBold;
		italic = Preferences.getBool(italicKey) ?? defaultItalic;
		color.load();
	}

	void export(Map<String, String> settings) {
		if (fontFamily != null)
			settings[fontFamilyKey] = fontFamily!;

		settings[boldKey] = bold.toString();
		settings[italicKey] = italic.toString();
		color.export(settings);

	}
	Future<void> import(Map<String, String> settings) async {
		fontFamily = settings[fontFamilyKey];
		if (fontFamily != null)
			await Preferences.setString(fontFamilyKey, fontFamily!);
		else
			await Preferences.remove(fontFamilyKey);


		bold = _boolFromString(settings[boldKey]) ?? defaultBold;
		await Preferences.setBool(boldKey, bold);


		italic = _boolFromString(settings[italicKey]) ?? defaultItalic;
		await Preferences.setBool(italicKey, italic);

		await color.import(settings);
	}
}


class SettingsProvider extends ChangeNotifier {
	final _backgroundColor = SettingsColor(
		withContext: (context) => Theme.of(context).colorScheme.surface,
		key: BACKGROUND_COLOR,
	);
	Color backgroundColor(BuildContext context) {
		final color = _backgroundColor.get();
		if (color != null) {
			return color;
		} else if (_backgroundOpacity == 1.0) {
			return _backgroundColor.withContext(context);
		} else {
			return Color(0x00000000);
		}
	}
	bool get backgroundColorIsNull => _backgroundColor.isNull();
	Future<void> setBackgroundColor(String? value) async {
		await _backgroundColor.set(value);
		notifyListeners();
	}

	final _textColor = SettingsColor(
		withContext: (context) => Theme.of(context).colorScheme.onSurface,
		key: TEXT_COLOR,
	);
	Color textColor(BuildContext context) =>
		_textColor.get() ?? _textColor.withContext(context);
	bool get textColorIsNull => _textColor.isNull();
	Future<void> setTextColor(String? value) async {
		await _textColor.set(value);
		notifyListeners();
	}
	TextStyle textStyle(BuildContext context) => TextStyle(
		color: textColor(context),
		fontFamily: _songFontFamily,
		fontSize: _songFontSize,
	);
	TextStyle editorStyle() => TextStyle(
		fontFamily: _editorFontFamily,
		fontSize: _editorFontSize,
		height: 1.6,
	); // only for raw and source modes

	final _chordsColor = SettingsColor(
		withContext: (context) => Theme.of(context).colorScheme.primary,
		key: CHORDS_COLOR,
	);
	Color chordsColor(BuildContext context) =>
		_chordsColor.get() ?? _chordsColor.withContext(context);
	bool get chordsColorIsNull => _chordsColor.isNull();
	Future<void> setChordsColor(String? value) async {
		_chordsColor.set(value);
		notifyListeners();
	}
	TextStyle chordsStyle(BuildContext context) => TextStyle(
		color: chordsColor(context),
		fontFamily: _songFontFamily,
		fontSize: _songFontSize,
		fontWeight: .bold,
	);

	final _rhythmColor = SettingsColor(
		withContext: (context) => Theme.of(context).colorScheme.tertiary,
		key: RHYTHM_COLOR,
	);
	Color rhythmColor(BuildContext context) =>
		_rhythmColor.get() ?? _rhythmColor.withContext(context);
	bool get rhythmColorIsNull => _rhythmColor.isNull();
	Future<void> setRhythmColor(String? value) async {
		_rhythmColor.set(value);
		notifyListeners();
	}
	TextStyle rhythmStyle(BuildContext context) => TextStyle(
		color: rhythmColor(context),
		fontFamily: _songFontFamily,
		fontSize: _songFontSize,
		fontWeight: .bold,
	);


	final _titleStyle = FontStyle(
		color: SettingsColor(
			withContext: (context) => Theme.of(context).colorScheme.secondary,
			key: TITLE_COLOR,
		),
		fontFamily: null,
		bold: true,
		italic: false,
		defaultBold: true,
		defaultItalic: false,
		fontFamilyKey: TITLE_FONT_FAMILY,
		boldKey: IS_TITLE_BOLD,
		italicKey: IS_TITLE_ITALIC,
	);
	String get titleFontFamily => _titleStyle.fontFamily ?? _songFontFamily;
	bool get isTitleBold => _titleStyle.bold;
	bool get isTitleItalic => _titleStyle.italic;
	bool get isTitleStyleNull => _titleStyle.isNull();
	Color titleColor(BuildContext context) =>
		_titleStyle.color.get() ?? _titleStyle.color.withContext(context);
	TextStyle titleStyle(BuildContext context) => TextStyle(
		color: titleColor(context),
		fontSize: _songFontSize * 1.5,
		fontFamily: titleFontFamily,
		fontWeight: isTitleBold
			? .bold
			: .normal,
		fontStyle: isTitleItalic
			? .italic
			: .normal,
	);

	Future<void> setTitleFontFamily(String value) async {
		await _titleStyle.setFontFamily(value);
		notifyListeners();
	}
	Future<void> setIsTitleBold(bool value) async {
		await _titleStyle.setBold(value);
		notifyListeners();
	}
	Future<void> setIsTitleItalic(bool value) async {
		await _titleStyle.setItalic(value);
		notifyListeners();
	}
	Future<void> setTitleColor(String? value) async {
		await _titleStyle.color.set(value);
		notifyListeners();
	}
	Future<void> resetTitleStyle() async {
		await _titleStyle.reset();
		notifyListeners();
	}


	final _notesStyle = FontStyle(
		color: SettingsColor(
			withContext: (context) => Theme.of(context).colorScheme.onSurfaceVariant,
			key: NOTES_COLOR,
		),
		fontFamily: null,
		bold: false,
		italic: false,
		defaultBold: false,
		defaultItalic: false,
		fontFamilyKey: NOTES_FONT_FAMILY,
		boldKey: IS_NOTES_BOLD,
		italicKey: IS_NOTES_ITALIC,
	);
	String get notesFontFamily => _notesStyle.fontFamily ?? _songFontFamily;
	bool get isNotesBold => _notesStyle.bold;
	bool get isNotesItalic => _notesStyle.italic;
	bool get isNotesStyleNull => _notesStyle.isNull();
	Color notesColor(BuildContext context) =>
		_notesStyle.color.get() ?? _notesStyle.color.withContext(context);
	TextStyle notesStyle(BuildContext context) => TextStyle(
		color: notesColor(context),
		fontSize: _songFontSize * 0.9,
		fontFamily: notesFontFamily,
		fontWeight: isNotesBold
			? .bold
			: .normal,
		fontStyle: isNotesItalic
			? .italic
			: .normal,
	);

	Future<void> setNotesFontFamily(String value) async {
		await _notesStyle.setFontFamily(value);
		notifyListeners();
	}

	Future<void> setIsNotesBold(bool value) async {
		await _notesStyle.setBold(value);
		notifyListeners();
	}

	Future<void> setIsNotesItalic(bool value) async {
		await _notesStyle.setItalic(value);
		notifyListeners();
	}
	Future<void> setNotesColor(String? value) async {
		await _notesStyle.color.set(value);
		notifyListeners();
	}
	Future<void> resetNotesStyle() async {
		await _notesStyle.reset();
		notifyListeners();
	}


	final _fingeringsStyle = FontStyle(
		color: SettingsColor(
			withContext: (context) => Theme.of(context).colorScheme.onSurface,
			key: FINGERINGS_COLOR,
		),
		fontFamily: null,
		bold: true,
		italic: false,
		defaultBold: true,
		defaultItalic: false,
		fontFamilyKey: FINGERINGS_FONT_FAMILY,
		boldKey: IS_FINGERINGS_BOLD,
		italicKey: IS_FINGERINGS_ITALIC,
	);
	String get fingeringsFontFamily => _fingeringsStyle.fontFamily ?? _songFontFamily;
	bool get isFingeringsBold => _fingeringsStyle.bold;
	bool get isFingeringsItalic => _fingeringsStyle.italic;
	bool get isFingeringsStyleNull => _fingeringsStyle.isNull();
	Color fingeringsColor(BuildContext context) =>
		_fingeringsStyle.color.get() ?? _fingeringsStyle.color.withContext(context);
	TextStyle fingeringsStyle(BuildContext context) {
		final size = switch (fingeringSizeInSong) {
			FingeringSize.small => _songFontSize * 0.5,
			FingeringSize.medium => _songFontSize * 0.75,
			FingeringSize.big => _songFontSize,
		};

		return TextStyle(
			color: fingeringsColor(context),
			fontSize: size,
			fontFamily: fingeringsFontFamily,
			fontWeight: isFingeringsBold
				? .bold
				: .normal,
			fontStyle: isFingeringsItalic
				? .italic
				: .normal,
		);
	}
	TextStyle fingeringsTitleStyle(BuildContext context) {
		final size = switch (fingeringSizeInSong) {
			FingeringSize.small => _songFontSize * 0.75,
			FingeringSize.medium => _songFontSize,
			FingeringSize.big => _songFontSize * 1.25,
		};

		return TextStyle(
			color: chordsColor(context),
			fontSize: size,
		);
	}

	Future<void> setFingeringsFontFamily(String value) async {
		await _fingeringsStyle.setFontFamily(value);
		notifyListeners();
	}

	Future<void> setIsFingeringsBold(bool value) async {
		await _fingeringsStyle.setBold(value);
		notifyListeners();
	}

	Future<void> setIsFingeringsItalic(bool value) async {
		await _fingeringsStyle.setItalic(value);
		notifyListeners();
	}
	Future<void> setFingeringsColor(String? value) async {
		await _fingeringsStyle.color.set(value);
		notifyListeners();
	}
	Future<void> resetFingeringsStyle() async {
		await _fingeringsStyle.reset();
		notifyListeners();
	}


	final _tabStyle = FontStyle(
		color: SettingsColor(
			withContext: (context) => Theme.of(context).colorScheme.onSurface,
			key: TAB_COLOR,
		),
		fontFamily: null,
		bold: true,
		italic: false,
		defaultBold: true,
		defaultItalic: false,
		fontFamilyKey: TAB_FONT_FAMILY,
		boldKey: IS_TAB_BOLD,
		italicKey: IS_TAB_ITALIC,
	);
	String get tabFontFamily => _tabStyle.fontFamily ?? _songFontFamily;
	bool get isTabBold => _tabStyle.bold;
	bool get isTabItalic => _tabStyle.italic;
	bool get isTabStyleNull => _tabStyle.isNull();
	Color tabColor(BuildContext context) =>
		_tabStyle.color.get() ?? _tabStyle.color.withContext(context);
	TextStyle tabStyle(BuildContext context) => TextStyle(
		color: tabColor(context),
		fontFamily: tabFontFamily,
		fontSize: _songFontSize,
		fontWeight: isTabBold
			? .bold
			: .normal,
		fontStyle: isTabItalic
			? .italic
			: .normal,
	);
	Future<void> setTabFontFamily(String value) async {
		await _tabStyle.setFontFamily(value);
		notifyListeners();
	}

	Future<void> setIsTabBold(bool value) async {
		await _tabStyle.setBold(value);
		notifyListeners();
	}

	Future<void> setIsTabItalic(bool value) async {
		await _tabStyle.setItalic(value);
		notifyListeners();
	}
	Future<void> setTabColor(String? value) async {
		await _tabStyle.color.set(value);
		notifyListeners();
	}
	Future<void> resetTabStyle() async {
		await _tabStyle.reset();
		notifyListeners();
	}


	final _plainTextStyle = FontStyle(
		color: SettingsColor(
			withContext: (context) => Theme.of(context).colorScheme.onSurface,
			key: PLAIN_TEXT_COLOR,
		),
		fontFamily: null,
		bold: false,
		italic: true,
		defaultBold: false,
		defaultItalic: true,
		fontFamilyKey: PLAIN_TEXT_FONT_FAMILY,
		boldKey: IS_PLAIN_TEXT_BOLD,
		italicKey: IS_PLAIN_TEXT_ITALIC,
	);
	String get plainTextFontFamily => _plainTextStyle.fontFamily ?? _songFontFamily;
	bool get isPlainTextBold => _plainTextStyle.bold;
	bool get isPlainTextItalic => _plainTextStyle.italic;
	bool get isPlainTextStyleNull => _plainTextStyle.isNull();
	Color plainTextColor(BuildContext context) =>
		_plainTextStyle.color.get() ?? _plainTextStyle.color.withContext(context);
	TextStyle plainTextStyle(BuildContext context) => TextStyle(
		color: plainTextColor(context),
		fontFamily: plainTextFontFamily,
		fontSize: _songFontSize,
		fontWeight: isPlainTextBold
			? .bold
			: .normal,
		fontStyle: isPlainTextItalic
			? .italic
			: .normal,
	);
	Future<void> setPlainTextFontFamily(String value) async {
		await _plainTextStyle.setFontFamily(value);
		notifyListeners();
	}

	Future<void> setIsPlainTextBold(bool value) async {
		await _plainTextStyle.setBold(value);
		notifyListeners();
	}

	Future<void> setIsPlainTextItalic(bool value) async {
		await _plainTextStyle.setItalic(value);
		notifyListeners();
	}
	Future<void> setPlainTextColor(String? value) async {
		await _plainTextStyle.color.set(value);
		notifyListeners();
	}
	Future<void> resetPlainTextStyle() async {
		await _plainTextStyle.reset();
		notifyListeners();
	}



	bool _isAmoled = false;
	bool get isAmoled => _isAmoled;
	Future<void> setAmoled(bool value) async {
		_isAmoled = value;
		await Preferences.setBool(IS_AMOLED, value);

		notifyListeners();
	}

	String _colorAccent = 'blue';
	Color get colorAccent => _stringToColor(_colorAccent) ?? Colors.blue;
	Future<void> setColorAccent(String value) async {
		_colorAccent = value;
		await Preferences.setString(COLOR_ACCENT, value);

		notifyListeners();
	}

	bool? _isDarkTheme;
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
	Future<void> setThemeMode(ThemeMode value) async {
		final isDark = switch (value) {
			ThemeMode.dark => true,
			ThemeMode.light => false,
			ThemeMode.system => null
		};


		_isDarkTheme = isDark;
		if (isDark != null) {
			await Preferences.setBool(IS_DARK_THEME, isDark);
		} else {
			await Preferences.remove(IS_DARK_THEME);
		}

		notifyListeners();
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
		surfaceContainerHighest: Color(0xFF333333),
	);
	ThemeData ligthTheme() {
		final colorScheme = lightColorScheme();
		final surface = colorScheme.surface.withValues(alpha: _backgroundOpacity);
		final surfaceContainer = colorScheme.surfaceContainer.withValues(alpha: _calculateOpacity());
		final surfaceVariant = colorScheme.surfaceContainerHighest.withValues(alpha: _calculateOpacity());


		return ThemeData(
			useMaterial3: true,
			colorScheme: colorScheme.copyWith(
				surface: surface,
				surfaceContainer: surfaceContainer,
				surfaceContainerHighest: surfaceVariant,
			),
			snackBarTheme: snackBarTheme(),
		);
	}
	ThemeData darkTheme() {
		final colorScheme = _isAmoled
			? amoledColorScheme()
			: darkColorScheme();
		final surface = colorScheme.surface.withValues(alpha: _backgroundOpacity);
		final surfaceContainer = colorScheme.surfaceContainer.withValues(alpha: _calculateOpacity());
		final surfaceVariant = colorScheme.surfaceContainerHighest.withValues(alpha: _calculateOpacity());


		return ThemeData(
			useMaterial3: true,
			colorScheme: colorScheme.copyWith(
				surface: surface,
				surfaceContainer: surfaceContainer,
				surfaceContainerHighest: surfaceVariant,
			),
			snackBarTheme: snackBarTheme(),
		);
	}



	Map<String, File> _customFonts = {};

	double _editorFontSize = 14;
	String _editorFontFamily = 'CascadiaMono';
	double _songFontSize = 14;
	String _songFontFamily = 'JetBrainsMono';
	String? _language;
	Locale? _locale;
	String? _androidCustomLibPath;
	bool _sharpOnly = false;
	bool _lineWrapInSong = true;
	String? _fingeringSizeInSong;
	File? _backgroundImage;
	double _backgroundOpacity = 1.0;

	FingeringSize get fingeringSizeInSong {
		return FingeringSize.from_string(_fingeringSizeInSong) ?? FingeringSize.medium;
	}


	double get editorFontSize => _editorFontSize;
	String get editorFontFamily => _editorFontFamily;

	double get songFontSize => _songFontSize;
	String get songFontFamily => _songFontFamily;

	Locale? get locale => _locale;
	String? get language => _language;

	String? get androidCustomLibPath => _androidCustomLibPath;

	bool get sharpOnly => _sharpOnly;

	bool get lineWrapInSong => _lineWrapInSong;

	File? get backgroundImage => _backgroundImage;
	double get backgroundOpacity => _backgroundOpacity;

	List<String> get customFontFamilies => _customFonts.keys.toList();


	SettingsProvider() {
		_loadAllSettings();
	}

	void _loadAllSettings() async {
		_titleStyle.load();
		_notesStyle.load();
		_fingeringsStyle.load();
		_tabStyle.load();
		_plainTextStyle.load();

		_backgroundColor.load();
		_textColor.load();
		_chordsColor.load();
		_rhythmColor.load();

		_isDarkTheme = Preferences.getBool(IS_DARK_THEME);
		_isAmoled = Preferences.getBool(IS_AMOLED) ?? false;
		_colorAccent = Preferences.getString(COLOR_ACCENT) ?? 'blue';
		_editorFontSize = Preferences.getDouble(EDITOR_FONT_SIZE) ?? 14;
		_editorFontFamily = Preferences.getString(EDITOR_FONT_FAMILY) ?? 'CascadiaMono';
		_songFontSize = Preferences.getDouble(SONG_FONT_SIZE) ?? 14;
		_songFontFamily = Preferences.getString(SONG_FONT_FAMILY) ?? 'JetBrainsMono';
		_sharpOnly = Preferences.getBool(SHARP_ONLY) ?? false;
		_lineWrapInSong = Preferences.getBool(LINE_WRAP_IN_SONG) ?? true;
		_fingeringSizeInSong = Preferences.getString(FINGERING_SIZE_IN_SONG);
		_backgroundOpacity = Preferences.getDouble(BACKGROUND_OPACITY) ?? 1.0;
		_androidCustomLibPath = Preferences.getString(ANDROID_CUSTOM_LIB_PATH);
		_language = Preferences.getString(LANGUAGE);
		if (_language != null)
			_locale = Locale(_language!);

		await _loadBackgroundImage();
		await _loadFonts();


		notifyListeners();
	}

	Future<void> _loadBackgroundImage() async {
		final dir = await getApplicationSupportDirectory();
		final savedFile = File(dir.path + pathDivider + 'background_img');
		if (savedFile.existsSync()) {
			_backgroundImage = savedFile;
		}
	}

	Future<void> _loadFonts() async {
		final dir = await getApplicationSupportDirectory();
		final fontsDir = Directory(dir.path + pathDivider + 'fonts');
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
		// ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
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
				final fontsDir = Directory(dir.path + pathDivider + 'fonts');

				if (!fontsDir.existsSync()) {
					await fontsDir.create(recursive: true);
				}


				final savedFile = File(fontsDir.path + pathDivider + file.name);
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

	Future<void> setLanguage(String? value) async {
		_language = value;
		_locale = (value != null) ? Locale(value) : null;
		if (value != null)
			await Preferences.setString(LANGUAGE, value);
		else
			await Preferences.remove(LANGUAGE);

		notifyListeners();
	}
	
	void setLocale(Locale? value) {
		_locale = value;
	}

	Future<void> setAndroidCustomLibPath(String? value) async {
		_androidCustomLibPath = value;
		if (value != null)
			await Preferences.setString(ANDROID_CUSTOM_LIB_PATH, value);
		else
			await Preferences.remove(ANDROID_CUSTOM_LIB_PATH);

		notifyListeners();
	}

	Future<void> setSharpOnly(bool value) async {
		_sharpOnly = value;
		await Preferences.setBool(SHARP_ONLY, value);
		rust_theory.setSharpOnly(isSharpOnly: value);

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
			final savedPath = dir.path + pathDivider + 'background_img';

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
		final fontsDir = Directory(dir.path + pathDivider + 'fonts');
		if (!fontsDir.existsSync())
			return;

		await fontsDir.delete(recursive: true);
		_customFonts = {};
	}


	Future<bool> exportBackup() async {
		final dir = await getApplicationSupportDirectory();
		final tempBackup = File(dir.path + pathDivider + 'backup.zip');
		final settings = _exportAllSettingsToMap();

		String? fontsPath;
		if (!_customFonts.isEmpty) {
			fontsPath = dir.path + pathDivider + 'fonts';
		}

		String? backgroundPath = _backgroundImage?.path;

		await rust_lib.exportBackup(
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
				await tempBackup.rename(outputPath);
			}
		}

		return true;
	}
	Map<String, String> _exportAllSettingsToMap() {
		Map<String, String> settings = {};

		_titleStyle.export(settings);
		_notesStyle.export(settings);
		_fingeringsStyle.export(settings);
		_tabStyle.export(settings);
		_plainTextStyle.export(settings);

		_textColor.export(settings);
		_backgroundColor.export(settings);
		_chordsColor.export(settings);
		_rhythmColor.export(settings);


		settings[IS_DARK_THEME] = _isDarkTheme.toString();
		settings[IS_AMOLED] = _isAmoled.toString();
		settings[COLOR_ACCENT] = _colorAccent;
		settings[EDITOR_FONT_SIZE] = _editorFontSize.toString();
		settings[EDITOR_FONT_FAMILY] = _editorFontFamily;
		settings[SONG_FONT_SIZE] = _songFontSize.toString();
		settings[SONG_FONT_FAMILY] = _songFontFamily;
		settings[SHARP_ONLY] = _sharpOnly.toString();
		settings[LINE_WRAP_IN_SONG] = _lineWrapInSong.toString();

		if (_fingeringSizeInSong != null)
			settings[FINGERING_SIZE_IN_SONG] = _fingeringSizeInSong!;

		settings[BACKGROUND_OPACITY] = _backgroundOpacity.toString();
		if (_language != null)
			settings[LANGUAGE] = _language!;

		if (_androidCustomLibPath != null)
			settings[ANDROID_CUSTOM_LIB_PATH] = _androidCustomLibPath!;

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
		final fontsPath = dir.path + pathDivider + 'fonts';
		final backgroundImagePath = dir.path + pathDivider + 'background_img';
		final settings = await rust_lib.importBackup(
			backupPathStr: backupPath,
			fontsPathStr: fontsPath,
			backgroundPathStr: backgroundImagePath,
		);
		await _importAllSettingsFromMap(settings);
		return true;
	}
	Future<void> _importAllSettingsFromMap(Map<String, String> settings) async {

		await _titleStyle.import(settings);
		await _notesStyle.import(settings);
		await _fingeringsStyle.import(settings);
		await _tabStyle.import(settings);
		await _plainTextStyle.import(settings);

		await _backgroundColor.import(settings);
		await _textColor.import(settings);
		await _chordsColor.import(settings);
		await _rhythmColor.import(settings);


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


		_sharpOnly = _boolFromString(settings[SHARP_ONLY]) ?? true;
		await Preferences.setBool(SHARP_ONLY, _sharpOnly);


		_lineWrapInSong = _boolFromString(settings[LINE_WRAP_IN_SONG]) ?? true;
		await Preferences.setBool(LINE_WRAP_IN_SONG, _lineWrapInSong);


		_fingeringSizeInSong = settings[FINGERING_SIZE_IN_SONG];
		if (_fingeringSizeInSong != null)
			await Preferences.setString(FINGERING_SIZE_IN_SONG, _fingeringSizeInSong!);
		else
			await Preferences.remove(FINGERING_SIZE_IN_SONG);


		_backgroundOpacity = _doubleFromString(settings[BACKGROUND_OPACITY]) ?? 1.0;
		await Preferences.setDouble(BACKGROUND_OPACITY, _backgroundOpacity);


		_language = settings[LANGUAGE];
		if (_language != null) {
			_locale = Locale(_language!);
			await Preferences.setString(LANGUAGE, _language!);
		} else {
			await Preferences.remove(LANGUAGE);
		}

		_androidCustomLibPath = settings[ANDROID_CUSTOM_LIB_PATH];
		if (_androidCustomLibPath != null)
			await Preferences.setString(ANDROID_CUSTOM_LIB_PATH, _androidCustomLibPath!);
		else
			await Preferences.remove(ANDROID_CUSTOM_LIB_PATH);


		notifyListeners();
	}


	Future<void> resetToDefault() async {
		await resetBackgroundImage();
		await resetCustomFonts();
		await Preferences.clear();
		_loadAllSettings();
	}
	Future<void> resetLibrary() async {
		rust_lib.resetLibrary();
		Restart.restartApp();
	}


	double _calculateOpacity() {
		final opacity = _backgroundOpacity + ((_backgroundOpacity + 0.2) * 0.25);
		if (opacity > 1)
			return _backgroundOpacity;
		else
			return opacity;
	}
}

Color? _stringToColor(String? colorStr) {
	if (colorStr == null) {
		return null;
	}

	if (colorStr.startsWith('#')) {
		return Color(int.parse(colorStr.substring(1), radix: 16));
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
		return double.tryParse(value);
}

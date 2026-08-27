import 'dart:io';
import 'package:flutter/material.dart';

import 'package:restart_app/restart_app.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import 'package:songbook/main.dart';
import 'package:songbook/services/preferences.dart';
import 'package:songbook/services/font_manager.dart';
import 'package:songbook/services/font_style.dart';
import 'package:songbook/services/keys.dart';
import 'package:songbook/services/functions.dart';
import 'package:songbook/src/rust/api/library.dart' as rust_lib;
import 'package:songbook/src/rust/api/theory.dart' as rust_theory;
import 'package:songbook/l10n/app_localizations.dart';


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

	String? _fingeringSizeInSong;
	FingeringSize get fingeringSizeInSong {
		return FingeringSize.from_string(_fingeringSizeInSong) ?? FingeringSize.medium;
	}
	Future<void> setFingeringSizeInSong(FingeringSize value) async {
		_fingeringSizeInSong = value.to_string();
		await Preferences.setString(FINGERING_SIZE_IN_SONG, _fingeringSizeInSong!);

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
	Color get colorAccent => stringToColor(_colorAccent) ?? Colors.blue;
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
	double _calculateOpacity() {
		final opacity = _backgroundOpacity + ((_backgroundOpacity + 0.2) * 0.25);
		if (opacity > 1)
			return _backgroundOpacity;
		else
			return opacity;
	}


	File? _backgroundImage;
	File? get backgroundImage => _backgroundImage;
	Future<void> _loadBackgroundImage() async {
		final dir = await getApplicationSupportDirectory();
		final savedFile = File(dir.path + pathDivider + 'background_img');
		if (savedFile.existsSync()) {
			_backgroundImage = savedFile;
		}
	}
	Future<void> setBackgroundImage() async {
		final file = await FilePicker.pickFile(
			type: FileType.image,
		);

		if (file != null && file.path != null) {
			await resetBackgroundImage();
			PaintingBinding.instance.imageCache.clear();
			PaintingBinding.instance.imageCache.clearLiveImages();

			final dir = await getApplicationSupportDirectory();
			final savedPath = dir.path + pathDivider + 'background_img';

			await File(file.path!).copy(savedPath);
			_backgroundImage = File(savedPath);

			notifyListeners();
		}
	}
	Future<void> resetBackgroundImage() async {
		await _backgroundImage?.delete();
		_backgroundImage = null;

		notifyListeners();
	}

	double _backgroundOpacity = 1.0;
	double get backgroundOpacity => _backgroundOpacity;
	Future<void> setBackgroundOpacity(double value) async {
		_backgroundOpacity = value;
		await Preferences.setDouble(BACKGROUND_OPACITY, value);

		notifyListeners();
	}


	String? _language;
	String? get language => _language;
	Future<void> setLanguage(String? value) async {
		_language = value;
		_locale = (value != null) ? Locale(value) : null;
		if (value != null)
			await Preferences.setString(LANGUAGE, value);
		else
			await Preferences.remove(LANGUAGE);

		notifyListeners();
	}

	Locale? _locale;
	Locale? get locale => _locale;
	void setLocale(Locale? value) {
		_locale = value;
	}


	double _editorFontSize = 14;
	double get editorFontSize => _editorFontSize;
	Future<void> setEditorFontSize(double value) async {
		_editorFontSize = value;
		await Preferences.setDouble(EDITOR_FONT_SIZE, value);

		notifyListeners();
	}


	String _editorFontFamily = 'CascadiaMono';
	String get editorFontFamily => _editorFontFamily;
	Future<void> setEditorFontFamily(String value) async {
		_editorFontFamily = value;
		await Preferences.setString(EDITOR_FONT_FAMILY, value);

		notifyListeners();
	}


	double _songFontSize = 14;
	double get songFontSize => _songFontSize;
	Future<void> setSongFontSize(double value) async {
		_songFontSize = value;
		await Preferences.setDouble(SONG_FONT_SIZE, value);

		notifyListeners();
	}


	String _songFontFamily = 'JetBrainsMono';
	String get songFontFamily => _songFontFamily;
	Future<void> setSongFontFamily(String value) async {
		_songFontFamily = value;
		await Preferences.setString(SONG_FONT_FAMILY, value);

		notifyListeners();
	}


	bool _sharpOnly = false;
	bool get sharpOnly => _sharpOnly;
	Future<void> setSharpOnly(bool value) async {
		_sharpOnly = value;
		await Preferences.setBool(SHARP_ONLY, value);
		rust_theory.setSharpOnly(isSharpOnly: value);

		notifyListeners();
	}


	bool _lineWrapInSong = true;
	bool get lineWrapInSong => _lineWrapInSong;
	Future<void> setLineWrapInSong(bool value) async {
		_lineWrapInSong = value;
		await Preferences.setBool(LINE_WRAP_IN_SONG, value);

		notifyListeners();
	}

	late String _libPath;
	String get libPath => _libPath;
	bool get libPathIsNull => Preferences.getString(LIB_PATH) == null;
	Future<void> setLibPath(String value) async {
		await rust_lib.moveLibrary(newDir: value);

		_libPath = value;
		await Preferences.setString(LIB_PATH, value);

		notifyListeners();
	}
	Future<void> resetLibPath() async {
		if (Platform.isAndroid) {
			final appDataDir = await getExternalStorageDirectory();
			final dataDir = appDataDir!.path + pathDivider + "songbook";
			await rust_lib.moveLibrary(newDir: dataDir);

			_libPath = dataDir;
		} else {
			final dataDir = rust_lib.getDefaultLibraryPath()! + pathDivider + "songbook";
			await rust_lib.moveLibrary(newDir: dataDir);

			_libPath = dataDir;
		}

		await Preferences.remove(LIB_PATH);


		notifyListeners();
	}


	SettingsProvider._create();
	static Future<SettingsProvider> create() async {
		final s = SettingsProvider._create();
		await s._loadAllSettings();
		return s;
	}

	Future<void> _loadAllSettings() async {
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
		_lineWrapInSong = Preferences.getBool(LINE_WRAP_IN_SONG) ?? true;
		_fingeringSizeInSong = Preferences.getString(FINGERING_SIZE_IN_SONG);
		_backgroundOpacity = Preferences.getDouble(BACKGROUND_OPACITY) ?? 1.0;

		_language = Preferences.getString(LANGUAGE);
		if (_language != null)
			_locale = Locale(_language!);


		// Checking is shapr_only env var preinstaled before starting app
		final sharpOnlyEnv = rust_theory.getSharpOnly();
		_sharpOnly = sharpOnlyEnv
			?? Preferences.getBool(SHARP_ONLY)
			?? false;
		// if it's preinstalled do not set var in env
		if (sharpOnlyEnv == null)
			rust_theory.setSharpOnly(isSharpOnly: _sharpOnly);


		final libPathEnv = rust_lib.getDataDirEnv();
		if (libPathEnv == null) {
			final libPathPrefs = Preferences.getString(LIB_PATH);
			if (libPathPrefs == null) {
				if (Platform.isAndroid) {
					_libPath = (await getExternalStorageDirectory())!.path + pathDivider + "songbook";
				} else {
					_libPath = rust_lib.getDefaultLibraryPath()! + pathDivider + "songbook";
				}
			} else {
				_libPath = libPathPrefs;
			}

			rust_lib.setDataDirEnv(dataDir: _libPath);
		} else {
			_libPath = libPathEnv;
		}


		await _loadBackgroundImage();
		await FontManager.load();


		notifyListeners();
	}


	Future<bool> exportBackup() async {
		final dir = await getApplicationSupportDirectory();
		final tempBackup = File(dir.path + pathDivider + 'backup.zip');
		final settings = _exportAllSettingsToMap();

		String? fontsPath;
		if (!FontManager.getCustom().isEmpty) {
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
		final outputPath = await FilePicker.saveFile(
			dialogTitle: 'Save backup as...',
			fileName: 'songbook_backup_$date.zip',
			bytes: await tempBackup.readAsBytes(),
		);

		await tempBackup.delete();
		if (outputPath == null)
			return false;

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


		return settings;
	}

	Future<bool> importBackup() async {
		final file = await FilePicker.pickFile(
			type: FileType.custom,
			allowedExtensions: ['zip'],
		);
		if (file == null || file.path == null)
			return false;

		final String backupPath = file.path!;

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


		_isDarkTheme = boolFromString(settings[IS_DARK_THEME]);
		if (_isDarkTheme != null)
			await Preferences.setBool(IS_DARK_THEME, _isDarkTheme!);
		else
			await Preferences.remove(IS_DARK_THEME);


		_isAmoled = boolFromString(settings[IS_AMOLED]) ?? false;
		await Preferences.setBool(IS_AMOLED, _isAmoled);
		

		_colorAccent = settings[COLOR_ACCENT] ?? 'blue';
		await Preferences.setString(COLOR_ACCENT, _colorAccent);


		_editorFontSize = doubleFromString(settings[EDITOR_FONT_SIZE]) ?? 14;
		await Preferences.setDouble(EDITOR_FONT_SIZE, _editorFontSize);

		_editorFontFamily = settings[EDITOR_FONT_FAMILY] ?? 'CascadiaMono';
		await Preferences.setString(EDITOR_FONT_FAMILY, _editorFontFamily);


		_songFontSize = doubleFromString(settings[SONG_FONT_SIZE]) ?? 14;
		await Preferences.setDouble(SONG_FONT_SIZE, _songFontSize);

		_songFontFamily = settings[SONG_FONT_FAMILY] ?? 'JetBrainsMono';
		await Preferences.setString(SONG_FONT_FAMILY, _songFontFamily);


		_sharpOnly = boolFromString(settings[SHARP_ONLY]) ?? true;
		await Preferences.setBool(SHARP_ONLY, _sharpOnly);


		_lineWrapInSong = boolFromString(settings[LINE_WRAP_IN_SONG]) ?? true;
		await Preferences.setBool(LINE_WRAP_IN_SONG, _lineWrapInSong);


		_fingeringSizeInSong = settings[FINGERING_SIZE_IN_SONG];
		if (_fingeringSizeInSong != null)
			await Preferences.setString(FINGERING_SIZE_IN_SONG, _fingeringSizeInSong!);
		else
			await Preferences.remove(FINGERING_SIZE_IN_SONG);


		_backgroundOpacity = doubleFromString(settings[BACKGROUND_OPACITY]) ?? 1.0;
		await Preferences.setDouble(BACKGROUND_OPACITY, _backgroundOpacity);


		_language = settings[LANGUAGE];
		if (_language != null) {
			_locale = Locale(_language!);
			await Preferences.setString(LANGUAGE, _language!);
		} else {
			await Preferences.remove(LANGUAGE);
		}


		notifyListeners();
	}


	Future<void> resetToDefault() async {
		await resetBackgroundImage();
		await resetLibPath();
		await FontManager.reset();
		await Preferences.clear();
		_loadAllSettings();
	}
	Future<void> resetLibrary() async {
		rust_lib.resetLibrary();
		Restart.restartApp();
	}
}

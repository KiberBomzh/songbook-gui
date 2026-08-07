import 'package:flutter/material.dart';
import 'package:songbook/services/preferences.dart';
import 'package:songbook/services/functions.dart';


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

	Color? get() => stringToColor(str);
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


		bold = boolFromString(settings[boldKey]) ?? defaultBold;
		await Preferences.setBool(boldKey, bold);


		italic = boolFromString(settings[italicKey]) ?? defaultItalic;
		await Preferences.setBool(italicKey, italic);

		await color.import(settings);
	}
}

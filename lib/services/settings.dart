import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


// keys
const String IS_DARK_THEME = 'is_dark_theme';
const String COLOR_ACCENT = 'color_accent';


class SettingsProvider extends ChangeNotifier {
	bool? _isDarkTheme;
	String _colorAccent = 'blue';

	bool? get isDarkTheme => _isDarkTheme;
	Color get colorAccent => _stringToColor(_colorAccent) ?? Colors.blue;

	SettingsProvider() {
		_loadAllSettings();
	}

	void _loadAllSettings() {
		_isDarkTheme = Preferences.getBool(IS_DARK_THEME);
		_colorAccent = Preferences.getString(COLOR_ACCENT) ?? _colorAccent;

		notifyListeners();
	}

	Future<void> setDarkTheme(bool? value) async {
		_isDarkTheme = value;
		if (value != null) {
			await Preferences.setBool(IS_DARK_THEME, value!);
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
	


	Future<void> resetToDefault() async {
		await Preferences.clear();
	}


	Color? _stringToColor(String colorStr) {
		if (colorStr.startsWith('0x')) {
			return Color(int.parse(colorStr, radix: 16));
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

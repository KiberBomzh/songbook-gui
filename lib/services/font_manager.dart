import 'dart:io';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import 'package:songbook/main.dart';


const List<String> FONT_FAMILIES = [
	'JetBrainsMono',
	'CascadiaMono',
	'VictorMono',
	'Lilex',
	'RobotoMono',
	'FiraCode',
	'PTMono',
];

class FontManager {
	static final Map<String, File> _customFonts = {};

	static List<String> getCustom() {
		return _customFonts.keys.toList();
	}

	static Future<void> addNew() async {
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

	static Future<void> remove(String fontFamily) async {
		final fontFile = _customFonts[fontFamily];
		if (fontFile != null) {
			if (fontFile.existsSync())
				await fontFile.delete();

			_customFonts.remove(fontFamily);
		}
	}

	static Future<void> reset() async {
		final dir = await getApplicationSupportDirectory();
		final fontsDir = Directory(dir.path + pathDivider + 'fonts');
		if (!fontsDir.existsSync())
			return;

		await fontsDir.delete(recursive: true);
		_customFonts.clear();
	}

	static Future<void> load() async {
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
	static Future<void> _loadFontFromFile(File fontFile) async {
		final fontFamily = fontFile.uri.pathSegments.last.replaceAll(RegExp(r'\.(ttf|otf)$'), '');
		final uniqueId = 'font_' + _customFonts.length.toString();

		final fontLoader = FontLoader(uniqueId);
		// ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
		fontLoader.loadFont(await fontFile.readAsBytes(), fontFamily);
		await fontLoader.load();

		_customFonts[fontFamily] = fontFile;
	}
}

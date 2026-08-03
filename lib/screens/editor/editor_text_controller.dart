import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:songbook/services/settings.dart';

import 'package:songbook/src/rust/api/song.dart';


class EditorTextController extends TextEditingController {
	late BuildContext context;
	late SettingsProvider _settings;

	bool isSourceMode;
	final Map<RegExp, TextStyle> _patterns = {};

	// Colors from Tomorrow Night
	final Map<String, Map<String, Color>> _editorTheme = {
		'night': {
			'blue': Color(0xff81a2be),
			'cyan': Color(0xff7eada7),
			'purple': Color(0xffb294bb),
			'yellow': Color(0xfff0c674),
			'orange': Color(0xffde935f),
			'red': Color(0xffcc6666),
		},
		'day': {
			'blue': Color(0xff0070c1),
			'cyan': Color(0xff1e797f),
			'purple': Color(0xff7929c8),
			'yellow': Color(0xff7c5c20),
			'orange': Color(0xffdf5926),
			'red': Color(0xffa31515),
		},
	};

	late String _brightness;
	final String _rawKey = 'blue';
	final String _rawStartEndPrimary = 'red';
	final String _rawStartEndSecondary = 'purple';
  

	EditorTextController({
		required this.isSourceMode,
		super.text,
	});


	void _setPatterns() {
		if (Theme.of(context).brightness == Brightness.dark)
			_brightness = 'night';
		else
			_brightness = 'day';


		_patterns.clear();
		if (isSourceMode)
			_setYamlPatterns();
		else
			_setRawPatterns();
	}

	void _setYamlPatterns() {
		// Ключи (слова перед двоеточием)
		_patterns[RegExp(r'(?<=^[ \t]*(?:- )?)[\w\-\.]+(?=\s*:)', multiLine: true)] =
		TextStyle(
			color: _editorTheme[_brightness]?['blue'],
			fontWeight: FontWeight.bold,
		);

		// Числовые значения
		_patterns[RegExp(r'(?<![a-zA-Z0-9_#])\d+\.?\d*(?![a-zA-Z0-9_])')] = TextStyle(
			color: _editorTheme[_brightness]?['orange'],
		);

		// Булевы значения и null
		_patterns[RegExp(r'\b(true|false|yes|no|on|off|null|~)\b', caseSensitive: true)] =
		TextStyle(
			color: _editorTheme[_brightness]?['orange'],
			fontWeight: FontWeight.bold,
		);

		// Списки (элементы с дефисом)
		_patterns[RegExp(r'^(\s*)-\s', multiLine: true)] = TextStyle(
			color: _editorTheme[_brightness]?['red'],
			fontWeight: FontWeight.bold,
		);

		// Теги YAML
		_patterns[RegExp(r'![\w]+')] = TextStyle(
			color: _editorTheme[_brightness]?['yellow'],
			fontWeight: FontWeight.bold,
		);
	}

	void _setRawPatterns() {
		final notesColor = Colors.grey;
		final chordsColor = _settings.chordsColor(context);
		final rhythmColor = _settings.rhythmColor(context);
		final textColor = _settings.textColor(context);

		final keywordOpacity = 0.5;
		final theme = _editorTheme[_brightness];
		final keyColor = theme?[_rawKey];
		final secondary = theme?[_rawStartEndSecondary];



		_setMetadataPatterns();
		
		_addBlockPattern(blockStart(), blockEnd(), theme?[_rawStartEndPrimary]);
		_addKeyValuePattern(titleSymbol(), keyColor);
		_addKeyValuePattern(blockNoteSymbol(), keyColor);
		_addKeyValuePattern(chordsLineSymbol(), keyColor);
		_addKeyValuePattern(noteLineSymbol(), keyColor);

		_addBlockPattern(plainTextStart(), plainTextEnd(), secondary);
		_addInBlockPattern(
			plainTextStart(),
			plainTextEnd(),
			TextStyle(fontStyle: .italic, fontWeight: .bold)
		);

		_addBlockPattern(tabStartSymbol(), tabEndSymbol(), secondary);
		_addInBlockPattern(
			tabStartSymbol(),
			tabEndSymbol(),
			TextStyle(fontWeight: .bold),
		);

		_addBlockPattern(songNoteStartSymbol(), songNoteEndSymbol(), secondary);
		_addInBlockPattern(
			songNoteStartSymbol(),
			songNoteEndSymbol(),
			TextStyle(
				color: notesColor,
				fontStyle: .italic,
			),
		);


		_patterns[RegExp(
			'^' + RegExp.escape(emptyLineSymbol()) + '\$',
			multiLine: true,
		)] = TextStyle(color: notesColor);


		_addBlockPattern(rowStart(), rowEnd(), secondary);

		_patterns[RegExp(
			'^' + RegExp.escape(chordsSymbol()),
			multiLine: true,
		)] = TextStyle(color: chordsColor.withValues(alpha: keywordOpacity), fontWeight: .bold);
		_patterns[RegExp(
			'(?<=' + RegExp.escape(chordsSymbol()) + ')s*.+',
		)] = TextStyle(color: chordsColor);

		_patterns[RegExp(
			'^' + RegExp.escape(rhythmSymbol()),
			multiLine: true,
		)] = TextStyle(color: rhythmColor.withValues(alpha: keywordOpacity), fontWeight: .bold);
		_patterns[RegExp(
			'(?<=' + RegExp.escape(rhythmSymbol()) + ')s*.+',
		)] = TextStyle(color: rhythmColor);

		_patterns[RegExp(
			'^' + RegExp.escape(textSymbol()),
			multiLine: true,
		)] = TextStyle(color: textColor.withValues(alpha: keywordOpacity), fontWeight: .bold);
		_patterns[RegExp(
			'(?<=' + RegExp.escape(textSymbol()) + ')s*.+',
		)] = TextStyle(color: textColor);
	}
	void _setMetadataPatterns() {
		final metadataPrimaryColor = _editorTheme[_brightness]?['blue'];
		final metadataSecondaryColor = _editorTheme[_brightness]?['cyan'];


		_addBlockPattern(metadataStart(), metadataEnd(), _editorTheme[_brightness]?[_rawStartEndSecondary]);
		_addKeyValuePattern(songTitleSymbol(), metadataPrimaryColor);
		_addKeyValuePattern(songArtistSymbol(), metadataPrimaryColor);
		_addKeyValuePattern(songKeySymbol(), metadataSecondaryColor);
		_addKeyValuePattern(songCapoSymbol(), metadataSecondaryColor);
		_addKeyValuePattern(songAutoscrollSpeedSymbol(), metadataSecondaryColor);
		_addKeyValuePattern(songAutoscrollDelaySymbol(), metadataSecondaryColor);
		_addKeyValuePattern(songShowOptionsSymbol(), metadataSecondaryColor);
		_addKeyValuePattern(songTagsSymbol(), metadataSecondaryColor);
		_addBlockPattern(songFingeringsStart(), songFingeringsEnd(), _editorTheme[_brightness]?[_rawStartEndPrimary]);
	}
	void _addKeyValuePattern(String key, Color? color) {
		key = RegExp.escape(key);

		_patterns[RegExp('^' + key, multiLine: true)] = TextStyle(color: color);
		_patterns[RegExp('(?<=^$key).*.+', multiLine: true)] = TextStyle(fontStyle: .italic);
	}
	void _addBlockPattern(String start, String end, Color? color) {
		start = RegExp.escape(start);
		end = RegExp.escape(end);

		_patterns[RegExp('^$start|^$end', multiLine: true)] = TextStyle(color: color, fontWeight: .bold);
	}
	void _addInBlockPattern(String start, String end, TextStyle style) {
		start = RegExp.escape(start);
		end = RegExp.escape(end);

		_patterns[ 
			RegExp( '(?<=^$start\$).*?(?=^$end\$)',
				multiLine: true,
				dotAll: true,
			)
		] = style;
	}
  
  
	@override
	TextSpan buildTextSpan({
		required BuildContext context,
		TextStyle? style,
		required bool withComposing,
	}) {
		this.context = context;
		_settings = context.watch<SettingsProvider>();
		_setPatterns();


		if (text.isEmpty || _patterns.isEmpty) {
			return TextSpan(text: text, style: style);
		}
    
		final matches = <_HighlightMatch>[];
    
		for (final entry in _patterns.entries) {
			final pattern = entry.key;
			final textStyle = entry.value;
      
			for (final match in pattern.allMatches(text)) {
				if (match.group(0)!.isNotEmpty) {
					matches.add(_HighlightMatch(
						start: match.start,
						end: match.end,
						style: textStyle,
					));
				}
			}
		}
    
		if (matches.isEmpty) {
			return TextSpan(text: text, style: style);
		}
    
		matches.sort((a, b) => a.start.compareTo(b.start));
		final filtered = <_HighlightMatch>[];
		var lastEnd = 0;
    
		for (final match in matches) {
			if (match.start >= lastEnd) {
				filtered.add(match);
				lastEnd = match.end;
			}
		}
    
		final spans = <TextSpan>[];
		var currentPos = 0;
    
		for (final match in filtered) {
			if (match.start > currentPos) {
				spans.add(TextSpan(
					text: text.substring(currentPos, match.start),
					style: style,
				));
			}
      
			spans.add(TextSpan(
				text: text.substring(match.start, match.end),
				style: style?.merge(match.style) ?? match.style,
			));
      
			currentPos = match.end;
		}
    
		if (currentPos < text.length) {
			spans.add(TextSpan(
				text: text.substring(currentPos),
				style: style,
			));
		}
    
		return TextSpan(children: spans);
	}
  
	@override
	void dispose() {
		_patterns.clear();
		super.dispose();
	}
}

class _HighlightMatch {
	final int start;
	final int end;
	final TextStyle style;
  
	_HighlightMatch({
		required this.start,
		required this.end,
		required this.style,
	});
}

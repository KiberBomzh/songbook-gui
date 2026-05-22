import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

import 'package:songbook/services/settings.dart';
import 'package:songbook/src/rust/api/song.dart';


enum EditorMode {
	source,
	raw
}


class EditorScreen extends StatefulWidget {
	SimpleSong? song;
	final String path;
	final EditorMode? mode;

	EditorScreen({
		super.key,
		required this.path,
		this.song,
		this.mode,
	});


	@override
	State<EditorScreen> createState() => _EditorState();
}

class _EditorState extends State<EditorScreen> {
	late SettingsProvider _settings;


	late EditorMode _currentMode;

	String? _rawText;
	String? _sourceText;


	List<String> _rawHistory = [];
	int _rawHistoryIndex = -1;

	List<String> _sourceHistory = [];
	int _sourceHistoryIndex = -1;

	// Позиция курсора
	TextSelection? _rawSelection;
	TextSelection? _sourceSelection;



	late CustomTextController _textController;
	bool _isSelection = false;

	late FocusNode _focusNode;

	List<String> _history = [];
	int _historyIndex = -1;
	Timer? _historyTimer;


	@override
	void initState() {
		super.initState();
		_currentMode = widget.mode ?? EditorMode.raw;
		_textController = CustomTextController(
			isSourceMode: _currentMode == EditorMode.source,
		);
		_loadText();

		_focusNode = FocusNode();
		_saveToHistory();
	}

	@override
	void dispose() {
		_textController.dispose();
		_focusNode.dispose();
		_historyTimer?.cancel();
		super.dispose();
	}

	Future<void> _loadText() async {
		if (_currentMode == EditorMode.source) {
			_textController.text = await File(widget.path).readAsString();
		} else {
			_textController.text = widget.song?.getForEditing() ?? '';
		};
	}

	void _updateSelection() => setState(
		() => _isSelection = _textController.selection.isCollapsed
	);

	void _save() async {
		if (_currentMode == EditorMode.source) {
			await File(widget.path).writeAsString(_textController.text);
			try {
				widget.song = SimpleSong.open(pathStr: widget.path);
			} catch (e) {
				widget.song = null;
				debugPrint(e.toString());
			}
			_rawText = null;
			_rawHistory = [];
			_rawHistoryIndex = -1;
			_rawSelection = null;
		} else {
			widget.song?.changeFromEdited(s: _textController.text);
			_sourceText = null;
			_sourceHistory = [];
			_sourceHistoryIndex = -1;
			_sourceSelection = null;
		}

		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(
				content: Text('Saved!'),
				duration: Duration(seconds: 1),
			),
		);
	}


	void _saveToHistory() {
		_historyTimer?.cancel();
		_historyTimer = Timer(const Duration(milliseconds: 250), () => setState(() {
			if (_historyIndex < _history.length - 1) {
				_history.removeRange(_historyIndex + 1, _history.length);
			}
			if (_history.length >= 50)
				_history.removeAt(0);

			_history.add(_textController.text);
			_historyIndex = _history.length - 1;
		}));
	}
	void _undo() {
		if (_historyIndex > 0) setState(() {
			_historyIndex--;
			_textController.text = _history[_historyIndex];
			_textController.selection = TextSelection.fromPosition(
				TextPosition(offset: _textController.text.length),
			);
		});
	}
	void _redo() {
		if (_historyIndex < _history.length - 1) setState(() {
			_historyIndex++;
			_textController.text = _history[_historyIndex];
			_textController.selection = TextSelection.fromPosition(
				TextPosition(offset: _textController.text.length),
			);
		});
	}

	void _insert(String text) {
		final selection = _textController.selection;
		if (selection.start == -1)
			return;

		final newText = _textController.text.replaceRange(
			selection.start,
			selection.end,
			text
		);
		_textController.value = TextEditingValue(
			text: newText,
			selection: TextSelection.collapsed(offset: selection.start + text.length),
		);
		_saveToHistory();
		_focusNode.requestFocus();
	}

	void _selectBlock() {
		_focusNode.requestFocus();

		final cursorPosition = _textController.selection.baseOffset;
		if (cursorPosition < 0)
			return;


		final text = _textController.text;
		final startMarker = blockStart();
		final endMarker = blockEnd();

		final startIndex = text.lastIndexOf(startMarker, cursorPosition);
		if (startIndex == -1)
			return;

		final endIndex = text.indexOf(endMarker, cursorPosition);
		if (endIndex == -1)
			return;


		_textController.selection = TextSelection(
			baseOffset: startIndex,
			extentOffset: endIndex + endMarker.length
		);
	}


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();

		return PopScope(
			canPop: !(_isSelection && _focusNode.hasFocus),
			onPopInvokedWithResult: (didPop, result) {
				final baseOffset = _textController.selection.baseOffset;
				_textController.selection = TextSelection(
					baseOffset: baseOffset,
					extentOffset: baseOffset,
				);
				setState(() => _isSelection = false);
				_focusNode.unfocus();
			},
			child: Container(
				decoration: BoxDecoration(
					image: (_settings.backgroundImage != null)
						? DecorationImage(
							image: FileImage(_settings.backgroundImage!),
							fit: .cover,
						)
						: null,
				),
				child: Scaffold(
					body: Stack(
						children: [
							Align(
								alignment: .bottomCenter,
								child: Container(
									color: Colors.black,
									width: MediaQuery.of(context).size.width,
									height: MediaQuery.of(context).padding.bottom,
								),
							), // for safe area
							Padding(
								padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
								child: _buildBody(),
							),
						],
					),
				),
			),
		);
	}

	Widget _buildBody() {
		return Stack(
			children: [
				Column(
					children: [
						SizedBox( height: MediaQuery.of(context).padding.top), // top safe area
						Expanded(
							child: EditorField(
								controller: _textController,
								focusNode: _focusNode,
								onChanged: (_) => _saveToHistory(),
								onTap: _updateSelection,
							),
						),

						if (_currentMode == EditorMode.raw)
							SizedBox(height: 50),

						const SizedBox(height: 70),
					],
				),

				_buildBottomBar(),
			],
		);
	}

	Widget _buildBottomBar() {
		return Column(
			crossAxisAlignment: .start,
			mainAxisAlignment: .end,
			children: [
				Container(
					margin: const EdgeInsets.only(right: 10, bottom: 5),
					alignment: .centerRight,
					child: SegmentedButton<EditorMode>(
						style: SegmentedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.7),
						),
						segments: const <ButtonSegment<EditorMode>>[
							ButtonSegment(
								value: EditorMode.source,
								label: Text('Source'),
							),
							ButtonSegment(
								value: EditorMode.raw,
								label: Text('Raw'),
							),
						],
						selected: <EditorMode>{_currentMode},
						onSelectionChanged: (newSelection) => setState(() {
							switch (_currentMode) {
								case (EditorMode.source):
									if (widget.song == null) {
										try {
											widget.song = SimpleSong.open(pathStr: widget.path);
										} catch (e) {
											showDialog(
												context: context,
												builder: (context) => AlertDialog(
													title: const Text("Error whil opening song..."),
													content: SizedBox(
														height: MediaQuery.of(context).size.height * 0.8,
														child: SingleChildScrollView(
															child: Padding(
																padding: const .all(5),
																child: Text(e.toString()),
															),
														),
													),
													actions: [
														TextButton(
															child: Text("Ok"),
															onPressed: () => Navigator.of(context).pop(),
														),
													],
												),
											);
											return;
										}
									}

									_textController.isSourceMode = false;

									_sourceText = _textController.text;
									_sourceHistory = _history;
									_sourceHistoryIndex = _historyIndex;
									_sourceSelection = _textController.selection;
									_historyTimer?.cancel();

									_currentMode = newSelection.first;

									switch (newSelection.first) {
										case (EditorMode.raw):
											if (_rawText != null) {
												_textController.text = _rawText!;
											} else {
												_loadText();
											}

											_textController.selection = _rawSelection ?? TextSelection.collapsed(offset: 0);

											_history = _rawHistory;
											_historyIndex = _rawHistoryIndex;
											if (_historyIndex < 0)
												_saveToHistory();
											break;

										default:
											break;
									}
									break;

								case (EditorMode.raw):
									_rawText = _textController.text;
									_rawHistory = _history;
									_rawHistoryIndex = _historyIndex;
									_rawSelection = _textController.selection;
									_historyTimer?.cancel();

									_currentMode = newSelection.first;

									switch (newSelection.first) {
										case (EditorMode.source):
											if (_sourceText != null) {
												_textController.text = _sourceText!;
											} else {
												_loadText();
											}

											_textController.selection = _sourceSelection ?? TextSelection.collapsed(offset: 0);

											_history = _sourceHistory;
											_historyIndex = _sourceHistoryIndex;
											if (_historyIndex < 0)
												_saveToHistory();

											_textController.isSourceMode = true;
											break;

										default:
											break;
									}
									break;
							}
						}),
					),
				),

				if (_currentMode == EditorMode.raw)
					FastKeywordsLine(onTap: _insert),

				Container(
					height: 70,
					padding: const EdgeInsets.symmetric(horizontal: 20),
					decoration: BoxDecoration(
						color: Theme.of(context).colorScheme.surfaceVariant,
						borderRadius: .vertical(top: Radius.circular(10)),
					),
					child: Row(
						mainAxisAlignment: .end,
						children: [
							BackButton(),
							Spacer(),

							IconButton(
								icon: Icon(Icons.save),
								tooltip: 'Save',
								onPressed: _save,
							),

							IconButton(
								icon: Icon(Icons.help),
								tooltip: 'Help',
								onPressed: _showHelp,
							),

							if (_currentMode == EditorMode.raw)
								IconButton(
									icon: Icon(Icons.article),
									tooltip: 'Select block',
									onPressed: _selectBlock,
								),

							IconButton(
								icon: Icon(Icons.undo),
								tooltip: 'Undo',
								onPressed: _undo,
								color: (_historyIndex > 0)
									? Theme.of(context).colorScheme.primary
									: Colors.grey,
							),
							IconButton(
								icon: Icon(Icons.redo),
								tooltip: 'Redo',
								onPressed: _redo,
								color: (_historyIndex < _history.length - 1)
									? Theme.of(context).colorScheme.primary
									: Colors.grey,
							),
						]
					),
				),
			]
		);
	}


	void _showHelp() {
		showDialog(
			context: context,
			builder: (context) => SimpleDialog(
				title: Center( child: Text('Help') ),
				contentPadding: const EdgeInsets.all(10),
				children: [
					Text(getEditorHelpMsg()),
				],
			),
		);
	}
}

class EditorField extends StatefulWidget {
	final TextEditingController controller;
	final FocusNode focusNode;
	final Function(String) onChanged;
	final VoidCallback onTap;

	EditorField({
		super.key,
		required this.controller,
		required this.focusNode,
		required this.onChanged,
		required this.onTap,
	});


	@override
	State<EditorField> createState() => EditorFieldState();
}
class EditorFieldState extends State<EditorField> {
	late SettingsProvider _settings;


	List<String> _lineNumbers = [];

	late final LinkedScrollControllerGroup _controllers;
	late final ScrollController _textFieldScrollController;
	late final ScrollController _lineNumbersScrollController;

	@override
	void initState() {
		super.initState();
		_updateLineNumbers();
		widget.controller.addListener(_updateLineNumbers);

		_controllers = LinkedScrollControllerGroup();
		_textFieldScrollController = _controllers.addAndGet();
		_lineNumbersScrollController = _controllers.addAndGet();
	}

	@override
	void dispose() {
		widget.controller.removeListener(_updateLineNumbers);

		_textFieldScrollController.dispose();
		_lineNumbersScrollController.dispose();
		super.dispose();
	}

	void _updateLineNumbers() {
		final lineCount = '\n'.allMatches(widget.controller.text).length + 1;
		setState(() => _lineNumbers = List.generate(lineCount, (index) => '${index + 1}'));
	}

	double _calculateLineNumbersWidth() {
		final textPainter = TextPainter(
			text: TextSpan(
				text: _lineNumbers[_lineNumbers.length - 1],
				style: _settings.editorStyle()
			),
			textDirection: .ltr
		)..layout();
		return textPainter.width + 15;
	}
	double _calculateLineHeight() {
		final textPainter = TextPainter(
			text: TextSpan(
				text: _lineNumbers[0],
				style: _settings.editorStyle()
			),
			textDirection: .ltr
		)..layout();
		return textPainter.height;
	}


	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();
		final lineHeight = _calculateLineHeight();
		final lineNumbersWidth = _calculateLineNumbersWidth();

		return Row(
			mainAxisAlignment: .start,
			children: [
				Container(
					width: lineNumbersWidth,
					padding: const .symmetric(horizontal: 5),
					child: ScrollConfiguration(
						behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
						child: SingleChildScrollView(
							controller: _lineNumbersScrollController,
							child: Column(
								children: _lineNumbers.map((n) => Text(n,
									maxLines: 1,
									style: _settings.editorStyle()
										.copyWith(color: Colors.grey, fontWeight: .bold),
								)).toList(),
							),
						),
					),
				),

				Expanded(
					child: SingleChildScrollView(
						scrollDirection: Axis.horizontal,
						child: ConstrainedBox(
							constraints: BoxConstraints(
								minWidth: MediaQuery.of(context).size.width - lineNumbersWidth - 10,
							),
							child: IntrinsicWidth(
								child: TextField(
									controller: widget.controller,
									scrollController: _textFieldScrollController,
									focusNode: widget.focusNode,
									maxLines: null,
									expands: true,
									selectionWidthStyle: .tight,
									style: _settings.editorStyle(),
									decoration: const InputDecoration(
										border: InputBorder.none,
										contentPadding: .all(0),
									),
									onTap: widget.onTap,
									onChanged: widget.onChanged,
								),
							),
						),
					),
				),
				const SizedBox(width: 10),
			],
		);
	}
}

class FastKeywordsLine extends StatefulWidget {
	final Function(String) onTap;

	FastKeywordsLine({
		super.key,
		required this.onTap,
	});

	@override
	State<FastKeywordsLine> createState() => FastLineState();
}

class FastLineState extends State<FastKeywordsLine> {
	late ScrollController _controller;

	@override
	void initState() {
		super.initState();
		_controller = ScrollController();
	}

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Container(
			alignment: .centerRight,
			margin: const .symmetric(horizontal: 10),
			child: Scrollbar(
				controller: _controller,
				interactive: true,
				thickness: 5.0,
				radius: const .circular(8),
				child: SingleChildScrollView(
					scrollDirection: .horizontal,
					controller: _controller,
					child: Padding(
						padding: const .only(bottom: 10),
						child: Row(
							spacing: 5,
							children: getEditorKeywords().map((k) {
								return FilterChip(
									label: Text(k),
									onSelected: (_) => widget.onTap(k),
								);
							}).toList(),
						),
					),
				),
			),
		);
	}
}

class CustomTextController extends TextEditingController {
	late SettingsProvider _settings;

	Highlighter? _highlighter;
	bool isSourceMode;

	final Map<RegExp, TextStyle> _patterns = {};
  

	CustomTextController({
		required this.isSourceMode,
		String? text,
	}) : super(text: text) {
		_initHighlighter();
	}

	Future<void> _initHighlighter() async {
		final language = 'yaml';
		await Highlighter.initialize([language]);
		final theme = await HighlighterTheme.loadDarkTheme();
		_highlighter = Highlighter(
			language: language,
			theme: theme,
		);

		notifyListeners();
	}

	void _setPatterns(BuildContext context) {
		_patterns.clear();
		_setMetadataPatterns();
		
		final blockColor = Colors.orange;

		_addBlockPattern(blockStart(), blockEnd(), blockColor);
		_addKeyValuePattern(titleSymbol(), _settings.titleColor(context));
		_addKeyValuePattern(blockNoteSymbol(), _settings.notesColor(context));
		_addKeyValuePattern(chordsLineSymbol(), _settings.chordsColor(context));

		_addBlockPattern(plainTextStart(), plainTextEnd(), Colors.green);
		_addInBlockPattern(
			plainTextStart(),
			plainTextEnd(),
			TextStyle(fontStyle: .italic, fontWeight: .bold)
		);

		_addBlockPattern(tabStartSymbol(), tabEndSymbol(), Colors.purpleAccent);
		_addInBlockPattern(
			tabStartSymbol(),
			tabEndSymbol(),
			TextStyle(fontWeight: .bold),
		);

		_addBlockPattern(songNoteStartSymbol(), songNoteEndSymbol(), _settings.notesColor(context));
		_addInBlockPattern(
			songNoteStartSymbol(),
			songNoteEndSymbol(),
			TextStyle(
				color: _settings.notesColor(context),
				fontStyle: .italic,
			),
		);


		_patterns[RegExp(
			'^' + RegExp.escape(emptyLineSymbol()) + '\$',
			multiLine: true,
		)] = TextStyle(color: Colors.grey);


		final chordsColor = _settings.chordsColor(context);
		final rhythmColor = _settings.rhythmColor(context);
		final textColor = _settings.textColor(context);

		_patterns[RegExp(
			'^' + RegExp.escape(chordsSymbol()),
			multiLine: true,
		)] = TextStyle(color: chordsColor, fontWeight: .bold);

		_patterns[RegExp(
			'^' + RegExp.escape(rhythmSymbol()),
			multiLine: true,
		)] = TextStyle(color: rhythmColor, fontWeight: .bold);

		_patterns[RegExp(
			'^' + RegExp.escape(textSymbol()),
			multiLine: true,
		)] = TextStyle(color: textColor, fontWeight: .bold);
	}
	void _setMetadataPatterns() {
		final metadataPrimaryColor = Colors.blue;
		final metadataSecondaryColor = Colors.cyan;
		final metadataBlockColor = Colors.limeAccent;


		_addBlockPattern(metadataStart(), metadataEnd(), metadataBlockColor);
		_addKeyValuePattern(songTitleSymbol(), metadataPrimaryColor);
		_addKeyValuePattern(songArtistSymbol(), metadataPrimaryColor);
		_addKeyValuePattern(songKeySymbol(), metadataSecondaryColor);
		_addKeyValuePattern(songCapoSymbol(), metadataSecondaryColor);
		_addKeyValuePattern(songAutoscrollSpeedSymbol(), metadataSecondaryColor);
		_addKeyValuePattern(songShowOptionsSymbol(), metadataSecondaryColor);
	}
	void _addKeyValuePattern(String key, Color color) {
		key = RegExp.escape(key);

		_patterns[RegExp('^' + key, multiLine: true)] = TextStyle(color: color);
		_patterns[RegExp('(?<=^${key}).*.+', multiLine: true)] = TextStyle(fontStyle: .italic);
	}
	void _addBlockPattern(String start, String end, Color color) {
		start = RegExp.escape(start);
		end = RegExp.escape(end);

		_patterns[RegExp('^${start}|^${end}', multiLine: true)] = TextStyle(color: color, fontWeight: .bold);
	}
	void _addInBlockPattern(String start, String end, TextStyle style) {
		start = RegExp.escape(start);
		end = RegExp.escape(end);

		_patterns[ 
			RegExp( '(?<=^${start}\n).*?(?=^${end}\$)',
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
		_settings = context.watch<SettingsProvider>();
		_setPatterns(context);


		if (isSourceMode && _highlighter != null && !text.isEmpty) {
			final highlighted = _highlighter!.highlight(text);
			if (style != null) {
				return TextSpan(
					style: style,
					children: highlighted.children,
				);
			}

			return highlighted;
		}

		if (text.isEmpty || _patterns.isEmpty || isSourceMode) {
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

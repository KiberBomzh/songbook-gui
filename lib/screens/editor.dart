import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';

import 'package:songbook/services/settings.dart';
import 'package:songbook/src/rust/api/song.dart';


enum EditorMode {
	source,
	raw,
	normal
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


	final GlobalKey<SongEditorState> _graphicalEditorKey = GlobalKey<SongEditorState>();
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
		_currentMode = widget.mode ?? EditorMode.normal;
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
			if (_currentMode == EditorMode.normal)
				await _graphicalEditorKey.currentState?.writeInMainTextController();
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
							child: (_currentMode == EditorMode.normal)
								? GraphicalSongEditor(
									key: _graphicalEditorKey,
									mainTextController: _textController,
								)
								: EditorField(
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
							ButtonSegment(
								value: EditorMode.normal,
								label: Text('Normal'),
							),
						],
						selected: <EditorMode>{_currentMode},
						onSelectionChanged: (newSelection) async {
							if (_currentMode == EditorMode.source) {
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
							} else {
								if (_currentMode == EditorMode.normal)
									await _graphicalEditorKey.currentState?.writeInMainTextController();

								_currentMode = newSelection.first;
								if (newSelection.first == EditorMode.source) {
									_rawText = _textController.text;
									_rawHistory = _history;
									_rawHistoryIndex = _historyIndex;
									_rawSelection = _textController.selection;
									_historyTimer?.cancel();

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
								}
							}

							setState(() {});
						},
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


							if (_currentMode == EditorMode.raw) ...[
								IconButton(
									icon: Icon(Icons.help),
									tooltip: 'Help',
									onPressed: _showHelp,
								),
								IconButton(
									icon: Icon(Icons.article),
									tooltip: 'Select block',
									onPressed: _selectBlock,
								),
							],

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
			crossAxisAlignment: .start,
			children: [
				Container(
					width: lineNumbersWidth,
					padding: const .symmetric(horizontal: 5),
					child: ScrollConfiguration(
						behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
						child: SingleChildScrollView(
							controller: _lineNumbersScrollController,
							child: Column(
								mainAxisAlignment: .start,
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
									onTapAlwaysCalled: true,
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
	late BuildContext context;

	bool isSourceMode;
	final Map<RegExp, TextStyle> _patterns = {};
  

	CustomTextController({
		required this.isSourceMode,
		String? text,
	}) : super(text: text);


	void _setPatterns() {
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
			color: Colors.blue,
			fontWeight: FontWeight.bold,
		);

		// Строковые значения в кавычках
		_patterns[RegExp('"[^"]*"|\'[^\']*\'')] = TextStyle(
			color: Colors.yellow,
		);

		// Числовые значения
		_patterns[RegExp(r'(?<![a-zA-Z0-9_#])\d+\.?\d*(?![a-zA-Z0-9_])')] = TextStyle(
			color: Colors.orange,
		);

		// Булевы значения и null
		_patterns[RegExp(r'\b(true|false|yes|no|on|off|null|~)\b', caseSensitive: true)] =
		TextStyle(
			color: Colors.orange,
			fontWeight: FontWeight.bold,
		);

		// Списки (элементы с дефисом)
		_patterns[RegExp(r'^(\s*)-\s', multiLine: true)] = TextStyle(
			color: Colors.redAccent,
			fontWeight: FontWeight.bold,
		);

		// Якоря и ссылки
		_patterns[RegExp(r'&[\w]+|\*[\w]+')] = TextStyle(
			color: Colors.teal,
			fontWeight: FontWeight.bold,
		);

		// Теги YAML
		_patterns[RegExp(r'![\w]+')] = TextStyle(
			color: Colors.pink,
			fontWeight: FontWeight.bold,
		);
	}

	_setRawPatterns() {
		final notesColor = Colors.grey;
		final chordsColor = Colors.lime;
		final rhythmColor = Colors.orange;
		final textColor = Theme.of(context).colorScheme.onSurface;

		final keywordOpacity = 0.5;



		_setMetadataPatterns();
		
		_addBlockPattern(blockStart(), blockEnd(), Colors.indigoAccent);
		_addKeyValuePattern(titleSymbol(), Colors.lightGreen);
		_addKeyValuePattern(blockNoteSymbol(), notesColor);
		_addKeyValuePattern(chordsLineSymbol(), chordsColor);

		_addBlockPattern(plainTextStart(), plainTextEnd(), Colors.green);
		_addInBlockPattern(
			plainTextStart(),
			plainTextEnd(),
			TextStyle(fontStyle: .italic, fontWeight: .bold)
		);

		_addBlockPattern(tabStartSymbol(), tabEndSymbol(), Colors.lightBlue);
		_addInBlockPattern(
			tabStartSymbol(),
			tabEndSymbol(),
			TextStyle(fontWeight: .bold),
		);

		_addBlockPattern(songNoteStartSymbol(), songNoteEndSymbol(), notesColor);
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


		_addBlockPattern(rowStart(), rowEnd(), Colors.yellow);

		_patterns[RegExp(
			'^' + RegExp.escape(chordsSymbol()),
			multiLine: true,
		)] = TextStyle(color: chordsColor.withOpacity(keywordOpacity), fontWeight: .bold);
		_patterns[RegExp(
			'(?<=' + RegExp.escape(chordsSymbol()) + ')\s*.+',
		)] = TextStyle(color: chordsColor);

		_patterns[RegExp(
			'^' + RegExp.escape(rhythmSymbol()),
			multiLine: true,
		)] = TextStyle(color: rhythmColor.withOpacity(keywordOpacity), fontWeight: .bold);
		_patterns[RegExp(
			'(?<=' + RegExp.escape(rhythmSymbol()) + ')\s*.+',
		)] = TextStyle(color: rhythmColor);

		_patterns[RegExp(
			'^' + RegExp.escape(textSymbol()),
			multiLine: true,
		)] = TextStyle(color: textColor.withOpacity(keywordOpacity), fontWeight: .bold);
		_patterns[RegExp(
			'(?<=' + RegExp.escape(textSymbol()) + ')\s*.+',
		)] = TextStyle(color: textColor);
	}
	void _setMetadataPatterns() {
		final metadataPrimaryColor = Colors.blue;
		final metadataSecondaryColor = Colors.cyan;
		final metadataBlockColor = Colors.indigoAccent;


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
			RegExp( '(?<=^${start}\$).*?(?=^${end}\$)',
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


class GraphicalSongEditor extends StatefulWidget {
	final CustomTextController mainTextController;

	GraphicalSongEditor({
		super.key,
		required this.mainTextController,
	});


	@override
	State<GraphicalSongEditor> createState() => SongEditorState();
}
class SongEditorState extends State<GraphicalSongEditor> {
	late Metadata _metadata;
	String songNote = '';
	List<DragAndDropList> _contents = [];

	@override
	initState() {
		super.initState();
		readFromMainTextController();

	}

	void readFromMainTextController() {
		_metadata = Metadata.from_string(widget.mainTextController.text);
		_parseBlocks();
	}
	void _parseBlocks() {
		String blockText = '';
		bool inBlock = false;
		bool inSongNote = false;
		for (final line in widget.mainTextController.text.split('\n')) {
			if (inBlock) {
				if (line.startsWith(blockEnd())) {
					inBlock = false;
					final (block, lines) = Block.from_string(
						blockText,
						'block_${_contents.length + 1}',
						_contents.length,
						_deleteBlock,
						_addNewBlockAfter,
						_deleteLine,
					);
					_contents.add(
						_buildDragAndDropList(
							block: block,
							lines: lines.map((line) => DragAndDropItem(child: line)).toList(),
						),
					);
					blockText = '';
				} else {
					blockText += line + '\n';
				}
			} else if (inSongNote) {
				if (line.startsWith(songNoteEndSymbol())) {
					inSongNote = false;
				} else {
					songNote += line + '\n';
				}
			} else {
				if (line.startsWith(songNoteStartSymbol())) {
					inSongNote = true;
				} else if (line.startsWith(blockStart())) {
					inBlock = true;
				}
			}
		}
	}
	DragAndDropList _buildDragAndDropList({
		required Block block,
		List<DragAndDropItem>? lines,
	}) => DragAndDropList(
		header: block,
		children: lines ?? [],
		leftSide: const SizedBox(width: 20),
		rightSide: const SizedBox(width: 20),
	);

	Future<void> writeInMainTextController() async {
		String text = '';

		text += _metadata.to_string();
		if (songNote.isNotEmpty) {
			text += songNoteStartSymbol() + '\n';
			text += songNote;
			if (!text.endsWith('\n'))
				text += '\n';
			text += songNoteEndSymbol() + '\n\n';
		}

		for (final list in _contents) {
			final Block block = list.header! as Block;
			final lines = list.children.map((item) => item.child as Line).toList();
			text += block.to_string(lines);
		}

		widget.mainTextController.text = text;
	}

	void _deleteBlock(int index) => setState(() {
		_contents.removeAt(index);
		_updateBlocksIndexesAfter(index);
	});
	void _deleteLine(int index, int parentIndex) => setState(() {
		_contents[parentIndex].children.removeAt(index);
		_updateLinesIndexesAfter(index, parentIndex);
	});

	void _addNewBlockAfter(int index) => setState(() {
		final int newIndex = index + 1;
		final block = Block(
			key: Key('block_${_contents.length + 1}'),
			index: newIndex,
			onDelete: _deleteBlock,
			onAddNewBlock: _addNewBlockAfter,
		);
		_contents.insert(newIndex,
			_buildDragAndDropList(block: block),
		);

		_updateBlocksIndexesAfter(newIndex + 1);
	});


	void _updateBlocksIndexesAfter(int index) {
		for (int i = index; i < _contents.length; i++) {
			final block = _contents[i].header! as Block;
			final lines = _contents[i].children.map((item) => item.child as Line).toList();

			block.index = i;
			for (final line in lines) {
				line.parentIndex = i;
			}
		}
	}
	void _updateLinesIndexesAfter(int index, int parentIndex) {
		for (int i = index; i < _contents[parentIndex].children.length; i++) {
			final line = _contents[parentIndex].children[i].child as Line;
			line.index = i;
		}
	}

	void _updateAllBlocksIndexes() {
		for (int i = 0; i < _contents.length; i++) {
			final block = _contents[i].header! as Block;
			block.index = i;

			_updateAllLinesIndexesInBlock(i);
		}
	}
	void _updateAllLinesIndexesInBlock(int index) {
		for (int i = 0; i < _contents[index].children.length; i++) {
			final line = _contents[index].children[i].child as Line;
			line.index = i;
			line.parentIndex = index;
		}
	}


	@override
	Widget build(BuildContext context) {
		return DragAndDropLists(
			children: _contents,
			onItemReorder: _onItemReorder,
			onListReorder: _onListReorder,
			listDecoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainer,
				borderRadius: .circular(10),
			),
			listPadding: .all(10),
			itemDivider: const SizedBox(height: 10),
		);
	}

	_onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
		setState(() {
			var movedItem = _contents[oldListIndex].children.removeAt(oldItemIndex);
			_contents[newListIndex].children.insert(newItemIndex, movedItem);
			_updateAllLinesIndexesInBlock(newListIndex);
		});
	}

	_onListReorder(int oldListIndex, int newListIndex) {
		setState(() {
			var movedList = _contents.removeAt(oldListIndex);
			_contents.insert(newListIndex, movedList);
			_updateAllBlocksIndexes();
		});
	}
}

class Block extends StatefulWidget {
	String? title;
	String? note;

	int index;
	final Function(int) onDelete;
	final Function(int) onAddNewBlock;

	Block({
		super.key,
		this.title,
		this.note,
		required this.index,
		required this.onDelete,
		required this.onAddNewBlock,
	});

	static (Block, List<Line>) from_string(
		String text,
		String key_str,
		int index,
		Function(int) onDelete,
		Function(int) onAddNewBlock,
		Function(int, int) onDeleteChild,
	) {
		List<Line> lines = [];
		String plainText = '';
		String tab = '';
		String? title;
		String? note;

		String textBlockBuf = '';

		bool inPlainText = false;
		bool inTab = false;
		bool inTextBlock = false;
		for (final line in text.split('\n')) {
			if (line.startsWith(plainTextEnd())) {
				inPlainText = false;
				if (plainText.isNotEmpty) {
					lines.add(PlainText(
						text: plainText.trim(),
						key: Key('${key_str}-line${lines.length + 1}'),
						index: lines.length,
						parentIndex: index,
						onDelete: onDeleteChild,
					));
					plainText = '';
				}
			} else if (inPlainText) {
				plainText += line + '\n';
			} else if (line.startsWith(plainTextStart())) {
				inPlainText = true;

			} else if (line.startsWith(tabEndSymbol())) {
				inTab = false;
				if (tab.isNotEmpty) {
					lines.add(Tab(
						tab: tab.trim(),
						key: Key('${key_str}-line${lines.length + 1}'),
						index: lines.length,
						parentIndex: index,
						onDelete: onDeleteChild,
					));
					tab = '';
				}
			} else if (inTab) {
				tab += line + '\n';
			} else if (line.startsWith(tabStartSymbol())) {
				inTab = true;

			} else if (line.startsWith(rowEnd())) {
				inTextBlock = false;
				lines.add(TextBlock.from_string(
					textBlockBuf, 
					Key('${key_str}-line${lines.length + 1}'),
					lines.length,
					index,
					onDeleteChild,
				));
				textBlockBuf = '';
			} else if (inTextBlock) {
				textBlockBuf += line + '\n';
			} else if (line.startsWith(rowStart())) {
				inTextBlock = true;

			} else if (line.startsWith(chordsLineSymbol())) {
				final chords = _parseKeyValueLine(line);
				if (chords != null)
					lines.add(ChordsLine(
						chords: chords!,
						key: Key('${key_str}-line${lines.length + 1}'),
						index: lines.length,
						parentIndex: index,
						onDelete: onDeleteChild,
					));
			} else if (line.startsWith(emptyLineSymbol())) {
				lines.add(EmptyLine(
					key: Key('${key_str}-line${lines.length + 1}'),
					index: lines.length,
					parentIndex: index,
					onDelete: onDeleteChild,
				));

			} else if (line.startsWith(titleSymbol())) {
				title = _parseKeyValueLine(line);
			} else if (line.startsWith(blockNoteSymbol())) {
				note = _parseKeyValueLine(line);
			}
		}


		return ( Block(
			key: Key(key_str),
			title: title,
			note: note,
			index: index,
			onDelete: onDelete,
			onAddNewBlock: onAddNewBlock,
		), lines);
	}

	String to_string(List<Line> lines) {
		String result = '';

		result += blockStart() + '\n';

		if (title != null)
			result += titleSymbol() + title! + '\n';

		if (note != null)
			result += blockNoteSymbol() + note! + '\n';
		
		for (final line in lines) {
			result += line.to_string() + '\n';
		}
		result = result.trim() + '\n';

		result += blockEnd() + '\n\n';


		return result;
	}

	@override
	State<Block> createState() => BlockState();
}
class BlockState extends State<Block> {
	late SettingsProvider _settings;

	late final TextEditingController _titleController;
	late final TextEditingController _noteController;

	@override
	void initState() {
		super.initState();
		_titleController = TextEditingController(text: widget.title);
		_noteController = TextEditingController(text: widget.note);
	}

	@override
	void dispose() {
		_titleController.dispose();
		_noteController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();

		return Padding(
			padding: const .all(10),
			child: Column(
				crossAxisAlignment: .start,
				children: [
					Align(
						alignment: .centerRight,
						child: MenuButton(
							label: 'Block',
							options: { 
								'Delete': () => widget.onDelete(widget.index),
								'Add new Block': () => widget.onAddNewBlock(widget.index),
							},
						),
					),
					const SizedBox(height: 5),

					OneLineTextField(
						controller: _titleController,
						style: _settings.titleStyle(context),
						onChanged: (value) => widget.title = value,
						label: 'Title'
					),
					const SizedBox(height: 10),

					OneLineTextField(
						controller: _noteController,
						style: _settings.notesStyle(context),
						onChanged: (value) => widget.note = value,
						label: 'Note',
					),
					const SizedBox(height: 10),
				],
			),
		);
	}
}

sealed class Line extends StatefulWidget {
	int index;
	int parentIndex;
	final Function(int, int) onDelete;

	Line({
		super.key,
		required this.index,
		required this.parentIndex,
		required this.onDelete,
	});

	String to_string() => '';

	@override
	State<Line> createState() => LineState();
}
class LineState extends State<Line> {
	@override
	Widget build(BuildContext context) => Text('Base class Line');
}

class TextBlock extends Line {
	String? chords;
	String? rhythm;
	String? text;

	TextBlock({
		super.key,
		this.chords,
		this.rhythm,
		this.text,
		required super.index,
		required super.parentIndex,
		required super.onDelete,
	});

	static TextBlock from_string(
		String lines,
		Key key,
		int index,
		int parentIndex,
		Function(int, int) onDelete,
	) {
		String? chords;
		String? rhythm;
		String? text;
		
		for (final line in lines.split('\n')) {
			if (line.startsWith(chordsSymbol())) {
				chords = line.substring(chordsSymbol().length);
			} else if (line.startsWith(rhythmSymbol())) {
				rhythm = line.substring(rhythmSymbol().length);
			} else if (line.startsWith(textSymbol())) {
				text = line.substring(textSymbol().length);
			}
		}


		return TextBlock(
			key: key,
			chords: chords,
			rhythm: rhythm,
			text: text,
			index: index,
			parentIndex: parentIndex,
			onDelete: onDelete,
		);
	}

	String to_string() {
		String result = '';

		result += rowStart() + '\n';
		result += chordsSymbol() + (chords ?? '') + '\n';
		result += rhythmSymbol() + (rhythm ?? '') + '\n';
		result += textSymbol() + (text ?? '') + '\n';
		result += rowEnd() + '\n';

		return result;
	}


	@override
	State<TextBlock> createState() => TextBlockState();
}
class TextBlockState extends State<TextBlock> {
	late SettingsProvider _settings;
	late double _lineHeight;
	late double _charWidth;

	late final TextEditingController _chordsController;
	late final TextEditingController _rhythmController;
	late final TextEditingController _textController;

	late final ScrollController _scrollController;


	@override
	void initState() {
		super.initState();
		_chordsController = TextEditingController(text: widget.chords);
		_rhythmController = TextEditingController(text: widget.rhythm);
		_textController = TextEditingController(text: widget.text);
		_scrollController = ScrollController();
	}

	@override
	void dispose() {
		_chordsController.dispose();
		_rhythmController.dispose();
		_textController.dispose();
		_scrollController.dispose();
		super.dispose();
	}

	void _calculateCharSize() {
		final textPainter = TextPainter(
			text: TextSpan(text: 'W', style: _settings.textStyle(context)),
			textDirection: .ltr
		)..layout();
		_lineHeight = textPainter.height;
		_charWidth = textPainter.width;
	}


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();
		_calculateCharSize();


		return LineContainer(
			title: MenuButton(
				label: 'Row',
				options: { 'Delete': () => widget.onDelete(widget.index, widget.parentIndex) },
			),
			child: Row(
				children: [
					_buildLinesHelp(),
					Expanded(
						child: Scrollbar(
							controller: _scrollController,
							interactive: true,
							thickness: 5.0,
							radius: const .circular(8),
							child: SingleChildScrollView(
								controller: _scrollController,
								scrollDirection: .horizontal,
								child: _buildLines(),
							),
						),
					),
				],
			),
		);
	}

	Widget _buildLinesHelp() {
		final textStyle = _settings.textStyle(context);

		return Container(
			padding: const .only(right: 2),
			margin: const .only(right: 5),
			decoration: BoxDecoration(
				border: Border(
					right: BorderSide(
						width: 2,
						color: Theme.of(context).colorScheme.outline,
					),
				),
			),
			child: Column(
				mainAxisAlignment: .start,
				children: [
					SizedBox(
						height: _lineHeight,
						child: Text('C', style: textStyle),
					),

					SizedBox(
						height: _lineHeight,
						child: Text('R', style: textStyle),
					),

					SizedBox(
						height: _lineHeight,
						child: Text('T', style: textStyle),
					),

					const SizedBox(height: 10),
				],
			),
		);
	}

	Widget _buildLines() => Column(
		crossAxisAlignment: .start,
		mainAxisAlignment: .start,
		children: [
			IntrinsicWidth(
				child: SizedBox(
					height: _lineHeight,
					child: TextField(
						controller: _chordsController,
						style: _settings.chordsStyle(context),
						selectionWidthStyle: .tight,
						decoration: _buildInputDecoration(),
						onChanged: (value) => widget.chords = value,
					),
				),
			),

			IntrinsicWidth(
				child: SizedBox(
					height: _lineHeight,
					child: TextField(
						controller: _rhythmController,
						style: _settings.rhythmStyle(context),
						selectionWidthStyle: .tight,
						decoration: _buildInputDecoration(),
						onChanged: (value) => widget.rhythm = value,
					),
				),
			),

			IntrinsicWidth(
				child: SizedBox(
					height: _lineHeight,
					child: TextField(
						controller: _textController,
						style: _settings.textStyle(context),
						selectionWidthStyle: .tight,
						decoration: _buildInputDecoration(),
						onChanged: (value) => widget.text = value,
					),
				),
			),


			const SizedBox(height: 10),
		],
	);

	InputDecoration _buildInputDecoration() => InputDecoration(
		border: .none,
		contentPadding: .all(0),
		isCollapsed: true,
		constraints: BoxConstraints(
			minWidth: MediaQuery.of(context).size.width - 20 - 40 - 20 - 10 - _charWidth,
		),
	);
}

class ChordsLine extends Line {
	String chords;

	ChordsLine({
		super.key,
		required this.chords,
		required super.index,
		required super.parentIndex,
		required super.onDelete,
	});

	String to_string() {
		return chordsLineSymbol() + chords + '\n';
	}

	@override
	State<ChordsLine> createState() => ChordsLineState();
}
class ChordsLineState extends State<ChordsLine> {
	late SettingsProvider _settings;

	late final TextEditingController _controller;


	@override
	void initState() {
		super.initState();
		_controller = TextEditingController(text: widget.chords);
	}

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();

		return LineContainer(
			title: MenuButton(
				label: 'ChordsLine',
				options: { 'Delete': () => widget.onDelete(widget.index, widget.parentIndex) },
			),
			child: OneLineTextField(
				controller: _controller,
				style: _settings.chordsStyle(context),
				onChanged: (value) => widget.chords = value,
			),
		);
	}
}

class PlainText extends Line {
	String text;

	PlainText({
		super.key,
		required this.text,
		required super.index,
		required super.parentIndex,
		required super.onDelete,
	});

	String to_string() {
		String result = '';

		result += plainTextStart() + '\n';
		result += text;
		if (!text.endsWith('\n'))
			result += '\n';
		result += plainTextEnd() + '\n';

		return result;
	}

	@override
	State<PlainText> createState() => PlainTextState();
}
class PlainTextState extends State<PlainText> {
	late SettingsProvider _settings;
	late final TextEditingController _controller;

	@override
	void initState() {
		super.initState();
		_controller = TextEditingController(text: widget.text);
	}

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();

		return LineContainer(
			title: MenuButton(
				label: 'PlainText',
				options: { 'Delete': () => widget.onDelete(widget.index, widget.parentIndex) },
			),
			child: IntrinsicHeight(
				child: Padding(
					padding: const .only(bottom: 10),
					child: ManyLineTextField(
						controller: _controller,
						style: _settings.plainTextStyle(context),
						onChanged: (value) => widget.text = value,
					),
				),
			),
		);
	}
}

class Tab extends Line {
	String tab;

	Tab({
		super.key,
		required this.tab,
		required super.index,
		required super.parentIndex,
		required super.onDelete,
	});

	String to_string() {
		String result = '';

		result += tabStartSymbol() + '\n';
		result += tab;
		if (!tab.endsWith('\n'))
			result += '\n';
		result += tabEndSymbol() + '\n';

		return result;
	}

	@override
	State<Tab> createState() => TabState();
}
class TabState extends State<Tab> {
	late SettingsProvider _settings;
	late final TextEditingController _controller;
	late final ScrollController _scrollController;

	late double _lineHeight;
	late double _textFieldHeight;

	@override
	void initState() {
		super.initState();
		_controller = TextEditingController(text: widget.tab);
		_scrollController = ScrollController();
	}

	@override
	void dispose() {
		_controller.dispose();
		_scrollController.dispose();
		super.dispose();
	}

	void _calculateLineHeight() {
		final textPainter = TextPainter(
			text: TextSpan(text: 'I', style: _settings.tabStyle(context)),
			textDirection: .ltr
		)..layout();
		_lineHeight = textPainter.height;
	}

	void _calculateTextFieldHeight() {
		final lineCount = '\n'.allMatches(_controller.text).length + 1;
		setState(() => _textFieldHeight = (_lineHeight + (_lineHeight / 6)) * lineCount + 10);
	}

	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();
		_calculateLineHeight();
		_calculateTextFieldHeight();

		return LineContainer(
			title: MenuButton(
				label: 'Tab',
				options: { 'Delete': () => widget.onDelete(widget.index, widget.parentIndex) },
			),
			child: Scrollbar(
				controller: _scrollController,
				interactive: true,
				thickness: 5.0,
				radius: const .circular(8),
				child: SingleChildScrollView(
					controller: _scrollController,
					scrollDirection: .horizontal,
					child: IntrinsicWidth(
						child: SizedBox(
							height: _textFieldHeight,
							child: ManyLineTextField(
								controller: _controller,
								style: _settings.tabStyle(context),
								onChanged: (value) {
									widget.tab = value;
									setState(() {});
								},
							),
						),
					),
				),
			),
		);
	}
}

class EmptyLine extends Line {
	EmptyLine({
		super.key,
		required super.index,
		required super.parentIndex,
		required super.onDelete,
	});

	String to_string() {
		return emptyLineSymbol() + '\n';
	}

	@override
	State<EmptyLine> createState() => EmptyLineState();
}
class EmptyLineState extends State<EmptyLine> {
	@override
	Widget build(BuildContext context) {
		return LineContainer(
			title: MenuButton(
				label: 'EmptyLine',
				options: { 'Delete': () => widget.onDelete(widget.index, widget.parentIndex) },
			),
			child: Text(''),
		);
	}
}


class Metadata extends StatefulWidget {
	String title;
	String artist;
	String? Key;
	int? capo;
	int? autoscrollSpeed;
	ShowOptions showOptions;

	Metadata({
		super.key,
		required this.title,
		required this.artist,
		required this.showOptions,
		this.Key,
		this.capo,
		this.autoscrollSpeed,
	});

	static Metadata from_string(String text) {
		String title = '';
		String artist = '';
		String? key;
		int? capo;
		int? autoscrollSpeed;
		ShowOptions options = ShowOptions();

		bool inMetadata = false;
		for (final line in text.split('\n')) {
			if (inMetadata) {
				if ( line.startsWith(metadataEnd()) ) {
					break;
				} else if ( line.startsWith(songTitleSymbol()) ) {
					title = _parseKeyValueLine(line) ?? 'some title';
				} else if ( line.startsWith(songArtistSymbol()) ) {
					artist = _parseKeyValueLine(line) ?? 'some artist';
				} else if ( line.startsWith(songKeySymbol()) ) {
					key = _parseKeyValueLine(line);
				} else if ( line.startsWith(songCapoSymbol()) ) {
					final result = _parseKeyValueLine(line);
					if (result != null)
						capo = int.tryParse(result!);
				} else if ( line.startsWith(songAutoscrollSpeedSymbol()) ) {
					final result = _parseKeyValueLine(line);
					if (result != null)
						autoscrollSpeed = int.tryParse(result!);
				} else if ( line.startsWith(songShowOptionsSymbol()) ) {
					options.from_string(line);
				}
			} else {
				if ( line.startsWith(metadataStart()) )
					inMetadata = true;
			}
		}

		return Metadata(
			title: title,
			artist: artist,
			Key: key,
			capo: capo,
			autoscrollSpeed: autoscrollSpeed,
			showOptions: options
		);
	}

	String to_string() {
		String result = '';

		result += metadataStart() + '\n';

		result += songTitleSymbol() + title + '\n';
		result += songArtistSymbol() + artist + '\n';

		result += songKeySymbol();
		if (Key != null)
			result += Key.toString();
		result += '\n';

		result += songCapoSymbol();
		if (capo != null)
			result += capo.toString();
		result += '\n';

		result += songAutoscrollSpeedSymbol();
		if (autoscrollSpeed != null)
			result += autoscrollSpeed.toString();
		result += '\n';

		result += songShowOptionsSymbol() + showOptions.to_string() + '\n';

		result += metadataEnd() + '\n\n';


		return result;
	}


	@override
	State<Metadata> createState() => MetadataState();
}
class MetadataState extends State<Metadata> {
	@override
	Widget build(BuildContext context) {
		return Column(
			children: [
				Text(widget.title),
				Text(widget.artist),
				Text(widget.Key.toString()),
				Text(widget.capo.toString()),
				Text(widget.autoscrollSpeed.toString()),
				Text(widget.showOptions.to_string()),
			],
		);
	}
}
class ShowOptions {
	bool chords;
	bool rhythm;
	bool notes;
	bool fingerings;

	ShowOptions({
		this.chords = true,
		this.rhythm = true,
		this.notes = true,
		this.fingerings = false,
	});

	String to_string() {
		String result = '';

		if (chords)
			result += 'c ';

		if (rhythm)
			result += 'r ';

		if (notes)
			result += 'n ';

		if (fingerings)
			result += 'f ';

		return result;
	}

	void from_string(String line) {
		final result = _parseKeyValueLine(line);
		if (result == null)
			return;

		final opts = result!;
		this.chords = opts.contains('c');
		this.rhythm = opts.contains('r');
		this.notes = opts.contains('n');
		this.fingerings = opts.contains('f');
	}
}


String? _parseKeyValueLine(String line) {
	final i = line.indexOf(':');
	if (i == -1)
		return null;

	final result = line.substring(i + 1).trim();
	if (result.isEmpty)
		return null;
	else
		return result;
}

class LineContainer extends StatelessWidget {
	final Widget child;
	final Widget title;

	LineContainer({
		super.key,
		required this.child,
		required this.title,
	});


	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const .all(10),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceVariant,
				borderRadius: .circular(8),
			),
			child: Column(
				crossAxisAlignment: .start,
				children: [
					Align(
						alignment: .centerRight,
						child: title,
					),

					const SizedBox(height: 10),
					child,
				],
			),
		);
	}
}

class ManyLineTextField extends StatelessWidget {
	final TextEditingController controller;
	final TextStyle style;
	final Function(String) onChanged;

	ManyLineTextField({
		super.key,
		required this.controller,
		required this.style,
		required this.onChanged,
	});

	@override
	Widget build(BuildContext context) {
		return TextField(
			controller: controller,
			style: style,
			maxLines: null,
			expands: true,
			selectionWidthStyle: .tight,
			decoration: const InputDecoration(
				border: InputBorder.none,
				contentPadding: .all(0),
				isCollapsed: true,
			),
			onChanged: onChanged,
		);
	}
}
class OneLineTextField extends StatelessWidget {
	final TextEditingController controller;
	final TextStyle style;
	final Function(String) onChanged;
	final String? label;

	OneLineTextField({
		super.key,
		required this.controller,
		required this.style,
		required this.onChanged,
		this.label,
	});

	@override
	Widget build(BuildContext context) {
		return TextField(
			controller: controller,
			style: style,
			selectionWidthStyle: .tight,
			decoration: InputDecoration(
				border: OutlineInputBorder(
					borderRadius: .circular(8),
				),
				labelText: label,
			),
			onChanged: onChanged,
		);
	}
}

class MenuButton extends StatelessWidget {
	final String label;
	final Map<String, VoidCallback> options;

	MenuButton({
		super.key,
		required this.label,
		required this.options,
	});


	@override
	Widget build(BuildContext context) => MenuAnchor(
		animated: true,
		builder: (context, controller, child) => TextButton(
			child: Text(label),
			onPressed: () {
				if (controller.isOpen) {
					controller.close();
				} else {
					controller.open();
				}
			},
			style: TextButton.styleFrom(
				foregroundColor: Theme.of(context).colorScheme.onSurface,
			),
		),
		menuChildren: options.entries.map((entry) => MenuItemButton(
			child: Text(entry.key),
			onPressed: entry.value,
		)).toList(),
	);
}

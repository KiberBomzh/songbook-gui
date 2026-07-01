import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';

import 'package:songbook/services/settings.dart';
import 'package:songbook/src/rust/api/song.dart';
import 'package:songbook/l10n/app_localizations.dart';


enum EditorMode {
	source,
	raw,
	normal
}

class EditorScrollOffsets {
	double source = 0;
	double raw = 0;
	double normal = 0;

	void update(double offset, EditorMode mode) {
		switch (mode) {
			case (.source):
				source = offset;
				break;

			case (.raw):
				raw = offset;
				break;

			case (.normal):
				normal = offset;
				break;
		}
	}
}


class EditorScreen extends StatefulWidget {
	SimpleSong? song;
	final String path;
	final EditorMode? mode;
	final EditorScrollOffsets? initialScrollOffsets;
	final Function(EditorScrollOffsets)? onOffsetsChanged;

	EditorScreen({
		super.key,
		required this.path,
		this.song,
		this.mode,
		this.initialScrollOffsets,
		this.onOffsetsChanged,
	});


	@override
	State<EditorScreen> createState() => _EditorState();
}

class _EditorState extends State<EditorScreen> {
	late SettingsProvider _settings;


	final GlobalKey<SongEditorState> _graphicalEditorKey = GlobalKey<SongEditorState>();
	final GlobalKey<EditorFieldState> _editorKey = GlobalKey<EditorFieldState>();
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

	late final EditorScrollOffsets _scrollOffsets;
	Timer? _keyStateTimer;



	late CustomTextController _textController;

	late FocusNode _focusNode;
	bool _canPop = true;

	List<String> _history = [];
	int _historyIndex = -1;
	Timer? _historyTimer;


	@override
	void initState() {
		super.initState();
		_currentMode = widget.mode ?? EditorMode.normal;
		_scrollOffsets = widget.initialScrollOffsets ?? EditorScrollOffsets();
		_textController = CustomTextController(
			isSourceMode: _currentMode == EditorMode.source,
		);
		_loadText();

		_focusNode = FocusNode();
		_focusNode.addListener(_updateCanPop);
		_saveToHistory();
	}

	@override
	void dispose() {
		_textController.dispose();
		_focusNode.removeListener(_updateCanPop);
		_focusNode.dispose();
		_historyTimer?.cancel();
		super.dispose();
	}

	Future<void> _loadText() async {
		if (_currentMode == EditorMode.source) {
			_textController.text = await File(widget.path).readAsString();
		} else {
			_textController.text = widget.song?.getForEditing() ?? '';
		}
	}

	void _updateCanPop() {
		Timer(Duration(milliseconds: 200),
			() {
				if (mounted)
					setState(() => _canPop = !_focusNode.hasFocus);
				}
		);
	}

	void _updateScrollOffsets(double offset) {
		_scrollOffsets.update(offset, _currentMode);

		if (widget.onOffsetsChanged != null)
			widget.onOffsetsChanged!(_scrollOffsets);
	}
	void _updateScrollControllers() {
		switch (_currentMode) {
			case (.source):
				_editorKey.currentState?.setScrollOffset(_scrollOffsets.source);
				break;

			case (.raw):
				_editorKey.currentState?.setScrollOffset(_scrollOffsets.raw);
				break;

			case (.normal):
				_graphicalEditorKey.currentState?.setScrollOffset(_scrollOffsets.normal);
				break;
		}
	}

	void _startKeyStateTimer(GlobalKey<State<StatefulWidget>> key, VoidCallback action) =>
		_keyStateTimer = Timer.periodic(
			Duration(milliseconds: 100),
			(timer) {
				if (key.currentState == null)
					return;

				action();
				_stopKeyStateTimer();
			}
		);
	void _stopKeyStateTimer() {
		_keyStateTimer?.cancel();
		_keyStateTimer = null;
	}

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
				await _graphicalEditorKey.currentState?.writeInTextController();
			widget.song?.changeFromEdited(s: _textController.text);
			_sourceText = null;
			_sourceHistory = [];
			_sourceHistoryIndex = -1;
			_sourceSelection = null;
		}

		if (mounted)
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(AppLocalizations.of(context)!.editorSavedMsg),
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
			canPop: _canPop,
			onPopInvokedWithResult: (didPop, result) {
				setState(() => _canPop = true);
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
									controller: _textController,
									onScrollUpdate: _updateScrollOffsets,
									initialScrollOffset: _scrollOffsets.normal,
									focusNode: _focusNode,
								)
								: EditorField(
									key: _editorKey,
									controller: _textController,
									focusNode: _focusNode,
									onChanged: (_) => _saveToHistory(),
									onScrollUpdate: _updateScrollOffsets,
									initialScrollOffset: (_currentMode == .source)
										? _scrollOffsets.source
										: _scrollOffsets.raw,
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
							backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
						),
						segments: <ButtonSegment<EditorMode>>[
							ButtonSegment(
								value: EditorMode.source,
								label: Text(AppLocalizations.of(context)!.editorModeSource),
							),
							ButtonSegment(
								value: EditorMode.raw,
								label: Text(AppLocalizations.of(context)!.editorModeRaw),
							),
							ButtonSegment(
								value: EditorMode.normal,
								label: Text(AppLocalizations.of(context)!.editorModeNormal),
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
												title: Text(AppLocalizations.of(context)!.songErrorMsg),
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
														child: Text(AppLocalizations.of(context)!.ok),
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
								if (_currentMode == EditorMode.normal) {
									await _graphicalEditorKey.currentState?.writeInTextController();
									_startKeyStateTimer(_editorKey, _updateScrollControllers);
								}

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

							_updateScrollControllers();
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
						color: Theme.of(context).colorScheme.surfaceContainerHighest,
						borderRadius: .vertical(top: Radius.circular(10)),
					),
					child: Row(
						mainAxisAlignment: .end,
						children: [
							BackButton(),
							Spacer(),

							IconButton(
								icon: Icon(Icons.save),
								tooltip: AppLocalizations.of(context)!.editorTooltipSave,
								onPressed: _save,
							),


							if (_currentMode == EditorMode.raw) ...[
								IconButton(
									icon: Icon(Icons.help),
									tooltip: AppLocalizations.of(context)!.editorTooltipHelp,
									onPressed: _showHelp,
								),
								IconButton(
									icon: Icon(Icons.article),
									tooltip: AppLocalizations.of(context)!.editorTooltipSelectBlock,
									onPressed: _selectBlock,
								),
							],

							if (_currentMode == EditorMode.normal) ...[
								IconButton(
									icon: Icon(Icons.abc),
									tooltip: AppLocalizations.of(context)!.editorTooltipEditMetadata,
									onPressed: () => _graphicalEditorKey.currentState?.showMetadataEditor(),
								),
							] else ...[
								IconButton(
									icon: Icon(Icons.undo),
									tooltip: AppLocalizations.of(context)!.editorTooltipUndo,
									onPressed: _undo,
									color: (_historyIndex > 0)
										? Theme.of(context).colorScheme.primary
										: Colors.grey,
								),
								IconButton(
									icon: Icon(Icons.redo),
									tooltip: AppLocalizations.of(context)!.editorTooltipRedo,
									onPressed: _redo,
									color: (_historyIndex < _history.length - 1)
										? Theme.of(context).colorScheme.primary
										: Colors.grey,
								),
							],
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
				title: Center( child: Text(AppLocalizations.of(context)!.editorHelpDialogTitle) ),
				contentPadding: const EdgeInsets.all(10),
				children: [
					Text(getEditorHelpMsg(), style: _settings.editorStyle()),
				],
			),
		);
	}
}

class EditorField extends StatefulWidget {
	final TextEditingController controller;
	final FocusNode focusNode;
	final Function(String) onChanged;
	final Function(double) onScrollUpdate;
	final double initialScrollOffset;

	const EditorField({
		super.key,
		required this.controller,
		required this.focusNode,
		required this.onChanged,
		required this.onScrollUpdate,
		required this.initialScrollOffset,
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

	bool _isFirstBuild = true;

	@override
	void initState() {
		super.initState();
		_updateLineNumbers();
		widget.controller.addListener(_updateLineNumbers);

		_controllers = LinkedScrollControllerGroup();
		_textFieldScrollController = _controllers.addAndGet();
		_lineNumbersScrollController = _controllers.addAndGet();

		_controllers.addOffsetChangedListener(_updateScroll);
	}

	@override
	void dispose() {
		widget.controller.removeListener(_updateLineNumbers);

		_controllers.removeOffsetChangedListener(_updateScroll);
		_textFieldScrollController.dispose();
		_lineNumbersScrollController.dispose();
		super.dispose();
	}

	void setScrollOffset(double offset) => _controllers.jumpTo(offset);

	void _updateScroll() => widget.onScrollUpdate(_controllers.offset);

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


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();
		final lineNumbersWidth = _calculateLineNumbersWidth();
		if (_isFirstBuild && _textFieldScrollController.hasClients) {
			_controllers.jumpTo(widget.initialScrollOffset);
			_isFirstBuild = false;
		}

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

	const FastKeywordsLine({
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
  

	CustomTextController({
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
		_addKeyValuePattern(songShowOptionsSymbol(), metadataSecondaryColor);
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


class GraphicalSongEditor extends StatefulWidget {
	final CustomTextController controller;
	final Function(double) onScrollUpdate;
	final double initialScrollOffset;
	final FocusNode? focusNode;

	const GraphicalSongEditor({
		super.key,
		required this.controller,
		required this.onScrollUpdate,
		required this.initialScrollOffset,
		this.focusNode,
	});


	@override
	State<GraphicalSongEditor> createState() => SongEditorState();
}
class SongEditorState extends State<GraphicalSongEditor> {
	late SettingsProvider _settings;

	late Metadata _metadata;
	String songNote = '';
	final List<DragAndDropList> _contents = [];

	late final TextEditingController _songNoteController;


	late final ScrollController _scrollController;


	@override
	void initState() {
		super.initState();
		readFromTextController();

		_songNoteController = TextEditingController(text: songNote);
		_scrollController = ScrollController(initialScrollOffset: widget.initialScrollOffset);
		_scrollController.addListener(_updateScroll);
	}

	@override
	void dispose() {
		_songNoteController.dispose();
		_scrollController.removeListener(_updateScroll);
		_scrollController.dispose();

		_contents.clear();
		super.dispose();
	}

	void setScrollOffset(double offset) => _scrollController.jumpTo(offset);

	void readFromTextController() {
		_metadata = Metadata.from_string(widget.controller.text);
		_parseBlocks();
	}
	void _parseBlocks() {
		String blockText = '';
		bool inBlock = false;
		bool inSongNote = false;
		for (final line in widget.controller.text.split('\n')) {
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
						_addNewLineInBlockAfter,
						_copyBlockAfter,
						_copyLineInBlockAfter,
						_splitBlockBefore,
						_mergeBlockWithNext,
						_splitRow,
						_mergeRow,
						_convertPlainTextToRow,
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

	Future<void> writeInTextController() async {
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

		widget.controller.text = text;
	}

	void _updateScroll() => widget.onScrollUpdate(_scrollController.offset);

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
			key: UniqueKey(),
			index: newIndex,
			onDelete: _deleteBlock,
			onAddNewBlock: _addNewBlockAfter,
			onCopy: _addNewBlockAfter,
			onMergeBlock: _mergeBlockWithNext,
		);
		_contents.insert(newIndex,
			_buildDragAndDropList(block: block),
		);

		_updateBlocksIndexesAfter(newIndex + 1);
	});

	void _addNewLineInBlockAfter(int parentIndex, int index) async {
		final LineType? lineType = await showModalBottomSheet<LineType?>(
			isScrollControlled: true,
			context: context,
			builder: (context) => SelectLineTypeScreen(),
		);
		if (lineType == null)
			return;

		final newIndex = index + 1;
		final line = switch (lineType) {
			LineType.textBlock => TextBlock(
				key: UniqueKey(),
				index: newIndex,
				parentIndex: parentIndex,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
				onCopy: _copyLineInBlockAfter,
				onSplitRow: _splitRow,
				onMerge: _mergeRow,
			),
			LineType.chordsLine => ChordsLine(
				chords: '',
				key: UniqueKey(),
				index: newIndex,
				parentIndex: parentIndex,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onCopy: _copyLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
			),
			LineType.noteLine => NoteLine(
				text: '',
				key: UniqueKey(),
				index: newIndex,
				parentIndex: parentIndex,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onCopy: _copyLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
			),
			LineType.plainText => PlainText(
				text: '',
				key: UniqueKey(),
				index: newIndex,
				parentIndex: parentIndex,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onCopy: _copyLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
				onConvertToRow: _convertPlainTextToRow,
			),
			LineType.tab => Tab(
				tab: '',
				key: UniqueKey(),
				index: newIndex,
				parentIndex: parentIndex,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onCopy: _copyLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
			),
			LineType.emptyLine => EmptyLine(
				key: UniqueKey(),
				index: newIndex,
				parentIndex: parentIndex,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onCopy: _copyLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
			),
		};

		setState(() {
			_contents[parentIndex].children.insert(newIndex,
				DragAndDropItem(child: line),
			);

			_updateLinesIndexesAfter(newIndex, parentIndex);
		});
	}
	void _copyLineInBlockAfter(int parentIndex, int  index, Line line) {
		final newIndex = index + 1;
		setState(() {
			_contents[parentIndex].children.insert(newIndex,
				DragAndDropItem(
					child: line.copyWith(
						key: UniqueKey(),
						index: newIndex,
					)
				),
			);

			_updateLinesIndexesAfter(newIndex, parentIndex);
		});
	}
	void _copyBlockAfter(int index) {
		final item = _contents[index];
		final block = item.header! as Block;
		final lines = item.children.map((item) => item.child as Line).toList();

		final newIndex = index + 1;
		final newBlock = block.copyWith(
			key: UniqueKey(),
			index: newIndex,
		);
		final newLines = lines.map((line) {
			return DragAndDropItem(
				child: line.copyWith(
					key: UniqueKey(),
					parentIndex: newIndex,
				),
			);
		}).toList();

		final newItem = _buildDragAndDropList(
			block: newBlock,
			lines: newLines,
		);
		
		setState(() {
			_contents.insert(newIndex, newItem);
			_updateBlocksIndexesAfter(newIndex);
		});
	}

	void _splitBlockBefore(int blockIndex, int lineIndex) {
		final item = _contents.removeAt(blockIndex);

		final block = item.header! as Block;
		final List<DragAndDropItem> lines = item.children;

		final oldBlockLines = lines.sublist(0, lineIndex);
		final oldItem = _buildDragAndDropList(
			block: block,
			lines: oldBlockLines,
		);

		final newIndex = blockIndex + 1;
		final newBlockLines = lines.sublist(lineIndex);
		final newBlock = Block(
			key: UniqueKey(),
			index: newIndex,
			onDelete: _deleteBlock,
			onAddNewBlock: _addNewBlockAfter,
			onCopy: _addNewBlockAfter,
			onMergeBlock: _mergeBlockWithNext,
		);

		final newItem = _buildDragAndDropList(
			block: newBlock,
			lines: newBlockLines,
		);


		setState(() {
			_contents.insert(blockIndex, oldItem);
			_contents.insert(newIndex, newItem);

			_updateBlocksIndexesAfter(blockIndex);
			_updateAllLinesIndexesInBlock(blockIndex + 1);
		});
	}

	void _mergeBlockWithNext(int index) {
		if (index == _contents.length - 1) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(AppLocalizations.of(context)!.editorTheLastBlockMsg),
					duration: Duration(seconds: 1),
				),
			);


			return;
		}


		final nextItem = _contents.removeAt(index + 1);
		final item = _contents.removeAt(index);

		final block = item.header! as Block;
		final lines = item.children;
		final nextLines = nextItem.children;

		final newBlock = block.copyWith(key: UniqueKey());
		final newLines = [...lines, ...nextLines];

		final newItem = _buildDragAndDropList(
			block: newBlock,
			lines: newLines,
		);


		setState(() {
			_contents.insert(index, newItem);
			_updateBlocksIndexesAfter(index);
			_updateLinesIndexesAfter(lines.length, index);
		});
	}

	void _splitRow(int blockIndex, int lineIndex, int inlineIndex) {
		final item = _contents[blockIndex];
		final row = item.children[lineIndex].child as TextBlock;


		String chords = row.chords ?? '';
		String rhythm = row.rhythm ?? '';
		String text = row.text ?? '';

		int maxLen = chords.length;
		if (rhythm.length > maxLen)
			maxLen = rhythm.length;
		if (text.length > maxLen)
			maxLen = text.length;

		if (chords.length < maxLen)
			chords += ' ' * (maxLen - chords.length);
		if (rhythm.length < maxLen)
			rhythm += ' ' * (maxLen - rhythm.length);
		if (text.length < maxLen)
			text += ' ' * (maxLen - text.length);


		final oldChords = chords.substring(0, inlineIndex);
		final newChords = chords.substring(inlineIndex);

		final oldRhythm = rhythm.substring(0, inlineIndex);
		final newRhythm = rhythm.substring(inlineIndex);

		final oldText = text.substring(0, inlineIndex);
		final newText = text.substring(inlineIndex);


		final oldRow = row.copyWith(
			key: UniqueKey(),
			index: lineIndex,
			chords: oldChords,
			rhythm: oldRhythm,
			text: oldText,
		);

		final newIndex = lineIndex + 1;
		final newRow = row.copyWith(
			key: UniqueKey(),
			index: newIndex,
			chords: newChords,
			rhythm: newRhythm,
			text: newText,
			requestFocus: true,
		);


		setState(() {
			item.children.removeAt(lineIndex);

			item.children.insert(lineIndex, DragAndDropItem(child: oldRow));
			item.children.insert(newIndex, DragAndDropItem(child: newRow));


			_updateLinesIndexesAfter(lineIndex, blockIndex);
		});
	}
	void _mergeRow(int blockIndex, int lineIndex) {
		final item = _contents[blockIndex];
		if (item.children.length == lineIndex + 1) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(AppLocalizations.of(context)!.editorTheLastRowInTheBlockMsg),
					duration: Duration(seconds: 1),
				),
			);


			return;
		}

		if (item.children[lineIndex + 1].child is! TextBlock) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(AppLocalizations.of(context)!.editorNextLineIsNotARowMsg),
					duration: Duration(seconds: 1),
				),
			);


			return;
		}


		final row = item.children[lineIndex].child as TextBlock;
		final nextRow = item.children[lineIndex + 1].child as TextBlock;

		final newRow = row.copyWith(
			key: UniqueKey(),

			chords: (row.chords ?? '') + (nextRow.chords ?? ''),
			rhythm: (row.rhythm ?? '') + (nextRow.rhythm ?? ''),
			text: (row.text ?? '') + (nextRow.text ?? ''),
		);


		setState(() {
			item.children.removeAt(lineIndex + 1);
			item.children[lineIndex] = DragAndDropItem(child: newRow);

			_updateLinesIndexesAfter(lineIndex, blockIndex);
		});
	}

	void _convertPlainTextToRow(int blockIndex, int lineIndex) {
		final item = _contents[blockIndex];
		final plainText = item.children[lineIndex].child as PlainText;

		final List<String> lines = plainText.text.split('\n');
		final rows = [];
		for (int i = 0; i < lines.length; i++) {
			final line = lines[i];
			final row = TextBlock(
				text: line,
				key: UniqueKey(),
				parentIndex: blockIndex,
				index: lineIndex + i,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
				onCopy: _copyLineInBlockAfter,
				onSplitRow: _splitRow,
				onMerge: _mergeRow,
			);
			rows.add(DragAndDropItem(child: row));
		}

		setState(() {
			item.children.removeAt(lineIndex);
			int newIndex = lineIndex;
			for (final row in rows) {
				item.children.insert(newIndex, row);
				newIndex++;
			}

			_updateLinesIndexesAfter(newIndex, blockIndex);
		});
	}


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


	void _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
		setState(() {
			var movedItem = _contents[oldListIndex].children.removeAt(oldItemIndex);
			_contents[newListIndex].children.insert(newItemIndex, movedItem);
			_updateAllLinesIndexesInBlock(newListIndex);
		});
	}

	void _onListReorder(int oldListIndex, int newListIndex) {
		setState(() {
			var movedList = _contents.removeAt(oldListIndex);
			_contents.insert(newListIndex, movedList);
			_updateAllBlocksIndexes();
		});
	}


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();

		return Focus(
			focusNode: widget.focusNode,
			child: CustomScrollView(
				controller: _scrollController,
				slivers: [DragAndDropLists(
					children: _contents,
					contentsWhenEmpty: TextButton.icon(
						icon: Icon(Icons.add),
						label: Text(AppLocalizations.of(context)!.editorAddNewBlock),
						onPressed: () => _addNewBlockAfter(-1),
					),

					onItemReorder: _onItemReorder,
					onListReorder: _onListReorder,

					listDecoration: BoxDecoration(
						color: Theme.of(context).colorScheme.surfaceContainer,
						borderRadius: .circular(10),
					),
					listPadding: .all(10),
					itemDivider: const SizedBox(height: 10),

					sliverList: true,
					scrollController: _scrollController,
				)],
			),
		);
	}

	void showMetadataEditor() {
		showModalBottomSheet(
			backgroundColor: Theme.of(context).colorScheme.surface,
			isScrollControlled: true,

			context: context,
			builder: (context) => SizedBox(
				height: MediaQuery.of(context).size.height * 0.9,
				child: Column(
					children: [
						Expanded(
							child: ListView(
								children: [
									_metadata,
									_buildSongNoteField(),
								],
							),
						),

						SizedBox(height: MediaQuery.of(context).viewInsets.bottom), // для клавиатуры
						SizedBox(height: MediaQuery.of(context).padding.bottom), // safe area
					],
				),
			),
		);
	}

	Widget _buildSongNoteField() => Container(
		margin: const .all(10),
		padding: const .all(10),
		decoration: BoxDecoration(
			color: Theme.of(context).colorScheme.surfaceContainer,
			borderRadius: .circular(8),
		),
		child: Column(
			children: [
				Align(
					alignment: .centerRight,
					child: Text(AppLocalizations.of(context)!.editorSongNote),
				),
				
				Padding(
				padding: const .all(10),
					child: IntrinsicHeight(
						child: ManyLineTextField(
							controller: _songNoteController,
							style: _settings.notesStyle(context),
							onChanged: (value) => songNote = value,
						),
					),
				),
			],
		),
	);

	DragAndDropList _buildDragAndDropList({
		required Block block,
		List<DragAndDropItem>? lines,
	}) => DragAndDropList(
		header: block,
		children: lines ?? [],

		leftSide: const SizedBox(width: 20),
		rightSide: const SizedBox(width: 20),

		contentsWhenEmpty: TextButton.icon(
			icon: Icon(Icons.add),
			label: Text(''), //AppLocalizations.of(context)!.editorAddNewLine),
			onPressed: () => _addNewLineInBlockAfter(block.index, -1),
		),
	);
}

class Block extends StatefulWidget {
	String? title;
	String? note;

	int index;
	final Function(int) onDelete;
	final Function(int) onAddNewBlock;
	final Function(int) onCopy;
	final Function(int) onMergeBlock;

	Block({
		super.key,
		this.title,
		this.note,
		required this.index,
		required this.onDelete,
		required this.onAddNewBlock,
		required this.onCopy,
		required this.onMergeBlock,
	});

	static (Block, List<Line>) from_string(
		String text,
		String key_str,
		int index,
		Function(int) onDelete,
		Function(int) onAddNewBlock,
		Function(int, int) onDeleteChild,
		Function(int, int) onAddNewLine,
		Function(int) onCopy,
		Function(int, int, Line) onCopyChild,
		Function(int, int) onSplitBlock,
		Function(int) onMergeBlock,
		Function(int, int, int) onSplitRow,
		Function(int, int) onMergeRow,
		Function(int, int) onConvertToRow,
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
						key: Key('$key_str-line${lines.length + 1}'),
						index: lines.length,
						parentIndex: index,
						onDelete: onDeleteChild,
						onAddNewLine: onAddNewLine,
						onCopy: onCopyChild,
						onSplitBlock: onSplitBlock,
						onConvertToRow: onConvertToRow,
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
						key: Key('$key_str-line${lines.length + 1}'),
						index: lines.length,
						parentIndex: index,
						onDelete: onDeleteChild,
						onAddNewLine: onAddNewLine,
						onCopy: onCopyChild,
						onSplitBlock: onSplitBlock,
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
					Key('$key_str-line${lines.length + 1}'),
					lines.length,
					index,
					onDeleteChild,
					onAddNewLine,
					onCopyChild,
					onSplitBlock,
					onSplitRow,
					onMergeRow,
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
						chords: chords,
						key: Key('$key_str-line${lines.length + 1}'),
						index: lines.length,
						parentIndex: index,
						onDelete: onDeleteChild,
						onAddNewLine: onAddNewLine,
						onCopy: onCopyChild,
						onSplitBlock: onSplitBlock,
					));
			} else if (line.startsWith(noteLineSymbol())) {
				final note = _parseKeyValueLine(line);
				if (note != null)
					lines.add(NoteLine(
						text: note,
						key: Key('$key_str-line${lines.length + 1}'),
						index: lines.length,
						parentIndex: index,
						onDelete: onDeleteChild,
						onAddNewLine: onAddNewLine,
						onCopy: onCopyChild,
						onSplitBlock: onSplitBlock,
					));
			} else if (line.startsWith(emptyLineSymbol())) {
				lines.add(EmptyLine(
					key: Key('$key_str-line${lines.length + 1}'),
					index: lines.length,
					parentIndex: index,
					onDelete: onDeleteChild,
					onAddNewLine: onAddNewLine,
					onCopy: onCopyChild,
					onSplitBlock: onSplitBlock,
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
			onCopy: onCopy,
			onMergeBlock: onMergeBlock,
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

	Block copyWith({
		Key? key,
		String? title,
		String? note,

		int? index,
	}) => Block(
		key: key,
		title: title ?? this.title,
		note: note ?? this.note,
		index: index ?? this.index,

		onDelete: onDelete,
		onAddNewBlock: onAddNewBlock,
		onCopy: onCopy,
		onMergeBlock: onMergeBlock,
	);


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
							label: AppLocalizations.of(context)!.editorBlock,
							options: { 
								AppLocalizations.of(context)!.editorDelete: () =>
									widget.onDelete(widget.index),

								AppLocalizations.of(context)!.editorAddNewBlock: () =>
									widget.onAddNewBlock(widget.index),

								AppLocalizations.of(context)!.editorCopy: () =>
									widget.onCopy(widget.index),

								AppLocalizations.of(context)!.editorMergeWithNext: () =>
									widget.onMergeBlock(widget.index),
							},
						),
					),
					const SizedBox(height: 5),

					OneLineTextField(
						controller: _titleController,
						style: _settings.titleStyle(context),
						onChanged: (value) => widget.title = value,
						label: AppLocalizations.of(context)!.editorTitle
					),
					const SizedBox(height: 10),

					OneLineTextField(
						controller: _noteController,
						style: _settings.notesStyle(context),
						onChanged: (value) => widget.note = value,
						label: AppLocalizations.of(context)!.editorNote,
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
	final Function(int, int) onAddNewLine;
	final Function(int, int, Line) onCopy;
	final Function(int, int) onSplitBlock;

	Line({
		super.key,
		required this.index,
		required this.parentIndex,
		required this.onDelete,
		required this.onAddNewLine,
		required this.onCopy,
		required this.onSplitBlock,
	});

	String to_string() => '';

	Line copyWith({
		Key? key,
		int? index,
		int? parentIndex,
	}) => this;


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

	final Function(int, int, int) onSplitRow;
	final Function(int, int) onMerge;
	final bool requestFocus;

	TextBlock({
		super.key,
		this.chords,
		this.rhythm,
		this.text,
		required super.index,
		required super.parentIndex,
		required super.onDelete,
		required super.onAddNewLine,
		required super.onCopy,
		required super.onSplitBlock,
		required this.onSplitRow,
		required this.onMerge,
		this.requestFocus = false,
	});

	static TextBlock from_string(
		String lines,
		Key key,
		int index,
		int parentIndex,
		Function(int, int) onDelete,
		Function(int, int) onAddNewLine,
		Function(int, int, Line) onCopy,
		Function(int, int) onSplitBlock,
		Function(int, int, int) onSplitRow,
		Function(int, int) onMerge,
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
			onAddNewLine: onAddNewLine,
			onCopy: onCopy,
			onSplitBlock: onSplitBlock,
			onSplitRow: onSplitRow,
			onMerge: onMerge,
		);
	}

	@override
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
	TextBlock copyWith({
		Key? key,
		int? index,
		int? parentIndex,

		String? chords,
		String? rhythm,
		String? text,
		bool? requestFocus,
	}) => TextBlock(
		key: key,
		index: index ?? this.index,
		parentIndex: parentIndex ?? this.parentIndex,

		chords: chords ?? this.chords,
		rhythm: rhythm ?? this.rhythm,
		text: text ?? this.text,

		onDelete: onDelete,
		onAddNewLine: onAddNewLine,
		onCopy: onCopy,
		onSplitBlock: onSplitBlock,
		onSplitRow: onSplitRow,
		onMerge: onMerge,
		requestFocus: requestFocus ?? this.requestFocus,
	);


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

	late final FocusNode _chordsFocus;
	late final FocusNode _rhythmFocus;
	late final FocusNode _textFocus;

	late final ScrollController _scrollController;


	@override
	void initState() {
		super.initState();
		_chordsController = TextEditingController(text: widget.chords);
		_rhythmController = TextEditingController(text: widget.rhythm);
		_textController = TextEditingController(text: widget.text);
		
		_chordsFocus = FocusNode();
		_rhythmFocus = FocusNode();
		_textFocus = FocusNode();

		_scrollController = ScrollController();


		if (widget.requestFocus)
			_textFocus.requestFocus();
	}

	@override
	void dispose() {
		_chordsController.dispose();
		_rhythmController.dispose();
		_textController.dispose();

		_chordsFocus.dispose();
		_rhythmFocus.dispose();
		_textFocus.dispose();

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

	void _split() {
		int position = 0;
		if (_chordsFocus.hasFocus)
			position = _chordsController.selection.baseOffset;
		else if (_rhythmFocus.hasFocus)
			position = _rhythmController.selection.baseOffset;
		else if (_textFocus.hasFocus)
			position = _textController.selection.baseOffset;

		if (position == -1)
			position = 0;
		
		widget.onSplitRow(widget.parentIndex, widget.index, position);
	}


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();
		_calculateCharSize();


		return LineContainer(
			title: MenuButton(
				label: AppLocalizations.of(context)!.editorRow,
				options: {
					AppLocalizations.of(context)!.editorDelete: () =>
						widget.onDelete(widget.index, widget.parentIndex),

					AppLocalizations.of(context)!.editorAddNewLine: () =>
						widget.onAddNewLine(widget.parentIndex, widget.index),

					AppLocalizations.of(context)!.editorCopy: () =>
						widget.onCopy(widget.parentIndex, widget.index, widget),

					AppLocalizations.of(context)!.editorMergeWithNext: () =>
						widget.onMerge(widget.parentIndex, widget.index),

					AppLocalizations.of(context)!.editorSplitBlock: () =>
						widget.onSplitBlock(widget.parentIndex, widget.index),
				},
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
						child: Text(AppLocalizations.of(context)!.editorChordsShort, style: textStyle),
					),

					SizedBox(
						height: _lineHeight,
						child: Text(AppLocalizations.of(context)!.editorRhythmShort, style: textStyle),
					),

					SizedBox(
						height: _lineHeight,
						child: Text(AppLocalizations.of(context)!.editorTextShort, style: textStyle),
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
						focusNode: _chordsFocus,
						style: _settings.chordsStyle(context),
						selectionWidthStyle: .tight,
						decoration: _buildInputDecoration(),
						onChanged: (value) => widget.chords = value,
						onSubmitted: (value) => _split(),
					),
				),
			),

			IntrinsicWidth(
				child: SizedBox(
					height: _lineHeight,
					child: TextField(
						controller: _rhythmController,
						focusNode: _rhythmFocus,
						style: _settings.rhythmStyle(context),
						selectionWidthStyle: .tight,
						decoration: _buildInputDecoration(),
						onChanged: (value) => widget.rhythm = value,
						onSubmitted: (value) => _split(),
					),
				),
			),

			IntrinsicWidth(
				child: SizedBox(
					height: _lineHeight,
					child: TextField(
						controller: _textController,
						focusNode: _textFocus,
						style: _settings.textStyle(context),
						selectionWidthStyle: .tight,
						decoration: _buildInputDecoration(),
						onChanged: (value) => widget.text = value,
						onSubmitted: (value) => _split(),
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
		required super.onAddNewLine,
		required super.onCopy,
		required super.onSplitBlock,
	});

	@override
	String to_string() {
		return chordsLineSymbol() + chords + '\n';
	}

	@override
	ChordsLine copyWith({
		Key? key,
		int? index,
		int? parentIndex,

		String? chords,
	}) => ChordsLine(
		key: key,
		index: index ?? this.index,
		parentIndex: parentIndex ?? this.parentIndex,

		chords: chords ?? this.chords,

		onDelete: onDelete,
		onAddNewLine: onAddNewLine,
		onCopy: onCopy,
		onSplitBlock: onSplitBlock,
	);


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
				label: AppLocalizations.of(context)!.editorChordsLine,
				options: {
					AppLocalizations.of(context)!.editorDelete: () =>
						widget.onDelete(widget.index, widget.parentIndex),

					AppLocalizations.of(context)!.editorAddNewLine: () =>
						widget.onAddNewLine(widget.parentIndex, widget.index),

					AppLocalizations.of(context)!.editorCopy: () =>
						widget.onCopy(widget.parentIndex, widget.index, widget),

					AppLocalizations.of(context)!.editorSplitBlock: () =>
						widget.onSplitBlock(widget.parentIndex, widget.index),
				},
			),
			child: OneLineTextField(
				controller: _controller,
				style: _settings.chordsStyle(context),
				onChanged: (value) => widget.chords = value,
			),
		);
	}
}

class NoteLine extends Line {
	String text;

	NoteLine({
		super.key,
		required this.text,
		required super.index,
		required super.parentIndex,
		required super.onDelete,
		required super.onAddNewLine,
		required super.onCopy,
		required super.onSplitBlock,
	});

	@override
	String to_string() {
		return noteLineSymbol() + text + '\n';
	}

	@override
	NoteLine copyWith({
		Key? key,
		int? index,
		int? parentIndex,

		String? text,
	}) => NoteLine(
		key: key,
		index: index ?? this.index,
		parentIndex: parentIndex ?? this.parentIndex,

		text: text ?? this.text,

		onDelete: onDelete,
		onAddNewLine: onAddNewLine,
		onCopy: onCopy,
		onSplitBlock: onSplitBlock,
	);


	@override
	State<NoteLine> createState() => NoteLineState();
}
class NoteLineState extends State<NoteLine> {
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
				label: AppLocalizations.of(context)!.editorNoteLine,
				options: {
					AppLocalizations.of(context)!.editorDelete: () =>
						widget.onDelete(widget.index, widget.parentIndex),

					AppLocalizations.of(context)!.editorAddNewLine: () =>
						widget.onAddNewLine(widget.parentIndex, widget.index),

					AppLocalizations.of(context)!.editorCopy: () =>
						widget.onCopy(widget.parentIndex, widget.index, widget),

					AppLocalizations.of(context)!.editorSplitBlock: () =>
						widget.onSplitBlock(widget.parentIndex, widget.index),
				},
			),
			child: OneLineTextField(
				controller: _controller,
				style: _settings.notesStyle(context),
				onChanged: (value) => widget.text = value,
			),
		);
	}
}

class PlainText extends Line {
	String text;
	final Function(int, int) onConvertToRow;

	PlainText({
		super.key,
		required this.text,
		required super.index,
		required super.parentIndex,
		required super.onDelete,
		required super.onAddNewLine,
		required super.onCopy,
		required super.onSplitBlock,
		required this.onConvertToRow,
	});

	@override
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
	PlainText copyWith({
		Key? key,
		int? index,
		int? parentIndex,

		String? text,
	}) => PlainText(
		key: key,
		index: index ?? this.index,
		parentIndex: parentIndex ?? this.parentIndex,

		text: text ?? this.text,

		onDelete: onDelete,
		onAddNewLine: onAddNewLine,
		onCopy: onCopy,
		onSplitBlock: onSplitBlock,
		onConvertToRow: onConvertToRow,
	);


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
				label: AppLocalizations.of(context)!.editorPlainText,
				options: {
					AppLocalizations.of(context)!.editorDelete: () =>
						widget.onDelete(widget.index, widget.parentIndex),

					AppLocalizations.of(context)!.editorAddNewLine: () =>
						widget.onAddNewLine(widget.parentIndex, widget.index),

					AppLocalizations.of(context)!.editorCopy: () =>
						widget.onCopy(widget.parentIndex, widget.index, widget),

					AppLocalizations.of(context)!.editorSplitBlock: () =>
						widget.onSplitBlock(widget.parentIndex, widget.index),

					AppLocalizations.of(context)!.editorConvertToRow: () =>
						widget.onConvertToRow(widget.parentIndex, widget.index),
				},
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
		required super.onAddNewLine,
		required super.onCopy,
		required super.onSplitBlock,
	});

	@override
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
	Tab copyWith({
		Key? key,
		int? index,
		int? parentIndex,

		String? tab,
	}) => Tab(
		key: key,
		index: index ?? this.index,
		parentIndex: parentIndex ?? this.parentIndex,

		tab: tab ?? this.tab,

		onDelete: onDelete,
		onAddNewLine: onAddNewLine,
		onCopy: onCopy,
		onSplitBlock: onSplitBlock,
	);

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
				label: AppLocalizations.of(context)!.editorTab,
				options: {
					AppLocalizations.of(context)!.editorDelete: () =>
						widget.onDelete(widget.index, widget.parentIndex),

					AppLocalizations.of(context)!.editorAddNewLine: () =>
						widget.onAddNewLine(widget.parentIndex, widget.index),

					AppLocalizations.of(context)!.editorCopy: () =>
						widget.onCopy(widget.parentIndex, widget.index, widget),

					AppLocalizations.of(context)!.editorSplitBlock: () =>
						widget.onSplitBlock(widget.parentIndex, widget.index),
				},
			),
			child: Scrollbar(
				controller: _scrollController,
				interactive: true,
				thickness: 5.0,
				radius: const .circular(8),
				child: SingleChildScrollView(
					controller: _scrollController,
					scrollDirection: .horizontal,
					child: ConstrainedBox(
						constraints: BoxConstraints(
							minWidth: MediaQuery.of(context).size.width - 20 - 40 - 20,
						),
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
		required super.onAddNewLine,
		required super.onCopy,
		required super.onSplitBlock,
	});

	@override
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
				label: AppLocalizations.of(context)!.editorEmptyLine,
				options: {
					AppLocalizations.of(context)!.editorDelete: () =>
						widget.onDelete(widget.index, widget.parentIndex),

					AppLocalizations.of(context)!.editorAddNewLine: () =>
						widget.onAddNewLine(widget.parentIndex, widget.index),

					AppLocalizations.of(context)!.editorCopy: () =>
						widget.onCopy(widget.parentIndex, widget.index, widget),

					AppLocalizations.of(context)!.editorSplitBlock: () =>
						widget.onSplitBlock(widget.parentIndex, widget.index),
				},
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
						capo = int.tryParse(result);
				} else if ( line.startsWith(songAutoscrollSpeedSymbol()) ) {
					final result = _parseKeyValueLine(line);
					if (result != null)
						autoscrollSpeed = int.tryParse(result);
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
	late final TextEditingController _titleController;
	late final TextEditingController _artistController;
	late final TextEditingController _keyController;
	late final TextEditingController _capoController;
	late final TextEditingController _autoscrollSpeedController;


	@override
	void initState() {
		super.initState();
		_titleController = TextEditingController(text: widget.title);
		_artistController = TextEditingController(text: widget.artist);
		_keyController = TextEditingController(text: widget.Key);
		_capoController = TextEditingController(text: widget.capo?.toString());
		_autoscrollSpeedController = TextEditingController(text: widget.autoscrollSpeed?.toString());
	}

	@override
	void dispose() {
		_titleController.dispose();
		_artistController.dispose();
		_keyController.dispose();
		_capoController.dispose();
		_autoscrollSpeedController.dispose();
		super.dispose();
	}


	@override
	Widget build(BuildContext context) {
		final style = TextStyle();

		return Container(
			padding: const .all(10),
			margin: const .all(10),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainer,
				borderRadius: .circular(8),
			),
			child: Column(
				crossAxisAlignment: .start,
				children: [
					Align(
						alignment: .centerRight,
						child: Text(AppLocalizations.of(context)!.editorMetadata),
					),
					const SizedBox(height: 10),

					OneLineTextField(
						label: AppLocalizations.of(context)!.editorMetadataTitle,
						controller: _titleController,
						style: style,
						onChanged: (value) => widget.title = value,
					),
					const SizedBox(height: 10),

					OneLineTextField(
						label: AppLocalizations.of(context)!.editorMetadataArtist,
						controller: _artistController,
						style: style,
						onChanged: (value) => widget.artist = value,
					),
					const SizedBox(height: 10),

					OneLineTextField(
						label: AppLocalizations.of(context)!.editorMetadataKey,
						controller: _keyController,
						style: style,
						onChanged: (value) => widget.Key = (value.trim().isEmpty)
							? null
							: value,
					),
					const SizedBox(height: 10),

					OneLineTextField(
						label: AppLocalizations.of(context)!.editorMetadataCapo,
						controller: _capoController,
						style: style,
						onChanged: (value) => widget.capo = int.tryParse(value),
					),
					const SizedBox(height: 10),

					OneLineTextField(
						label: AppLocalizations.of(context)!.editorMetadataAutoscrollSpeed,
						controller: _autoscrollSpeedController,
						style: style,
						onChanged: (value) => widget.autoscrollSpeed = int.tryParse(value),
					),
					const SizedBox(height: 10),
					

					widget.showOptions,
				],
			),
		);
	}
}
class ShowOptions extends StatefulWidget {
	bool chords;
	bool rhythm;
	bool notes;
	bool fingerings;

	ShowOptions({
		super.key,
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
		if (result == null) {
			this.chords = false;
			this.rhythm = false;
			this.notes = false;
			this.fingerings = false;
			return;
		}

		final opts = result;
		this.chords = opts.contains('c');
		this.rhythm = opts.contains('r');
		this.notes = opts.contains('n');
		this.fingerings = opts.contains('f');
	}


	@override
	State<ShowOptions> createState() => ShowOptionsState();
}
class ShowOptionsState extends State<ShowOptions> {
	@override
	Widget build(BuildContext context) {
		return Container(
			width: double.infinity,
			margin: const .all(10),
			padding: const .all(10),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainerHighest,
				borderRadius: .circular(8),
			),
			child: Material(
				color: Theme.of(context).colorScheme.surfaceContainerHighest,
				child: Column(
					children: [
						Align(
							alignment: .centerRight,
							child: Text(AppLocalizations.of(context)!.editorShowOptions),
						),
						const SizedBox(height: 10),


						CheckboxListTile(
							title: Text(AppLocalizations.of(context)!.chords),
							value: widget.chords,
							onChanged: (bool? value) {
								if (value != null)
									setState(() => widget.chords = value);
							}
						),
						CheckboxListTile(
							title: Text(AppLocalizations.of(context)!.rhythm),
							value: widget.rhythm,
							onChanged: (bool? value) {
								if (value != null)
									setState(() => widget.rhythm = value);
							}
						),
						CheckboxListTile(
							title: Text(AppLocalizations.of(context)!.notes),
							value: widget.notes,
							onChanged: (bool? value) {
								if (value != null)
									setState(() => widget.notes = value);
							}
						),
						CheckboxListTile(
							title: Text(AppLocalizations.of(context)!.fingerings),
							value: widget.fingerings,
							onChanged: (bool? value) {
								if (value != null)
									setState(() => widget.fingerings = value);
							}
						),
					],
				),
			),
		);
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

	const LineContainer({
		super.key,
		required this.child,
		required this.title,
	});


	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const .all(10),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

	const ManyLineTextField({
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

	const OneLineTextField({
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

	const MenuButton({
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

enum LineType {
	textBlock,
	chordsLine,
	noteLine,
	plainText,
	tab,
	emptyLine;

	String to_string(BuildContext context) {
		return switch(this) {
			LineType.textBlock => AppLocalizations.of(context)!.editorRow,
			LineType.chordsLine => AppLocalizations.of(context)!.editorChordsLine,
			LineType.noteLine => AppLocalizations.of(context)!.editorNoteLine,
			LineType.plainText => AppLocalizations.of(context)!.editorPlainText,
			LineType.tab => AppLocalizations.of(context)!.editorTab,
			LineType.emptyLine => AppLocalizations.of(context)!.editorEmptyLine,
		};
	}
}
class SelectLineTypeScreen extends StatelessWidget {
	const SelectLineTypeScreen({super.key});

	@override
	Widget build(BuildContext context) {
		final colorScheme = Theme.of(context).colorScheme;

		return IntrinsicHeight(
			child: Material(
				color: colorScheme.surfaceContainerHighest,
				shape: RoundedRectangleBorder(
					borderRadius: .circular(12),
				),
				clipBehavior: .antiAlias,
				child: Column(
					mainAxisAlignment: .start,
					children: [
						...LineType.values.map((value) => InkWell(
							onTap: () => Navigator.of(context).pop(value),
							child: Container(
								width: double.infinity,
								padding: const .all(10),
								margin: const .all(5),
								child: Text(value.to_string(context)),
							),
						)),

						SizedBox(height: MediaQuery.of(context).padding.bottom), // safe area
					],
				),
			),
		);
	}
}

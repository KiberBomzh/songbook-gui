import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import 'package:songbook/screens/editor/graphical_editor/graphical_editor.dart';
import 'package:songbook/screens/editor/editor_field.dart';
import 'package:songbook/screens/editor/editor_text_controller.dart';
import 'package:songbook/services/settings.dart';

import 'package:songbook/src/rust/api/song.dart';
import 'package:songbook/l10n/app_localizations.dart';


enum EditorMode {
	source,
	raw,
	normal;

	String to_string(BuildContext context) => switch(this) {
		source => AppLocalizations.of(context)!.editorModeSource,
		raw => AppLocalizations.of(context)!.editorModeRaw,
		normal => AppLocalizations.of(context)!.editorModeNormal,
	};
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


	final GlobalKey<GraphicalSongEditorState> _graphicalEditorKey = GlobalKey<GraphicalSongEditorState>();
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



	late EditorTextController _textController;

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
		_textController = EditorTextController(
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


	void _switchMode(EditorMode newMode) async {
		 if (_currentMode == newMode)
			return;

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

			_currentMode = newMode;



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

			_currentMode = newMode;
			if (newMode == EditorMode.source) {
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
	}


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();

		return CallbackShortcuts(
			bindings: {
				const SingleActivator(LogicalKeyboardKey.keyQ, control: true):
					() => Navigator.of(context).pop(),
				const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,

				const SingleActivator(LogicalKeyboardKey.keyN, control: true, alt: true):
					() => _switchMode(.normal),
				const SingleActivator(LogicalKeyboardKey.keyR, control: true, alt: true):
					() => _switchMode(.raw),
				const SingleActivator(LogicalKeyboardKey.keyS, control: true, alt: true):
					() => _switchMode(.source),
			},
			child: Focus(
				autofocus: true,
				child: PopScope(
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

							IconButton(
								icon: Icon(Icons.menu_open),
								tooltip: AppLocalizations.of(context)!.editorTooltipMode,
								onPressed: _changeMode,
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

	void _changeMode() async {
		final result = await showDialog<EditorMode?>(
			context: context,
			builder: (context) => SimpleDialog(
				title: Text(AppLocalizations.of(context)!.editorChangeModeDialogTitle),
				children: EditorMode.values.map((value) => SimpleDialogOption(
					child: (_currentMode == value)
						? Row(
							children: [
								Icon(Icons.label_important),
								Text(value.to_string(context)),
							],
						)
						: Text(value.to_string(context)),
					onPressed: () => Navigator.of(context).pop(value),
				)).toList(),
			),
		);

		if (result == null)
			return;

		_switchMode(result);
	}
}


class FastKeywordsLine extends StatefulWidget {
	final Function(String) onTap;

	const FastKeywordsLine({
		super.key,
		required this.onTap,
	});

	@override
	State<FastKeywordsLine> createState() => _FastKeywordsLineState();
}

class _FastKeywordsLineState extends State<FastKeywordsLine> {
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

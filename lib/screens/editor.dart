import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:songbook/services/settings.dart';
import 'package:songbook/src/rust/api/song.dart';


enum EditorMode {
	source,
	raw
}


class EditorScreen extends StatefulWidget {
	SimpleSong song;
	final String path;
	final EditorMode? mode;

	EditorScreen({
		super.key,
		required this.song,
		required this.path,
		this.mode,
	});


	@override
	State<EditorScreen> createState() => _EditorState();
}

class _EditorState extends State<EditorScreen> {
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



	late TextEditingController _textController;
	late FocusNode _focusNode;

	List<String> _history = [];
	int _historyIndex = -1;
	Timer? _historyTimer;


	@override
	void initState() {
		super.initState();
		_currentMode = widget.mode ?? EditorMode.raw;
		_textController = TextEditingController();
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
			_textController.text = widget.song.getForEditing();
		};
	}

	void _save() async {
		if (_currentMode == EditorMode.source) {
			await File(widget.path).writeAsString(_textController.text);
			widget.song = SimpleSong.open(pathStr: widget.path);
			_rawText = null;
			_rawHistory = [];
			_rawHistoryIndex = -1;
			_rawSelection = null;
		} else {
			widget.song.changeFromEdited(s: _textController.text);
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


	@override
	Widget build(BuildContext context) {
		return SafeArea(
			bottom: true,
			top: true,
			child: Scaffold(
				body: _buildBody(),
			),
		);
	}

	Widget _buildBody() {
		return Stack(
			children: [
				Column(
					children: [
						Expanded(
							child: _buildTextField(),
						),

						if (_currentMode == EditorMode.raw)
							SizedBox(height: 50),

						const SizedBox(height: 60),
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
							backgroundColor: Colors.black.withOpacity(0.7),
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

	Widget _buildTextField() {
		final settings = context.watch<SettingsProvider>();
		final fontSize = settings.editorFontSize;

		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 15),
			child: SingleChildScrollView(
				scrollDirection: Axis.horizontal,
				child: ConstrainedBox(
					constraints: BoxConstraints(
						minWidth: MediaQuery.of(context).size.width,
					),
					child: IntrinsicWidth(
						child: TextField(
							controller: _textController,
							focusNode: _focusNode,
							maxLines: null,
							expands: true,
							textAlignVertical: .top,
							style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'CascadiaMono', fontSize: fontSize),
							decoration: const InputDecoration(
								border: InputBorder.none,
								hintText: "Song's text...",
								hintStyle: TextStyle(color: Colors.grey),
							),
							onChanged: (text) {
								_saveToHistory();
							}
						),
					),
				),
			),
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
			margin: const EdgeInsets.only(bottom: 5, right: 10, left: 10),
			child: Scrollbar(
				controller: _controller,
				interactive: true,
				child: SingleChildScrollView(
					scrollDirection: .horizontal,
					controller: _controller,
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
		);
	}
}

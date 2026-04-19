import 'dart:async';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:songbook/services/settings.dart';
import 'package:songbook/src/rust/api/song.dart';


class EditorScreen extends StatefulWidget {
	SimpleSong song;

	EditorScreen({super.key, required this.song});


	@override
	State<EditorScreen> createState() => _EditorState();
}

class _EditorState extends State<EditorScreen> {
	late TextEditingController _textController;
	late FocusNode _focusNode;

	final List<String> _history = [];
	int _historyIndex = -1;
	Timer? _historyTimer;


	@override
	void initState() {
		super.initState();
		_textController = TextEditingController();
		_textController.text = widget.song.getForEditing();

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

	void _save() {
		widget.song.changeFromEdited(s: _textController.text);
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
		return Column(
			crossAxisAlignment: .start,
			children: [
				Expanded(
					child: _buildTextField(),
				),
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

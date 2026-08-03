import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:songbook/l10n/app_localizations.dart';
import 'package:songbook/src/rust/api/song.dart';

import 'package:songbook/screens/editor/graphical_editor/line/line.dart' as line_;
import 'package:songbook/screens/editor/graphical_editor/widgets.dart';
import 'package:songbook/functions/parse_key_value_line.dart';
import 'package:songbook/services/settings.dart';


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

	static (Block, List<line_.Line>) from_string(
		String text,
		String key_str,
		int index,
		Function(int) onDelete,
		Function(int) onAddNewBlock,
		Function(int, int) onDeleteChild,
		Function(int, int) onAddNewLine,
		Function(int) onCopy,
		Function(int, int, line_.Line) onCopyChild,
		Function(int, int) onSplitBlock,
		Function(int) onMergeBlock,
		Function(int, int, int) onSplitRow,
		Function(int, int) onMergeRow,
		Function(int, int) onConvertToRow,
	) {
		List<line_.Line> lines = [];
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
					lines.add(line_.PlainText(
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
					lines.add(line_.Tab(
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
				lines.add(line_.TextBlock.from_string(
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
				final chords = parseKeyValueLine(line);
				if (chords != null)
					lines.add(line_.ChordsLine(
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
				final note = parseKeyValueLine(line);
				if (note != null)
					lines.add(line_.NoteLine(
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
				lines.add(line_.EmptyLine(
					key: Key('$key_str-line${lines.length + 1}'),
					index: lines.length,
					parentIndex: index,
					onDelete: onDeleteChild,
					onAddNewLine: onAddNewLine,
					onCopy: onCopyChild,
					onSplitBlock: onSplitBlock,
				));

			} else if (line.startsWith(titleSymbol())) {
				title = parseKeyValueLine(line);
			} else if (line.startsWith(blockNoteSymbol())) {
				note = parseKeyValueLine(line);
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

	String to_string(List<line_.Line> lines) {
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
	State<Block> createState() => _BlockState();
}
class _BlockState extends State<Block> {
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

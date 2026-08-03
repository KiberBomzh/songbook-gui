import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:songbook/l10n/app_localizations.dart';
import 'package:songbook/src/rust/api/song.dart';

import 'package:songbook/screens/editor/graphical_editor/widgets.dart';
import 'package:songbook/services/settings.dart';


part 'text_block.dart';
part 'chords_line.dart';
part 'note_line.dart';
part 'plain_text.dart';
part 'tab.dart';
part 'empty_line.dart';


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

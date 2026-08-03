part of 'line.dart';


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
	State<EmptyLine> createState() => _EmptyLineState();
}
class _EmptyLineState extends State<EmptyLine> {
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

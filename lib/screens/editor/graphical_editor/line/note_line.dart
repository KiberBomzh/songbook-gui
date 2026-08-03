part of 'line.dart';


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
	State<NoteLine> createState() => _NoteLineState();
}
class _NoteLineState extends State<NoteLine> {
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

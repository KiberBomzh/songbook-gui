part of 'line.dart';


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
	State<ChordsLine> createState() => _ChordsLineState();
}
class _ChordsLineState extends State<ChordsLine> {
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

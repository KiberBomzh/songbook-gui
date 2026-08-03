part of 'line.dart';


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
	State<PlainText> createState() => _PlainTextState();
}
class _PlainTextState extends State<PlainText> {
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

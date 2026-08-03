part of 'line.dart';


class TextBlock extends Line { // Row
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
	State<TextBlock> createState() => _TextBlockState();
}
class _TextBlockState extends State<TextBlock> {
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

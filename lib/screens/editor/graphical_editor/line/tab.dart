part of 'line.dart';


class Tab extends Line {
	String tab;

	Tab({
		super.key,
		required this.tab,
		required super.index,
		required super.parentIndex,
		required super.onDelete,
		required super.onAddNewLine,
		required super.onCopy,
		required super.onSplitBlock,
	});

	@override
	String to_string() {
		String result = '';

		result += tabStartSymbol() + '\n';
		result += tab;
		if (!tab.endsWith('\n'))
			result += '\n';
		result += tabEndSymbol() + '\n';

		return result;
	}

	@override
	Tab copyWith({
		Key? key,
		int? index,
		int? parentIndex,

		String? tab,
	}) => Tab(
		key: key,
		index: index ?? this.index,
		parentIndex: parentIndex ?? this.parentIndex,

		tab: tab ?? this.tab,

		onDelete: onDelete,
		onAddNewLine: onAddNewLine,
		onCopy: onCopy,
		onSplitBlock: onSplitBlock,
	);

	@override
	State<Tab> createState() => _TabState();
}
class _TabState extends State<Tab> {
	late SettingsProvider _settings;
	late final TextEditingController _controller;
	late final ScrollController _scrollController;

	late double _lineHeight;
	late double _textFieldHeight;

	@override
	void initState() {
		super.initState();
		_controller = TextEditingController(text: widget.tab);
		_scrollController = ScrollController();
	}

	@override
	void dispose() {
		_controller.dispose();
		_scrollController.dispose();
		super.dispose();
	}

	void _calculateLineHeight() {
		final textPainter = TextPainter(
			text: TextSpan(text: 'I', style: _settings.tabStyle(context)),
			textDirection: .ltr
		)..layout();
		_lineHeight = textPainter.height;
	}

	void _calculateTextFieldHeight() {
		final lineCount = '\n'.allMatches(_controller.text).length + 1;
		setState(() => _textFieldHeight = (_lineHeight + (_lineHeight / 6)) * lineCount + 10);
	}

	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();
		_calculateLineHeight();
		_calculateTextFieldHeight();

		return LineContainer(
			title: MenuButton(
				label: AppLocalizations.of(context)!.editorTab,
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
			child: Scrollbar(
				controller: _scrollController,
				interactive: true,
				thickness: 5.0,
				radius: const .circular(8),
				child: SingleChildScrollView(
					controller: _scrollController,
					scrollDirection: .horizontal,
					child: ConstrainedBox(
						constraints: BoxConstraints(
							minWidth: MediaQuery.of(context).size.width - 20 - 40 - 20,
						),
						child: IntrinsicWidth(
							child: SizedBox(
								height: _textFieldHeight,
								child: ManyLineTextField(
									controller: _controller,
									style: _settings.tabStyle(context),
									onChanged: (value) {
										widget.tab = value;
										setState(() {});
									},
								),
							),
						),
					),
				),
			),
		);
	}
}

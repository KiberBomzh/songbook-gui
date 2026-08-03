import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:provider/provider.dart';

import 'package:songbook/services/settings.dart';


class EditorField extends StatefulWidget {
	final TextEditingController controller;
	final FocusNode focusNode;
	final Function(String) onChanged;
	final Function(double) onScrollUpdate;
	final double initialScrollOffset;

	const EditorField({
		super.key,
		required this.controller,
		required this.focusNode,
		required this.onChanged,
		required this.onScrollUpdate,
		required this.initialScrollOffset,
	});


	@override
	State<EditorField> createState() => EditorFieldState();
}
class EditorFieldState extends State<EditorField> {
	late SettingsProvider _settings;


	List<String> _lineNumbers = [];

	late final LinkedScrollControllerGroup _controllers;
	late final ScrollController _textFieldScrollController;
	late final ScrollController _lineNumbersScrollController;

	bool _isFirstBuild = true;

	@override
	void initState() {
		super.initState();
		_updateLineNumbers();
		widget.controller.addListener(_updateLineNumbers);

		_controllers = LinkedScrollControllerGroup();
		_textFieldScrollController = _controllers.addAndGet();
		_lineNumbersScrollController = _controllers.addAndGet();

		_controllers.addOffsetChangedListener(_updateScroll);
	}

	@override
	void dispose() {
		widget.controller.removeListener(_updateLineNumbers);

		_controllers.removeOffsetChangedListener(_updateScroll);
		_textFieldScrollController.dispose();
		_lineNumbersScrollController.dispose();
		super.dispose();
	}

	void setScrollOffset(double offset) => _controllers.jumpTo(offset);

	void _updateScroll() => widget.onScrollUpdate(_controllers.offset);

	void _updateLineNumbers() {
		final lineCount = '\n'.allMatches(widget.controller.text).length + 1;
		setState(() => _lineNumbers = List.generate(lineCount, (index) => '${index + 1}'));
	}

	double _calculateLineNumbersWidth() {
		final textPainter = TextPainter(
			text: TextSpan(
				text: _lineNumbers[_lineNumbers.length - 1],
				style: _settings.editorStyle()
			),
			textDirection: .ltr
		)..layout();
		return textPainter.width + 15;
	}


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();
		final lineNumbersWidth = _calculateLineNumbersWidth();
		if (_isFirstBuild && _textFieldScrollController.hasClients) {
			_controllers.jumpTo(widget.initialScrollOffset);
			_isFirstBuild = false;
		}

		return Focus(
			onKeyEvent: (node, event) {
				if (event.logicalKey != LogicalKeyboardKey.tab || event is KeyUpEvent) {
					return KeyEventResult.ignored;
				}

				final selection = widget.controller.selection;
				if (selection.isValid) {
					final newText = widget.controller.text.replaceRange(
						selection.start,
						selection.end,
						'\t',
					);
					widget.controller.value = TextEditingValue(
						text: newText,
						selection: TextSelection.collapsed(
							offset: selection.start + 1,
						),
					);
				}
				return KeyEventResult.handled;
			},
			child: Row(
				mainAxisAlignment: .start,
				crossAxisAlignment: .start,
				children: [
					Container(
						width: lineNumbersWidth,
						padding: const .symmetric(horizontal: 5),
						child: ScrollConfiguration(
							behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
							child: SingleChildScrollView(
								controller: _lineNumbersScrollController,
								child: Column(
									mainAxisAlignment: .start,
									children: _lineNumbers.map((n) => Text(n,
										maxLines: 1,
										style: _settings.editorStyle()
											.copyWith(color: Colors.grey, fontWeight: .bold),
									)).toList(),
								),
							),
						),
					),

					Expanded(
						child: SingleChildScrollView(
							scrollDirection: Axis.horizontal,
							child: ConstrainedBox(
								constraints: BoxConstraints(
									minWidth: MediaQuery.of(context).size.width - lineNumbersWidth - 10,
								),
								child: IntrinsicWidth(
									child: TextField(
										controller: widget.controller,
										scrollController: _textFieldScrollController,
										focusNode: widget.focusNode,
										maxLines: null,
										expands: true,
										onTapAlwaysCalled: true,
										selectionWidthStyle: .tight,
										style: _settings.editorStyle(),
										decoration: const InputDecoration(
											border: InputBorder.none,
											contentPadding: .all(0),
										),
										onChanged: widget.onChanged,
									),
								),
							),
						),
					),
					const SizedBox(width: 10),
				],
			),
		);
	}
}

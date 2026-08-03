import 'package:flutter/material.dart';

import 'package:songbook/l10n/app_localizations.dart';


class Tags extends StatefulWidget {
	List<String> tags;

	Tags({
		super.key,
		required this.tags,
	});

	String to_string() {
		return tags.join(', ');
	}

	@override
	State<Tags> createState() => _TagsState();
}
class _TagsState extends State<Tags> {
	bool _isAddButtonPressed = false;

	@override
	Widget build(BuildContext context) {
		return Container(
			width: double.infinity,
			margin: const .all(10),
			padding: const .all(10),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainerHighest,
				borderRadius: .circular(8),
			),
			child: Column(
				crossAxisAlignment: .start,
				children: [
					Align(
						alignment: .centerRight,
						child: Text(AppLocalizations.of(context)!.editorTags),
					),
					const SizedBox(height: 10),

					Wrap(
						spacing: 5,
						runSpacing: 5,
						children: [
							...widget.tags.asMap().entries.map((entry) {
								final index = entry.key;
								final tag = entry.value;

								return Tag(
									key: UniqueKey(),
									value: tag,
									requestFocus: (_isAddButtonPressed && index == (widget.tags.length - 1)),
									onChanged: (value) => widget.tags[index] = value,
									onSubmitted: (value) {
										if (value.isEmpty)
											setState(() {
												widget.tags.removeAt(index);
												_isAddButtonPressed = false;
											});
										else
											widget.tags[index] = value;
									},
								);
							}),

							IconButton(
								icon: Icon(Icons.add),
								onPressed: () => setState(() {
									widget.tags.add('');
									_isAddButtonPressed = true;
								}),
							),
						],
					),
				],
			),
		);
	}
}
class Tag extends StatefulWidget {
	final String value;
	final bool requestFocus;
	final Function(String) onChanged;
	final Function(String) onSubmitted;

	const Tag({
		super.key,
		required this.value,
		required this.requestFocus,
		required this.onChanged,
		required this.onSubmitted,
	});

	@override
	State<Tag> createState() => _TagState();
}
class _TagState extends State<Tag> {
	late final TextEditingController _controller;
	late final FocusNode _focusNode;

	@override
	void initState() {
		super.initState();
		_controller = TextEditingController(text: widget.value);
		_focusNode = FocusNode();

		if (widget.requestFocus)
			_focusNode.requestFocus();
	}

	@override
	void dispose() {
		_controller.dispose();
		_focusNode.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return IntrinsicWidth(
			child: Container(
				padding: const .symmetric(horizontal: 10),
				decoration: BoxDecoration(
					color: Theme.of(context).colorScheme.surface,
					borderRadius: .circular(8),
				),
				child: Row(
					children: [
						Text('#'),

						Expanded(
							child: TextField(
								controller: _controller,
								focusNode: _focusNode,
								decoration: InputDecoration(
									border: .none,
									contentPadding: const .all(0),
									constraints: BoxConstraints(
										minWidth: 10,
									),
								),
								onChanged: (value) => widget.onChanged(value),
								onSubmitted: (value) {
									_focusNode.unfocus();
									widget.onSubmitted(value);
								},
							),
						),
					],
				),
			),
		);
	}
}

import 'package:flutter/material.dart';


class LineContainer extends StatelessWidget {
	final Widget child;
	final Widget title;

	const LineContainer({
		super.key,
		required this.child,
		required this.title,
	});


	@override
	Widget build(BuildContext context) {
		return Container(
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
						child: title,
					),

					const SizedBox(height: 10),
					child,
				],
			),
		);
	}
}

class ManyLineTextField extends StatelessWidget {
	final TextEditingController controller;
	final TextStyle style;
	final Function(String) onChanged;

	const ManyLineTextField({
		super.key,
		required this.controller,
		required this.style,
		required this.onChanged,
	});

	@override
	Widget build(BuildContext context) {
		return TextField(
			controller: controller,
			style: style,
			maxLines: null,
			expands: true,
			selectionWidthStyle: .tight,
			decoration: const InputDecoration(
				border: InputBorder.none,
				contentPadding: .all(0),
				isCollapsed: true,
			),
			onChanged: onChanged,
		);
	}
}
class OneLineTextField extends StatelessWidget {
	final TextEditingController controller;
	final TextStyle style;
	final Function(String) onChanged;
	final String? label;

	const OneLineTextField({
		super.key,
		required this.controller,
		required this.style,
		required this.onChanged,
		this.label,
	});

	@override
	Widget build(BuildContext context) {
		return TextField(
			controller: controller,
			style: style,
			selectionWidthStyle: .tight,
			decoration: InputDecoration(
				border: OutlineInputBorder(
					borderRadius: .circular(8),
				),
				labelText: label,
			),
			onChanged: onChanged,
		);
	}
}

class MenuButton extends StatelessWidget {
	final String label;
	final Map<String, VoidCallback> options;

	const MenuButton({
		super.key,
		required this.label,
		required this.options,
	});


	@override
	Widget build(BuildContext context) => MenuAnchor(
		animated: true,
		builder: (context, controller, child) => TextButton(
			child: Text(label),
			onPressed: () {
				if (controller.isOpen) {
					controller.close();
				} else {
					controller.open();
				}
			},
			style: TextButton.styleFrom(
				foregroundColor: Theme.of(context).colorScheme.onSurface,
			),
		),
		menuChildren: options.entries.map((entry) => MenuItemButton(
			child: Text(entry.key),
			onPressed: entry.value,
		)).toList(),
	);
}

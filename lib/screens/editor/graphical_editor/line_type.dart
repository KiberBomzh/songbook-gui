import 'package:flutter/material.dart';

import 'package:songbook/l10n/app_localizations.dart';


enum LineType {
	textBlock,
	chordsLine,
	noteLine,
	plainText,
	tab,
	emptyLine;

	String to_string(BuildContext context) {
		return switch(this) {
			LineType.textBlock => AppLocalizations.of(context)!.editorRow,
			LineType.chordsLine => AppLocalizations.of(context)!.editorChordsLine,
			LineType.noteLine => AppLocalizations.of(context)!.editorNoteLine,
			LineType.plainText => AppLocalizations.of(context)!.editorPlainText,
			LineType.tab => AppLocalizations.of(context)!.editorTab,
			LineType.emptyLine => AppLocalizations.of(context)!.editorEmptyLine,
		};
	}
}
class SelectLineType extends StatelessWidget {
	const SelectLineType({super.key});

	@override
	Widget build(BuildContext context) {
		final colorScheme = Theme.of(context).colorScheme;

		return IntrinsicHeight(
			child: Material(
				color: colorScheme.surfaceContainerHighest,
				shape: RoundedRectangleBorder(
					borderRadius: .circular(12),
				),
				clipBehavior: .antiAlias,
				child: Column(
					mainAxisAlignment: .start,
					children: [
						...LineType.values.map((value) => InkWell(
							onTap: () => Navigator.of(context).pop(value),
							child: Container(
								width: double.infinity,
								padding: const .all(10),
								margin: const .all(5),
								child: Text(value.to_string(context)),
							),
						)),

						SizedBox(height: MediaQuery.of(context).padding.bottom), // safe area
					],
				),
			),
		);
	}
}

import 'package:flutter/material.dart';

import 'package:songbook/l10n/app_localizations.dart';

import 'package:songbook/functions/parse_key_value_line.dart';


class ShowOptions extends StatefulWidget {
	bool chords;
	bool rhythm;
	bool notes;
	bool fingerings;

	ShowOptions({
		super.key,
		this.chords = true,
		this.rhythm = true,
		this.notes = true,
		this.fingerings = false,
	});

	String to_string() {
		String result = '';

		if (chords)
			result += 'c ';

		if (rhythm)
			result += 'r ';

		if (notes)
			result += 'n ';

		if (fingerings)
			result += 'f ';

		return result;
	}

	void from_string(String line) {
		final result = parseKeyValueLine(line);
		if (result == null) {
			this.chords = false;
			this.rhythm = false;
			this.notes = false;
			this.fingerings = false;
			return;
		}

		final opts = result;
		this.chords = opts.contains('c');
		this.rhythm = opts.contains('r');
		this.notes = opts.contains('n');
		this.fingerings = opts.contains('f');
	}


	@override
	State<ShowOptions> createState() => _ShowOptionsState();
}
class _ShowOptionsState extends State<ShowOptions> {
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
			child: Material(
				color: Theme.of(context).colorScheme.surfaceContainerHighest,
				child: Column(
					children: [
						Align(
							alignment: .centerRight,
							child: Text(AppLocalizations.of(context)!.editorShowOptions),
						),
						const SizedBox(height: 10),


						CheckboxListTile(
							title: Text(AppLocalizations.of(context)!.chords),
							value: widget.chords,
							onChanged: (bool? value) {
								if (value != null)
									setState(() => widget.chords = value);
							}
						),
						CheckboxListTile(
							title: Text(AppLocalizations.of(context)!.rhythm),
							value: widget.rhythm,
							onChanged: (bool? value) {
								if (value != null)
									setState(() => widget.rhythm = value);
							}
						),
						CheckboxListTile(
							title: Text(AppLocalizations.of(context)!.notes),
							value: widget.notes,
							onChanged: (bool? value) {
								if (value != null)
									setState(() => widget.notes = value);
							}
						),
						CheckboxListTile(
							title: Text(AppLocalizations.of(context)!.fingerings),
							value: widget.fingerings,
							onChanged: (bool? value) {
								if (value != null)
									setState(() => widget.fingerings = value);
							}
						),
					],
				),
			),
		);
	}
}

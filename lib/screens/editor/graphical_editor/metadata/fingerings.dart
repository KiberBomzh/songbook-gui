import 'package:flutter/material.dart';

import 'package:songbook/l10n/app_localizations.dart';


class Fingerings extends StatefulWidget {
	List<(String, String)> fingerings;

	Fingerings({
		super.key,
		required this.fingerings,
	});

	static Fingerings from_string(String s) {
		final List<(String, String)> fingerings = [];
		for (final line in s.split('\n')) {
			final index = line.indexOf('\t');
			if (index < 0)
				continue;

			final chord = line.substring(0, index).trim();
			final fingering = line.substring(index + 1).trim();

			fingerings.add( (chord, fingering) );
		}

		return Fingerings(fingerings: fingerings);
	}
	String to_string() {
		String result = "";

		for (final (chord, fingering) in fingerings) {
			result += chord + '\t' + fingering + '\n';
		}

		return result;
	}

	@override
	State<Fingerings> createState() => _FingeringsState();
}
class _FingeringsState extends State<Fingerings> {
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
						child: Text(AppLocalizations.of(context)!.editorFingerings),
					),
					const SizedBox(height: 10),

					...widget.fingerings.map<Widget>((entry) {
						final index = widget.fingerings.indexOf(entry);

						return Dismissible(
							key: UniqueKey(),
							onDismissed: (_) => setState(() {
								widget.fingerings.removeAt(index);
								_isAddButtonPressed = false;
							}),
							child: Container(
								width: double.infinity,
								margin: const .symmetric(vertical: 5, horizontal: 20),
								padding: const .all(10),
								decoration: BoxDecoration(
									color: Theme.of(context).colorScheme.surface,
									borderRadius: .circular(8),
								),
								child: Fingering(
									key: UniqueKey(),
									requestFocus: (_isAddButtonPressed && index == widget.fingerings.length - 1),
									chord: entry.$1,
									fingering: entry.$2,
									onChangedChord: (value) =>
										widget.fingerings[index] = (value, widget.fingerings[index].$2),
									onChangedFingering: (value) =>
										widget.fingerings[index] = (widget.fingerings[index].$1, value),
								),
							),
						);
					}),

					Material(
						color: Colors.transparent,
						clipBehavior: .antiAlias,
						shape: RoundedRectangleBorder(
							borderRadius: .circular(8),
						),
						child: InkWell(
							onTap: () => setState(() {
								widget.fingerings.add(('', ''));
								_isAddButtonPressed = true;
							}),
							child: Padding(
								padding: const .symmetric(vertical: 10),
								child: Center(
									child: Icon(Icons.add),
								),
							),
						),
					),
				],
			),
		);
	}
}
class Fingering extends StatefulWidget {
	final String chord;
	final String fingering;
	final Function(String) onChangedChord;
	final Function(String) onChangedFingering;
	final bool requestFocus;

	const Fingering({
		super.key,
		required this.chord,
		required this.fingering,
		required this.onChangedChord,
		required this.onChangedFingering,
		required this.requestFocus,
	});

	@override
	State<Fingering> createState() => _FingeringState();
}
class _FingeringState extends State<Fingering> {
	late final TextEditingController _chordController;
	late final FocusNode _chordFocus;
	late final TextEditingController _fingeringController;
	late final FocusNode _fingeringFocus;

	@override
	void initState() {
		super.initState();
		_chordController = TextEditingController(text: widget.chord);
		_chordFocus = FocusNode();
		if (widget.requestFocus)
			_chordFocus.requestFocus();

		_fingeringController = TextEditingController(text: widget.fingering);
		_fingeringFocus = FocusNode();
	}

	@override
	void dispose() {
		_chordController.dispose();
		_chordFocus.dispose();
		_fingeringController.dispose();
		_fingeringFocus.dispose();

		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Row(
			children: [
				IntrinsicWidth(
					child: TextField(
						controller: _chordController,
						focusNode: _chordFocus,
						onChanged: (value) => widget.onChangedChord(value),
						onSubmitted: (_) => _fingeringFocus.requestFocus(),
						decoration: InputDecoration(
							border: OutlineInputBorder(
								borderRadius: .circular(8),
							),
						),
					),
				),

				const SizedBox(width: 10),

				Expanded(
					child: TextField(
						controller: _fingeringController,
						focusNode: _fingeringFocus,
						onChanged: (value) => widget.onChangedFingering(value),
						onSubmitted: (_) => _fingeringFocus.unfocus(),
						decoration: InputDecoration(
							border: OutlineInputBorder(
								borderRadius: .circular(8),
							),
						),
					),
				),
			],
		);
	}
}

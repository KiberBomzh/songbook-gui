import 'package:flutter/material.dart';

import 'package:songbook/src/rust/api/theory.dart';


class Fretboard extends StatefulWidget {
	int fret;

	Fretboard({
		super.key,
		required this.fret,
	});

	@override
	State<Fretboard> createState() => _FretboardState();
}
class _FretboardState extends State<Fretboard> {
	final fretboard = getFretboard(tuning: getStandartTuning());


	(double, double) _getSize() {
		final textPainter = TextPainter(
			text: TextSpan(text: 'W'),
			textDirection: TextDirection.ltr,
		)..layout();
		final width = textPainter.width * 2 + 2;
		final height = textPainter.height + 30;

		return (width, height);
	}

	@override
	Widget build(BuildContext context) {
		final (width, height) = _getSize();
		final borderColor =  Theme.of(context).colorScheme.outlineVariant;

		return SingleChildScrollView(
			child: Stack(
				alignment: .topCenter,
				children: [
					Row(
						mainAxisAlignment: .center,
						children: fretboard.reversed.map((string) => Stack(
							alignment: .topCenter,
							children: [
								Container(
									margin: .only(top: height),
									color: borderColor,
									width: 2,
									height: 24 * height,
								),
								Column(
									children: string.asMap().keys.map((index) {
										final top = BorderSide(width: 3, color: borderColor);
										final fret = BorderSide(width: 2, color: borderColor);


										if (index == 0)
											return Container(
												width: width,
												height: height - 2,
												margin: .only(bottom: 2),
												decoration: BoxDecoration(
													border: Border(
														bottom: top,
													),
												),
											);


										if (index == 1)
											return Container(
												width: width,
												height: height,
												decoration: BoxDecoration(
													border: Border(
														top: top,
														bottom: fret,
													),
												),
											);


										return Container(
											width: width,
											height: height,
											decoration: BoxDecoration(
												border: Border(
													bottom: fret,
												),
											),
										);
									}).toList()
								),

								Column(
									children: string.map((note) => SizedBox(
										width: width,
										height: height,
										child: Center(
											child: Text(note.toString()),
										),
									)).toList(),
								),
							],
						)).toList(),
					),

					Material(
						color: Colors.transparent,
						child: Column(
							children: fretboard[0].asMap().keys.map((index) {
								if (widget.fret == index) {
									return Container(
										decoration: BoxDecoration(
											borderRadius: .circular(8),
											color: Colors.grey.withValues(alpha: 0.1),
										),
										width: double.infinity,
										height: height,
										padding: const .only(left: 5),
										child: Align(
											alignment: .centerLeft,
											child: Text(index.toString()),
										),
									);
								}

								return SizedBox(
									height: height,
									width: double.infinity,
									child: InkWell(
										borderRadius: .circular(8),
										onTap: () => setState(() => widget.fret = index),
										child: Container(
											padding: const .only(left: 5),
											child: Align(
												alignment: .centerLeft,
												child: Text(index.toString()),
											),
										),
									),
								);
							}).toList(),
						),
					),
				],
			),
		);
	}
}

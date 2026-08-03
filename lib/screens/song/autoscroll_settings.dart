import 'package:flutter/material.dart';

import 'package:songbook/l10n/app_localizations.dart';

import 'package:songbook/screens/song/song.dart';


class AutoscrollSettings extends StatefulWidget {
	double delay;
	double speed;

	AutoscrollSettings({
		super.key,
		required this.delay,
		required this.speed,
	});

	@override
	State<AutoscrollSettings> createState() => _AutoscrollSettingsState();
}
class _AutoscrollSettingsState extends State<AutoscrollSettings> {
	@override
	void initState() {
		super.initState();
		if (widget.delay > MaxAutoscrollDelay)
			widget.delay = MaxAutoscrollDelay.toDouble();
		else if (widget.delay < 0)
			widget.delay = 0;

		if (widget.speed > MaxAutoscrollSpeed)
			widget.speed = MaxAutoscrollSpeed.toDouble();
		else if (widget.speed < 20)
			widget.speed = 20;
	}

	@override
	Widget build(BuildContext context) => IntrinsicHeight(
		child: Column(
			children: [
				Container(
					padding: .all(10),
					decoration: BoxDecoration(
						color: Theme.of(context).colorScheme.surfaceContainer,
						borderRadius: .circular(8),
					),
					child: Column(
						children: [
							Row(
								mainAxisAlignment: .spaceBetween,
								children: [
									Text(AppLocalizations.of(context)!.songAutoscrollDelay),
									Text(widget.delay.floor().toString() + AppLocalizations.of(context)!.songSecondsShort),
								],
							),
							Slider(
								value: widget.delay,
								min: 0,
								max: MaxAutoscrollDelay.toDouble(),
								divisions: 61,
								onChanged: (value) {
									setState(() => widget.delay = value);
								},
							),
						],
					),
				),

				const SizedBox(height: 10),

				Container(
					padding: .all(10),
					decoration: BoxDecoration(
						color: Theme.of(context).colorScheme.surfaceContainer,
						borderRadius: .circular(8),
					),
					child: Column(
						children: [
							Row(
								mainAxisAlignment: .spaceBetween,
								children: [
									Text(AppLocalizations.of(context)!.songAutoscrollSpeed),
									Text(widget.speed.floor().toString() + AppLocalizations.of(context)!.songMillisecondsShort),
								],
							),
							Slider(
								value: widget.speed,
								min: 20,
								max: MaxAutoscrollSpeed.toDouble(),
								divisions: ((MaxAutoscrollSpeed - 20) / MinimalAutoscrollSpeedStep).floor(),
								onChanged: (value) {
									setState(() => widget.speed = value);
								},
							),
						],
					),
				),
			]
		),
	);
}

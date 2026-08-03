import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:songbook/src/rust/api/theory.dart';


class CircleOfFifth extends StatefulWidget {
	final SimpleKey? simpleKey;
	final double size;

	const CircleOfFifth({
		super.key,
		required this.simpleKey,
		required this.size,
	});

	@override
	State<CircleOfFifth> createState() => CircleOfFifthState();
}

class CircleOfFifthState extends State<CircleOfFifth> {
	final _keys = getAllKeys();
	final List<SimpleKey> _keysNearby = [];
	late SimpleKey? currentKey;

	@override
	void initState() {
		super.initState();

		currentKey = widget.simpleKey;
		for (final k in _keys) {
			if (widget.simpleKey.toString() == k.toString()) {
				currentKey = k;
				break;
			}
		}

		_updateKeysNearby();
	}

	void _updateKeysNearby() {
		if (currentKey == null)
			return;


		final index = _keys.indexOf(currentKey!);
		_keysNearby.clear();

		final stepsBackward = currentKey!.isMinor() ? 3 : 2;
		for (int step = stepsBackward; step > 0; step--) {
			int stepIndex = index - step;
			if (stepIndex < 0)
				stepIndex += _keys.length;

			_keysNearby.add(_keys[stepIndex]);
		}


		final stepsForward = currentKey!.isMinor() ? 2 : 3;
		for (int step = 1; step <= stepsForward; step++) {
			int stepIndex = index + step;
			if (stepIndex > _keys.length - 1)
				stepIndex -= _keys.length;

			_keysNearby.add(_keys[stepIndex]);
		}
	}

	@override
	Widget build(BuildContext context) {
		final size = widget.size;
    

		final double majorRadius = size * 0.411;
		final double minorRadius = size * 0.25;
		final double centerOffset = size / 2;
    
		final double majorButtonSize = size * 0.15;
		final double minorButtonSize = size * 0.11;
		final double fontSize = size * 0.045;

		return SizedBox(
			height: size,
			width: size,
			child: Center(
				child: Stack(
					alignment: .center,
					children: [
						CustomPaint(
							size: Size(size, size),
							painter: CirclePainter(),
						),
            

						...List.generate(12, (index) {
							final angle = _getAngle(index);
							final key = _getMajorKey(index);
							final double x = centerOffset + majorRadius * math.cos(angle) - (majorButtonSize / 2);
							final double y = centerOffset + majorRadius * math.sin(angle) - (majorButtonSize / 2);

							return Positioned(
								left: x,
								top: y,
								child: _buildKeyButton(
									key: key,
									size: majorButtonSize,
									fontSize: fontSize,
									isMajor: true,
								),
							);
						}),

						...List.generate(12, (index) {
							final angle = _getAngle(index);
							final key = _getMinorKey(index);
							final double x = centerOffset + minorRadius * math.cos(angle) - (minorButtonSize / 2);
							final double y = centerOffset + minorRadius * math.sin(angle) - (minorButtonSize / 2);
              
							return Positioned(
								left: x,
								top: y,
								child: _buildKeyButton(
									key: key,
									size: minorButtonSize,
									fontSize: fontSize * 0.75,
									isMajor: false,
								),
							);
						}),
					],
				),
			),
		);
	}

	Widget _buildKeyButton({
		required SimpleKey key,
		required double size,
		required double fontSize,
		required bool isMajor,
	}) {
		final isSelected = (currentKey == key);
		final isNearby = _keysNearby.contains(key);

		final colorScheme = Theme.of(context).colorScheme;
		final background = isSelected
			? colorScheme.primaryContainer
			: isNearby
				? colorScheme.tertiaryContainer
				: colorScheme.surfaceContainerHighest;
		final color = isSelected
			? colorScheme.onPrimaryContainer
			: isNearby
				? colorScheme.onTertiaryContainer
				: colorScheme.onSurface;
    
		return Material(
			color: background,
			shape: CircleBorder(),
			clipBehavior: .antiAlias,
			child: InkWell(
				onTap: () => setState(() {
					currentKey = key;
					_updateKeysNearby();
				}),
				child: Container(
					width: size,
					height: size,
					decoration: BoxDecoration(
						shape: BoxShape.circle,
					),
					child: Center(
						child: Text(
							key.toString(),
							style: TextStyle(
								color: color,
								fontSize: fontSize,
							),
						),
					),
				),
			),
		);
	}

	double _getAngle(int index) => -math.pi / 2 + (index * math.pi / 6);

	SimpleKey _getMajorKey(int index) => _keys[index * 2];
	SimpleKey _getMinorKey(int index) => _keys[index * 2 + 1];
}

class CirclePainter extends CustomPainter {
	@override
	void paint(Canvas canvas, Size size) {
		final center = Offset(size.width / 2, size.height / 2);
		final radius = (size.width / 2);
		final paint = Paint()
			..color = Colors.grey
			..strokeWidth = 2
			..style = PaintingStyle.stroke;

		canvas.drawCircle(center, radius, paint);

		final innerRadius = radius * 0.65;
		canvas.drawCircle(center, innerRadius, paint);

		final innerInnerRadius = radius * 0.35;
		canvas.drawCircle(center, innerInnerRadius, paint);

		for (int i = 0; i < 12; i++) {
			final angle = -math.pi / 2 + (i * math.pi / 6) + math.pi / 12;
			final startX = center.dx + innerInnerRadius * math.cos(angle);
			final startY = center.dx + innerInnerRadius * math.sin(angle);
			final endX = center.dx + radius * math.cos(angle);
			final endY = center.dy + radius * math.sin(angle);
			canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
		}
    
	}

	@override
	bool shouldRepaint(CustomPainter oldDelegate) => false;
}

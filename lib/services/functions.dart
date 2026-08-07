import 'package:flutter/material.dart';


Color? stringToColor(String? colorStr) {
	if (colorStr == null) {
		return null;
	}

	if (colorStr.startsWith('#')) {
		return Color(int.parse(colorStr.substring(1), radix: 16));
	}

	return switch (colorStr) {
		'red' => Colors.red,
		'pink' => Colors.pink,
		'purple' => Colors.purple,
		'deepPurple' => Colors.deepPurple,
		'indigo' => Colors.indigo,
		'blue' => Colors.blue,
		'lightBlue' => Colors.lightBlue,
		'cyan' => Colors.cyan,
		'green' => Colors.green,
		'lightGreen' => Colors.lightGreen,
		'lime' => Colors.lime,
		'yellow' => Colors.yellow,
		'amber' => Colors.amber,
		'orange' => Colors.orange,
		'deepOrange' => Colors.deepOrange,
		'brown' => Colors.brown,
		_ => null
	};
}
bool? boolFromString(String? value) {
	if (value == 'true') {
		return true;
	} else if (value == 'false') {
		return false;
	} else {
		return null;
	}
}
double? doubleFromString(String? value) {
	if (value == null)
		return null;
	else
		return double.tryParse(value);
}

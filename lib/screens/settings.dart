import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:songbook/services/settings.dart';


class SettingsScreen extends StatefulWidget {
	SettingsScreen({super.key});

	@override
	State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
	late SettingsProvider _settings;

	late ThemeMode _currentTheme;
	late Color _currentAccent;


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();
		_currentTheme = _settings.themeMode;
		_currentAccent = _settings.colorAccent;

		return Scaffold(
			appBar: AppBar( title: Text('Settings') ),
			body: _buildBody(),
		);
	}

	Widget _buildBody() {
		return Material(
			child: Padding(
				padding: const EdgeInsets.symmetric(vertical: 5),
				child: ListView(
					children: [
						_buildItem(
							text: 'Theme',
							child: SegmentedButton<ThemeMode>(
								segments: const <ButtonSegment<ThemeMode>>[
									ButtonSegment<ThemeMode>(
										value: ThemeMode.light,
										label: Icon(Icons.light_mode),
									),
									ButtonSegment<ThemeMode>(
										value: ThemeMode.system,
										label: Text('Auto'),
									),
									ButtonSegment<ThemeMode>(
										value: ThemeMode.dark,
										label: Icon(Icons.dark_mode),
									),
								],
								selected: <ThemeMode>{_currentTheme},
								onSelectionChanged: (newSelection) => _settings.setThemeMode(newSelection.first),
								selectedIcon: Container(),
							),
							onTap: null,
						),

						_buildItem(
							text: 'Accent',
							child: ListView(
								scrollDirection: Axis.horizontal,
								shrinkWrap: true,
								children: [
									_buildColorItem(
										color: Colors.blue,
										text: 'blue',
									),
									_buildColorItem(
										color: Colors.green,
										text: 'green',
									),
									_buildColorItem(
										color: Colors.yellow,
										text: 'yellow',
									),
									_buildColorItem(
										color: Colors.orange,
										text: 'orange',
									),
									_buildColorItem(
										color: Colors.brown,
										text: 'brown',
									),
									_buildColorItem(
										color: Colors.red,
										text: 'red',
									),
									_buildColorItem(
										color: Colors.purple,
										text: 'purple',
									),
								],
							),
							onTap: null,
						),

						_buildItem(
							text: 'Reset',
							child: null,
							onTap: () => _settings.resetToDefault(),
						),
					],
				),
			),
		);
	}

	Widget _buildItem({
		required VoidCallback? onTap,
		required String text,
		required Widget? child,
	}) {
		final primary = Theme.of(context).colorScheme.primary;
		return InkWell(
			onTap: onTap,
			splashColor: primary.withOpacity(0.1),
			highlightColor: primary.withOpacity(0.05),
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 15),
				child: SizedBox(
					height: 50,
					child: Row(
						mainAxisAlignment: .spaceBetween,
						children: [
							Text(text),
							const SizedBox(width: 100),
							if (child != null)
								Flexible(child: child!),
						],
					),
				),
			),
		);
	}

	Widget _buildColorItem({
		required Color color,
		required String text,
	}) {
		return Container(
			margin: const EdgeInsets.symmetric(horizontal: 5),
			child: IconButton(
				icon: Icon(Icons.check),
				color: (_currentAccent == color)
					? Theme.of(context).colorScheme.onPrimary
					: Colors.transparent,
				onPressed: () => _settings.setColorAccent(text),
				style: IconButton.styleFrom(
					backgroundColor: color,
					fixedSize: Size(50, 50),
				),
			),
		);
	}
}

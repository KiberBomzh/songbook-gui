import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

import 'package:songbook/services/settings.dart';


class SettingsScreen extends StatefulWidget {
	SettingsScreen({super.key});

	@override
	State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
	late SettingsProvider _settings;

	List<ColorItem> _colors = [
		ColorItem(
			color: Colors.red,
			value: 'red',
		),
		ColorItem(
			color: Colors.purple,
			value: 'purple',
		),
		ColorItem(
			color: Colors.blue,
			value: 'blue',
		),
		ColorItem(
			color: Colors.green,
			value: 'green',
		),
		ColorItem(
			color: Colors.yellow,
			value: 'yellow',
		),
		ColorItem(
			color: Colors.orange,
			value: 'orange',
		),
		ColorItem(
			color: Colors.brown,
			value: 'brown',
		),
	];


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();

		return Scaffold(
			appBar: AppBar( title: Text('Settings') ),
			body: _buildBody(),
		);
	}

	Widget _buildBody() {
		return Material(
			color: Theme.of(context).colorScheme.surfaceContainer,
			child: ListView(
				children: [
					_buildTitle('Global'),

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
							selected: <ThemeMode>{_settings.themeMode},
							onSelectionChanged: (newSelection) => _settings.setThemeMode(newSelection.first),
							selectedIcon: Container(),
						),
						onTap: null,
					),

					_buildItem(
						text: 'Accent',
						child: ListView.builder(
							scrollDirection: Axis.horizontal,
							shrinkWrap: true,
							itemCount: _colors.length,
							itemBuilder: (context, index) {
								final colorItem = _colors[index];

								return colorItem.build(
									context: context,
									isSelected: (colorItem.color == _settings.colorAccent),
									onTap: _settings.setColorAccent,
								);
							},
						),
						onTap: null,
					),


					_buildTitle('Editor'),

					_buildItem(
						text: 'Font size',
						child: Text(_settings.editorFontSize.toString()),
						onTap: () async {
							final String? newSizeStr = await _askDialog(
								context: context,
								validator: _fontSizeValidator,
								title: 'Song font size',
								initialValue: _settings.editorFontSize.toString(),
								hintText: 'Font size...',
							);
							if (newSizeStr != null) {
								final newSize = double.parse(newSizeStr);
								await _settings.setEditorFontSize(newSize!);
							}
						},
					),

					
					_buildTitle('Song'),

					_buildItem(
						text: 'Line wrap',
						child: Switch(
							value: _settings.lineWrapInSong,
							onChanged: _settings.setLineWrapInSong,
						),
						onTap: null,
					),

					_buildItem(
						text: 'Font size',
						child: Text(_settings.songFontSize.toString()),
						onTap: () async {
							final String? newSizeStr = await _askDialog(
								context: context,
								validator: _fontSizeValidator,
								title: 'Song font size',
								initialValue: _settings.songFontSize.toString(),
								hintText: 'Font size...',
							);
							if (newSizeStr != null) {
								final newSize = double.parse(newSizeStr);
								await _settings.setSongFontSize(newSize!);
							}
						},
					),

					_buildItem(
						text: 'Chords color',
						child: Row(
							mainAxisAlignment: .end,
							children: [
								ElevatedButton(
									child: Text('Reset'),
									onPressed: (Preferences.getString(CHORDS_COLOR) != null)
										? () => _settings.setChordsColor(null)
										: null,
									style: ElevatedButton.styleFrom(
										backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
									),
								),

								const SizedBox(width: 5),

								ColorItem(
									color: _settings.chordsColor(context),
									value: '',
								).build(
									context: context,
									isSelected: false,
									onTap: (_) async {
										final String? newColor = await _showColorPickerDialog(
											context: context,
											initialColor: _settings.chordsColor(context),
										);
										await _settings.setChordsColor(newColor);
									}
								)
							],
						),
						onTap: null,
					),

					_buildItem(
						text: 'Rhythm color',
						child: Row(
							mainAxisAlignment: .end,
							children: [
								ElevatedButton(
									child: Text('Reset'),
									onPressed: (Preferences.getString(RHYTHM_COLOR) != null)
										? () => _settings.setRhythmColor(null)
										: null,
									style: ElevatedButton.styleFrom(
										backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
									),
								),

								const SizedBox(width: 5),

								ColorItem(
									color: _settings.rhythmColor(context),
									value: '',
								).build(
									context: context,
									isSelected: false,
									onTap: (_) async {
										final String? newColor = await _showColorPickerDialog(
											context: context,
											initialColor: _settings.rhythmColor(context),
										);
										await _settings.setRhythmColor(newColor);
									}
								)
							],
						),
						onTap: null,
					),

					_buildItem(
						text: 'Text color',
						child: Row(
							mainAxisAlignment: .end,
							children: [
								ElevatedButton(
									child: Text('Reset'),
									onPressed: (Preferences.getString(TEXT_COLOR) != null)
										? () => _settings.setTextColor(null)
										: null,
									style: ElevatedButton.styleFrom(
										backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
									),
								),

								const SizedBox(width: 5),

								ColorItem(
									color: _settings.textColor(context),
									value: '',
								).build(
									context: context,
									isSelected: false,
									onTap: (_) async {
										final String? newColor = await _showColorPickerDialog(
											context: context,
											initialColor: _settings.textColor(context),
										);
										await _settings.setTextColor(newColor);
									}
								)
							],
						),
						onTap: null,
					),

					_buildItem(
						text: 'Notes color',
						child: Row(
							mainAxisAlignment: .end,
							children: [
								ElevatedButton(
									child: Text('Reset'),
									onPressed: (Preferences.getString(NOTES_COLOR) != null)
										? () => _settings.setNotesColor(null)
										: null,
									style: ElevatedButton.styleFrom(
										backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
									),
								),

								const SizedBox(width: 5),

								ColorItem(
									color: _settings.notesColor(context),
									value: '',
								).build(
									context: context,
									isSelected: false,
									onTap: (_) async {
										final String? newColor = await _showColorPickerDialog(
											context: context,
											initialColor: _settings.notesColor(context),
										);
										await _settings.setNotesColor(newColor);
									}
								)
							],
						),
						onTap: null,
					),

					_buildItem(
						text: 'Title color',
						child: Row(
							mainAxisAlignment: .end,
							children: [
								ElevatedButton(
									child: Text('Reset'),
									onPressed: (Preferences.getString(TITLE_COLOR) != null)
										? () => _settings.setTitleColor(null)
										: null,
									style: ElevatedButton.styleFrom(
										backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
									),
								),

								const SizedBox(width: 5),

								ColorItem(
									color: _settings.titleColor(context),
									value: '',
								).build(
									context: context,
									isSelected: false,
									onTap: (_) async {
										final String? newColor = await _showColorPickerDialog(
											context: context,
											initialColor: _settings.titleColor(context),
										);
										await _settings.setTitleColor(newColor);
									}
								)
							],
						),
						onTap: null,
					),

					_buildItem(
						text: 'Background',
						child: Row(
							mainAxisAlignment: .end,
							children: [
								ElevatedButton(
									child: Text('Reset'),
									onPressed: (Preferences.getString(BACKGROUND_COLOR) != null)
										? () => _settings.setBackgroundColor(null)
										: null,
									style: ElevatedButton.styleFrom(
										backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
									),
								),

								const SizedBox(width: 5),

								ColorItem(
									color: _settings.backgroundColor(context),
									value: '',
								).build(
									context: context,
									isSelected: false,
									onTap: (_) async {
										final String? newColor = await _showColorPickerDialog(
											context: context,
											initialColor: _settings.backgroundColor(context),
										);
										await _settings.setBackgroundColor(newColor);
									}
								)
							],
						),
						onTap: null,
					),


					_buildTitle('Other'),

					_buildItem(
						text: 'Reset',
						child: null,
						onTap: () => _settings.resetToDefault(),
					),
				],
			),
		);
	}

	Widget _buildTitle(String text) {
		return Container(
			color: Theme.of(context).colorScheme.surface,
			padding: const EdgeInsets.only(
				left: 15,
				right: 15,
				top: 25,
				bottom: 5,
			),
			child: Text(text, style: Theme.of(context).textTheme.titleLarge),
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
				padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
				child: SizedBox(
					height: 50,
					child: Row(
						mainAxisAlignment: .spaceBetween,
						children: [
							SizedBox(
								width: 100,
								child: Text(text),
							),
							const SizedBox(width: 20),
							if (child != null)
								Flexible(child: child!),
						],
					),
				),
			),
		);
	}
}


Future<String?> _askDialog({
	required String? Function(String) validator,
	required BuildContext context,
	required String title,
	String initialValue = '',
	String hintText = 'Type something...'
}) {
	final controller = TextEditingController();
	controller.text = initialValue;

	String? errorText;

	return showDialog<String>(
		context: context,
		builder: (context) => StatefulBuilder(
			builder: (context, setState) => AlertDialog(
				title: Text(title),
				content: TextField(
					controller: controller,
					autofocus: true,
					decoration: InputDecoration(
						hintText: hintText,
						errorText: errorText,
						border: const OutlineInputBorder(),
					),
					onChanged: (value) => setState(() => errorText = validator(value)),
					onSubmitted: (value) {
						final checkResult = validator(value);

						if (checkResult != null) {
							setState(() => errorText = checkResult);
						} else {
							Navigator.of(context).pop(value.trim());
						}
					},
				),
				actions: [
					TextButton(
						child: Text('Cancel'),
						onPressed: () => Navigator.of(context).pop(),
					),
					ElevatedButton(
						child: Text('Ok'),
						onPressed: () {
							final value = controller.text;
							final checkResult = validator(value);

							if (checkResult != null) {
								setState(() => errorText = checkResult);
							} else {
								Navigator.of(context).pop(value.trim());
							}
						},
					),
				],
			),
		),
	);
}

String? _fontSizeValidator(String text) {
	final value = text.trim();
	final double? result = double.tryParse(value);

	if (result == null) {
		return 'Not valid input!';
	} else {
		if (result! < 1) {
			return 'Value must be bigger than 0!';
		} else if (result! >= 100) {
			return 'Value must be smaller than 100!';
		} else {
			return null;
		}
	}
}


class ColorItem {
	final Color color;
	final String value;

	const ColorItem({
		required this.color,
		required this.value,
	});


	Widget build({
		required BuildContext context,
		required bool isSelected,
		required Function(String) onTap,
	}) {
		return Container(
			margin: const EdgeInsets.symmetric(horizontal: 5),
			child: IconButton(
				icon: Icon(Icons.check),
				color: (isSelected)
					? Theme.of(context).colorScheme.onPrimary
					: Colors.transparent,
				onPressed: () => onTap(value),
				style: IconButton.styleFrom(
					backgroundColor: color,
					fixedSize: Size(50, 50),
				),
			),
		);
	}
}


Future<String?> _showColorPickerDialog({
	required BuildContext context,
	required Color initialColor,
}) async {
	Color dialogPickerColor = initialColor;
  
	final bool result = await ColorPicker(
		color: dialogPickerColor,
		onColorChanged: (color) => dialogPickerColor = color,
		enableOpacity: true,
		showColorCode: true,
		pickersEnabled: const {
			ColorPickerType.wheel: true,
			ColorPickerType.primary: true,
			ColorPickerType.accent: true,
		},
		actionButtons: const ColorPickerActionButtons(
			okButton: true,
			closeButton: true,
			dialogActionButtons: false,
		),
	).showPickerDialog(
		context,
		constraints: const BoxConstraints(
			minHeight: 480, minWidth: 320, maxWidth: 320,
		),
	);

	if (!result)
		return null;
	else
		return '#${dialogPickerColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

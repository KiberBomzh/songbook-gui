import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:restart_app/restart_app.dart';

import 'package:songbook/services/settings.dart';


class SettingsScreen extends StatefulWidget {
	SettingsScreen({super.key});

	@override
	State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
	late SettingsProvider _settings;


	bool _isLoading = false;


	void _exportBackup() async {
		setState(() => _isLoading = true);
		try {
			final bool result = await _settings.exportBackup();
			if (result)
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(
						content: Text('Succes!'),
						duration: Duration(seconds: 1),
					),
				);
		} catch (e) {
			debugPrint(e.toString());
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text('Error!'),
					duration: Duration(seconds: 3),
				),
			);
		}
		setState(() => _isLoading = false);
	}
	void _importBackup() async {
		try {
			final bool result = await _settings.importBackup();
			if (result) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(
						content: Text('Succes, songbook needs to restart!'),
						duration: Duration(seconds: 1),
					),
				);
				Restart.restartApp();
			}
		} catch (e) {
			debugPrint(e.toString());
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text('Error!'),
					duration: Duration(seconds: 3),
				),
			);
		}
	}

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

		return Stack(
			children: [
				Container(
					decoration: BoxDecoration(
						image: (_settings.backgroundImage != null)
							? DecorationImage(
								image: FileImage(_settings.backgroundImage!),
								fit: .cover,
							)
							: null,
					),
					child: Scaffold(
						appBar: AppBar( title: Text('Settings') ),
						body: _buildBody(),
					),
				),

				if (_isLoading)
					Container(
						color: Colors.black.withOpacity(0.5),
						child: Center(
							child: CircularProgressIndicator(),
						),
					),
			],
		);
	}

	Widget _buildBody() {
		return ListView(
			children: [
				_buildSection(_globalSection()),
				_buildSection(_editorSection()),
				_buildSection(_songSection()),
				_buildSection(_otherSection()),
			],
		);
	}

	List<Widget> _globalSection() => <Widget>[
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
						label: Icon(Icons.brightness_4),
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
			text: 'Amoled',
			child: Switch(
				value: _settings.isAmoled,
				onChanged: _settings.setAmoled,
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

		_buildItem(
			text: 'Background opacity',
			child: Text(_settings.backgroundOpacity.toString()),
			onTap: () async {
				final String? newOpacityStr = await _askDialog(
					context: context,
					validator: _backgroundOpacityValidator,
					title: 'Background opacity',
					initialValue: _settings.backgroundOpacity.toString(),
					hintText: 'Opacity...',
				);
				if (newOpacityStr != null) {
					final newOpacity = double.parse(newOpacityStr);
					await _settings.setBackgroundOpacity(newOpacity!);
				}
			},
		),

		_buildItem(
			text: 'Background image',
			child: ElevatedButton(
				child: Text('Reset'),
				onPressed: (_settings.backgroundImage != null)
					? _settings.resetBackgroundImage
					: null,
				style: ElevatedButton.styleFrom(
					backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
				),
			),
			onTap: _settings.setBackgroundImage,
		),
	];

	List<Widget> _editorSection() => [
		_buildTitle('Editor'),

		_buildItem(
			text: 'Font size',
			child: Text(_settings.editorFontSize.toString()),
			onTap: () async {
				final String? newSizeStr = await _askDialog(
					context: context,
					validator: _fontSizeValidator,
					title: 'Editor font size',
					initialValue: _settings.editorFontSize.toString(),
					hintText: 'Font size...',
				);
				if (newSizeStr != null) {
					final newSize = double.parse(newSizeStr);
					await _settings.setEditorFontSize(newSize!);
				}
			},
		),

		_buildItem(
			text: 'Font family',
			child: Text(_settings.editorFontFamily),
			onTap: () async {
				final String? newFontFamily = await showModalBottomSheet<String?>(
					context: context,
					builder: (context) => SelectFontFamilyScreen(initialValue: _settings.editorFontFamily)
				);
				if (newFontFamily != null)
					await _settings.setEditorFontFamily(newFontFamily!);
			},
		),
	];

	List<Widget> _songSection() => [
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
			text: 'Fingerings size',
			child: PopupMenuButton<FingeringSize>(
				clipBehavior: .antiAlias,
				shape: RoundedRectangleBorder(
					borderRadius: .circular(8),
				),

				initialValue: _settings.fingeringSizeInSong,
				onSelected: (v) => _settings.setFingeringSizeInSong(v),
				itemBuilder: (context) => FingeringSize.values.map<PopupMenuItem<FingeringSize>>((v) {
					return PopupMenuItem<FingeringSize>(
						value: v,
						child: Text(v.display()),
					);
				}).toList(),

				borderRadius: .circular(8),
				child: Padding(
					padding: const EdgeInsets.all(5),
					child: Text(_settings.fingeringSizeInSong.display()),
				),
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
			text: 'Font family',
			child: Text(_settings.songFontFamily),
			onTap: () async {
				final String? newFontFamily = await showModalBottomSheet<String?>(
					context: context,
					builder: (context) => SelectFontFamilyScreen(initialValue: _settings.songFontFamily)
				);
				if (newFontFamily != null)
					await _settings.setSongFontFamily(newFontFamily!);
			},
		),

		_buildExpansionItem(
			title: Row(
				mainAxisAlignment: .spaceBetween,
				children: [
					Flexible(
						child: Text('Title', style: Theme.of(context).textTheme.bodyMedium),
					),
					const SizedBox(width: 15),

					ElevatedButton(
						child: Text('Reset'),
						onPressed: (_settings.isTitleStyleNull)
							? null
							: () => _settings.resetTitleStyle(),
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
						),
					),
				],
			),
			children: [
				_buildItem(
					text: 'Font family',
					child: Text(_settings.titleFontFamily),
					onTap: () async {
						final String? newFontFamily = await showModalBottomSheet<String?>(
							context: context,
							builder: (context) => SelectFontFamilyScreen(initialValue: _settings.titleFontFamily)
						);
						if (newFontFamily != null)
							await _settings.setTitleFontFamily(newFontFamily!);
					},
				),
				_buildItem(
					text: 'Bold',
					child: Switch(
						value: _settings.isTitleBold,
						onChanged: _settings.setIsTitleBold,
					),
					onTap: null,
				),
				_buildItem(
					text: 'Italic',
					child: Switch(
						value: _settings.isTitleItalic,
						onChanged: _settings.setIsTitleItalic,
					),
					onTap: null,
				),
			],
		),

		_buildExpansionItem(
			title: Row(
				mainAxisAlignment: .spaceBetween,
				children: [
					Flexible(
						child: Text('Notes', style: Theme.of(context).textTheme.bodyMedium),
					),
					const SizedBox(width: 15),

					ElevatedButton(
						child: Text('Reset'),
						onPressed: (_settings.isNotesStyleNull)
							? null
							: () => _settings.resetNotesStyle(),
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
						),
					),
				],
			),
			children: [
				_buildItem(
					text: 'Font family',
					child: Text(_settings.notesFontFamily),
					onTap: () async {
						final String? newFontFamily = await showModalBottomSheet<String?>(
							context: context,
							builder: (context) => SelectFontFamilyScreen(initialValue: _settings.notesFontFamily)
						);
						if (newFontFamily != null)
							await _settings.setNotesFontFamily(newFontFamily!);
					},
				),
				_buildItem(
					text: 'Bold',
					child: Switch(
						value: _settings.isNotesBold,
						onChanged: _settings.setIsNotesBold,
					),
					onTap: null,
				),
				_buildItem(
					text: 'Italic',
					child: Switch(
						value: _settings.isNotesItalic,
						onChanged: _settings.setIsNotesItalic,
					),
					onTap: null,
				),
			],
		),

		_buildExpansionItem(
			title: Row(
				mainAxisAlignment: .spaceBetween,
				children: [
					Flexible(
						child: Text('Fingerings', style: Theme.of(context).textTheme.bodyMedium),
					),
					const SizedBox(width: 15),

					ElevatedButton(
						child: Text('Reset'),
						onPressed: (_settings.isFingeringsStyleNull)
							? null
							: () => _settings.resetFingeringsStyle(),
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
						),
					),
				],
			),
			children: [
				_buildItem(
					text: 'Font family',
					child: Text(_settings.fingeringsFontFamily),
					onTap: () async {
						final String? newFontFamily = await showModalBottomSheet<String?>(
							context: context,
							builder: (context) => SelectFontFamilyScreen(initialValue: _settings.fingeringsFontFamily)
						);
						if (newFontFamily != null)
							await _settings.setFingeringsFontFamily(newFontFamily!);
					},
				),
				_buildItem(
					text: 'Bold',
					child: Switch(
						value: _settings.isFingeringsBold,
						onChanged: _settings.setIsFingeringsBold,
					),
					onTap: null,
				),
				_buildItem(
					text: 'Italic',
					child: Switch(
						value: _settings.isFingeringsItalic,
						onChanged: _settings.setIsFingeringsItalic,
					),
					onTap: null,
				),
			],
		),

		_buildExpansionItem(
			title: Row(
				mainAxisAlignment: .spaceBetween,
				children: [
					Flexible(
						child: Text('Tab', style: Theme.of(context).textTheme.bodyMedium),
					),
					const SizedBox(width: 15),

					ElevatedButton(
						child: Text('Reset'),
						onPressed: (_settings.isTabStyleNull)
							? null
							: () => _settings.resetTabStyle(),
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
						),
					),
				],
			),
			children: [
				_buildItem(
					text: 'Font family',
					child: Text(_settings.tabFontFamily),
					onTap: () async {
						final String? newFontFamily = await showModalBottomSheet<String?>(
							context: context,
							builder: (context) => SelectFontFamilyScreen(initialValue: _settings.tabFontFamily)
						);
						if (newFontFamily != null)
							await _settings.setTabFontFamily(newFontFamily!);
					},
				),
				_buildItem(
					text: 'Bold',
					child: Switch(
						value: _settings.isTabBold,
						onChanged: _settings.setIsTabBold,
					),
					onTap: null,
				),
				_buildItem(
					text: 'Italic',
					child: Switch(
						value: _settings.isTabItalic,
						onChanged: _settings.setIsTabItalic,
					),
					onTap: null,
				),
			],
		),

		_buildExpansionItem(
			title: Row(
				mainAxisAlignment: .spaceBetween,
				children: [
					Flexible(
						child: Text('Plain text', style: Theme.of(context).textTheme.bodyMedium),
					),
					const SizedBox(width: 15),

					ElevatedButton(
						child: Text('Reset'),
						onPressed: (_settings.isPlainTextStyleNull)
							? null
							: () => _settings.resetPlainTextStyle(),
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
						),
					),
				],
			),
			children: [
				_buildItem(
					text: 'Font family',
					child: Text(_settings.plainTextFontFamily),
					onTap: () async {
						final String? newFontFamily = await showModalBottomSheet<String?>(
							context: context,
							builder: (context) => SelectFontFamilyScreen(initialValue: _settings.plainTextFontFamily)
						);
						if (newFontFamily != null)
							await _settings.setPlainTextFontFamily(newFontFamily!);
					},
				),
				_buildItem(
					text: 'Bold',
					child: Switch(
						value: _settings.isPlainTextBold,
						onChanged: _settings.setIsPlainTextBold,
					),
					onTap: null,
				),
				_buildItem(
					text: 'Italic',
					child: Switch(
						value: _settings.isPlainTextItalic,
						onChanged: _settings.setIsPlainTextItalic,
					),
					onTap: null,
				),
			],
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
	];

	List<Widget> _otherSection() => [
		_buildTitle('Other'),

		_buildItem(
			text: 'Export backup',
			child: null,
			onTap: _exportBackup,
		),
		_buildItem(
			text: 'Import backup',
			child: null,
			onTap: _importBackup,
		),

		_buildItem(
			text: 'Reset settings',
			child: null,
			onTap: _settings.resetToDefault,
		),

		_buildItem(
			text: 'Reset library',
			child: null,
			onTap: _settings.resetLibrary,
		),
	];



	Widget _buildSection(List<Widget> children) {
		return Container(
			margin: const EdgeInsets.all(10),
			child: Material(
				color: Theme.of(context).colorScheme.surfaceContainer,
				clipBehavior: .antiAlias,
				shape: RoundedRectangleBorder(
					borderRadius: .circular(8),
				),
				child: Column(
					mainAxisAlignment: .start,
					crossAxisAlignment: .start,
					children: children,
				),
			),
		);
	}

	Widget _buildTitle(String text) {
		return Container(
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

	Widget _buildExpansionItem({
		required Widget title,
		required List<Widget> children,
	}) {
		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
			child: ExpansionTile(
				title: title,
				children: children,
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
String? _backgroundOpacityValidator(String text) {
	final value = text.trim();
	final double? result = double.tryParse(value);

	if (result == null) {
		return 'Not valid input!';
	} else {
		if (result! < 0) {
			return 'Value must be bigger than 0!';
		} else if (result! > 1) {
			return 'Value must be 1 or smaller!';
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

class SelectFontFamilyScreen extends StatefulWidget {
	final String? initialValue;

	const SelectFontFamilyScreen({super.key, this.initialValue});

	@override
	State<SelectFontFamilyScreen> createState() => SelectFontFamilyState();
}

class SelectFontFamilyState extends State<SelectFontFamilyScreen> {
	late SettingsProvider _settings;


	final List<String> _fonts = FONT_FAMILIES;
	late List<String> _customFonts;
	String? _selected;

	@override
	void initState() {
		_selected = widget.initialValue;
		super.initState();
	}

	void _loadCustomFonts() => setState(() {
		_customFonts = _settings.customFontFamilies;
	});


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();
		_customFonts = _settings.customFontFamilies;

		return Container(
			height: MediaQuery.of(context).size.height * 0.5,
			width: double.infinity,
			padding: const EdgeInsets.all(10),
			decoration: BoxDecoration(
				borderRadius: .circular(8),
				color: Theme.of(context).colorScheme.surfaceVariant,
			),
			child: Material(
				color: Colors.transparent,
				child: _buildFonts(),
			),
		);
	}

	Widget _buildFonts() {
		return ListView.builder(
			itemCount: _fonts.length + _customFonts.length + 1,
			itemBuilder: (context, fontIndex) {
				final customFontIndex = fontIndex - _fonts.length;
				final bool isCustom = (customFontIndex >= 0);

				if (fontIndex == (_fonts.length + _customFonts.length))
					return _buildAddNewItem();


				final String family = isCustom
					? _customFonts[customFontIndex]
					: _fonts[fontIndex];

				return _buildFontItem(family, isCustom);
			},
		);
	}

	Widget _buildFontItem(String family, bool isCustom) {
		final String textExample = 'The quick brown fox jumps over the lazy dog';

		return _buildItem(
			child: Container(
				padding: const EdgeInsets.all(10),
				margin: const EdgeInsets.symmetric(vertical: 5),
				child: Row(
					mainAxisAlignment: .spaceBetween,
					children: [
						Flexible(
							child: Column(
								crossAxisAlignment: .start,
								children: [
									Row(
										children: [
											if (_selected == family) ...[
												Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
												SizedBox(width: 10),
											],

											Text(family),
										],
									),
									const SizedBox(height: 10),
									Text(textExample,
										style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: family)
									),
								],
							),
						),

						if (isCustom) ...[
							IconButton(
								icon: Icon(Icons.delete),
								onPressed: () async {
									await _settings.removeCustomFont(family);
									_loadCustomFonts();

									if (_selected == family) {
										setState(() => _selected = _fonts[0]);
										Navigator.of(context).pop(_selected);
									}
								},
							),
						],
					],
				),
			),
			onTap: () {
				setState(() => _selected = family);
				Navigator.of(context).pop(_selected);
			},
		);
	}

	Widget _buildAddNewItem() => _buildItem(
		child: Center(
			child: Padding(
				padding: const EdgeInsets.symmetric(vertical: 10),
				child: Icon(Icons.add),
			),
		),
		onTap: () async {
			await _settings.addNewCustomFont();
			_loadCustomFonts();
		},
	);


	Widget _buildItem({required Widget child, required VoidCallback onTap}) {
		final primary = Theme.of(context).colorScheme.primary;

		return InkWell(
			splashColor: primary.withOpacity(0.1),
			highlightColor: primary.withOpacity(0.05),
			child: child,
			onTap: onTap,
		);
	}
}

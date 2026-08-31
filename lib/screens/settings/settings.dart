import 'dart:io';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:restart_app/restart_app.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:songbook/screens/settings/select_font_family.dart';
import 'package:songbook/services/settings.dart';

import 'package:songbook/l10n/app_localizations.dart';


class SettingsScreen extends StatefulWidget {
	const SettingsScreen({super.key});

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
			if (result && mounted)
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text(AppLocalizations.of(context)!.settingsExportSuccesMsg),
						duration: Duration(seconds: 1),
					),
				);
		} catch (e) {
			debugPrint(e.toString());
			if (mounted)
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text(AppLocalizations.of(context)!.settingsErrorMsg),
						duration: Duration(seconds: 3),
					),
				);
		}
		setState(() => _isLoading = false);
	}
	void _importBackup() async {
		setState(() => _isLoading = true);
		try {
			final bool result = await _settings.importBackup();
			if (result && mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text(AppLocalizations.of(context)!.settingsImportSuccesMsg),
						duration: Duration(seconds: 1),
					),
				);
				Restart.restartApp();
			}
		} catch (e) {
			debugPrint(e.toString());
			if (mounted)
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text(AppLocalizations.of(context)!.settingsErrorMsg),
						duration: Duration(seconds: 3),
					),
				);
		}
	}

	void _setLibPath() async {
		setState(() => _isLoading = true);

		final String? selectedDir = await FilePicker.getDirectoryPath();
		if (selectedDir == null) {
			setState(() => _isLoading = false);
			return;
		}

		try {
			await _settings.setLibPath(selectedDir);
			Restart.restartApp();
		} catch (e) {
			debugPrint(e.toString());
			if (mounted)
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text(AppLocalizations.of(context)!.settingsErrorMsg),
						duration: Duration(seconds: 3),
					),
				);
		}

		setState(() => _isLoading = false);
	}
	void _resetLibPath() async {
		setState(() => _isLoading = true);

		try {
			await _settings.resetLibPath();
			Restart.restartApp();
		} catch (e) {
			debugPrint(e.toString());
			if (mounted)
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text(AppLocalizations.of(context)!.settingsErrorMsg),
						duration: Duration(seconds: 3),
					),
				);
		}

		setState(() => _isLoading = false);
	}

	final List<ColorItem> _colors = [
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

		return PopScope(
			canPop: (!_isLoading),
			onPopInvokedWithResult: (_, _) {},
			child: Stack(
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
							appBar: AppBar( title: Text(AppLocalizations.of(context)!.settingsAppBarTitle) ),
							body: _buildBody(),
						),
					),

					if (_isLoading)
						Container(
							color: Colors.black.withValues(alpha: 0.5),
							child: Center(
								child: CircularProgressIndicator(),
							),
						),
				],
			),
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
		_buildTitle(AppLocalizations.of(context)!.settingsGlobalTitle),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsLanguage,
			child: MenuAnchor(
				animated: true,
				builder: (context, controller, child) => TextButton(
					child: (_settings.language != null) // setted by user
						? Text(LANGUAGES[_settings.locale?.languageCode] ?? '')
						: Text(AppLocalizations.of(context)!.settingsLanguageSystem),
					onPressed: () {
						if (controller.isOpen) {
							controller.close();
						} else {
							controller.open();
						}
					},
					style: TextButton.styleFrom(
						foregroundColor: Theme.of(context).colorScheme.onSurface,
					),
				),
				menuChildren: [
					MenuItemButton(
						child: Text(AppLocalizations.of(context)!.settingsLanguageSystem),
						onPressed: () => _settings.setLanguage(null),
					),

					...LANGUAGES.entries.map((entry) => MenuItemButton(
						child: Text(entry.value),
						onPressed: () => _settings.setLanguage(entry.key),
					))
				],
			),
			onTap: null,
		),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsLibPath,
			child: ElevatedButton(
				child: Text(AppLocalizations.of(context)!.settingsReset),
				onPressed: (!_settings.libPathIsNull)
					? () => _resetLibPath()
					: null,
				style: ElevatedButton.styleFrom(
					backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
				),
			),
			onTap: () async {
				if (Platform.isAndroid) {
					if ( await Permission.manageExternalStorage.request().isGranted )
						_setLibPath();
				} else {
					_setLibPath();
				}
			},
		),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsTheme,
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
			text: AppLocalizations.of(context)!.settingsAmoled,
			child: Switch(
				value: _settings.isAmoled,
				onChanged: _settings.setAmoled,
			),
			onTap: null,
		),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsAccent,
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
			text: AppLocalizations.of(context)!.settingsBackgroundOpacity,
			child: Text(_settings.backgroundOpacity.toString()),
			onTap: () async {
				final String? newOpacityStr = await _askDialog(
					validator: _backgroundOpacityValidator,
					title: AppLocalizations.of(context)!.settingsBackgroundOpacity,
					initialValue: _settings.backgroundOpacity.toString(),
					hintText: AppLocalizations.of(context)!.settingsBackgroundOpacityHint,
				);
				if (newOpacityStr != null) {
					final newOpacity = double.parse(newOpacityStr);
					await _settings.setBackgroundOpacity(newOpacity);
				}
			},
		),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsBackgroundImage,
			child: ElevatedButton(
				child: Text(AppLocalizations.of(context)!.settingsReset),
				onPressed: (_settings.backgroundImage != null)
					? _settings.resetBackgroundImage
					: null,
				style: ElevatedButton.styleFrom(
					backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
				),
			),
			onTap: _settings.setBackgroundImage,
		),
	];

	List<Widget> _editorSection() => [
		_buildTitle(AppLocalizations.of(context)!.settingsEditorTitle),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsFontSize,
			child: Text(_settings.editorFontSize.toString()),
			onTap: () async {
				final String? newSizeStr = await _askDialog(
					validator: _fontSizeValidator,
					title: AppLocalizations.of(context)!.settingsEditorFontSize,
					initialValue: _settings.editorFontSize.toString(),
					hintText: AppLocalizations.of(context)!.settingsFontSizeHint,
				);
				if (newSizeStr != null) {
					final newSize = double.parse(newSizeStr);
					await _settings.setEditorFontSize(newSize);
				}
			},
		),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsFontFamily,
			child: Text(_settings.editorFontFamily),
			onTap: () async {
				final String? newFontFamily = await _bottomSheetDialog(
					SelectFontFamily(initialValue: _settings.editorFontFamily)
				);
				if (newFontFamily != null)
					await _settings.setEditorFontFamily(newFontFamily);
			},
		),
	];

	List<Widget> _songSection() => [
		_buildTitle(AppLocalizations.of(context)!.settingsSongTitle),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsSharpOnly,
			child: Switch(
				value: _settings.sharpOnly,
				onChanged: _settings.setSharpOnly,
			),
			onTap: null,
		),
		_buildItem(
			text: AppLocalizations.of(context)!.settingsLineWrap,
			child: Switch(
				value: _settings.lineWrapInSong,
				onChanged: _settings.setLineWrapInSong,
			),
			onTap: null,
		),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsFingeringsSize,
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
						child: Text(v.display(context)),
					);
				}).toList(),

				borderRadius: .circular(8),
				child: Padding(
					padding: const EdgeInsets.all(5),
					child: Text(_settings.fingeringSizeInSong.display(context)),
				),
			),
			onTap: null,
		),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsFontSize,
			child: Text(_settings.songFontSize.toString()),
			onTap: () async {
				final String? newSizeStr = await _askDialog(
					validator: _fontSizeValidator,
					title: AppLocalizations.of(context)!.settingsSongFontSize,
					initialValue: _settings.songFontSize.toString(),
					hintText: AppLocalizations.of(context)!.settingsFontSizeHint,
				);
				if (newSizeStr != null) {
					final newSize = double.parse(newSizeStr);
					await _settings.setSongFontSize(newSize);
				}
			},
		),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsFontFamily,
			child: Text(_settings.songFontFamily),
			onTap: () async {
				final String? newFontFamily = await _bottomSheetDialog(
					SelectFontFamily(initialValue: _settings.songFontFamily)
				);
				if (newFontFamily != null)
					await _settings.setSongFontFamily(newFontFamily);
			},
		),

		_buildExpansionItem(
			title: Row(
				mainAxisAlignment: .spaceBetween,
				children: [
					Flexible(
						child: Text(AppLocalizations.of(context)!.settingsTitles,
							style: Theme.of(context).textTheme.bodyMedium
						),
					),
					const SizedBox(width: 15),

					ElevatedButton(
						child: Text(AppLocalizations.of(context)!.settingsReset),
						onPressed: (_settings.isTitleStyleNull)
							? null
							: () => _settings.resetTitleStyle(),
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
						),
					),
				],
			),
			children: [
				_buildItem(
					text: AppLocalizations.of(context)!.settingsColor,
					onTap: null,
					child: ColorItem(
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
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsFontFamily,
					child: Text(_settings.titleFontFamily),
					onTap: () async {
						final String? newFontFamily = await _bottomSheetDialog(
							SelectFontFamily(initialValue: _settings.titleFontFamily)
						);
						if (newFontFamily != null)
							await _settings.setTitleFontFamily(newFontFamily);
					},
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsBold,
					child: Switch(
						value: _settings.isTitleBold,
						onChanged: _settings.setIsTitleBold,
					),
					onTap: null,
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsItalic,
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
						child: Text(AppLocalizations.of(context)!.settingsNotes,
							style: Theme.of(context).textTheme.bodyMedium
						),
					),
					const SizedBox(width: 15),

					ElevatedButton(
						child: Text(AppLocalizations.of(context)!.settingsReset),
						onPressed: (_settings.isNotesStyleNull)
							? null
							: () => _settings.resetNotesStyle(),
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
						),
					),
				],
			),
			children: [
				_buildItem(
					text: AppLocalizations.of(context)!.settingsColor,
					onTap: null,
					child: ColorItem(
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
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsFontFamily,
					child: Text(_settings.notesFontFamily),
					onTap: () async {
						final String? newFontFamily = await _bottomSheetDialog(
							SelectFontFamily(initialValue: _settings.notesFontFamily)
						);
						if (newFontFamily != null)
							await _settings.setNotesFontFamily(newFontFamily);
					},
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsBold,
					child: Switch(
						value: _settings.isNotesBold,
						onChanged: _settings.setIsNotesBold,
					),
					onTap: null,
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsItalic,
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
						child: Text(AppLocalizations.of(context)!.settingsFingerings,
							style: Theme.of(context).textTheme.bodyMedium
						),
					),
					const SizedBox(width: 15),

					ElevatedButton(
						child: Text(AppLocalizations.of(context)!.settingsReset),
						onPressed: (_settings.isFingeringsStyleNull)
							? null
							: () => _settings.resetFingeringsStyle(),
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
						),
					),
				],
			),
			children: [
				_buildItem(
					text: AppLocalizations.of(context)!.settingsColor,
					onTap: null,
					child: ColorItem(
						color: _settings.fingeringsColor(context),
						value: '',
					).build(
						context: context,
						isSelected: false,
						onTap: (_) async {
							final String? newColor = await _showColorPickerDialog(
								context: context,
								initialColor: _settings.fingeringsColor(context),
							);
							await _settings.setFingeringsColor(newColor);
						}
					)
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsFontFamily,
					child: Text(_settings.fingeringsFontFamily),
					onTap: () async {
						final String? newFontFamily = await _bottomSheetDialog(
							SelectFontFamily(initialValue: _settings.fingeringsFontFamily)
						);
						if (newFontFamily != null)
							await _settings.setFingeringsFontFamily(newFontFamily);
					},
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsBold,
					child: Switch(
						value: _settings.isFingeringsBold,
						onChanged: _settings.setIsFingeringsBold,
					),
					onTap: null,
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsItalic,
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
						child: Text(AppLocalizations.of(context)!.settingsTabs,
							style: Theme.of(context).textTheme.bodyMedium
						),
					),
					const SizedBox(width: 15),

					ElevatedButton(
						child: Text(AppLocalizations.of(context)!.settingsReset),
						onPressed: (_settings.isTabStyleNull)
							? null
							: () => _settings.resetTabStyle(),
						style: ElevatedButton.styleFrom(
				 			backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
						),
					),
				],
			),
			children: [
				_buildItem(
					text: AppLocalizations.of(context)!.settingsColor,
					onTap: null,
					child: ColorItem(
						color: _settings.tabColor(context),
						value: '',
					).build(
						context: context,
						isSelected: false,
						onTap: (_) async {
							final String? newColor = await _showColorPickerDialog(
								context: context,
								initialColor: _settings.tabColor(context),
							);
							await _settings.setTabColor(newColor);
						}
					)
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsFontFamily,
					child: Text(_settings.tabFontFamily),
					onTap: () async {
						final String? newFontFamily = await _bottomSheetDialog(
							SelectFontFamily(initialValue: _settings.tabFontFamily)
						);
						if (newFontFamily != null)
							await _settings.setTabFontFamily(newFontFamily);
					},
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsBold,
					child: Switch(
						value: _settings.isTabBold,
						onChanged: _settings.setIsTabBold,
					),
					onTap: null,
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsItalic,
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
						child: Text(AppLocalizations.of(context)!.settingsPlainText,
							style: Theme.of(context).textTheme.bodyMedium
						),
					),
					const SizedBox(width: 15),

					ElevatedButton(
						child: Text(AppLocalizations.of(context)!.settingsReset),
						onPressed: (_settings.isPlainTextStyleNull)
							? null
							: () => _settings.resetPlainTextStyle(),
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
						),
					),
				],
			),
			children: [
				_buildItem(
					text: AppLocalizations.of(context)!.settingsColor,
					onTap: null,
					child: ColorItem(
						color: _settings.plainTextColor(context),
						value: '',
					).build(
						context: context,
						isSelected: false,
						onTap: (_) async {
							final String? newColor = await _showColorPickerDialog(
								context: context,
								initialColor: _settings.plainTextColor(context),
							);
							await _settings.setPlainTextColor(newColor);
						}
					)
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsFontFamily,
					child: Text(_settings.plainTextFontFamily),
					onTap: () async {
						final String? newFontFamily = await _bottomSheetDialog(
							SelectFontFamily(initialValue: _settings.plainTextFontFamily)
						);
						if (newFontFamily != null)
							await _settings.setPlainTextFontFamily(newFontFamily);
					},
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsBold,
					child: Switch(
						value: _settings.isPlainTextBold,
						onChanged: _settings.setIsPlainTextBold,
					),
					onTap: null,
				),
				_buildItem(
					text: AppLocalizations.of(context)!.settingsItalic,
					child: Switch(
						value: _settings.isPlainTextItalic,
						onChanged: _settings.setIsPlainTextItalic,
					),
					onTap: null,
				),
			],
		),


		_buildItem(
			text: AppLocalizations.of(context)!.settingsChordsColor,
			child: Row(
				mainAxisAlignment: .end,
				children: [
					ElevatedButton(
						child: Text(AppLocalizations.of(context)!.settingsReset),
						onPressed: !_settings.chordsColorIsNull
							? () => _settings.setChordsColor(null)
							: null,
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
			text: AppLocalizations.of(context)!.settingsRhythmColor,
			child: Row(
				mainAxisAlignment: .end,
				children: [
					ElevatedButton(
						child: Text(AppLocalizations.of(context)!.settingsReset),
						onPressed: !_settings.rhythmColorIsNull
							? () => _settings.setRhythmColor(null)
							: null,
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
			text: AppLocalizations.of(context)!.settingsTextColor,
			child: Row(
				mainAxisAlignment: .end,
				children: [
					ElevatedButton(
						child: Text(AppLocalizations.of(context)!.settingsReset),
						onPressed: !_settings.textColorIsNull
							? () => _settings.setTextColor(null)
							: null,
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
			text: AppLocalizations.of(context)!.settingsBackground,
			child: Row(
				mainAxisAlignment: .end,
				children: [
					ElevatedButton(
						child: Text(AppLocalizations.of(context)!.settingsReset),
						onPressed: !_settings.backgroundColorIsNull
							? () => _settings.setBackgroundColor(null)
							: null,
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
		_buildTitle(AppLocalizations.of(context)!.settingsOtherTitle),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsExportBackup,
			child: null,
			onTap: _exportBackup,
		),
		_buildItem(
			text: AppLocalizations.of(context)!.settingsImportBackup,
			child: null,
			onTap: _importBackup,
		),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsResetSettings,
			child: null,
			onTap: _settings.resetToDefault,
		),

		_buildItem(
			text: AppLocalizations.of(context)!.settingsResetLibrary,
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
			splashColor: primary.withValues(alpha: 0.1),
			highlightColor: primary.withValues(alpha: 0.05),
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
				child: SizedBox(
					height: 50,
					child: Row(
						mainAxisAlignment: .spaceBetween,
						children: [
							IntrinsicWidth(
								child: Text(text),
							),
							const SizedBox(width: 20),
							if (child != null)
								Flexible(child: child),
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


	Future<String?> _bottomSheetDialog(Widget child) => showModalBottomSheet<String?>(
		clipBehavior: .antiAlias,
		isScrollControlled: true,
		context: context,
		builder: (context) => child,
	);

	Future<String?> _askDialog({
		required String? Function(String) validator,
		required String title,
		String initialValue = '',
		String hintText = '',
	}) {
		if (hintText.isEmpty)
			hintText = AppLocalizations.of(context)!.hintText;

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
							child: Text(AppLocalizations.of(context)!.cancel),
							onPressed: () => Navigator.of(context).pop(),
						),
						ElevatedButton(
							child: Text(AppLocalizations.of(context)!.ok),
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
			return AppLocalizations.of(context)!.notValidInput;
		} else {
			if (result < 1) {
				return AppLocalizations.of(context)!.valueMustBeBiggerThan0;
			} else if (result >= 100) {
				return AppLocalizations.of(context)!.valueMustBeSmallerThan100;
			} else {
				return null;
			}
		}
	}

	String? _backgroundOpacityValidator(String text) {
		final value = text.trim();
		final double? result = double.tryParse(value);

		if (result == null) {
			return AppLocalizations.of(context)!.notValidInput;
		} else {
			if (result < 0) {
				return AppLocalizations.of(context)!.valueMustBeBiggerThan0;
			} else if (result > 1) {
				return AppLocalizations.of(context)!.valueMustBe1OrSmaller;
			} else {
				return null;
			}
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
		return '#${dialogPickerColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}


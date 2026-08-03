import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:songbook/services/settings.dart';
import 'package:songbook/l10n/app_localizations.dart';

import 'package:songbook/src/rust/api/library.dart';


class AddSong extends StatefulWidget {
	Function(String, String, String) onDone;

	AddSong({super.key, required this.onDone});


	@override
	State<AddSong> createState() => _AddSongState();
}

class _AddSongState extends State<AddSong> {
	late SettingsProvider _settings;


	late TextEditingController _artistController;
	late FocusNode _artistFocusNode;
	String? _artistError;

	late TextEditingController _titleController;
	late FocusNode _titleFocusNode;
	String? _titleError;

	late TextEditingController _songContentController;
	late FocusNode _songContentFocusNode;

	@override
	void initState() {
		super.initState();
		_artistController = TextEditingController();
		_artistFocusNode = FocusNode();

		_titleController = TextEditingController();
		_titleFocusNode = FocusNode();

		_songContentController = TextEditingController();
		_songContentFocusNode = FocusNode();
		_songContentFocusNode.requestFocus();
	}

	@override
	void dispose() {
		_artistController.dispose();
		_artistFocusNode.dispose();

		_titleController.dispose();
		_titleFocusNode.dispose();

		_songContentController.dispose();
		_songContentFocusNode.dispose();

		super.dispose();
	}


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();

		return Column(
			children: [
				Padding(
					padding: const EdgeInsets.all(15),
					child: Row(
						children: [
							TextButton(
								child: Text(AppLocalizations.of(context)!.cancel),
								onPressed: () => Navigator.of(context).pop(),
							),
							Spacer(),
							ElevatedButton(
								child: Text(AppLocalizations.of(context)!.done),
								onPressed: () {
									final artist = _artistController.text.trim();
									final artistCheckResult = _validateName(artist);
									if (artistCheckResult != null) {
										setState(() => _artistError = artistCheckResult);
										_artistFocusNode.requestFocus();

										return;
									}

									final title = _titleController.text.trim();
									final titleCheckResult = _validateName(title);
									if (titleCheckResult != null) {
										setState(() => _titleError = titleCheckResult);
										_titleFocusNode.requestFocus();

										return;
									}

									final text = _songContentController.text;
									widget.onDone(artist, title, text);
								},
							),
						],
					),
				),

				Row(
					children: [
						Expanded(
							child: TextField(
								controller: _artistController,
								focusNode: _artistFocusNode,
								style: _settings.editorStyle(),
								decoration: InputDecoration(
									border: OutlineInputBorder(),
									hintText: AppLocalizations.of(context)!.newSongDialogArtistHint,
									errorText: _artistError,
								),
								onChanged: (value) {
									setState(() => _artistError = _validateName(value));
								},
								onSubmitted: (value) {
									final String text = value.trim();
									final checkResult = _validateName(text);
									if (checkResult == null) {
										_titleFocusNode.requestFocus();
									} else {
										setState(() => _artistError = checkResult);
										_artistFocusNode.requestFocus();
									}
								}
							),
						),
						const SizedBox(width: 10),
						Expanded(
							child: TextField(
								controller: _titleController,
								focusNode: _titleFocusNode,
								style: _settings.editorStyle(),
								decoration: InputDecoration(
									border: OutlineInputBorder(),
									hintText: AppLocalizations.of(context)!.newSongDialogTitleHint,
									errorText: _titleError,
								),
								onChanged: (value) {
									setState(() => _titleError = _validateName(value));
								},
								onSubmitted: (value) {
									final String text = value.trim();
									final checkResult = _validateName(text);
									if (checkResult == null) {
										_songContentFocusNode.requestFocus();
									} else {
										setState(() => _titleError = checkResult);
										_titleFocusNode.requestFocus();
									}
								}
							),
						),
					]
				),
				const SizedBox(height: 20),
				Expanded(
					child: TextField(
						controller: _songContentController,
						focusNode: _songContentFocusNode,
						maxLines: null,
						expands: true,
						textAlignVertical: .top,
						style: _settings.editorStyle(),
						decoration: InputDecoration(
							border: OutlineInputBorder(),
							hintText: AppLocalizations.of(context)!.newSongDialogTextHint,
						),
					),
				),

				SizedBox(height: MediaQuery.of(context).viewInsets.bottom), // для клавиатуры
				SizedBox(height: MediaQuery.of(context).padding.bottom), // safe area
			],
		);
	}
	String? _validateName(String value) {
		final trimmed = value.trim();

		if (trimmed.isEmpty)
			return AppLocalizations.of(context)!.nameValidatorErrorEmptyText;
		
		final forbiddenChars = getForbiddenChars();
		if (trimmed.characters.any((char) => forbiddenChars.contains(char)))
			return AppLocalizations.of(context)!.nameValidatorErrorForbiddenChars;
		
		return null;
	}
}

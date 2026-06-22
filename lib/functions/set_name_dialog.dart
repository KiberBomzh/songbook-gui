import 'package:flutter/material.dart';

import 'package:songbook/src/rust/api/library.dart';
import 'package:songbook/l10n/app_localizations.dart';


Future<String?> setName({
	required bool Function(String) existsCheck,
	required BuildContext context,
	required String title,
	String initialValue = '',
	String hintText = '',
}) async {
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

					onChanged: (value) {
						setState(() => errorText = _validateName(value, existsCheck, context));
					},
					onSubmitted: (value) {
						final err = _validateName(value, existsCheck, context);
						if (err == null) {
							Navigator.of(context).pop(value.trim());
						} else {
							setState(() => errorText = err);
						}
					}
				),
				actions: [
					TextButton(
						child: Text(AppLocalizations.of(context)!.cancel),
						onPressed: () => Navigator.of(context).pop(),
					),
					ElevatedButton(
						child: Text(AppLocalizations.of(context)!.ok),
						onPressed: () {
							final name = controller.text.trim();
							final err = _validateName(name, existsCheck, context);

							if (err == null) {
								Navigator.of(context).pop(name);
							} else {
								setState(() => errorText = err);
							}
						},
					),
				],
			),
		),
	);
}

String? _validateName(String value, bool Function(String) isExists, BuildContext context) {
	final trimmed = value.trim();

	if (trimmed.isEmpty)
		return AppLocalizations.of(context)!.nameCannotBeEmpty;
	
	final forbiddenChars = getForbiddenChars();
	if (trimmed.characters.any((char) => forbiddenChars.contains(char)))
		return AppLocalizations.of(context)!.theNameContainsForbiddenChars;
	
	if (isExists(trimmed))
		return AppLocalizations.of(context)!.theNameIsAlreadyExists;
	

	return null;
}

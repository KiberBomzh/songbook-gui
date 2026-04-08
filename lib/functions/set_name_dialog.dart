import 'package:flutter/material.dart';

import 'package:songbook/src/rust/api/library.dart';


Future<String?> setName({
	required bool Function(String) existsCheck,
	required BuildContext context,
	required String title,
	String initialValue = '',
	String hintText = 'Type something...',
}) async {
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
						setState(() => errorText = _validateName(value, existsCheck));
					},
					onSubmitted: (value) {
						final err = _validateName(value, existsCheck);
						if (err == null) {
							Navigator.of(context).pop(value.trim());
						} else {
							setState(() => errorText = err);
						}
					}
				),
				actions: [
					TextButton(
						child: Text('Cancel'),
						onPressed: () => Navigator.of(context).pop(),
					),
					ElevatedButton(
						child: Text('Ok'),
						onPressed: () {
							final name = controller.text.trim();
							final err = _validateName(name, existsCheck);

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

String? _validateName(String value, bool Function(String) isExists) {
	final trimmed = value.trim();

	if (trimmed.isEmpty)
		return 'Name cannot be empty!';
	
	final forbiddenChars = getForbiddenChars();
	if (trimmed.characters.any((char) => forbiddenChars.contains(char)))
		return 'Name contains forbidden chars!';
	
	if (isExists(trimmed))
		return 'This name is already exitsts!';
	

	return null;
}

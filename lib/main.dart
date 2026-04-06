import 'package:flutter/material.dart';

import 'package:songbook/src/rust/frb_generated.dart';

import 'package:songbook/screens/library.dart';


Future<void> main() async {
	await RustLib.init();
	runApp(const MyApp());
}


class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
		final themeMode = ThemeMode.dark;
		final accentColor = Colors.blue;

		return MaterialApp(
			title: 'Songbook',
			theme: ThemeData(
				useMaterial3: true,
				colorScheme: ColorScheme.fromSeed(
					brightness: .light,
					seedColor: accentColor,
				),
			),
			darkTheme: ThemeData(
				useMaterial3: true,
				colorScheme: ColorScheme.fromSeed(
					brightness: .dark,
					seedColor: accentColor,
				),
			),
			themeMode: themeMode,
			home: LibraryScreen(),
		);
	}
}

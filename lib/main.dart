import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:songbook/src/rust/frb_generated.dart';

import 'package:songbook/screens/library.dart';
import 'package:songbook/services/settings.dart';


Future<void> main() async {
	WidgetsFlutterBinding.ensureInitialized();
	await RustLib.init();
	await Preferences.init();
	runApp(
		ChangeNotifierProvider(
			create: (_) => SettingsProvider(),
			child: const MyApp()
		),
	);
}


class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
		final settings = context.watch<SettingsProvider>();
		final themeMode = settings.themeMode;
		final accentColor = settings.colorAccent;

		return SafeArea(
			top: true,
			bottom: true,
			child: MaterialApp(
				title: 'Songbook',
				theme: ThemeData(
					useMaterial3: true,
					colorScheme: ColorScheme.fromSeed(
						brightness: .light,
						seedColor: accentColor,
					),
					snackBarTheme: SnackBarThemeData(
						shape: RoundedRectangleBorder(
							borderRadius: .vertical(top: Radius.circular(10)),
						),
						elevation: 4,
					),
				),
				darkTheme: ThemeData(
					useMaterial3: true,
					colorScheme: ColorScheme.fromSeed(
						brightness: .dark,
						seedColor: accentColor,
					),
					snackBarTheme: SnackBarThemeData(
						shape: RoundedRectangleBorder(
							borderRadius: .vertical(top: Radius.circular(10)),
						),
						elevation: 4,
					),
				),
				themeMode: themeMode,
				home: LibraryScreen(),
			),
		);
	}
}

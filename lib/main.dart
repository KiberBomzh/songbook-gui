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

		var themeMode = ThemeMode.system;
		final bool? isDark = settings.isDarkTheme;
		if (isDark != null) {
			themeMode = (isDark!)
				? ThemeMode.dark
				: ThemeMode.light;
		}
		themeMode = ThemeMode.dark;

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
			),
		);
	}
}

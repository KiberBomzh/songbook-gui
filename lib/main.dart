import 'dart:io';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:songbook/l10n/app_localizations.dart';

import 'package:songbook/src/rust/frb_generated.dart';

import 'package:songbook/screens/library.dart';
import 'package:songbook/services/settings.dart';


String pathDivider = '/';

Future<void> main() async {
	if (Platform.isWindows)
		pathDivider = '\\';

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

		return MaterialApp(
			title: 'Songbook',
			theme: settings.ligthTheme(),
			darkTheme: settings.darkTheme(),
			themeMode: settings.themeMode,
			home: LibraryScreen(),

			supportedLocales: LANGUAGES.keys.map((key) => Locale(key)).toList(),
			localizationsDelegates: [
				AppLocalizations.delegate,
				GlobalMaterialLocalizations.delegate,
				GlobalWidgetsLocalizations.delegate,
				GlobalCupertinoLocalizations.delegate,
			],
			localeResolutionCallback: (locale, supportedLocales) {
				if (settings.locale != null)
					return settings.locale;

				if (supportedLocales.contains(Locale(locale!.languageCode))) {
					settings.setLocale(locale);
					return locale;
				}

				return const Locale('en');
			},
		);
	}
}

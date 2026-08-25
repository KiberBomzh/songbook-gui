import 'dart:io';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:songbook/l10n/app_localizations.dart';
import 'package:zikzak_share_handler/zikzak_share_handler.dart';

import 'package:songbook/src/rust/frb_generated.dart';

import 'package:songbook/screens/library/library.dart';
import 'package:songbook/utils/share_viewer.dart';
import 'package:songbook/services/settings.dart';
import 'package:songbook/services/preferences.dart';


String pathDivider = '/';

Future<void> main() async {
	if (Platform.isWindows)
		pathDivider = '\\';

	WidgetsFlutterBinding.ensureInitialized();
	await RustLib.init();
	await Preferences.init();
	final settings = await SettingsProvider.create();
	runApp(
		ChangeNotifierProvider(
			create: (_) => settings,
			child: const MyApp()
		),
	);
}


class MyApp extends StatefulWidget {
	const MyApp({super.key});

	@override
	State<MyApp> createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
	SharedMedia? _media;


	@override
	void initState() {
		super.initState();
		_initPlatformState();
	}

	Future<void> _initPlatformState() async {
		final handler = ShareHandlerPlatform.instance;
		_media = await handler.getInitialSharedMedia();

		handler.sharedMediaStream.listen((media) {
			if (!mounted)
				return;

			setState(() => this._media = media);
		});
		if (!mounted)
			return;

		setState(() {});
	}

	@override
	Widget build(BuildContext context) {
		final settings = context.watch<SettingsProvider>();

		return MaterialApp(
			title: 'Songbook',
			theme: settings.ligthTheme(),
			darkTheme: settings.darkTheme(),
			themeMode: settings.themeMode,
			home: (_media != null)
				? ShareViewer(media: _media!)
				: LibraryScreen(),

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

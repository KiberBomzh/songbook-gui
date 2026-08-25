import 'dart:io';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:songbook/l10n/app_localizations.dart';
import 'package:zikzak_share_handler/zikzak_share_handler.dart';
import 'package:open_with_app/open_with_app.dart';

import 'package:songbook/src/rust/frb_generated.dart';

import 'package:songbook/screens/library/library.dart';
import 'package:songbook/utils/song_viewer.dart';
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
	String? _sharedSongPath;


	@override
	void initState() {
		super.initState();
		_initShareHandler();
		_initOpenWithApp();
	}

	Future<void> _initShareHandler() async {
		final handler = ShareHandlerPlatform.instance;
		final media = await handler.getInitialSharedMedia();
		_handleMedia(media);

		handler.sharedMediaStream.listen((media) {
			if (!mounted)
				return;

			_handleMedia(media);
		});
		if (!mounted)
			return;

		setState(() {});
	}
	void _handleMedia(SharedMedia? media) {
		setState(() {
			_sharedSongPath = media?.attachments?[0].path;
		});
	}

	Future<void> _initOpenWithApp() async {
		final handler = OpenWithApp();
		_sharedSongPath = await handler.getInitialFile();

		handler.getFileStream().listen((path) {
			_sharedSongPath = path;
		});
	}

	@override
	Widget build(BuildContext context) {
		final settings = context.watch<SettingsProvider>();

		return MaterialApp(
			title: 'Songbook',
			theme: settings.ligthTheme(),
			darkTheme: settings.darkTheme(),
			themeMode: settings.themeMode,
			home: (_sharedSongPath != null)
				? SongViewer(path: _sharedSongPath!)
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

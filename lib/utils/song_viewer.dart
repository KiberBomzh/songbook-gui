import 'package:flutter/material.dart';

import 'package:restart_app/restart_app.dart';

import 'package:songbook/l10n/app_localizations.dart';
import 'package:songbook/src/rust/api/library.dart' as lib;
import 'package:songbook/src/rust/api/song.dart' as song;

import 'package:songbook/screens/song/song.dart';


class SongViewer extends StatelessWidget {
	String path;

	SongViewer({
		super.key,
		required this.path,
	});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Song Viewer'),
				actions: [
					TextButton(
						child: Text('Cancel'),
						onPressed: () => Restart.restartApp(),
					),
					ElevatedButton(
						child: Text('Save'),
						onPressed: () {
							try {
								final s = song.SimpleSong.open(pathStr: path);
								lib.importSong(song: s, dirPath: null);
								Restart.restartApp();
							} catch (e) {
								debugPrint(e.toString());
								ScaffoldMessenger.of(context).showSnackBar(
									SnackBar(
										content: Text(AppLocalizations.of(context)!.settingsErrorMsg),
										duration: Duration(seconds: 3),
									),
								);
							}
						},
					),
				],
			),
			body: SongScreen(path: path),
		);
	}
}

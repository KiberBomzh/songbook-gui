import 'package:flutter/material.dart';

import 'package:restart_app/restart_app.dart';

import 'package:songbook/l10n/app_localizations.dart';
import 'package:songbook/src/rust/api/library.dart' as lib;
import 'package:songbook/src/rust/api/song.dart' as song;

import 'package:songbook/screens/song/song.dart';
import 'package:songbook/utils/path_picker.dart';


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
				actions: [
					TextButton(
						child: Text('Cancel'),
						onPressed: () => Restart.restartApp(),
					),

					Spacer(),

					ElevatedButton(
						child: Text('Save as...'),
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
							foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
						),
						onPressed: () async {
							try {
								final s = song.SimpleSong.open(pathStr: path);
								final libPath = lib.getLibraryPath();
								final dirPath = await Navigator.push(context,
									MaterialPageRoute(
										builder: (context) => PathPicker(dir: libPath),
									),
								);
								if (dirPath == null)
									return;

								lib.importSong(song: s, dirPath: dirPath);
								Restart.restartApp();
							} catch (e) {
								debugPrint(e.toString());
								if (context.mounted)
									ScaffoldMessenger.of(context).showSnackBar(
										SnackBar(
											content: Text(AppLocalizations.of(context)!.settingsErrorMsg),
											duration: Duration(seconds: 3),
										),
									);
							}
						},
					),

					const SizedBox(width: 5),

					ElevatedButton(
						child: Text('Save'),
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.primaryContainer,
							foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
						),
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

import 'dart:io';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';

import 'package:songbook/screens/song.dart';

import 'package:songbook/src/rust/api/library.dart';


var _isAppDirSet = false;

class LibraryScreen extends StatefulWidget {
	final String? path;
	LibraryScreen({super.key, this.path});

	State<LibraryScreen> createState() => _LibraryState();
}

class _LibraryState extends State<LibraryScreen> {
	List<String> _dirs = [];
	List<String> _files = [];

	@override
	void initState() {
		super.initState();
		_loadDirectory();
	}

	Future<void> _loadDirectory() async {
		if (Platform.isAndroid && !_isAppDirSet) {
			// Установка переменной окружения с путем к библиотеке
			final appDataDir = await getExternalStorageDirectory();
			initLibrary(appDataDir: appDataDir!.path);
			_isAppDirSet = true;
		}
		var (d, f) = readDirectory(pathStr: widget.path);
		setState(() {
			_dirs = d;
			_files = f;
		});
	}

	Future<void> setAppDataDir() async {
	}



	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar( title: Text('Library') ),
			body: _buildBody(),
		);
	}


	Widget _buildBody() {
		return ListView.builder(
			itemCount: _dirs.length + _files.length,
			itemBuilder: (context, dirsIndex) {
				final filesIndex = dirsIndex - _dirs.length;
				final bool isItemDir = (dirsIndex < _dirs.length);
				final itemPath = isItemDir
					? _dirs[dirsIndex]
					: _files[filesIndex];

				final itemName = itemPath.substring(itemPath.lastIndexOf('/') + 1);

				return Container(
					decoration: BoxDecoration(
						borderRadius: .circular(10),
					),
					child: _buildItem(
						name: itemName,
						onTap: () =>  Navigator.push(context,
							MaterialPageRoute(
								builder: (context) {
									if (isItemDir)
										return LibraryScreen(path: itemPath);
									else
										return SongScreen(path: itemPath);
								},
							),
						),
					),
				);
			},
		);
	}

	Widget _buildItem({
		required String name,
		required VoidCallback onTap,
	}) {
		return Material(
			color: Colors.transparent,
			child: InkWell(
				onTap: onTap,
				splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
				highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
					child: Text(name),
				),
			),
		);
	}
}

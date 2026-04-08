import 'dart:io';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'package:songbook/screens/song.dart';
import 'package:songbook/functions/set_name_dialog.dart';

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
	late String _currentPath;

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
		var (d, f, p) = readDirectory(pathStr: widget.path);
		setState(() {
			_dirs = d;
			_files = f;
			_currentPath = p;
		});
	}



	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar( title: Text('Library') ),
			body: _buildBody(),
			floatingActionButtonLocation: ExpandableFab.location,
			floatingActionButton: _buildFAB(),
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
					margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10), 
					decoration: BoxDecoration(
						borderRadius: .circular(10),
						border: Border.all(
							color: Theme.of(context).colorScheme.outline,
							width: 2,
						),
					),
					child: _buildItem(
						name: itemName,
						path: itemPath,
						isDir: isItemDir,
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
		required String path,
		required bool isDir,
		required VoidCallback onTap,
	}) {
		return Material(
			color: Colors.transparent,
			child: InkWell(
				onTap: onTap,
				splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
				highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
					child: Row(
						children: [
							Icon( (isDir) ? Icons.folder : Icons.music_note),
							const SizedBox(width: 5),

							Expanded(
								child: Text(name,
									maxLines: 2,
									overflow: TextOverflow.ellipsis,
								),
							),
							Spacer(),

							_buildPopupMenuButton(path, name),
						],
					),
				),
			),
		);
	}

	Widget _buildPopupMenuButton(String path, String name) {
		return PopupMenuButton<String>(
			icon: Icon(Icons.more_vert),
			tooltip: 'Options',
			offset: const Offset(0, 40),

			onSelected: (value) {
				switch (value) {
					case ('rename'):
						_rename(name);
						break;
					case ('delete'):
						removeFromLibrary(pathStr: path);
						_loadDirectory();
						break;
				}
			},
			itemBuilder: (context) => [
				const PopupMenuItem(
					value: 'rename',
					child: Text('Rename'),
				),
				const PopupMenuDivider(),

				const PopupMenuItem(
					value: 'delete',
					child: Text('Delete'),
				),

			],
		);
	}

	Widget _buildFAB() {
		return Padding(
			padding: const EdgeInsets.only(bottom: 20, right: 20),
			child: ExpandableFab(
				type: ExpandableFabType.up,
				distance: 70,
				overlayStyle: ExpandableFabOverlayStyle(
					color: Colors.white.withOpacity(0),
				),
				openButtonBuilder: RotateFloatingActionButtonBuilder(
					child: const Icon(Icons.add),
					fabSize: ExpandableFabSize.regular,
				),
				children: [
					Row(
						children: [
							Container(
								margin: const EdgeInsets.only(right: 10),
								padding: const EdgeInsets.all(10),
								decoration: BoxDecoration(
									borderRadius: .circular(10),
									color: Theme.of(context).colorScheme.primaryContainer,
								),
								child: Text('Add song',
									style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
								),
							),
							FloatingActionButton(
								heroTag: null,
								child: const Icon(Icons.music_note),
								onPressed: _addSong,
							),
						],
					),

					Row(
						children: [
							Container(
								margin: const EdgeInsets.only(right: 10),
								padding: const EdgeInsets.all(10),
								decoration: BoxDecoration(
									borderRadius: .circular(10),
									color: Theme.of(context).colorScheme.primaryContainer,
								),
								child: Text('Add folder',
									style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
								),
							),
							FloatingActionButton(
								heroTag: null,
								child: const Icon(Icons.folder),
								onPressed: _addFolder,
							),
						],
					),
				],
			),
		);
	}


	Future<void> _rename(String name) async {
		final String? newName = await setName(
			existsCheck: checkExistence,
			context: context,
			title: 'Rename',
			initialValue: name,
			hintText: 'New name...',
		);

		if (newName != null) {
			final String i_path = _currentPath + '/' + name;
			final String o_path = _currentPath + '/' + newName;
			moveFileOrDir(inputPathStr: i_path, outputPathStr: o_path);
			_loadDirectory();
		}
	}

	Future<void> _addFolder() async {
		final String? folderName = await setName(
			existsCheck: checkExistence,
			context: context,
			title: 'Create new folder',
			hintText: 'Folder name',
		);

		if (folderName != null) {
			final String path = _currentPath + '/' + folderName;
			createDirectory(pathStr: path);
			_loadDirectory();
		}
	}

	Future<void> _addSong() async {
	}


	bool checkExistence(String name) {
		final String path = _currentPath + '/' + name;
		
		return existenceCheck(pathStr: path);
	}
}

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'package:songbook/screens/song.dart';
import 'package:songbook/screens/settings.dart';
import 'package:songbook/functions/set_name_dialog.dart';

import 'package:songbook/src/rust/api/library.dart';
import 'package:songbook/src/rust/api/song.dart';


var _isAppDirSet = false;
const Duration _beforeDeleteDuration = Duration(seconds: 3);

List<String> _deleted = [];
Timer? _deleteTimer;

class LibraryScreen extends StatefulWidget {
	final String? path;
	final List<String>? copyBuffer;
	final List<String>? cutBuffer;
	LibraryScreen({super.key, this.path, this.copyBuffer, this.cutBuffer});

	State<LibraryScreen> createState() => _LibraryState();
}

class _LibraryState extends State<LibraryScreen> {
	List<String> _dirs = [];
	List<String> _files = [];
	late String _currentPath;
	bool _isCurrentDirEmpty = true;

	List<String> _selected = [];
	bool _isSelectMode = false;

	List<String> _copyBuffer = [];
	List<String> _cutBuffer = [];


	@override
	void initState() {
		super.initState();

		_copyBuffer = widget.copyBuffer ?? [];
		_cutBuffer = widget.cutBuffer ?? [];

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
			_isCurrentDirEmpty = (_dirs.isEmpty && _files.isEmpty);
		});
	}

	// Может быть сделаю ассинхронным
	void _paste() {
		if (_copyBuffer.isNotEmpty) {
			if (_copyBuffer.contains(_currentPath)) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(
						content: Text('Cannot copy in current dir!'),
						duration: Duration(seconds: 1)
					),
				);
				return;
			}

			copyPathListIn(
				pathsStr: _copyBuffer,
				outDirStr: _currentPath
			);
		} else if (_cutBuffer.isNotEmpty) {
			movePathListIn(
				pathsStr: _cutBuffer,
				outDirStr: _currentPath
			);
		}


		setState(() {
			_cutBuffer.clear();
			_copyBuffer.clear();
		});
		_loadDirectory();
	}

	void _delete(List<String> paths) {
		for (int i = 0; i < paths.length; i++) {
			String path = paths[i];
			if (_deleted.contains(path))
				continue;

			if (_copyBuffer.contains(path))
				_copyBuffer.remove(path);
			if (_cutBuffer.contains(path))
				_cutBuffer.remove(path);

			_deleted.add(path);
		}
		_scheduleDelete();
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(
				content: Row(
					mainAxisAlignment: .spaceBetween,
					children: [
						Text('Deleted: ${_deleted.length}'),
						TextButton(
							child: Text('Cancel', 
								style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary)
							),
							onPressed: () {
								_deleteTimer?.cancel();
								_deleted.clear();

								if (!mounted) return;
								ScaffoldMessenger.of(context).hideCurrentSnackBar();
								_loadDirectory();
							},
						),
					],
				),
				duration: _beforeDeleteDuration,
			),
		);

		_loadDirectory();
	}

	void _scheduleDelete() {
		_deleteTimer?.cancel();
		_deleteTimer = Timer(_beforeDeleteDuration, () {
			for (String path in _deleted) {
				removeFromLibrary(pathStr: path);
			}
			_deleted.clear();
		});
	}



	@override
	Widget build(BuildContext context) {
		return PopScope(
			canPop: !_isSelectMode,
			onPopInvokedWithResult: (didPop, result) async {
				if (_isSelectMode) {
					setState(() {
						_selected.clear();
						_isSelectMode = false;
					});
				}
			},
			child: _buildScaffold()
		);
	}

	Widget _buildScaffold() {
		return Scaffold(
			appBar: AppBar(
				title: Text( (widget.path == null)
					? 'Library'
					: _getPathName(_currentPath),
				),

				leading: (_isSelectMode || widget.path != null)
					? BackButton()
					: null,
				actions: [
					if (_copyBuffer.isNotEmpty || _cutBuffer.isNotEmpty)
						IconButton(
							icon: Icon(Icons.paste),
							tooltip: 'Paste',
							onPressed: _paste,
						),

					if (_isSelectMode)
						_buildAppBarPopupMenuButton(),

					if (!_isSelectMode)
						IconButton(
							icon: Icon(Icons.settings),
							tooltip: 'Settings',
							onPressed: () => Navigator.push(context,
								MaterialPageRoute(
									builder: (context) => SettingsScreen()
								),
							),
						),
				],
			),
			body: _isCurrentDirEmpty
				? Center( child: Text("There's nothing to show...") )
				: _buildBody(),
			floatingActionButtonLocation: ExpandableFab.location,
			floatingActionButton: _buildFAB(),
		);
	}

	Widget _buildAppBarPopupMenuButton() {
		return PopupMenuButton<String>(
			icon: Icon(Icons.more_vert),
			tooltip: 'Options',
			offset: const Offset(0, 40),
			shape: RoundedRectangleBorder(
				borderRadius: .circular(12),
			),

			onSelected: (value) {
				switch (value) {
					case ('rename'):
						String path = _selected[0];
						_rename(_getPathName(path));

						if (_copyBuffer.contains(path))
							_copyBuffer.remove(path);
						if (_cutBuffer.contains(path))
							_cutBuffer.remove(path);

						setState(() {
							_selected.clear();
							_isSelectMode = false;
						});
						break;
					case ('copy'):
						setState(() {
							_cutBuffer.clear();

							for (int i = 0; i < _selected.length; i++)
								if (!_copyBuffer.contains(_selected[i]))
									_copyBuffer.add(_selected[i]);

							_selected.clear();
							_isSelectMode = false;
						});
						break;
					case ('cut'):
						setState(() {
							_copyBuffer.clear();

							for (int i = 0; i < _selected.length; i++)
								if (!_cutBuffer.contains(_selected[i]))
									_cutBuffer.add(_selected[i]);

							_selected.clear();
							_isSelectMode = false;
						});
						break;
					case ('delete'):
						_delete(_selected);
						setState(() {
							_selected.clear();
							_isSelectMode = false;
						});
						break;
				}
			},
			itemBuilder: (context) => [
				if (_selected.length == 1)
					PopupMenuItem(
						value: 'rename',
						child: Text('Rename'),
					),
				const PopupMenuItem(
					value: 'copy',
					child: Text('Copy'),
				),
				const PopupMenuItem(
					value: 'cut',
					child: Text('Cut'),
				),
				const PopupMenuItem(
					value: 'delete',
					child: Text('Delete'),
				),
			],
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

				final itemName = _getPathName(itemPath);

				if (_cutBuffer.contains(itemPath) || _deleted.contains(itemPath))
					return SizedBox();


				return Container(
					margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10), 
					height: 70,
					child: _buildItem(
						name: itemName,
						path: itemPath,
						isDir: isItemDir,
						onTap: () async {
							if (!_isSelectMode) {
								await Navigator.push(context,
									MaterialPageRoute(
										builder: (context) {
											if (isItemDir)
												return LibraryScreen(
													path: itemPath,
													copyBuffer: _copyBuffer,
													cutBuffer: _cutBuffer,
												);
											else
												return SongScreen(path: itemPath);
										},
									),
								);
								_loadDirectory();
							} else
								_switchSelectionForPath(itemPath);
						},
						onLongPress: () {
							if (_isSelectMode) {
								if (_selected.contains(itemPath)) {
									_switchSelectionForPath(itemPath);
									return;
								}

								final List<String> allPaths = _files + _dirs;
								final int currentIndex = allPaths.indexOf(itemPath);
								final int lastAddedIndex = allPaths.indexOf(_selected.last);

								final betweenPaths = (currentIndex > lastAddedIndex)
									? allPaths.sublist(lastAddedIndex, currentIndex + 1)
									: allPaths.sublist(currentIndex, lastAddedIndex);


								setState(() {
									for (int i = 0; i < betweenPaths.length; i++) {
										final String path = betweenPaths[i];
										if (!_selected.contains(path))
											_selected.add(path);
									}
								});
							} else {
								setState(() {
									_isSelectMode = true;
									_selected.add(itemPath);
								});
							}
						},
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
		required VoidCallback onLongPress,
	}) {
		return Material(
			color: (_selected.contains(path))
				? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
				: Theme.of(context).colorScheme.surfaceContainer,
			clipBehavior: Clip.antiAlias,
			shape: RoundedRectangleBorder(
				borderRadius: .circular(10),
			),
			child: InkWell(
				onTap: onTap,
				onLongPress: onLongPress,
				splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
				highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
				child: Container(
					padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
					child: Row(
						mainAxisAlignment: .spaceBetween,
						children: [
							Icon( (isDir) ? Icons.folder : Icons.music_note),
							const SizedBox(width: 5),

							Expanded(
								child: Text(name,
									maxLines: 2,
									overflow: TextOverflow.ellipsis,
								),
							),
							const SizedBox(width: 10),

							if (!_isSelectMode)
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
			shape: RoundedRectangleBorder(
				borderRadius: .circular(12),
			),

			onSelected: (value) {
				switch (value) {
					case ('rename'):
						_rename(name);

						if (_copyBuffer.contains(path))
							_copyBuffer.remove(path);
						if (_cutBuffer.contains(path))
							_cutBuffer.remove(path);
						break;
					case ('copy'):
						_cutBuffer.clear();

						if (!_copyBuffer.contains(path))
							setState(() => _copyBuffer.add(path));
						break;
					case ('cut'):
						_copyBuffer.clear();

						if (!_cutBuffer.contains(path))
							setState(() => _cutBuffer.add(path));
						break;
					case ('delete'):
						_delete([path]);
						break;
				}
			},
			itemBuilder: (context) => [
				const PopupMenuItem(
					value: 'rename',
					child: Text('Rename'),
				),
				const PopupMenuItem(
					value: 'copy',
					child: Text('Copy'),
				),
				const PopupMenuItem(
					value: 'cut',
					child: Text('Cut'),
				),
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

					Row(
						children: [
							Container(
								margin: const EdgeInsets.only(right: 10),
								padding: const EdgeInsets.all(10),
								decoration: BoxDecoration(
									borderRadius: .circular(10),
									color: Theme.of(context).colorScheme.primaryContainer,
								),
								child: Text('Import',
									style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
								),
							),
							FloatingActionButton(
								heroTag: null,
								child: const Icon(Icons.download),
								onPressed: _importInLibrary,
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

	Future<void> _importInLibrary() async {
		final ImportFormat? importFormat = await _importDialog(context: context);
		if (importFormat == null)
			return;

		final List<String> extensions = switch (importFormat!) {
			ImportFormat.chordPro => ['cho'],
			ImportFormat.songBookPro => ['sbp', 'sbpbackup'],
			ImportFormat.yaml => ['yml', 'yaml'],
		};

		final FilePickerResult? result = await FilePicker.pickFiles(
			allowMultiple: true,
			type: FileType.custom,
			allowedExtensions: extensions,
		);

		if (result == null)
			return;

		switch (importFormat!) {
			case (ImportFormat.chordPro):
				_addFromChordPro(result.paths);
				break;

			case (ImportFormat.songBookPro):
				_addFromSongBookPro(result.paths);
				break;

			case (ImportFormat.yaml):
				_addFromYaml(result.paths);
				break;
		}

		await _loadDirectory();
	}
	void _addFromChordPro(List<String?> files) {
		for (int i = 0; i < files.length; i++) {
			if (files[i] == null)
				continue;

			final file = files[i]!;
			try { // в песни ниже поле path пустое
				SimpleSong song = SimpleSong.fromChordpro(pathStr: file);
				importSong(song: song, dirPath: _currentPath);
		} catch (e) {
				continue;
			}
		}
	}
	void _addFromSongBookPro(List<String?> files) {
		for (int i = 0; i < files.length; i++) {
			if (files[i] == null)
				continue;

			final file = files[i]!;
			try {
				List<SimpleSong> songs = SimpleSong.fromSongbookpro(pathStr: file);
				for (int i = 0; i < songs.length; i++) {
					final song = songs[i];
					try {
						importSong(song: song, dirPath: _currentPath);
					} catch (e) {
						continue;
					}
				}
		} catch (e) {
				continue;
			}
		}
	}
	void _addFromYaml(List<String?> files) {
		for (int i = 0; i < files.length; i++) {
			if (files[i] == null)
				continue;

			final file = files[i]!;
			try { // в песни ниже поле path пустое
				SimpleSong song = SimpleSong.open(pathStr: file);
				importSong(song: song, dirPath: _currentPath);
		} catch (e) {
				continue;
			}
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
		_buildAddSongBottomSheet(
			onDone: (artist, title, text) async {
				final String? songName = await setName(
					existsCheck: checkExistence,
					context: context,
					title: 'New song name',
					initialValue: artist + ' - ' + title,
					hintText: "Song's name",
				);
				if (songName == null)
					return;


				final String path = _currentPath + '/' + songName!;
				addNewSong(
					artist: artist,
					title: title,
					text: text,
					pathStr: path
				);
				_loadDirectory();


				Navigator.of(context).pop();
			},
		);
	}

	void _buildAddSongBottomSheet({required Function(String, String, String) onDone}) {
		showModalBottomSheet(
			context: context,
			isScrollControlled: true,
			builder: (context) {
				final screenHeight = MediaQuery.of(context).size.height;

				return Container(
					height: screenHeight * 0.9,
					width: double.infinity,
					padding: const EdgeInsets.all(10),
					decoration: BoxDecoration(
						borderRadius: .vertical(top: Radius.circular(12)),
						color: Theme.of(context).colorScheme.surfaceVariant,
					),
					child: SongAddScreen(onDone: onDone),
				);
			}
		);
	}


	bool checkExistence(String name) {
		final String path = _currentPath + '/' + name;
		
		return existenceCheck(pathStr: path);
	}


	String _getPathName(String path) {
		return path.substring(path.lastIndexOf('/') + 1);
	}

	void _switchSelectionForPath(String path) => setState(() {
		if (_selected.contains(path))
			_selected.remove(path);
		else
			_selected.add(path);

		if (_selected.isEmpty)
			_isSelectMode = false;
	});
}


class SongAddScreen extends StatefulWidget {
	Function(String, String, String) onDone;

	SongAddScreen({super.key, required this.onDone});


	@override
	State<SongAddScreen> createState() => SongAddState();
}

class SongAddState extends State<SongAddScreen> {
	late TextEditingController _artistController;
	late FocusNode _artistFocusNode;
	String? _artistError;

	late TextEditingController _titleController;
	late FocusNode _titleFocusNode;
	String? _titleError;

	late TextEditingController _songContentController;
	late FocusNode _songContentFocusNode;

	@override
	void initState() {
		super.initState();
		_artistController = TextEditingController();
		_artistFocusNode = FocusNode();

		_titleController = TextEditingController();
		_titleFocusNode = FocusNode();

		_songContentController = TextEditingController();
		_songContentFocusNode = FocusNode();
	}

	@override
	void dispose() {
		_artistController.dispose();
		_artistFocusNode.dispose();

		_titleController.dispose();
		_titleFocusNode.dispose();

		_songContentController.dispose();
		_songContentFocusNode.dispose();

		super.dispose();
	}


	@override
	Widget build(BuildContext context) {
		return Column(
			children: [
				Padding(
					padding: const EdgeInsets.all(15),
					child: Row(
						children: [
							TextButton(
								child: Text('Cancel'),
								onPressed: () => Navigator.of(context).pop(),
							),
							Spacer(),
							ElevatedButton(
								child: Text('Done'),
								onPressed: () {
									final artist = _artistController.text.trim();
									final artistCheckResult = _validateName(artist);
									if (artistCheckResult != null) {
										setState(() => _artistError = artistCheckResult);
										_artistFocusNode.requestFocus();

										return;
									}

									final title = _titleController.text.trim();
									final titleCheckResult = _validateName(title);
									if (titleCheckResult != null) {
										setState(() => _titleError = titleCheckResult);
										_titleFocusNode.requestFocus();

										return;
									}

									final text = _songContentController.text;
									widget.onDone(artist, title, text);
								},
							),
						],
					),
				),

				Row(
					children: [
						Expanded(
							child: TextField(
								controller: _artistController,
								focusNode: _artistFocusNode,
								decoration: InputDecoration(
									border: OutlineInputBorder(),
									hintText: "Artist...",
									errorText: _artistError,
								),
								onChanged: (value) {
									setState(() => _artistError = _validateName(value));
								},
								onSubmitted: (value) {
									final String text = value.trim();
									final checkResult = _validateName(text);
									if (checkResult == null) {
										_titleFocusNode.requestFocus();
									} else {
										setState(() => _artistError = checkResult);
										_artistFocusNode.requestFocus();
									}
								}
							),
						),
						const SizedBox(width: 10),
						Expanded(
							child: TextField(
								controller: _titleController,
								focusNode: _titleFocusNode,
								decoration: InputDecoration(
									border: OutlineInputBorder(),
									hintText: "Title...",
									errorText: _titleError,
								),
								onChanged: (value) {
									setState(() => _titleError = _validateName(value));
								},
								onSubmitted: (value) {
									final String text = value.trim();
									final checkResult = _validateName(text);
									if (checkResult == null) {
										_songContentFocusNode.requestFocus();
									} else {
										setState(() => _titleError = checkResult);
										_titleFocusNode.requestFocus();
									}
								}
							),
						),
					]
				),
				const SizedBox(height: 20),
				Expanded(
					child: TextField(
						controller: _songContentController,
						focusNode: _songContentFocusNode,
						maxLines: null,
						expands: true,
						textAlignVertical: .top,
						style: TextStyle(fontFamily: 'CascadiaMono'),
						decoration: const InputDecoration(
							border: OutlineInputBorder(),
							hintText: "Song's text...",
						),
					),
				),

				SizedBox(height: MediaQuery.of(context).viewInsets.bottom), // для клавиатуры
			],
		);
	}
	String? _validateName(String value) {
		final trimmed = value.trim();

		if (trimmed.isEmpty)
			return 'Text cannot be empty!';
		
		final forbiddenChars = getForbiddenChars();
		if (trimmed.characters.any((char) => forbiddenChars.contains(char)))
			return 'Text contains forbidden chars!';
		
		return null;
	}
}


enum ImportFormat {
	chordPro,
	songBookPro,
	yaml, // Собственный формат
}

Future<ImportFormat?> _importDialog({
	required BuildContext context,
}) async {
	return showDialog<ImportFormat?>(
		context: context,
		barrierDismissible: true,
		builder: (context) {
			return SimpleDialog(
				title: const Text('Import format'),
				children: [
					SimpleDialogOption(
						onPressed: () => Navigator.pop(context, ImportFormat.chordPro),
						padding: const EdgeInsets.all(20),
						child: Text('ChordPro (.cho)'),
					),
					SimpleDialogOption(
						onPressed: () => Navigator.pop(context, ImportFormat.songBookPro),
						padding: const EdgeInsets.all(20),
						child: Text('SongBookPro (.sbp, .sbpbackup)'),
					),
					SimpleDialogOption(
						onPressed: () => Navigator.pop(context, ImportFormat.yaml),
						padding: const EdgeInsets.all(20),
						child: Text('songbook (.yml, .yaml)'),
					),
				],
			);
		},
	);
}

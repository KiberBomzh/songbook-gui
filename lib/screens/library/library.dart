import 'dart:async';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:provider/provider.dart';

import 'package:songbook/main.dart';
import 'package:songbook/screens/song/song.dart';
import 'package:songbook/screens/editor/editor.dart';
import 'package:songbook/screens/settings/settings.dart';
import 'package:songbook/screens/library/add_song.dart';
import 'package:songbook/functions/set_name_dialog.dart';
import 'package:songbook/services/settings.dart';

import 'package:songbook/src/rust/api/library.dart';
import 'package:songbook/src/rust/api/song.dart';

import 'package:songbook/l10n/app_localizations.dart';


const Duration _beforeDeleteDuration = Duration(seconds: 3);
const Duration _beforeMoveDuration = Duration(seconds: 3);

List<String> _deleted = [];
Timer? _deleteTimer;

List<String> _moved = [];
Timer? _moveTimer;

class LibraryScreen extends StatefulWidget {
	final String? path;
	final List<String>? copyBuffer;
	final List<String>? cutBuffer;
	const LibraryScreen({
		super.key,
		this.path,
		this.copyBuffer,
		this.cutBuffer,
	});

	@override
	State<LibraryScreen> createState() => _LibraryState();
}

class _LibraryState extends State<LibraryScreen> {
	late SettingsProvider _settings;

	final _fabKey = GlobalKey<ExpandableFabState>();

	List<String> _dirs = [];
	List<String> _files = [];
	late String _currentPath;
	bool _isCurrentDirEmpty = true;

	final List<String> _selected = [];
	bool _isSelectMode = false;

	List<String> _copyBuffer = [];
	List<String> _cutBuffer = [];

	bool _isSearchMode = false;
	bool _isLoadingSearchResults = false;
	late final TextEditingController _searchTextController;
	late final FocusNode _searchFocusNode;
	Timer? _searchTimer;

	bool _isLoading = false;

	Set<String>? _currentTags;


	@override
	void initState() {
		super.initState();

		_copyBuffer = widget.copyBuffer ?? [];
		_cutBuffer = widget.cutBuffer ?? [];

		_searchTextController = TextEditingController();
		_searchFocusNode = FocusNode();

		_loadDirectory();
	}

	@override
	void dispose() {
		_searchTextController.dispose();
		_searchFocusNode.dispose();
		super.dispose();
	}

	Future<void> _loadDirectory() async {
		var (d, f, p) = readDirectory(pathStr: widget.path);
		setState(() {
			_isSearchMode = false;
			_searchTextController.text = '';
			_currentTags = null;
			_dirs = d;
			_files = f;
			_currentPath = p;
			_isCurrentDirEmpty = (_dirs.isEmpty && _files.isEmpty);
		});
	}

	void _search(String query) async {
		setState(() {
			_isCurrentDirEmpty = false;
			_isLoadingSearchResults = true;
		});
		_dirs.clear();

		if (query.startsWith('#')) {
			_currentTags = {};
			_files = await tagSearch(
				tags: query.split(', ').map((tag) {
					if (tag.isEmpty || !tag.startsWith('#'))
						return '';

					tag = tag.substring(1);
					_currentTags?.add(tag);

					return tag;
				}).toList()
			);
		} else {
			_currentTags == null;
			_files = search(pathStr: _currentPath, query: query);
		}

		setState(() {
			_isCurrentDirEmpty = _files.isEmpty;
			_isLoadingSearchResults = false;
		});
	}
	void _scheduleSearch(String query) {
		_searchTimer?.cancel();
		_searchTimer = Timer(Duration(milliseconds: 500), () => _search(query));
	}

	// Может быть сделаю ассинхронным
	void _paste() {
		if (_copyBuffer.isNotEmpty) {
			if (_copyBuffer.contains(_currentPath)) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text(AppLocalizations.of(context)!.librarySnackBarPasteErrorMsg),
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
						Text('${AppLocalizations.of(context)!.libraryDeletedMsg}: ${_deleted.length}'),
						TextButton(
							child: Text(AppLocalizations.of(context)!.cancel, 
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
			_loadDirectory();
		});
	}

	void _scheduleMove(String input, String output) {
		_moveTimer = Timer(_beforeMoveDuration, () {
			moveFileOrDir(
				inputPathStr: input,
				outputPathStr: output,
			);

			_moved.remove(input);
			if (mounted)
				_loadDirectory();
		});
	}



	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();

		return PopScope(
			canPop: !(_isSelectMode || _isSearchMode || _isLoading),
			onPopInvokedWithResult: (didPop, result) {
				if (_isSelectMode) {
					setState(() {
						_selected.clear();
						_isSelectMode = false;
					});
					return;
				}

				if (_isSearchMode) {
					setState(() => _isSearchMode = false);
					_loadDirectory();
					return;
				}
			},
			child: Container(
				decoration: BoxDecoration(
					image: (_settings.backgroundImage != null)
						? DecorationImage(
							image: FileImage(_settings.backgroundImage!),
							fit: .cover,
						)
						: null,
				),
				child: Stack(
					children: [
						_buildScaffold(),
						if (_isLoading)
							Container(
								color: Colors.black.withValues(alpha: 0.7),
								child: Center(
									child: CircularProgressIndicator(),
								),
							),
					],
				),
			),
		);
	}

	Widget _buildScaffold() {
		return Scaffold(
			appBar: AppBar(
				title: _buildAppBarTitle(),
				leading: (_isSelectMode || _isSearchMode || widget.path != null)
					? BackButton()
					: null,
				actions: [
					if ( (_copyBuffer.isNotEmpty || _cutBuffer.isNotEmpty) && !_isSearchMode)
						IconButton(
							icon: Icon(Icons.paste),
							tooltip: AppLocalizations.of(context)!.libraryTooltipPaste,
							onPressed: _paste,
						),

					if (!_isSearchMode)
						IconButton(
							icon: Icon(Icons.search),
							tooltip: AppLocalizations.of(context)!.libraryTooltipSearch,
							onPressed: () => setState(() {
								_isSearchMode = true;
								_files.clear();
								_dirs.clear();
								_searchFocusNode.requestFocus();
							}),
						),

					if (_isSelectMode)
						_buildAppBarMenuButton(),

					if (_isSearchMode && !_isSelectMode)
						IconButton(
							icon: Icon(Icons.tag),
							tooltip: AppLocalizations.of(context)!.libraryTags,
							onPressed: () async {
								setState(() => _isLoading = true);
								final tagMap = await getTagMap();
								setState(() => _isLoading = false);

								if (!mounted)
									return;

								final result = await showDialog(
									context: context,
									builder: (context) => AlertDialog(
										title:  Text(AppLocalizations.of(context)!.libraryTags),
										content: (tagMap.keys.isNotEmpty) 
											? Wrap(
												spacing: 5,
												runSpacing: 5,
												children: tagMap.keys.map((tag) => FilterChip(
													label: Text('#' + tag),
													onSelected: (_) => Navigator.of(context).pop('#' + tag),
												)).toList()
											)
											: Text(AppLocalizations.of(context)!.libraryTagsNotFoundMsg),
									),
								);
								
								if (result != null) {
									_searchTextController.text = result;
									_search(result!);
								}
							},
						),

					if (!_isSelectMode)
						IconButton(
							icon: Icon(Icons.settings),
							tooltip: AppLocalizations.of(context)!.libraryTooltipSettings,
							onPressed: () => Navigator.push(context,
								MaterialPageRoute(
									builder: (context) => SettingsScreen()
								),
							),
						),
				],
			),
			body: _isCurrentDirEmpty
				? Center( child: Text(AppLocalizations.of(context)!.libraryEmpty) )
				: _buildBody(),
			floatingActionButtonLocation: ExpandableFab.location,
			floatingActionButton: _buildFAB(),
		);
	}

	Widget _buildAppBarTitle() {
		if (_isSelectMode) {
			return Text(_selected.length.toString());
		} else if (_isSearchMode) {
			return TextField(
				controller: _searchTextController,
				focusNode: _searchFocusNode,
				decoration: InputDecoration(
					constraints: BoxConstraints(maxHeight: 40),
					contentPadding: const EdgeInsets.all(5),
					hintText: (widget.path == null)
						? AppLocalizations.of(context)!.libraryTitle
						: _getPathName(_currentPath),
					border: OutlineInputBorder(borderSide: .none),
				),
				onChanged: _scheduleSearch,
				onSubmitted: _search,
			);
		} else {
			return Text( (widget.path == null)
				? AppLocalizations.of(context)!.libraryTitle
				: _getPathName(_currentPath),
			);
		}
	}

	Widget _buildAppBarMenuButton() {
		return MenuAnchor(
			animated: true,
			builder: (context, controller, child) => IconButton(
				icon: Icon(Icons.more_vert),
				tooltip: AppLocalizations.of(context)!.libraryTooltipOptions,
				onPressed: () {
					if (controller.isOpen) {
						controller.close();
					} else {
						controller.open();
					}
				},
			),
			menuChildren: [
				if (_selected.length == 1) ...[
					MenuItemButton(
						child: Text(AppLocalizations.of(context)!.libraryOptionRename),
						onPressed: () {
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
						},
					),

					if (!_dirs.contains(_selected[0]))
					MenuItemButton(
						child: Text(AppLocalizations.of(context)!.libraryOptionEdit),
						onPressed: () {
							String path = _selected[0];
							Navigator.push(context,
								MaterialPageRoute(
									builder: (context) => EditorScreen(
										path: path,
										mode: EditorMode.source,
									),
								),
							);

							setState(() {
								_selected.clear();
								_isSelectMode = false;
							});
						},
					),
				],

				MenuItemButton(
					child: Text(AppLocalizations.of(context)!.libraryOptionCopy),
					onPressed: () {
						_cutBuffer.clear();

						for (int i = 0; i < _selected.length; i++)
							if (!_copyBuffer.contains(_selected[i]))
								_copyBuffer.add(_selected[i]);

						_selected.clear();
						_isSelectMode = false;
						_loadDirectory();
					},
				),

				MenuItemButton(
					child: Text(AppLocalizations.of(context)!.libraryOptionCut),
					onPressed: () {
						_copyBuffer.clear();

						for (int i = 0; i < _selected.length; i++)
							if (!_cutBuffer.contains(_selected[i]))
								_cutBuffer.add(_selected[i]);

						_selected.clear();
						_isSelectMode = false;
						_loadDirectory();
					},
				),

				MenuItemButton(
					child: Text(AppLocalizations.of(context)!.libraryOptionDelete),
					onPressed: () {
						_delete(_selected);
						setState(() {
							_selected.clear();
							_isSelectMode = false;
						});
					},
				),
			],
		);
	}


	Widget _buildBody() {
		if (_isLoadingSearchResults)
			return const Center(
				child: CircularProgressIndicator(),
			);

		return ListView.builder(
			itemCount: _dirs.length + _files.length,
			itemBuilder: (context, dirsIndex) {
				final filesIndex = dirsIndex - _dirs.length;
				final bool isItemDir = (dirsIndex < _dirs.length);
				final itemPath = isItemDir
					? _dirs[dirsIndex]
					: _files[filesIndex];

				final itemName = _getPathName(itemPath);

				if (_cutBuffer.contains(itemPath) || _deleted.contains(itemPath) || _moved.contains(itemPath))
					return SizedBox();


				return Container(
					margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10), 
					height: 70,
					decoration: BoxDecoration(
						color: Theme.of(context).colorScheme.surfaceContainer,
						borderRadius: .circular(10),
					),
					child: _buildItem(
						name: itemName,
						path: itemPath,
						isDir: isItemDir,
						onTap: () async {
							_searchFocusNode.unfocus();

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

								if (!_isSearchMode)
									_loadDirectory();
							} else
								_switchSelectionForPath(itemPath);
						},
						onLongPress: () {
							_searchFocusNode.unfocus();

							if (_isSelectMode) {
								if (_selected.contains(itemPath)) {
									_switchSelectionForPath(itemPath);
									return;
								}

								final List<String> allPaths = _dirs + _files;
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
		if (_isSelectMode)
			return _buildItemContent(
				name: name,
				path: path,
				isDir: isDir,
				onTap: onTap,
				onLongPress: onLongPress,
			);

		return LongPressDraggable<String>(
			data: path,
			onDraggableCanceled: (_, _) => onLongPress(),
			feedback: Container(
				padding: const .all(15),
				width: MediaQuery.of(context).size.width - 50,
				decoration: BoxDecoration(
					color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
					borderRadius: .circular(10),
				),
				child: _buildItemContent(
					name: name,
					path: path,
					isDir: isDir,
					onTap: null,
					onLongPress: null,
				),
			),
			childWhenDragging: Opacity(
				opacity: 0.3,
				child: _buildItemContent(
					name: name,
					path: path,
					isDir: isDir,
					onTap: null,
					onLongPress: null,
				),
			),
			child: DragTarget<String>(
				onWillAcceptWithDetails: (details) {
					if (details.data == path)
						return false;

					if (path.startsWith(details.data))
						return false;

					return isDir;
				},
				onAcceptWithDetails: (details) {
					if (_copyBuffer.contains(details.data))
						_copyBuffer.remove(details.data);
					if (_cutBuffer.contains(details.data))
						_cutBuffer.remove(details.data);

					_moved.add(details.data);

					_scheduleMove(details.data, path);
					ScaffoldMessenger.of(context).showSnackBar(
						SnackBar(
							content: Row(
								mainAxisAlignment: .spaceBetween,
								children: [
									Text(AppLocalizations.of(context)!.libraryMovedMsg),
									TextButton(
										child: Text(AppLocalizations.of(context)!.cancel, 
											style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary)
										),
										onPressed: () {
											_moveTimer?.cancel();
											_moved.remove(details.data);

											if (!mounted) return;
											ScaffoldMessenger.of(context).hideCurrentSnackBar();
											_loadDirectory();
										},
									),
								],
							),
							duration: _beforeMoveDuration,
						),
					);

					_loadDirectory();
				},
				builder: (context, candidateData, rejectedData) {
					final isActive = candidateData.isNotEmpty;

					return Container(
						decoration: BoxDecoration(
							color: (isActive)
								? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
								: Colors.transparent,
							borderRadius: .circular(10),
						),
						child: _buildItemContent(
							name: name,
							path: path,
							isDir: isDir,
							onTap: onTap,
							onLongPress: null,
						),
					);
				},
			),
		);
	}

	Widget _buildItemContent({
		required String name,
		required String path,
		required bool isDir,
		required VoidCallback? onTap,
		required VoidCallback? onLongPress,
	}) {
		return Material(
			color: (_selected.contains(path))
				? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)
				: Colors.transparent,
			clipBehavior: Clip.antiAlias,
			shape: RoundedRectangleBorder(
				borderRadius: .circular(10),
			),
			child: InkWell(
				onTap: onTap,
				onLongPress: onLongPress,
				splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
				highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
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
								_buildMenuButton(path, name, isDir),
						],
					),
				),
			),
		);
	}

	Widget _buildMenuButton(String path, String name, bool isDir) {
		return MenuAnchor(
			animated: true,
			builder: (context, controller, child) {
				return IconButton(
					icon: Icon(Icons.more_vert),
					tooltip: AppLocalizations.of(context)!.libraryTooltipOptions,
					onPressed: () {
						if (controller.isOpen) {
							controller.close();
						} else {
							controller.open();
						}
					},
				);
			},
			menuChildren: [
				MenuItemButton(
					child: Text(AppLocalizations.of(context)!.libraryOptionRename),
					onPressed: () {
						_rename(name);

						if (_copyBuffer.contains(path))
							_copyBuffer.remove(path);
						if (_cutBuffer.contains(path))
							_cutBuffer.remove(path);
					},
				),
				if (!isDir)
					MenuItemButton(
						child: Text(AppLocalizations.of(context)!.libraryOptionEdit),
						onPressed: () {
							Navigator.push(context,
								MaterialPageRoute(
									builder: (context) => EditorScreen(
										path: path,
										mode: EditorMode.source,
									),
								),
							);
						},
					),
				MenuItemButton(
					child: Text(AppLocalizations.of(context)!.libraryOptionCopy),
					onPressed: () {
						_cutBuffer.clear();

						if (!_copyBuffer.contains(path)) {
							_copyBuffer.add(path);
							_loadDirectory();
						}
					},
				),
				MenuItemButton(
					child: Text(AppLocalizations.of(context)!.libraryOptionCut),
					onPressed: () {
						_copyBuffer.clear();

						if (!_cutBuffer.contains(path)) {
							_cutBuffer.add(path);
							_loadDirectory();
						}
					},
				),
				MenuItemButton(
					child: Text(AppLocalizations.of(context)!.libraryOptionDelete),
					onPressed: () => _delete([path]),
				),
			],
		);
	}

	Widget _buildFAB() {
		return Padding(
			padding: const EdgeInsets.only(bottom: 20, right: 20),
			child: ExpandableFab(
				key: _fabKey,
				type: ExpandableFabType.up,
				distance: 70,
				overlayStyle: ExpandableFabOverlayStyle(
					color: Colors.white.withValues(alpha: 0),
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
								child: Text(AppLocalizations.of(context)!.libraryAddOptionSong,
									style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
								),
							),
							FloatingActionButton(
								heroTag: null,
								child: const Icon(Icons.music_note),
								onPressed: () => _fabActionWrapper(_addSong),
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
								child: Text(AppLocalizations.of(context)!.libraryAddOptionFolder,
									style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
								),
							),
							FloatingActionButton(
								heroTag: null,
								child: const Icon(Icons.folder),
								onPressed: () => _fabActionWrapper(_addFolder),
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
								child: Text(AppLocalizations.of(context)!.libraryAddOptionImport,
									style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
								),
							),
							FloatingActionButton(
								heroTag: null,
								child: const Icon(Icons.download),
								onPressed: () => _fabActionWrapper(_importInLibrary),
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
								child: Text(AppLocalizations.of(context)!.libraryAddOptionLink,
									style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
								),
							),
							FloatingActionButton(
								heroTag: null,
								child: const Icon(Icons.link),
								onPressed: () => _fabActionWrapper(_addFromLink),
							),
						],
					),
				],
			),
		);
	}
	void _fabActionWrapper(VoidCallback action) {
		if (_fabKey.currentState != null && _fabKey.currentState!.isOpen)
			_fabKey.currentState!.toggle();

		Timer(const Duration(milliseconds: 500), action);
	}


	Future<void> _rename(String name) async {
		final String? newName = await setName(
			existsCheck: checkExistence,
			context: context,
			title: AppLocalizations.of(context)!.libraryRenameDialogTitle,
			initialValue: name,
			hintText: AppLocalizations.of(context)!.libraryRenameDialogHint,
		);

		if (newName != null) {
			final String i_path = _currentPath + pathDivider + name;
			final String o_path = _currentPath + pathDivider + newName;
			moveFileOrDir(inputPathStr: i_path, outputPathStr: o_path);
			_loadDirectory();
		}
	}

	Future<void> _addFromLink() async {
		final link = await _addFromLinkDialog();
		if (link == null)
			return;

		try {
			setState(() => _isLoading = true);
			SimpleSong? song;
			song = await SimpleSong.fromUrl(url: link);
			

			if (song != null) {
				song.setTags(tags: (_isSearchMode) ? _currentTags : null);
				importSong(song: song, dirPath: _currentPath);
				_loadDirectory();
			} else {
				_showSnackBarAddFromLinkError();
			}
		} catch(e) {
			_showSnackBarAddFromLinkError();
		} finally {
			setState(() => _isLoading = false);
		}
	}
	void _showSnackBarAddFromLinkError() {
		if (mounted)
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(AppLocalizations.of(context)!.librarySnackBarAddFromLinkError),
					duration: Duration(seconds: 3)
				),
			);
	}
	Future<String?> _addFromLinkDialog() async {
		return showDialog<String?>(
			context: context,
			barrierDismissible: true,
			builder: (context) => _AddFromLinkDialog(),
		);
	}

	Future<void> _importInLibrary() async {
		final ImportFormat? importFormat = await _importDialog(context: context);
		if (importFormat == null)
			return;

		final List<String> extensions = switch (importFormat) {
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

		switch (importFormat) {
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
				song.setTags(tags: (_isSearchMode) ? _currentTags : null);
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
						song.setTags(tags: (_isSearchMode) ? _currentTags : null);
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
				song.setTags(tags: (_isSearchMode) ? _currentTags : null);
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
			title: AppLocalizations.of(context)!.libraryNewFolderDialogTitle,
			hintText: AppLocalizations.of(context)!.libraryNewFolderDialogHint,
		);

		if (folderName != null) {
			final String path = _currentPath + pathDivider + folderName;
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
					title: AppLocalizations.of(context)!.libraryAddSongDialogTitle,
					initialValue: artist + ' - ' + title,
					hintText: AppLocalizations.of(context)!.libraryAddSongDialogHint,
				);
				if (songName == null)
					return;


				final String path = _currentPath + pathDivider + songName;
				addNewSong(
					artist: artist,
					title: title,
					text: text,
					pathStr: path,
					tags: (_isSearchMode) ? _currentTags : null,
				);
				_loadDirectory();


				if (mounted)
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
						color: Theme.of(context).colorScheme.surfaceContainerHighest,
					),
					child: AddSong(onDone: onDone),
				);
			}
		);
	}


	bool checkExistence(String name) {
		final String path = _currentPath + pathDivider + name;
		
		return existenceCheck(pathStr: path);
	}


	String _getPathName(String path) {
		return path.substring(path.lastIndexOf(pathDivider) + 1);
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
				title: Text(AppLocalizations.of(context)!.libraryImportDialogTitle),
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

class _AddFromLinkDialog extends StatefulWidget {
	@override
	State<_AddFromLinkDialog> createState() => _AddFromLinkDialogState();
}
class _AddFromLinkDialogState extends State<_AddFromLinkDialog> {
	late final TextEditingController _controller;
	late final FocusNode _focusNode;

	@override
	void initState() {
		super.initState();
		_controller = TextEditingController();
		_focusNode = FocusNode();
		_focusNode.requestFocus();
	}

	@override
	void dispose() {
		_controller.dispose();
		_focusNode.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) => AlertDialog(
		title: Row(
			mainAxisAlignment: .spaceBetween,
			children: [
				Text(AppLocalizations.of(context)!.libraryAddFromLinkDialogTitle),
				IconButton(
					icon: Icon(Icons.help),
					onPressed: () => _availableSitesDialog(),
				),
			],
		),
		content: TextField(
			controller: _controller,
			focusNode: _focusNode,
			decoration: InputDecoration(
				border: OutlineInputBorder(),
				constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
			),
			onSubmitted: (value) => Navigator.of(context).pop(value),
		),
		actions: [
			TextButton(
				child: Text(AppLocalizations.of(context)!.cancel),
				onPressed: () => Navigator.of(context).pop(),
			),
			ElevatedButton(
				child: Text(AppLocalizations.of(context)!.done),
				onPressed: () => Navigator.of(context).pop(_controller.text),
			),
		]
	);

	Future<void> _availableSitesDialog() async {
		return showDialog(
			context: context,
			barrierDismissible: true,
			builder: (context) => SimpleDialog(
				title: Text(AppLocalizations.of(context)!.libraryAvailableSitesDialogTitle),
				children: getAvailableSites().map((site) => Padding(
					padding: const .all(10),
					child: Text(site),
				)).toList()
			),
		);
	}
}

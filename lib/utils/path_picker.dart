import 'dart:io';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:songbook/l10n/app_localizations.dart';

import 'package:songbook/functions/get_path_name.dart';
import 'package:songbook/services/settings.dart';


class PathPicker extends StatefulWidget {
	final String dir;

	const PathPicker({
		super.key,
		required this.dir,
	});

	@override
	State<PathPicker> createState() => _PathPickerState();
}

class _PathPickerState extends State<PathPicker> {
	late SettingsProvider _settings;

	bool _isLoading = false;
	late final Directory _dir;

	final _dirs = [];
	final _files = [];

	@override
	void initState() {
		super.initState();
		_dir = Directory(widget.dir);
		_loadDir();
	}

	Future<void> _loadDir() async {
		setState(() => _isLoading = true );

		_dirs.clear();
		_files.clear();

		await for (final entry in _dir.list(recursive: false, followLinks: true)) {
			if (entry is Directory) {
				_dirs.add(entry.path);
			} else if (entry is File) {
				_files.add(entry.path);
			}
		}

		_dirs.sort();
		_files.sort();

		setState(() => _isLoading = false );
	}


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();

		return Container(
			decoration: BoxDecoration(
				image: (_settings.backgroundImage != null)
					? DecorationImage(
						image: FileImage(_settings.backgroundImage!),
						fit: .cover,
					)
					: null,
			),
			child: Scaffold(
				appBar: AppBar(
					title: Text(getPathName(widget.dir)),
				),
				body: _buildBody(),
			),
		);
	}

	Widget _buildBody() {
		if (_isLoading)
			return Center(
				child: CircularProgressIndicator(),
			);


		return RefreshIndicator(
			onRefresh: _loadDir,
			child: Column(
				children: [
					Expanded(
						child: ListView(
							children: [
								..._dirs.map((dir) {
									return _buildItem(
										name: getPathName(dir),
										isDir: true,
										onTap: () async {
											final result = await Navigator.push(context,
												MaterialPageRoute(
													builder: (context) => PathPicker(dir: dir),
												),
											);

											if (result != null && mounted)
												Navigator.pop(context, result);
										},
									);
								}),

								..._files.map((file) {
									return _buildItem(
										name: getPathName(file),
										isDir: false,
										onTap: null,
									);
								}),
							],
						),
					),
					
					const SizedBox(height: 5),

					ElevatedButton(
						style: ElevatedButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
						),
						onPressed: () => Navigator.pop(context, _dir.path),
						child: SizedBox(
							width: double.infinity,
							height: 80,
							child: Center(
								child: Text(AppLocalizations.of(context)!.select),
							),
						),
					),


					SizedBox(height: MediaQuery.of(context).padding.bottom),
				],
			),
		);
	}

	Widget _buildItem({
		required String name,
		required bool isDir,
		required VoidCallback? onTap,
	}) {
		return Container(
			margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
			height: 70,
			decoration: BoxDecoration(
				borderRadius: .circular(10),
			),
			child: Material(
				color: Theme.of(context).colorScheme.surfaceContainer,
				clipBehavior: Clip.antiAlias,
				shape: RoundedRectangleBorder(
					borderRadius: .circular(10),
				),
				child: InkWell(
					onTap: onTap,
					child: Container(
						padding: const .symmetric(horizontal: 15, vertical: 15),
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
							],
						),
					),
				),
			),
		);
	}
}

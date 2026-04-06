import 'package:flutter/material.dart';

import 'package:songbook/src/rust/api/library.dart';


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

		var (d, f) = readDirectory(pathStr: widget.path);
		setState(() {
			_dirs = d;
			_files = f;
		});
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
						onTap: () {
							if (isItemDir) {
								Navigator.push(context,
									MaterialPageRoute(
										builder: (context) => LibraryScreen(path: itemPath),
									),
								);
							} else {
								print('fsdj');
							}
						},
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

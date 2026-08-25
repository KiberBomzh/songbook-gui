import 'package:flutter/material.dart';

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
				title: const Text('Share Handler'),
			),
			body: SongScreen(path: path),
		);
	}
}

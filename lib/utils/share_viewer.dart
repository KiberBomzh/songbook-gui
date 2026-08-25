import 'package:flutter/material.dart';

import 'package:zikzak_share_handler/zikzak_share_handler.dart';

import 'package:songbook/screens/song/song.dart';


class ShareViewer extends StatelessWidget {
	SharedMedia media;

	ShareViewer({
		super.key,
		required this.media,
	});

	@override
	Widget build(BuildContext context) {
		final path = media.attachments?[0].path;
		if (path == null)
			Navigator.of(context).pop();

		return Scaffold(
			appBar: AppBar(
				title: const Text('Share Handler'),
			),
			body: SongScreen(path: path!),
		);
	}
}

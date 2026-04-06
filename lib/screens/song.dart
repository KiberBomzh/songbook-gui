import 'package:flutter/material.dart';

import 'package:songbook/src/rust/api/song.dart';


class SongScreen extends StatefulWidget {
	final String path;

	SongScreen({super.key, required this.path});


	@override
	State<SongScreen> createState() => SongState();
}

class SongState extends State<SongScreen> {
	String song = '';

	@override
	void initState() {
		super.initState();
		setState(() {
			song = getSongAsString(pathStr: widget.path);
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar( title: Text('Song') ),
			body: SingleChildScrollView(
				child: Container(
					width: double.infinity,
					child: Text(song),
				),
			),
		);
	}
}

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:songbook/src/rust/api/song.dart';

import 'package:songbook/screens/editor.dart';


final Color chordsColor = Colors.cyan;
final Color rhythmColor = Colors.orange;
final Color notesColor = Colors.blue.withOpacity(0.7);


final chordsStyle = 
	GoogleFonts.jetBrainsMono( textStyle: TextStyle(color: chordsColor) );

final rhythmStyle =
	GoogleFonts.jetBrainsMono( textStyle: TextStyle(color: rhythmColor) );

final textStyle = GoogleFonts.jetBrainsMono();



class SongScreen extends StatefulWidget {
	final String path;

	SongScreen({super.key, required this.path});


	@override
	State<SongScreen> createState() => SongState();
}

class SongState extends State<SongScreen> {
	late SimpleSong song;

	@override
	void initState() {
		super.initState();
		song = SimpleSong.open(pathStr: widget.path);
	}


	void _edit() async {
		final result = await Navigator.push(context,
			MaterialPageRoute(
				builder: (context) => EditorScreen(song: song),
			),
		);

		setState(() {});
	}

	@override
	Widget build(BuildContext context) {
		final List<SimpleBlock> blocks = song.getBlocks();

		return Scaffold(
			appBar: AppBar(
				title: Text('Song'),
				actions: [
					IconButton(
						icon: Icon(Icons.edit),
						tooltip: 'Edit',
						onPressed: _edit,
					),
				],
			),
			body: (blocks.length > 0)
				? _buildBody(blocks)
				: Center(
					child: Text('The song is empty...')
				),
		);
	}

	Widget _buildBody(List<SimpleBlock> blocks) {
		return SingleChildScrollView(
			scrollDirection: Axis.horizontal,
			child: ConstrainedBox(
				constraints: BoxConstraints(
					minWidth: MediaQuery.of(context).size.width,
				),
				child: SingleChildScrollView(
					scrollDirection: Axis.vertical,
					child: Padding(
						padding: const EdgeInsets.symmetric(horizontal: 10),
						child: Column(
							crossAxisAlignment: .start,
							children: [
								...blocks.map((block) => _buildBlock(block)),
							],
						),
					),
				),
			),
		);
	}

	Widget _buildBlock(SimpleBlock block) {
		return Column(
			crossAxisAlignment: .start,
			children: [
				if (block.title != null || block.notes != null) ...[
					Row(
						children: [
							if (block.title != null) ...[
								Text(block.title!,
									style: Theme.of(context).textTheme.titleLarge,
								),
								const SizedBox(width: 10),
							],

							if (block.notes != null)
								Text(block.notes!,
									style: TextStyle(color: notesColor),
								),
						]
					),
					const SizedBox(height: 10),
				],

				...block.lines.map((l) {
					return switch (l) {
						SimpleLine_Row(field0: String chords, field1: String rhythm, field2: String text) =>
							RowWidget(chords: chords, rhythm: rhythm, text: text),
						SimpleLine_ChordsLine(field0: String chords) => Text(chords, style: chordsStyle),
						SimpleLine_PlainText(field0: String text) => Text(text, style: textStyle),
						SimpleLine_Tab(field0: String tab) => Text(tab, style: textStyle),
						SimpleLine_EmptyLine() => Text(''),
					};
				}).toList(),

				const SizedBox(height: 25),
			],
		);
	}
}

class RowWidget extends StatelessWidget {
	final String chords;
	final String rhythm;
	final String text;

	RowWidget({
		super.key,
		required this.chords,
		required this.rhythm,
		required this.text
	});

	@override
	Widget build(BuildContext context) {
		return Column(
			children: [
				if (chords.isNotEmpty)
					Text(chords, style: chordsStyle),

				if (rhythm.isNotEmpty)
					Text(rhythm, style: rhythmStyle),

				if (text.isNotEmpty)
					Text(text, style: textStyle)
			],
		);
	}
}

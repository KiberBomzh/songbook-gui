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


final useLineWrap = true;



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
		final screenWidth = MediaQuery.of(context).size.width;

		return SingleChildScrollView(
			scrollDirection: Axis.horizontal,
			child: ConstrainedBox(
				constraints: BoxConstraints(
					minWidth: screenWidth,
					maxWidth: useLineWrap
						? screenWidth
						: double.infinity,
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
							RowWidget(
								chords: chords.isEmpty
									? null
									: chords,

								rhythm: rhythm.isEmpty
									? null
									: rhythm,

								text: text.isEmpty
									? null
									: text
							),
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
	String? chords;
	String? rhythm;
	String? text;

	RowWidget({
		super.key,
		required this.chords,
		required this.rhythm,
		required this.text
	});

	@override
	Widget build(BuildContext context) {

		return Column(
			crossAxisAlignment: .start,
			children: useLineWrap
				? _getWraped(context)
				: _getDefault()
		);
	}

	List<Widget> _getWraped(BuildContext context) {
		final textPainter = TextPainter(
			text: TextSpan(text: 'W', style: textStyle),
			textDirection: TextDirection.ltr,
		)..layout();
		final charWidth = textPainter.width;

		final screenWidth = MediaQuery.of(context).size.width;
		final maxWidth = screenWidth - 20 - 20;

		final lineLength = _alignLines();
		final maxLineWidth = charWidth * lineLength;

		if (maxLineWidth < maxWidth)
			return _getDefault();


		final maxChars = (maxWidth / charWidth).floor();
		List<Widget> lines = [];

		int minusIndent = 0;
		final linesLength = (lineLength / maxChars).ceil();
		for (int i = 0; i < linesLength; i++) {
			final startIndex = (i * maxChars) - minusIndent;
			int endIndex = (i < linesLength - 1)
				? (i + 1) * maxChars
				: lineLength;


			if (chords != null && i < linesLength - 1) {
				while (chords![endIndex] != ' ' && chords![endIndex - 1] != '' && endIndex > startIndex) {
					minusIndent++;
					endIndex--;
				}
			}
			if (text != null && i < linesLength - 1) {
				while (text![endIndex] != ' ' && text![endIndex - 1] != '' && endIndex > startIndex) {
					minusIndent++;
					endIndex--;
				}
			}


			if (chords != null) {
				lines.add(
					Text(chords!.substring(startIndex, endIndex), style: chordsStyle)
				);
			}

			if (rhythm != null) {
				lines.add(
					Text(rhythm!.substring(startIndex, endIndex), style: rhythmStyle)
				);
			}

			if (text != null) {
				lines.add(
					Text(
						text!.substring(startIndex, endIndex),
						style: textStyle
					)
				);
			}
		}

		return lines;
	}

	List<Widget> _getDefault() {
		return [
			if (chords != null)
				Text(chords!, style: chordsStyle),

			if (rhythm != null)
				Text(rhythm!, style: rhythmStyle),

			if (text != null)
				Text(text!, style: textStyle)
		];
	}

	int _getMaxLineLength() {
		int max = 0;
		if (chords != null)
			max = chords!.length;

		if (rhythm != null && rhythm!.length > max)
			max = rhythm!.length;

		if (text != null && text!.length > max)
			max = text!.length;


		return max;
	}

	int _alignLines() {
		int max = _getMaxLineLength();

		if (chords != null && chords!.length < max)
			chords = chords! +  ' ' * (max - chords!.length);

		if (rhythm != null && rhythm!.length < max)
			rhythm = rhythm! + ' ' * (max - rhythm!.length);

		if (text != null && text!.length < max)
			text = text! + ' ' * (max - text!.length);

		return max;
	}
}

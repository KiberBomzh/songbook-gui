import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:songbook/src/rust/api/song.dart';

import 'package:songbook/screens/editor.dart';


final Color chordsColor = Colors.cyan;
final Color rhythmColor = Colors.orange;


final chordsStyle = TextStyle(
	color: chordsColor,
	fontFamily: 'JetBrainsMono',
);

final rhythmStyle = TextStyle(
	color: rhythmColor,
	fontFamily: 'JetBrainsMono',
);

final textStyle = TextStyle(fontFamily: 'JetBrainsMono');


final useLineWrap = true;



class SongScreen extends StatefulWidget {
	final String path;

	SongScreen({super.key, required this.path});


	@override
	State<SongScreen> createState() => SongState();
}

class SongState extends State<SongScreen> {
	late SimpleSong song;

	bool _showNotes = true;
	bool _showRhythm = true;
	bool _showChords = true;


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
				title: Column(
					crossAxisAlignment: .start,
					children: [
						Text(song.getTitle(),
							style: Theme.of(context).textTheme.titleMedium
						),
						Text(song.getArtist(),
							style: Theme.of(context).textTheme.titleSmall?.copyWith(
								color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
							),
						),
					],
				),
			),
			body: (blocks.length > 0)
				? _buildBody(blocks)
				: Center(
					child: Text('The song is empty...')
				),
			bottomSheet: BottomBar(
				edit: _edit,
				toggleNotes: () => setState(() => _showNotes = !_showNotes),
				toggleRhythm: () => setState(() => _showRhythm = !_showRhythm),
				toggleChords: () => setState(() => _showChords = !_showChords),
				showNotes: _showNotes,
				showRhythm: _showRhythm,
				showChords: _showChords,
			),
		);
	}

	Widget _buildBody(List<SimpleBlock> blocks) {
		final screenWidth = MediaQuery.of(context).size.width;
		final String? songNotes = song.getNotes();

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
								if (songNotes != null && _showNotes)
									Text(songNotes!,
										style: TextStyle(
											color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
										)
									),

								...blocks.map((block) => _buildBlock(block)),

								const SizedBox(height: 70),
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

							if (block.notes != null && _showNotes) ...[
								if (block.title == null)
									Spacer(),

								Text(block.notes!,
									style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
								),
							],
						]
					),
					const SizedBox(height: 10),
				],

				...block.lines.map((l) {
					return switch (l) {
						SimpleLine_Row(field0: String chords, field1: String rhythm, field2: String text) =>
							RowWidget(
								chords: (chords.isEmpty || !_showChords)
									? null
									: chords,

								rhythm: (rhythm.isEmpty || !_showRhythm)
									? null
									: rhythm,

								text: text.isEmpty
									? null
									: text
							),
						SimpleLine_ChordsLine(field0: String chords) => (_showChords)
							? Text(chords, style: chordsStyle)
							: SizedBox(),
						SimpleLine_PlainText(field0: String text) => Text(text, style: textStyle),
						SimpleLine_Tab(field0: String tab) => Text(tab, style: textStyle),
						SimpleLine_EmptyLine() => Text('', style: textStyle),
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

		int lastEndIndex = 0;
		while (lastEndIndex < lineLength) {
			final startIndex = lastEndIndex;
			int endIndex = lastEndIndex + maxChars;
			if (endIndex > lineLength)
				endIndex = lineLength;


			if (chords != null && endIndex < lineLength) {
				while (chords![endIndex] != ' ' && chords![endIndex - 1] != '' && endIndex > startIndex) {
					endIndex--;
				}
			}
			if (text != null && endIndex < lineLength) {
				while (text![endIndex] != ' ' && text![endIndex - 1] != '' && endIndex > startIndex) {
					endIndex--;
				}
			}
			lastEndIndex = endIndex;


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

class BottomBar extends StatefulWidget {
	final VoidCallback edit;

	// left
	final VoidCallback toggleNotes;
	final VoidCallback toggleRhythm;
	final VoidCallback toggleChords;
	bool showNotes;
	bool showRhythm;
	bool showChords;

	BottomBar({
		super.key,
		required this.edit,

		required this.toggleNotes,
		required this.toggleRhythm,
		required this.toggleChords,
		required this.showNotes,
		required this.showRhythm,
		required this.showChords,
	});


	@override
	State<BottomBar> createState() => _BarState();
}

class _BarState extends State<BottomBar> {
	@override
	Widget build(BuildContext context) {
		return Container(
			height: 70,
			decoration: BoxDecoration(
				borderRadius: .vertical(top: .circular(10)),
				color: Theme.of(context).colorScheme.surfaceVariant,
			),
			child: Row(
				mainAxisAlignment: .start,
				children: [
					const SizedBox(width: 10),
					SizedBox(
						width: 200,
						child: _buildLeftSide()
					),
					Spacer(),
					const SizedBox(width: 10),

					IconButton(
						icon: Icon(Icons.edit, size: 25),
						style: IconButton.styleFrom(
							backgroundColor: Theme.of(context).colorScheme.primary,
							foregroundColor: Theme.of(context).colorScheme.onPrimary,
							fixedSize: Size(50, 50),
						),
						onPressed: widget.edit,
					),

					const SizedBox(width: 10),
					Spacer(),
					SizedBox(
						width: 200,
						child: _buildRightSide()
					),
					const SizedBox(width: 10),
				],
			),
		);
	}

	Widget _buildLeftSide() {
		final activeColor = Theme.of(context).colorScheme.onPrimary;
		final inactiveColor = Theme.of(context).colorScheme.onSurface;

		return Material(
			color: Colors.transparent,
			child: Row(
				children: [
					_buildBarItem( // Notes toggle
						child: Icon(Icons.note,
							size: 25,
							color: (widget.showNotes)
								? activeColor
								: inactiveColor,
						),
						isActive: widget.showNotes,
						onTap: widget.toggleNotes,
					),
					_buildBarItem( // Rhythm toggle
						child: Icon(Icons.music_note,
							size: 25,
							color: (widget.showRhythm)
								? activeColor
								: inactiveColor,
						),
						isActive: widget.showRhythm,
						onTap: widget.toggleRhythm,
					),
					_buildBarItem( // Chords toggle
						child: Text('Am', 
							style: TextStyle(
								fontSize: 15,
								color: (widget.showChords)
									? activeColor
									: inactiveColor,
							)
						),
						isActive: widget.showChords,
						onTap: widget.toggleChords,
					),
				],
			),
		);
	}
	Widget _buildRightSide() {
		return Row(
			mainAxisAlignment: .end,
			children: [
				IconButton( // автопрокрутка
					icon: Icon(Icons.question_mark, size: 25),
					onPressed: () {},
				),
				IconButton( // тональность
					icon: Icon(Icons.question_mark, size: 25),
					onPressed: () {},
				),
				IconButton( // каподастр
					icon: Icon(Icons.question_mark, size: 25),
					onPressed: () {},
				),
			],
		);
	}

	Widget _buildBarItem({
		required Widget child,
		required VoidCallback onTap,
		bool isActive = true,
	}) {
		return Padding(
			padding: const EdgeInsets.all(5),
			child: Material(
				color: isActive
					? Theme.of(context).colorScheme.primary
					: Colors.transparent,
				clipBehavior: .antiAlias,
				shape: RoundedRectangleBorder(
					borderRadius: .circular(12),
				),
				child: InkWell(
					child: SizedBox(
						height: 40,
						width: 40,
						child: Center(
							child: child,
						),
					),
					onTap: onTap,
					splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
					highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
				),
			),
		);
	}

}

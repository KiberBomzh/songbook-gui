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
	late SimpleSong _song;

	late String _key;
	late int? _capo;

	bool _showNotes = true;
	bool _showRhythm = true;
	bool _showChords = true;


	@override
	void initState() {
		super.initState();
		_song = SimpleSong.open(pathStr: widget.path);
		_capo = _song.getCapo();

		String? checkKey = _song.getKey();
		if (checkKey == null) {
			_song.detectKey();
			_key = _song.getKey()!;
		} else {
			_key = checkKey!;
		}
	}


	void _edit() async {
		final result = await Navigator.push(context,
			MaterialPageRoute(
				builder: (context) => EditorScreen(song: _song),
			),
		);

		setState(() {});
	}

	@override
	Widget build(BuildContext context) {
		final List<SimpleBlock> blocks = _song.getBlocks();

		return Scaffold(
			appBar: AppBar(
				title: Column(
					crossAxisAlignment: .start,
					children: [
						Text(_song.getTitle(),
							style: Theme.of(context).textTheme.titleMedium
						),
						Text(_song.getArtist(),
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
				songCapo: _capo ?? 0,
				songKey: _key,
				transposeSong: (steps) => setState(() {
					_song.transpose(steps: steps);
					_key = _song.getKey()!;
				}),
				setCapo: (newCapo) => setState(() {
					_song.setCapo(capo: newCapo);
					_capo = _song.getCapo();
				}),
			),
		);
	}

	Widget _buildBody(List<SimpleBlock> blocks) {
		final screenWidth = MediaQuery.of(context).size.width;
		final String? songNotes = _song.getNotes();

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


enum RightSideMode {
	none,
	key,
	capo,
	autoscroll
}
class BottomBar extends StatefulWidget {
	final VoidCallback edit;

	// left
	final VoidCallback toggleNotes;
	final VoidCallback toggleRhythm;
	final VoidCallback toggleChords;
	final bool showNotes;
	final bool showRhythm;
	final bool showChords;

	final String songKey;
	final int songCapo;
	final Function(int) transposeSong;
	final Function(int) setCapo;

	BottomBar({
		super.key,
		required this.edit,

		required this.toggleNotes,
		required this.toggleRhythm,
		required this.toggleChords,
		required this.showNotes,
		required this.showRhythm,
		required this.showChords,

		required this.songKey,
		required this.songCapo,
		required this.transposeSong,
		required this.setCapo,
	});


	@override
	State<BottomBar> createState() => _BarState();
}

class _BarState extends State<BottomBar> {
	RightSideMode _currentMode = RightSideMode.none;

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
						width: 150,
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
						width: 150,
						child: _buildRightSide()
					),
					const SizedBox(width: 10),
				],
			),
		);
	}

	Widget _buildLeftSide() {
		return Row(
			children: [
				_buildBarItem( // Notes toggle
					child: Icon(Icons.note,
						size: 25,
					),
					isActive: widget.showNotes,
					onTap: widget.toggleNotes,
				),
				_buildBarItem( // Rhythm toggle
					child: Icon(Icons.music_note,
						size: 25,
					),
					isActive: widget.showRhythm,
					onTap: widget.toggleRhythm,
				),
				_buildBarItem( // Chords toggle
					child: Text('Am', 
						style: TextStyle(
							fontSize: 15,
							fontWeight: .bold,
						)
					),
					isActive: widget.showChords,
					onTap: widget.toggleChords,
				),
			],
		);
	}
	Widget _buildRightSide() {
		return Row(
			mainAxisAlignment: .end,
			children: switch (_currentMode) {
				RightSideMode.none => _buildDefaultRightSide(),
				RightSideMode.capo => _buildCapoRightSide(),
				RightSideMode.key => _buildKeyRightSide(),
				RightSideMode.autoscroll => _buildAutoscrollRightSide(),
			},
		);
	}

	List<Widget> _buildDefaultRightSide() {
		return [
			_buildBarItem( // Capo
				child: Text('Capo', 
					style: TextStyle(
						fontSize: 12,
						fontWeight: .bold,
					)
				),
				onTap: () => setState(() => _currentMode = RightSideMode.capo),
			),

			_buildBarItem( // Key
				child: Text('Key', 
					style: TextStyle(
						fontSize: 12,
						fontWeight: .bold,
					)
				),
				onTap: () => setState(() => _currentMode = RightSideMode.key),
			),

			_buildBarItem( // Autoscroll
				child: Icon(Icons.speed,
					size: 25,
				),
				onTap: () => setState(() => _currentMode = RightSideMode.autoscroll),
			),
		];
	}
	List<Widget> _buildCapoRightSide() {
		return [
			_buildBarItem(
				child: Text('-1', 
					style: TextStyle(
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: (widget.songCapo > 0)
					? () => widget.setCapo(widget.songCapo - 1)
					: null,
			),

			_buildBarItem(
				child: Text(widget.songCapo.toString(), 
					style: TextStyle(
						fontSize: 12,
						fontWeight: .bold,
					)
				),
				onTap: () => setState(() => _currentMode = RightSideMode.none),
			),

			_buildBarItem(
				child: Text('+1', 
					style: TextStyle(
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () => widget.setCapo(widget.songCapo + 1),
			),
		];
	}
	List<Widget> _buildKeyRightSide() {
		return [
			_buildBarItem(
				child: Text('-1', 
					style: TextStyle(
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () => widget.transposeSong(-1),
			),

			_buildBarItem(
				child: Text(widget.songKey, 
					style: TextStyle(
						fontSize: 12,
						fontWeight: .bold,
					)
				),
				onTap: () => setState(() => _currentMode = RightSideMode.none),
			),

			_buildBarItem(
				child: Text('+1', 
					style: TextStyle(
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () => widget.transposeSong(1),
			),
		];
	}
	List<Widget> _buildAutoscrollRightSide() {
		return [
			_buildBarItem(
				child: Text('-1', 
					style: TextStyle(
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () {},
			),

			_buildBarItem(
				child: Icon(Icons.speed, 
					size: 25,
				),
				onTap: () => setState(() => _currentMode = RightSideMode.none),
			),

			_buildBarItem(
				child: Text('+1', 
					style: TextStyle(
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () {},
			),
		];
	}

	Widget _buildBarItem({
		required Widget child,
		required VoidCallback? onTap,
		bool isActive = true,
	}) {
		return Padding(
			padding: const EdgeInsets.all(5),
			child: Material(
				color: isActive
					? Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.5)
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


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
		_loadSong();
	}

	void _loadSong() => setState(() {
		_song = SimpleSong.open(pathStr: widget.path);
		_capo = _song.getCapo();

		String? checkKey = _song.getKey();
		if (checkKey == null) {
			_song.detectKey();
			_key = _song.getKey()!;
		} else {
			_key = checkKey!;
		}
	});


	void _edit() async {
		final result = await Navigator.push(context,
			MaterialPageRoute(
				builder: (context) => EditorScreen(song: _song),
			),
		);

		_loadSong();
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
				? Stack(
					children: [
						_buildBody(blocks),

						Align(
							alignment: .bottomLeft,
							child: BottomBar(
								songCapo: _capo ?? 0,
								songKey: _key,
								transposeSong: (steps) => setState(() {
									_song.transpose(steps: steps);
									_key = _song.getKey()!;
								}),
								setCapo: (newCapo) => setState(() {
									_song.setCapo(capo: newCapo);
									_capo = _song.getCapo();
									_key = _song.getKey()!;
								}),
							),
						),
					],
				)
				: Center(
					child: Text('The song is empty...')
				),
			floatingActionButton: FloatingActionButton(
				child: Icon(Icons.edit),
				onPressed: _edit,
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

								const SizedBox(height: 80),
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


enum BarMode {
	none,
	key,
	capo,
	autoscroll
}
class BottomBar extends StatefulWidget {
	final String songKey;
	final int songCapo;
	final Function(int) transposeSong;
	final Function(int) setCapo;

	BottomBar({
		super.key,
		required this.songKey,
		required this.songCapo,
		required this.transposeSong,
		required this.setCapo,
	});


	@override
	State<BottomBar> createState() => _BarState();
}

class _BarState extends State<BottomBar> {
	BarMode _currentMode = BarMode.none;
	late Color _foregroundColor;


	@override
	Widget build(BuildContext context) {
		_foregroundColor = Theme.of(context).colorScheme.onPrimaryContainer;

		return Container(
			height: 80,
			width: 250,
			decoration: BoxDecoration(
				borderRadius: .only(topRight: .circular(10)),
				// color: Theme.of(context).colorScheme.surfaceVariant,
			),
			child: Row(
				mainAxisAlignment: .center,
				children: switch (_currentMode) {
					BarMode.none => _buildDefault(),
					BarMode.capo => _buildCapo(),
					BarMode.key => _buildKey(),
					BarMode.autoscroll => _buildAutoscroll(),
				},
			),
		);
	}
	List<Widget> _buildDefault() {
		return [
			_buildBarItem( // Capo
				child: Text((widget.songCapo > 0)
					? widget.songCapo.toString()
					: 'Capo',
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () => setState(() => _currentMode = BarMode.capo),
				size: 50,
			),
			const SizedBox(width: 10),

			_buildBarItem( // Key
				child: Text(widget.songKey.replaceFirst('/', '\n'), 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					),
					textAlign: .center,
				),
				onTap: () => setState(() => _currentMode = BarMode.key),
				size: 60,
			),

			const SizedBox(width: 10),

			_buildBarItem( // Autoscroll
				child: Icon(Icons.speed,
					color: _foregroundColor,
					size: 35,
				),
				onTap: () => setState(() => _currentMode = BarMode.autoscroll),
				size: 50,
			),
		];
	}
	List<Widget> _buildCapo() {
		return [
			_buildBarItem(
				child: Text('-1', 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: (widget.songCapo > 0)
					? () => widget.setCapo(widget.songCapo - 1)
					: null,
			),
			const SizedBox(width: 10),

			_buildBarItem(
				child: Text(widget.songCapo.toString(), 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 20,
						fontWeight: .bold,
					)
				),
				onTap: () => setState(() => _currentMode = BarMode.none),
				size: 60,
			),

			const SizedBox(width: 10),
			_buildBarItem(
				child: Text('+1', 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () => widget.setCapo(widget.songCapo + 1),
			),
		];
	}
	List<Widget> _buildKey() {
		return [
			_buildBarItem(
				child: Text('-1', 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () => widget.transposeSong(-1),
			),
			const SizedBox(width: 10),

			_buildBarItem(
				child: Text(widget.songKey.replaceFirst('/', '\n'), 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					),
					textAlign: .center,
				),
				onTap: () => setState(() => _currentMode = BarMode.none),
				size: 60,
			),

			const SizedBox(width: 10),
			_buildBarItem(
				child: Text('+1', 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () => widget.transposeSong(1),
			),
		];
	}
	List<Widget> _buildAutoscroll() {
		return [
			_buildBarItem(
				child: Text('-1', 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () {},
			),
			const SizedBox(width: 10),

			_buildBarItem(
				child: Icon(Icons.speed, 
					color: _foregroundColor,
					size: 35,
				),
				onTap: () => setState(() => _currentMode = BarMode.none),
				size: 60,
			),

			const SizedBox(width: 10),
			_buildBarItem(
				child: Text('+1', 
					style: TextStyle(
						color: _foregroundColor,
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
		double size = 40,
	}) {
		return Padding(
			padding: const EdgeInsets.all(5),
			child: Material(
				color: Theme.of(context).colorScheme.primaryContainer,
				clipBehavior: .antiAlias,
				shape: RoundedRectangleBorder(
					borderRadius: .circular(15),
				),
				child: InkWell(
					child: SizedBox(
						height: size,
						width: size,
						child: Center(
							child: child,
						),
					),
					onTap: onTap,
					splashColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
					highlightColor: Theme.of(context).colorScheme.surface.withOpacity(0.05),
				),
			),
		);
	}

}


import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:songbook/src/rust/api/song.dart';

import 'package:songbook/screens/editor.dart';
import 'package:songbook/services/settings.dart';
import 'package:songbook/screens/settings.dart';


const int AutoscrollSpeedStep = 50;



class SongScreen extends StatefulWidget {
	final String path;

	SongScreen({super.key, required this.path});


	@override
	State<SongScreen> createState() => SongState();
}

class SongState extends State<SongScreen> {
	late SimpleSong _song;

	late String? _key;
	late int? _capo;
	late int _autoscrollSpeed; // milliseconds per pixel

	bool _showNotes = true;
	bool _showRhythm = true;
	bool _showChords = true;

	late ScrollController _scrollController;
	Timer? _autoscrollTimer;
	bool _isAutoscrolling = false;
	late double _lineHeight;

	Timer? _saveTimer;


	late SettingsProvider _settings;
	late TextStyle _chordsStyle;
	late TextStyle _textStyle;
	late TextStyle _notesStyle;
	late TextStyle _titleStyle;


	@override
	void initState() {
		super.initState();
		_scrollController = ScrollController();
		_loadSong();
	}

	@override
	void dispose() {
		_stopAutoscroll();
		_scrollController.dispose();
		_saveTimer?.cancel();
		super.dispose();
	}

	void _calculateLineHeight() {
		final textPainter = TextPainter(
			text: TextSpan(text: 'W', style: _textStyle),
			textDirection: .ltr
		)..layout();
		_lineHeight = textPainter.height; // height in pixels
	}

	void _loadSong() => setState(() {
		_song = SimpleSong.open(pathStr: widget.path);
		_capo = _song.getCapo();

		String? checkKey = _song.getKey();
		if (checkKey == null) {
			_song.detectKey();
			_key = _song.getKey();
		} else {
			_key = checkKey;
		}
	});

	void _loadAutoscrollSpeed() {
		final int speedPerLine = _song.getAutoscrollSpeed()?.toInt() ?? 2500;
		_autoscrollSpeed = ((speedPerLine / _lineHeight) / AutoscrollSpeedStep).round() * AutoscrollSpeedStep;
	}

	void _scheduleSave() {
		_saveTimer?.cancel();
		_saveTimer = Timer(const Duration(milliseconds: 1000), () {
			_song.save();
		});
	}


	void _startAutoscroll() {
		_stopAutoscroll();

		_isAutoscrolling = true;
		_autoscrollTimer = Timer.periodic(
			Duration(milliseconds: _autoscrollSpeed),
			(timer) {
				if (!_scrollController.hasClients) return;

				final newOffset = _scrollController.offset + 1;
				final maxExtent = _scrollController.position.maxScrollExtent;
				if (newOffset >= maxExtent) {
					_stopAutoscroll();
				} else {
					_scrollController.animateTo(newOffset,
						duration: Duration(milliseconds: 1),
						curve: Curves.linear,
					);
				}
			}
		);
	}
	void _stopAutoscroll() {
		_isAutoscrolling = false;
		_autoscrollTimer?.cancel();
		_autoscrollTimer = null;
	}


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
		_settings = context.watch<SettingsProvider>();
		_chordsStyle = _settings.chordsStyle(context);
		_textStyle = _settings.textStyle(context);
		_notesStyle = _settings.notesStyle(context);
		_titleStyle = _settings.titleStyle(context);

		_calculateLineHeight();
		_loadAutoscrollSpeed();

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
				actions: [
					IconButton(
						icon: Icon(Icons.settings),
						tooltip: 'Settings',
						onPressed: () => Navigator.push(context,
							MaterialPageRoute(
								builder: (context) => SettingsScreen()
							),
						),
					),
				],
			),
			body: (blocks.length > 0)
				? Stack(
					children: [
						Container(
							color: _settings.backgroundColor(context),
							child: _buildBody(blocks),
						),

						Align(
							alignment: .bottomLeft,
							child: BottomBar(
								songCapo: _capo ?? 0,
								songKey: _key,
								autoscrollSpeed: _autoscrollSpeed,
								transposeSong: (steps) => setState(() {
									_song.transpose(steps: steps);
									_key = _song.getKey();
									_scheduleSave();
								}),
								setCapo: (newCapo) => setState(() {
									_song.setCapo(capo: newCapo);
									_capo = _song.getCapo();
									_key = _song.getKey();
									_scheduleSave();
								}),
								setAutoscrollSpeed: (newSpeed) => setState(() {
									_autoscrollSpeed = newSpeed;
									_startAutoscroll();

									final int speedPerLine = (_autoscrollSpeed * _lineHeight).round();
									_song.setAutoscrollSpeed(newSpeed: BigInt.from(speedPerLine));
									_scheduleSave();
								}),
								startAutoscroll: _startAutoscroll,
								stopAutoscroll: _stopAutoscroll,
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
					maxWidth: (_settings.lineWrapInSong)
						? screenWidth
						: double.infinity,
				),
				child: SingleChildScrollView(
					scrollDirection: Axis.vertical,
					controller: _scrollController,
					child: Padding(
						padding: const EdgeInsets.symmetric(horizontal: 10),
						child: Column(
							crossAxisAlignment: .start,
							children: [
								if (songNotes != null && _showNotes)
									Text(songNotes!, style: _notesStyle),

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
								Text(block.title!, style: _titleStyle),
								const SizedBox(width: 10),
							],

							if (block.notes != null && _showNotes) ...[
								if (block.title == null)
									Spacer(),

								Text(block.notes!, style: _notesStyle),
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
							? Text(chords, style: _chordsStyle)
							: SizedBox(),
						SimpleLine_PlainText(field0: String text) => Text(text, style: _textStyle),
						SimpleLine_Tab(field0: String tab) => TabWidget(
							text: Text(tab, style: _textStyle),
						),
						SimpleLine_EmptyLine() => Text('', style: _textStyle),
					};
				}).toList(),

				const SizedBox(height: 25),
			],
		);
	}
}

class TabWidget extends StatefulWidget {
	final Widget text;

	TabWidget({super.key, required this.text});

	@override
	State<TabWidget> createState() => TabState();
}
class TabState extends State<TabWidget> {
	late ScrollController _controller;

	@override
	void initState() {
		super.initState();
		_controller = ScrollController();
	}

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scrollbar(
			controller: _controller,
			interactive: true,
			child: SingleChildScrollView(
				controller: _controller,
				scrollDirection: Axis.horizontal,
				padding: const EdgeInsets.symmetric(vertical: 10),
				child: widget.text,
			),
		);
	}
}

class RowWidget extends StatelessWidget {
	String? chords;
	String? rhythm;
	String? text;

	late SettingsProvider _settings;
	late TextStyle _chordsStyle;
	late TextStyle _rhythmStyle;
	late TextStyle _textStyle;


	RowWidget({
		super.key,
		required this.chords,
		required this.rhythm,
		required this.text
	});

	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();
		_chordsStyle = _settings.chordsStyle(context);
		_rhythmStyle = _settings.rhythmStyle(context);
		_textStyle = _settings.textStyle(context);

		return Column(
			crossAxisAlignment: .start,
			children: (_settings.lineWrapInSong)
				? _getWraped(context)
				: _getDefault()
		);
	}

	List<Widget> _getWraped(BuildContext context) {
		final textPainter = TextPainter(
			text: TextSpan(text: 'W', style: _textStyle),
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
					Text(chords!.substring(startIndex, endIndex), style: _chordsStyle)
				);
			}

			if (rhythm != null) {
				lines.add(
					Text(rhythm!.substring(startIndex, endIndex), style: _rhythmStyle)
				);
			}

			if (text != null) {
				lines.add(
					Text(
						text!.substring(startIndex, endIndex),
						style: _textStyle
					)
				);
			}
		}

		return lines;
	}

	List<Widget> _getDefault() {
		return [
			if (chords != null)
				Text(chords!, style: _chordsStyle),

			if (rhythm != null)
				Text(rhythm!, style: _rhythmStyle),

			if (text != null)
				Text(text!, style: _textStyle)
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
	final String? songKey;
	final int songCapo;
	final int autoscrollSpeed;
	final Function(int) transposeSong;
	final Function(int) setCapo;
	final Function(int) setAutoscrollSpeed;

	final VoidCallback startAutoscroll;
	final VoidCallback stopAutoscroll;

	BottomBar({
		super.key,
		required this.songKey,
		required this.songCapo,
		required this.autoscrollSpeed,
		required this.transposeSong,
		required this.setCapo,
		required this.setAutoscrollSpeed,
		required this.startAutoscroll,
		required this.stopAutoscroll,
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
				onTap: (widget.songKey != null)
					? () => setState(() => _currentMode = BarMode.capo)
					: null,
				size: 50,
			),
			const SizedBox(width: 10),

			_buildBarItem( // Autoscroll
				child: Icon(Icons.speed,
					color: _foregroundColor,
					size: 35,
				),
				onTap: () {
					widget.startAutoscroll();
					setState(() => _currentMode = BarMode.autoscroll);
				},
				size: 60,
			),

			const SizedBox(width: 10),

			_buildBarItem( // Key
				child: Text(widget.songKey?.replaceFirst('/', '\n') ?? 'Key', 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					),
					textAlign: .center,
				),
				onTap: (widget.songKey != null)
					? () => setState(() => _currentMode = BarMode.key)
					: null,
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
				child: Text(widget.songKey!.replaceFirst('/', '\n'), 
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
				child: Text('-' + AutoscrollSpeedStep.toString(), 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: (widget.autoscrollSpeed > AutoscrollSpeedStep)
					? () => widget.setAutoscrollSpeed(widget.autoscrollSpeed - AutoscrollSpeedStep)
					: null,
			),
			const SizedBox(width: 10),

			_buildBarItem(
				child: Text(widget.autoscrollSpeed.toString(), 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () {
					widget.stopAutoscroll();
					setState(() => _currentMode = BarMode.none);
				},
				size: 60,
			),

			const SizedBox(width: 10),
			_buildBarItem(
				child: Text('+' + AutoscrollSpeedStep.toString(), 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () => widget.setAutoscrollSpeed(widget.autoscrollSpeed + AutoscrollSpeedStep),
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


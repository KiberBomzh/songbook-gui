import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:songbook/screens/song/autoscroll_settings.dart';
import 'package:songbook/screens/song/fretboard.dart';
import 'package:songbook/screens/song/circle_of_fifth.dart';
import 'package:songbook/screens/song/widgets.dart';
import 'package:songbook/screens/song/bottom_bar.dart';
import 'package:songbook/screens/editor/editor.dart';
import 'package:songbook/screens/settings/settings.dart';
import 'package:songbook/services/settings.dart';
import 'package:songbook/functions/is_wide_screen.dart';

import 'package:songbook/src/rust/api/song.dart';
import 'package:songbook/src/rust/api/theory.dart';
import 'package:songbook/l10n/app_localizations.dart';


const int AutoscrollSpeedStep = 25;
const int MinimalAutoscrollSpeedStep = 5;
const int MaxAutoscrollSpeed = 1000;
const int MaxAutoscrollDelay = 60;



class SongScreen extends StatefulWidget {
	final String path;

	const SongScreen({super.key, required this.path});


	@override
	State<SongScreen> createState() => _SongState();
}

class _SongState extends State<SongScreen> {
	late SimpleSong _song;
	EditorScrollOffsets? _editorScrollOffsets;

	late String? _key;
	late int? _capo;
	late int _autoscrollSpeed; // milliseconds per pixel
	late Duration _autoscrollDelay;

	bool _showRhythm = true;
	bool _showChords = true;
	bool _showNotes = true;
	bool _showFingerings = false;

	late ScrollController _scrollController;
	Timer? _autoscrollTimer;
	Timer? _postponedAutoscrollTimer;
	late double _lineHeight;

	Timer? _saveTimer;


	late SettingsProvider _settings;
	late TextStyle _chordsStyle;
	late TextStyle _textStyle;
	late TextStyle _notesStyle;
	late TextStyle _titleStyle;
	late TextStyle _plainTextStyle;
	late TextStyle _tabStyle;
	late double _fontSize;

	bool _isError = false;
	String _errorMessage = '';

	final GlobalKey<BarState> _barKey = GlobalKey<BarState>();


	bool _isScreenWide = false;
	String? _lastBlockKey; // for proper modulation handling


	@override
	void initState() {
		super.initState();
		_scrollController = ScrollController();
		_loadSong();
		WakelockPlus.enable();
	}

	@override
	void dispose() {
		WakelockPlus.disable();
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
		_isError = false;
		_errorMessage = '';
		try {
			_song = SimpleSong.open(pathStr: widget.path);
		} catch (e) {
			_isError = true;
			_errorMessage = e.toString();
			return;
		}
		_capo = _song.getCapo();

		String? checkKey = _song.getKeyWithCapo();
		if (checkKey == null) {
			_song.detectKey();
			_key = _song.getKeyWithCapo();
		} else {
			_key = checkKey;
		}

		_autoscrollDelay = Duration(seconds:
			_song.getAutoscrollDelay()?.toInt() ?? 3
		);

		final (c, r, n, f) = _song.getShowOptions();
		_showChords = c;
		_showRhythm = r;
		_showNotes = n;
		_showFingerings = f;
	});

	void _loadAutoscrollSpeed() {
		final int speedPerLine = _song.getAutoscrollSpeed()?.toInt() ?? 2500;
		_autoscrollSpeed = ((speedPerLine / _lineHeight) / MinimalAutoscrollSpeedStep).round() * MinimalAutoscrollSpeedStep;
	}

	void _scheduleSave() {
		_saveTimer?.cancel();
		_saveTimer = Timer(const Duration(milliseconds: 1000), () {
			_song.save();
		});
	}


	void _startAutoscroll() {
		_stopAutoscroll();

		_autoscrollTimer = Timer.periodic(
			Duration(milliseconds: _autoscrollSpeed),
			(timer) {
				if (!_scrollController.hasClients) return;

				final newOffset = _scrollController.offset + 1;
				final maxExtent = _scrollController.position.maxScrollExtent;
				if (newOffset >= maxExtent) {
					_barKey.currentState?.switchModeToDefault();
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
		_postponedAutoscrollTimer?.cancel();
		_autoscrollTimer?.cancel();
		_autoscrollTimer = null;
	}


	void _edit() async {
		await _navigatorPush(EditorScreen(
			song: _song,
			path: widget.path,
			initialScrollOffsets: _editorScrollOffsets,
			onOffsetsChanged: (newOffsets) => _editorScrollOffsets = newOffsets,
		));
		_loadSong();
		_loadAutoscrollSpeed();
	}

	void _setShowOptions() {
		_song.setShowOptions(
			chords: _showChords,
			rhythm: _showRhythm,
			notes: _showNotes,
			fingerings: _showFingerings,
		);
		_scheduleSave();
	}

	Future<void> _navigatorPush(Widget screen) async {
		WakelockPlus.disable();
		await Navigator.push(context,
			MaterialPageRoute(
				builder: (context) => screen,
			),
		);
		WakelockPlus.enable();
	}

	@override
	Widget build(BuildContext context) {
		if (_isError)
			return Scaffold(
				appBar: AppBar(
					title: Text(AppLocalizations.of(context)!.songErrorMsg),
					actions: [
						IconButton(
							icon: Icon(Icons.edit),
							onPressed: () async {
								await _navigatorPush(EditorScreen(
									path: widget.path,
									mode: EditorMode.source,
								));
								_loadSong();
								if (!_isError)
									_loadAutoscrollSpeed();
							},
						),
					]
				),
				body: SizedBox(
					width: double.infinity,
					child: SingleChildScrollView(
						child: Padding(
							padding: const .all(5),
							child: Text(_errorMessage),
						),
					),
				),
			);

		
		_isScreenWide = isWideScreen(context);

		_settings = context.watch<SettingsProvider>();
		_chordsStyle = _settings.chordsStyle(context);
		_textStyle = _settings.textStyle(context);
		_notesStyle = _settings.notesStyle(context);
		_titleStyle = _settings.titleStyle(context);
		_plainTextStyle = _settings.plainTextStyle(context);
		_tabStyle = _settings.tabStyle(context);
		_fontSize = _settings.songFontSize;

		_calculateLineHeight();
		_loadAutoscrollSpeed();


		return Container(
			decoration: BoxDecoration(
				image: (_settings.backgroundImage != null)
					? DecorationImage(
						image: FileImage(_settings.backgroundImage!),
						fit: .cover,
					)
					: null,
			),
			child: Stack(
				children: [
					Align(
						alignment: .bottomCenter,
						child: Container(
							color: Colors.black,
							width: MediaQuery.of(context).size.width,
							height: MediaQuery.of(context).padding.bottom,
						),
					), // for safe area

					if (_isScreenWide) ...[
						_buildScaffold(),
						Align(
							alignment: .bottomCenter,
							child: _buildBottomBar(),
						),
					] else ...[
						Column(
							children: [
								Expanded(
									child: _buildScaffold(),
								),
								Container(
									color: Theme.of(context).colorScheme.surface,
									child: _buildBottomBar(),
								),
							],
						),
					],
				],
			),
		);
	}

	Widget _buildBottomBar() {
		return BottomBar(
			key: _barKey,
			songCapo: _capo ?? 0,
			songKey: _key,
			autoscrollSpeed: _autoscrollSpeed,
			transposeSong: (steps) => setState(() {
				_song.transpose(steps: steps);
				_key = _song.getKeyWithCapo();
				_scheduleSave();
			}),
			setCapo: (newCapo) => setState(() {
				_song.setCapo(capo: newCapo);
				_capo = _song.getCapo();
				_key = _song.getKeyWithCapo();
				_scheduleSave();
			}),
			setAutoscrollSpeed: (newSpeed) => setState(() {
				_autoscrollSpeed = newSpeed;
				_startAutoscroll();

				final int speedPerLine = (_autoscrollSpeed * _lineHeight).round();
				_song.setAutoscrollSpeed(newSpeed: BigInt.from(speedPerLine));
				_scheduleSave();
			}),
			showKeyDialog: () => showModalBottomSheet(
				isScrollControlled: true,
				context: context,
				builder: (context) => _keyDialog(onDone: (key) => setState(() {
					_song.setKey(key: key);
					_key = _song.getKeyWithCapo();
					_scheduleSave();
				})),
			),
			showCapoDialog: () => showModalBottomSheet(
				isScrollControlled: true,
				context: context,
				builder: (context) =>  _capoDialog(onDone: (fret) => setState(() {
					_song.setCapo(capo: fret);
					_capo = _song.getCapo();
					_key = _song.getKeyWithCapo();
					_scheduleSave();
				})),
			),
			showAutoscrollDialog: () => showDialog(
				context: context,
				builder: (context) => _autoscrollDialog(onDone: (delay, speed) => setState(() {
					_autoscrollSpeed = speed.floor();

					final int speedPerLine = (_autoscrollSpeed * _lineHeight).round();
					_song.setAutoscrollSpeed(newSpeed: BigInt.from(speedPerLine));

					_autoscrollDelay = Duration(seconds: delay.floor());
					_song.setAutoscrollDelay(newDelay: BigInt.from(delay));


					_scheduleSave();
				})),
			),
			startAutoscroll: () {
				_postponedAutoscrollTimer = Timer(_autoscrollDelay, () {
					if (mounted)
						_startAutoscroll();
				});
			},
			stopAutoscroll: _stopAutoscroll,
			edit: _edit,
			popupMenuButton: PopupMenu(
				chords: _showChords,
				rhythm: _showRhythm,
				notes: _showNotes,
				fingerings: _showFingerings,

				switchChords: () => setState(() {
					_showChords = !_showChords;
					_setShowOptions();
				}),
				switchRhythm: () => setState(() {
					_showRhythm = !_showRhythm;
					_setShowOptions();
				}),
				switchNotes: () => setState(() {
					_showNotes = !_showNotes;
					_setShowOptions();
				}),
				switchFingerings: () => setState(() {
					_showFingerings = !_showFingerings;
					_setShowOptions();
				}),
			),
		);
	}

	Widget _buildScaffold() {
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
								color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
							),
						),
					],
				),
				actions: [
					PopupMenuButton<String>(
						icon: Icon(Icons.share),
						tooltip: AppLocalizations.of(context)!.songTooltipExport,
						offset: const Offset(0, 40),
						shape: RoundedRectangleBorder(
							borderRadius: .circular(12),
						),
						onSelected: (value) async { switch (value) {
							case ('text'):
								Clipboard.setData(ClipboardData(text: _song.asText()));
								break;

							case ('chordpro'):
								Clipboard.setData(ClipboardData(text: _song.asChordpro()));
								break;

							case ('songbook'):
								final pathMaybe = _song.getPath();
								if (pathMaybe == null) {
									break;
								}
								final String path = pathMaybe;
								final file = await File(path).rename(path + '.yml');

								final params = ShareParams(
									files: [ XFile(file.path)],
								);
								try {
									await SharePlus.instance.share(params);
								} finally {
									await file.rename(path);
								}

								break;

							default:
								break;
						}},
						itemBuilder: (context) => [
							PopupMenuItem(
								value: 'text',
								child: Text(AppLocalizations.of(context)!.songExportOptionText),
							),
							const PopupMenuItem(
								value: 'chordpro',
								child: Text('ChordPro'),
							),
							const PopupMenuItem(
								value: 'songbook',
								child: Text('songbook (.yml)'),
							),
						],
					),
					IconButton(
						icon: Icon(Icons.settings),
						tooltip: AppLocalizations.of(context)!.songTooltipSettings,
						onPressed: () => _navigatorPush(SettingsScreen()),
					),
				],
			),
			body: (blocks.isNotEmpty)
				? Container(
					margin: (_isScreenWide)
						? EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom) //safe area
						: null,
					padding: const EdgeInsets.symmetric(horizontal: 10),
					height: double.infinity,
					color: _settings.backgroundColor(context),
					child: _buildBody(blocks),
				)
				: Center(
					child: Text(AppLocalizations.of(context)!.songEmptyMsg)
				),
		);
	}

	Widget _buildBody(List<SimpleBlock> blocks) {
		final screenWidth = MediaQuery.of(context).size.width - 20; // padding
		final String? songNotes = _song.getNotes();
		final Map<String, String>? songFingerings = _song.getFingerings();
		final List<String>? keysSorted = songFingerings?.keys.toList();
		keysSorted?.sort();
		_lastBlockKey = _song.getKey();

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
					child: Column(
						crossAxisAlignment: .start,
						children: [
							const SizedBox(height: 10), // Отступ сверху

							if (_showChords && _showFingerings && songFingerings != null) ...[
								Center(
									child: Wrap(
										spacing: _fontSize * 1.6,
										runSpacing: _fontSize * 0.8,
										children: keysSorted!.map((k) {
											final String f = songFingerings[k]!;

											return Material(
												color: Colors.transparent,
												clipBehavior: .antiAlias,
												shape: RoundedRectangleBorder(
													borderRadius: .circular(8),
												),
												child: InkWell(
													onTap: () => showDialog(
														context: context,
														builder: (context) => _fingeringsDialog(k, getFingeringsForChord(chord: k)),
													),
													child: Column(
														mainAxisAlignment: .start,
														children: [
															Text(k, style: _settings.fingeringsTitleStyle(context)),
															SizedBox(height: _fontSize * 0.3),

															Padding(
																padding: .only(
																	left: _fontSize,
																),
																child: Text(f, style: _settings.fingeringsStyle(context)),
															),
														],
													),
												),
											);
										}).toList(),
									),
								),
								SizedBox(height: _fontSize * 1.5),
							],

							if (songNotes != null && _showNotes) ...[
								Text(songNotes, style: _notesStyle),
								SizedBox(height: _fontSize * 1.5),
							],

							...blocks.map((block) => _buildBlock(block)),

							if (_isScreenWide)
								const SizedBox(height: 80), // отступ для нижней панели
						],
					),
				),
			),
		);
	}

	Widget _buildBlock(SimpleBlock block) {
		final key = block.key ?? _song.getKey();
		final isModulation = key != _lastBlockKey;
		_lastBlockKey = key;

		return Column(
			crossAxisAlignment: .start,
			children: [
				if (block.title != null || block.notes != null || block.key != null) ...[
					Row(
						mainAxisAlignment: (block.title == null)
							? .end
							: .start,
						children: [
							if (block.title != null) ...[
								Text(block.title!, style: _titleStyle),
								SizedBox(width: _fontSize / 2),
							],

							if (block.notes != null && _showNotes) ...[
								Flexible(
									child:Text(block.notes!, style: _notesStyle, overflow: .ellipsis),
								),
							],
						]
					),
				],

				if (key != null && _showChords && isModulation) ...[
					Align(
						alignment: .centerRight,
						child: Text.rich(
							TextSpan(
								children: [
									TextSpan(text: '${AppLocalizations.of(context)!.songKey}: ', style: _notesStyle),
									TextSpan(text: key, style: _chordsStyle),
								],
							),
						),
					),
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
						SimpleLine_NoteLine(field0: String text) => (_showNotes)
							? Align(
								alignment: .centerRight,
								child: Text(text, style: _notesStyle),
							)
							: SizedBox(),
						SimpleLine_PlainText(field0: String text) => Text(text, style: _plainTextStyle),
						SimpleLine_Tab(field0: String tab) => TabWidget(
							text: Text(tab, style: _tabStyle),
						),
						SimpleLine_EmptyLine() => Text('', style: _textStyle),
					};
				}),

				SizedBox(height: _fontSize * 2),
			],
		);
	}

	Widget _fingeringsDialog(
		String chord,
		List<SimpleFingering> fingerings)
	{
		return AlertDialog(
			title: Text(chord),
			content: Padding(
				padding: const .all(10),
				child: SingleChildScrollView(
					child: Center(
						child: Wrap(
							spacing: _fontSize * 1.6,
							runSpacing: _fontSize * 2,
							children: fingerings.map((f) {
								return MenuAnchor(
									animated: true,
									builder: (context, controller, child) {
										return Material(
											color: Colors.transparent,
											clipBehavior: .antiAlias,
											shape: RoundedRectangleBorder(
												borderRadius: .circular(12),
											),
											child: InkWell(
												onLongPressUp: () {
													if (controller.isOpen)
														controller.close();
													else
														controller.open();
												},
												child: Padding(
													padding: .all(_fontSize * 0.5),
													child: Text(f.toString(), style: _settings.fingeringsStyle(context)),
												),
											),
										);
									},
									menuChildren: [
										MenuItemButton(
											child: Text(AppLocalizations.of(context)!.songFingeringOptionSetAsDefaultGlobal),
											onPressed: () {
												Navigator.of(context).pop();
												setState(() => setFingeringGlobal(fingering: f));
											}
										),
										MenuItemButton(
											child: Text(AppLocalizations.of(context)!.songFingeringOptionSetAsDefaultLocal),
											onPressed: () {
												Navigator.of(context).pop();
												setState(() => _song.setFingering(fingering: f));
											}
										),
									],
								);
							}).toList(),
						),
					),
				),
			),
		);
	}

	Widget _autoscrollDialog({
		required Function(double, double) onDone,
	}) {
		final settings = AutoscrollSettings(
			delay: _autoscrollDelay.inSeconds.toDouble(),
			speed: _autoscrollSpeed.toDouble(),
		);

		return AlertDialog(
			title: Text(AppLocalizations.of(context)!.songAutoscroll),
			content: SizedBox(
				width: double.maxFinite,
				child: settings,
			),
			actions: [
				TextButton(
					child: Text(AppLocalizations.of(context)!.cancel),
					onPressed: () => Navigator.of(context).pop(),
				),
				ElevatedButton(
					child: Text(AppLocalizations.of(context)!.done),
					onPressed: () {
						onDone(settings.delay, settings.speed);
						Navigator.of(context).pop();
					},
				),
			],
		);
	}

	Widget _bottomSheetDialogWrapper({
		required String title,
		required Widget content,
		required List<Widget> actions,
	}) => Container(
		padding: const .all(10),
		margin: const .only(top: 10),
		height: MediaQuery.of(context).size.height * 0.9,
		child: Column(
			children: [
				Align(
					alignment: .centerLeft,
					child: Text(title,
						style: Theme.of(context).textTheme.titleLarge,
					),
				),
				const SizedBox(height: 10),

				Expanded(
					child: content,
				),
				const SizedBox(height: 10),

				Row(
					mainAxisAlignment: .end,
					children: actions,
				),

				SizedBox(height: MediaQuery.of(context).padding.bottom), // safe area
			],
		),
	);

	Widget _capoDialog({
		required Function(int) onDone,
	}) {
		final key = GlobalKey<FretboardState>();

		return DraggableScrollableSheet(
			expand: false,
			initialChildSize: 0.9,
			maxChildSize: 0.9,
			builder: (context, scrollController) {
				return _bottomSheetDialogWrapper(
					title: AppLocalizations.of(context)!.songCapo,
					content: SizedBox(
						width: double.maxFinite,
						child: Fretboard(
							key: key,
							fret: _capo ?? 0,
							controller: scrollController,
						),
					),
					actions: [
						TextButton(
							child: Text(AppLocalizations.of(context)!.cancel),
							onPressed: () => Navigator.of(context).pop(),
						),
						ElevatedButton(
							child: Text(AppLocalizations.of(context)!.done),
							onPressed: () {
								if (key.currentState != null)
									onDone(key.currentState!.fret);
								Navigator.of(context).pop();
							},
						),
					],
				);
			},
		);
	}

	Widget _keyDialog({
		required Function(SimpleKey) onDone,
	}) {
		final key = GlobalKey<CircleOfFifthState>();

		return _bottomSheetDialogWrapper(
			title: AppLocalizations.of(context)!.songKey,
			content: SizedBox(
				width: double.maxFinite,
				child: LayoutBuilder(
					builder: (context, constraints) {
						final width = constraints.maxWidth;
						final height = constraints.maxHeight;

						final size = (width > height)
							? height
							: width;

						return CircleOfFifth(
							key: key,
							simpleKey: _song.getSimpleKey(),
							size: size,
						);
					},
				),
			),
			actions: [
				TextButton(
					child: Text(AppLocalizations.of(context)!.cancel),
					onPressed: () => Navigator.of(context).pop(),
				),
				ElevatedButton(
					child: Text(AppLocalizations.of(context)!.done),
					onPressed: () {
						if (key.currentState?.currentKey != null)
							onDone(key.currentState!.currentKey!);
						Navigator.of(context).pop();
					},
				),
			],
		);
	}
}

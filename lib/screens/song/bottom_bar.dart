import 'package:flutter/material.dart';

import 'package:songbook/l10n/app_localizations.dart';

import 'package:songbook/screens/song/song.dart';
import 'package:songbook/functions/is_wide_screen.dart';



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
	final VoidCallback showKeyDialog;
	final VoidCallback showCapoDialog;
	final VoidCallback showAutoscrollDialog;

	final VoidCallback startAutoscroll;
	final VoidCallback stopAutoscroll;

	final VoidCallback edit;
	final Widget popupMenuButton;

	const BottomBar({
		super.key,
		required this.songKey,
		required this.songCapo,
		required this.autoscrollSpeed,

		required this.transposeSong,
		required this.setCapo,
		required this.setAutoscrollSpeed,

		required this.showKeyDialog,
		required this.showCapoDialog,
		required this.showAutoscrollDialog,

		required this.startAutoscroll,
		required this.stopAutoscroll,


		required this.edit,
		required this.popupMenuButton,
	});


	@override
	State<BottomBar> createState() => BarState();
}

class BarState extends State<BottomBar> {
	BarMode _currentMode = BarMode.none;
	late Color _foregroundColor;

	void switchModeToDefault() => setState(() => _currentMode = BarMode.none);


	@override
	Widget build(BuildContext context) {
		_foregroundColor = Theme.of(context).colorScheme.onPrimaryContainer;
		final screenWidth = MediaQuery.of(context).size.width;

		return Container(
			height: 80,
			width: isWideScreen(context)
				? 400
				: screenWidth,
			margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
			decoration: BoxDecoration(
				borderRadius: .only(
					topRight: .circular(20),
					topLeft: .circular(20),
				),
				color: Theme.of(context).colorScheme.surfaceContainer,
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
			Container(
				padding: const EdgeInsets.only(left: 5),
				width: 60,
				child: Row(
					mainAxisAlignment: .start,
					children: [
						IconButton(
							icon: Icon(Icons.edit),
							onPressed: widget.edit
						),
					],
				),
			),
			Spacer(),

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
				onLongPress: widget.showCapoDialog,
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
				onLongPress: widget.showAutoscrollDialog,
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
				onLongPress: widget.showKeyDialog,
				size: 50,
			),

			Spacer(),
			Container(
				padding: const EdgeInsets.only(right: 10),
				width: 60,
				child: Row(
					mainAxisAlignment: .end,
					children: [
						widget.popupMenuButton,
					],
				),
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
				size: 40,
			),
			const SizedBox(width: 10),

			_buildBarItem(
				child: Text('-3', 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: (widget.songCapo > 2)
					? () => widget.setCapo(widget.songCapo - 3)
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
				child: Text('+3', 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () => widget.setCapo(widget.songCapo + 3),
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
				size: 40,
			),
		];
	}
	List<Widget> _buildKey() {
		return [
			_buildBarItem(
				child: Text('-0.5', 
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
				child: Text('-1', 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () => widget.transposeSong(-2),
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
				onTap: () => widget.transposeSong(2),
			),

			const SizedBox(width: 10),
			_buildBarItem(
				child: Text('+0.5', 
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
					: () => widget.setAutoscrollSpeed(0),
				size: 40,
			),
			const SizedBox(width: 10),

			_buildBarItem(
				child: Text('-' + (AutoscrollSpeedStep * 2).toString(), 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: (widget.autoscrollSpeed > (AutoscrollSpeedStep * 2))
					? () => widget.setAutoscrollSpeed(widget.autoscrollSpeed - (AutoscrollSpeedStep * 2))
					: () => widget.setAutoscrollSpeed(0),
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
				child: Text('+' + (AutoscrollSpeedStep * 2).toString(), 
					style: TextStyle(
						color: _foregroundColor,
						fontSize: 15,
						fontWeight: .bold,
					)
				),
				onTap: () => widget.setAutoscrollSpeed(widget.autoscrollSpeed + (AutoscrollSpeedStep * 2)),
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
				size: 40,
			),
		];
	}

	Widget _buildBarItem({
		required Widget child,
		required VoidCallback? onTap,
		VoidCallback? onLongPress,
		double size = 45,
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
					onLongPress: onLongPress,
					splashColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
					highlightColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
				),
			),
		);
	}
}

class PopupMenu extends StatefulWidget {
	final bool chords;
	final bool rhythm;
	final bool notes;
	final bool fingerings;

	final VoidCallback switchChords;
	final VoidCallback switchRhythm;
	final VoidCallback switchNotes;
	final VoidCallback switchFingerings;


	const PopupMenu({
		super.key,
		required this.chords,
		required this.rhythm,
		required this.notes,
		required this.fingerings,

		required this.switchChords,
		required this.switchRhythm,
		required this.switchNotes,
		required this.switchFingerings,
	});

	@override
	State<PopupMenu> createState() => _PopupMenuState();
}

class _PopupMenuState extends State<PopupMenu> {
	late Map<String, bool> _showOptions;

	@override
	void initState() {
		super.initState();
		_getOptions();
	}

	void _getOptions() {
		_showOptions = {
			'chords': widget.chords,
			'rhythm': widget.rhythm,
			'notes': widget.notes,
			'fingerings': widget.fingerings,
		};
	}

	@override
	Widget build(BuildContext context) {
		return MenuAnchor(
			animated: true,
			builder: (context, controller, child) => IconButton(
				icon: Icon(Icons.more_vert),
				onPressed: () {
					if (controller.isOpen) {
						controller.close();
					} else {
						controller.open();
					}
				},
			),
			menuChildren: _showOptions.keys.map((key) => MenuItemButton(
				child: StatefulBuilder(
					builder: (context, setState) {
						setState(() => _getOptions());

						return CheckboxListTile(
							title: Text(_getTextFromValue(key)),
							value: _showOptions[key],
							onChanged: (bool? value) {
								setState(() => _showOptions[key] = value!);
								switch (key) {
									case ('chords'):
										widget.switchChords();
										break;

									case ('rhythm'):
										widget.switchRhythm();
										break;

									case ('notes'):
										widget.switchNotes();
										break;

									case ('fingerings'):
										widget.switchFingerings();
										break;

									default:
										break;
								}
							},
							controlAffinity: ListTileControlAffinity.leading,
						);
					},
				),
			)).toList(),
		);
	}

	String _getTextFromValue(String value) => switch (value) {
		'chords' => AppLocalizations.of(context)!.chords,
		'rhythm' => AppLocalizations.of(context)!.rhythm,
		'notes' => AppLocalizations.of(context)!.notes,
		'fingerings' => AppLocalizations.of(context)!.fingerings,
		_ => '',
	};
}



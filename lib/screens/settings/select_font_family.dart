import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:songbook/services/settings.dart';
import 'package:songbook/l10n/app_localizations.dart';


class SelectFontFamily extends StatefulWidget {
	final String? initialValue;

	const SelectFontFamily({super.key, this.initialValue});

	@override
	State<SelectFontFamily> createState() => _SelectFontFamilyState();
}

class _SelectFontFamilyState extends State<SelectFontFamily> {
	late SettingsProvider _settings;


	final List<String> _fonts = FONT_FAMILIES;
	late List<String> _customFonts;
	String? _selected;

	@override
	void initState() {
		_selected = widget.initialValue;
		super.initState();
	}

	void _loadCustomFonts() => setState(() {
		_customFonts = _settings.customFontFamilies;
	});


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();
		_customFonts = _settings.customFontFamilies;

		return DraggableScrollableSheet(
			expand: false,
			snap: true,
			maxChildSize: 0.9,
			builder: (context, controller) => Padding(
				padding: const EdgeInsets.all(10),
				child: Material(
					color: Theme.of(context).colorScheme.surfaceContainerHighest,
					shape: RoundedRectangleBorder(
						borderRadius: .circular(8),
					),
					child: _buildFonts(controller),
				),
			),
		);
	}

	Widget _buildFonts(ScrollController controller) {
		return ListView.builder(
			controller: controller,
			itemCount: _fonts.length + _customFonts.length + 1,
			itemBuilder: (context, fontIndex) {
				final customFontIndex = fontIndex - _fonts.length;
				final bool isCustom = (customFontIndex >= 0);

				if (fontIndex == (_fonts.length + _customFonts.length))
					return _buildAddNewItem();


				final String family = isCustom
					? _customFonts[customFontIndex]
					: _fonts[fontIndex];

				return _buildFontItem(family, isCustom);
			},
		);
	}

	Widget _buildFontItem(String family, bool isCustom) {
		final String textExample = AppLocalizations.of(context)!.fontExampleText;

		return _buildItem(
			child: Container(
				padding: const EdgeInsets.all(10),
				margin: const EdgeInsets.symmetric(vertical: 5),
				child: Row(
					mainAxisAlignment: .spaceBetween,
					children: [
						Flexible(
							child: Column(
								crossAxisAlignment: .start,
								children: [
									Row(
										children: [
											if (_selected == family) ...[
												Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
												SizedBox(width: 10),
											],

											Text(family),
										],
									),
									const SizedBox(height: 10),
									Text(textExample,
										style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: family)
									),
								],
							),
						),

						if (isCustom) ...[
							IconButton(
								icon: Icon(Icons.delete),
								onPressed: () async {
									await _settings.removeCustomFont(family);
									_loadCustomFonts();

									if (_selected == family) {
										setState(() => _selected = _fonts[0]);
										if (mounted)
											Navigator.of(context).pop(_selected);
									}
								},
							),
						],
					],
				),
			),
			onTap: () {
				setState(() => _selected = family);
				Navigator.of(context).pop(_selected);
			},
		);
	}

	Widget _buildAddNewItem() => _buildItem(
		child: Center(
			child: Padding(
				padding: const EdgeInsets.symmetric(vertical: 10),
				child: Icon(Icons.add),
			),
		),
		onTap: () async {
			await _settings.addNewCustomFont();
			_loadCustomFonts();
		},
	);


	Widget _buildItem({required Widget child, required VoidCallback onTap}) {
		final primary = Theme.of(context).colorScheme.primary;

		return InkWell(
			splashColor: primary.withValues(alpha: 0.1),
			highlightColor: primary.withValues(alpha: 0.05),
			child: child,
			onTap: onTap,
		);
	}
}

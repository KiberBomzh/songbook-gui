import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:songbook/services/settings.dart';


class SettingsScreen extends StatefulWidget {
	SettingsScreen({super.key});

	@override
	State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
	late SettingsProvider _settings;

	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();

		return Scaffold(
			appBar: AppBar( title: Text('Settings') ),
			body: _buildBody(),
		);
	}

	Widget _buildBody() {
		return Material(
			child: Padding(
				padding: const EdgeInsets.symmetric(vertical: 5),
				child: ListView(
					children: [
						_buildItem(
							text: 'Theme',
							child: Container(),
							onTap: null,
						),
					],
				),
			),
		);
	}

	Widget _buildItem({
		required VoidCallback? onTap,
		required String text,
		required Widget child,
	}) {
		final primary = Theme.of(context).colorScheme.primary;
		return InkWell(
			onTap: onTap,
			splashColor: primary.withOpacity(0.1),
			highlightColor: primary.withOpacity(0.05),
			child: Padding(
				padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
				child: Row(
					mainAxisAlignment: .start,
					children: [
						Text(text),
						Spacer(),
						child,
					],
				),
			),
		);
	}
}

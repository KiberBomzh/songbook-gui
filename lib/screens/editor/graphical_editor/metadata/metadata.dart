import 'package:flutter/material.dart';

import 'package:songbook/l10n/app_localizations.dart';
import 'package:songbook/src/rust/api/song.dart';

import 'package:songbook/screens/editor/graphical_editor/widgets.dart';
import 'package:songbook/screens/editor/graphical_editor/metadata/fingerings.dart';
import 'package:songbook/screens/editor/graphical_editor/metadata/tags.dart';
import 'package:songbook/screens/editor/graphical_editor/metadata/show_options.dart';
import 'package:songbook/functions/parse_key_value_line.dart';


class Metadata extends StatefulWidget {
	String title;
	String artist;
	String? Key;
	int? capo;
	int? autoscrollSpeed;
	int? autoscrollDelay;
	ShowOptions showOptions;
	Tags tags;
	Fingerings fingerings;

	Metadata({
		super.key,
		required this.title,
		required this.artist,
		required this.showOptions,
		required this.tags,
		required this.fingerings,
		this.Key,
		this.capo,
		this.autoscrollSpeed,
		this.autoscrollDelay,
	});

	static Metadata from_string(String text) {
		String title = '';
		String artist = '';
		String? key;
		int? capo;
		int? autoscrollSpeed;
		int? autoscrollDelay;
		ShowOptions options = ShowOptions();
		List<String>? tags;
		String fingerings = "";

		bool inMetadata = false;
		bool inFingerings = false;
		for (final line in text.split('\n')) {
			if (inMetadata) {
				if ( line.startsWith(metadataEnd()) ) {
					break;
				} else if ( line.startsWith(songFingeringsEnd()) ) {
					inFingerings = false;
				} else if ( line.startsWith(songFingeringsStart()) ) {
					inFingerings = true;
				} else if ( inFingerings ) {
					fingerings += line + '\n';
				} else if ( line.startsWith(songTitleSymbol()) ) {
					title = parseKeyValueLine(line) ?? 'some title';
				} else if ( line.startsWith(songArtistSymbol()) ) {
					artist = parseKeyValueLine(line) ?? 'some artist';
				} else if ( line.startsWith(songKeySymbol()) ) {
					key = parseKeyValueLine(line);
				} else if ( line.startsWith(songCapoSymbol()) ) {
					final result = parseKeyValueLine(line);
					if (result != null)
						capo = int.tryParse(result);
				} else if ( line.startsWith(songAutoscrollSpeedSymbol()) ) {
					final result = parseKeyValueLine(line);
					if (result != null)
						autoscrollSpeed = int.tryParse(result);
				} else if ( line.startsWith(songAutoscrollDelaySymbol()) ) {
					final result = parseKeyValueLine(line);
					if (result != null)
						autoscrollDelay = int.tryParse(result);
				} else if ( line.startsWith(songShowOptionsSymbol()) ) {
					options.from_string(line);
				} else if ( line.startsWith(songTagsSymbol()) ) {
					final result = parseKeyValueLine(line);
					if (result != null)
						tags = result.split(', ');
				}
			} else {
				if ( line.startsWith(metadataStart()) )
					inMetadata = true;
			}
		}

		return Metadata(
			title: title,
			artist: artist,
			Key: key,
			capo: capo,
			autoscrollSpeed: autoscrollSpeed,
			autoscrollDelay: autoscrollDelay,
			showOptions: options,
			tags: Tags(tags: tags ?? []),
			fingerings: Fingerings.from_string(fingerings),
		);
	}

	String to_string() {
		String result = '';

		result += metadataStart() + '\n';

		result += songTitleSymbol() + title + '\n';
		result += songArtistSymbol() + artist + '\n';

		result += songKeySymbol();
		if (Key != null)
			result += Key.toString();
		result += '\n';

		result += songCapoSymbol();
		if (capo != null)
			result += capo.toString();
		result += '\n';

		result += songAutoscrollSpeedSymbol();
		if (autoscrollSpeed != null)
			result += autoscrollSpeed.toString();
		result += '\n';

		result += songAutoscrollDelaySymbol();
		if (autoscrollDelay != null)
			result += autoscrollDelay.toString();
		result += '\n';

		result += songShowOptionsSymbol() + showOptions.to_string() + '\n';

		result += songTagsSymbol() + tags.to_string() + '\n';

		result += songFingeringsStart() + '\n' + fingerings.to_string() + songFingeringsEnd() + '\n';

		result += metadataEnd() + '\n\n';


		return result;
	}


	@override
	State<Metadata> createState() => _MetadataState();
}
class _MetadataState extends State<Metadata> {
	late final TextEditingController _titleController;
	late final TextEditingController _artistController;
	late final TextEditingController _keyController;
	late final TextEditingController _capoController;
	late final TextEditingController _autoscrollSpeedController;
	late final TextEditingController _autoscrollDelayController;


	@override
	void initState() {
		super.initState();
		_titleController = TextEditingController(text: widget.title);
		_artistController = TextEditingController(text: widget.artist);
		_keyController = TextEditingController(text: widget.Key);
		_capoController = TextEditingController(text: widget.capo?.toString());
		_autoscrollSpeedController = TextEditingController(text: widget.autoscrollSpeed?.toString());
		_autoscrollDelayController = TextEditingController(text: widget.autoscrollDelay?.toString());
	}

	@override
	void dispose() {
		_titleController.dispose();
		_artistController.dispose();
		_keyController.dispose();
		_capoController.dispose();
		_autoscrollSpeedController.dispose();
		_autoscrollDelayController.dispose();
		super.dispose();
	}


	@override
	Widget build(BuildContext context) {
		final style = TextStyle();

		return Container(
			padding: const .all(10),
			margin: const .all(10),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainer,
				borderRadius: .circular(8),
			),
			child: Column(
				crossAxisAlignment: .start,
				children: [
					Align(
						alignment: .centerRight,
						child: Text(AppLocalizations.of(context)!.editorMetadata),
					),
					const SizedBox(height: 10),

					OneLineTextField(
						label: AppLocalizations.of(context)!.editorMetadataTitle,
						controller: _titleController,
						style: style,
						onChanged: (value) => widget.title = value,
					),
					const SizedBox(height: 10),

					OneLineTextField(
						label: AppLocalizations.of(context)!.editorMetadataArtist,
						controller: _artistController,
						style: style,
						onChanged: (value) => widget.artist = value,
					),
					const SizedBox(height: 10),

					OneLineTextField(
						label: AppLocalizations.of(context)!.editorMetadataKey,
						controller: _keyController,
						style: style,
						onChanged: (value) => widget.Key = (value.trim().isEmpty)
							? null
							: value,
					),
					const SizedBox(height: 10),

					OneLineTextField(
						label: AppLocalizations.of(context)!.editorMetadataCapo,
						controller: _capoController,
						style: style,
						onChanged: (value) => widget.capo = int.tryParse(value),
					),
					const SizedBox(height: 10),

					OneLineTextField(
						label: AppLocalizations.of(context)!.editorMetadataAutoscrollSpeed,
						controller: _autoscrollSpeedController,
						style: style,
						onChanged: (value) => widget.autoscrollSpeed = int.tryParse(value),
					),
					const SizedBox(height: 10),

					OneLineTextField(
						label: AppLocalizations.of(context)!.editorMetadataAutoscrollDelay,
						controller: _autoscrollDelayController,
						style: style,
						onChanged: (value) => widget.autoscrollDelay = int.tryParse(value),
					),
					const SizedBox(height: 10),


					widget.showOptions,
					widget.tags,
					widget.fingerings,
				],
			),
		);
	}
}

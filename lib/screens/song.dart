import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:songbook/src/rust/api/song.dart';

import 'package:songbook/screens/editor.dart';


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
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10),
			width: double.infinity,
			child: ListView.separated(
				itemCount: blocks.length,
				separatorBuilder: (context, index) => const SizedBox(height: 25),
				itemBuilder: (context, index) => _buildBlock(blocks[index]),
			),
		);
	}

	Widget _buildBlock(SimpleBlock block) {
		return Container(
			child: Column(
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
										style: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.7))
									),
							]
						),
						const SizedBox(height: 10),
					],

					...block.lines.map((l) {
						return Text(l,
							style: GoogleFonts.jetBrainsMono()
						);
					}).toList(),
				],
			),
		);
	}
}

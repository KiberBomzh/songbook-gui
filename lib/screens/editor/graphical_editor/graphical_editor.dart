import 'package:flutter/material.dart';

import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:provider/provider.dart';

import 'package:songbook/l10n/app_localizations.dart';
import 'package:songbook/src/rust/api/song.dart';

import 'package:songbook/screens/editor/graphical_editor/line/line.dart' as line_;
import 'package:songbook/screens/editor/graphical_editor/line_type.dart';
import 'package:songbook/screens/editor/graphical_editor/block.dart' as block_;
import 'package:songbook/screens/editor/graphical_editor/metadata/metadata.dart';
import 'package:songbook/screens/editor/graphical_editor/widgets.dart';
import 'package:songbook/screens/editor/editor_text_controller.dart';
import 'package:songbook/services/settings.dart';


class GraphicalSongEditor extends StatefulWidget {
	final EditorTextController controller;
	final Function(double) onScrollUpdate;
	final double initialScrollOffset;
	final FocusNode? focusNode;

	const GraphicalSongEditor({
		super.key,
		required this.controller,
		required this.onScrollUpdate,
		required this.initialScrollOffset,
		this.focusNode,
	});


	@override
	State<GraphicalSongEditor> createState() => GraphicalSongEditorState();
}
class GraphicalSongEditorState extends State<GraphicalSongEditor> {
	late SettingsProvider _settings;

	late Metadata _metadata;
	String songNote = '';
	final List<DragAndDropList> _contents = [];

	late final TextEditingController _songNoteController;


	late final ScrollController _scrollController;


	@override
	void initState() {
		super.initState();
		readFromTextController();

		_songNoteController = TextEditingController(text: songNote);
		_scrollController = ScrollController(initialScrollOffset: widget.initialScrollOffset);
		_scrollController.addListener(_updateScroll);
	}

	@override
	void dispose() {
		_songNoteController.dispose();
		_scrollController.removeListener(_updateScroll);
		_scrollController.dispose();

		_contents.clear();
		super.dispose();
	}

	void setScrollOffset(double offset) => _scrollController.jumpTo(offset);

	void readFromTextController() {
		_metadata = Metadata.from_string(widget.controller.text);
		_parseBlocks();
	}
	void _parseBlocks() {
		String blockText = '';
		bool inBlock = false;
		bool inSongNote = false;
		for (final line in widget.controller.text.split('\n')) {
			if (inBlock) {
				if (line.startsWith(blockEnd())) {
					inBlock = false;
					final (block, lines) = block_.Block.from_string(
						blockText,
						'block_${_contents.length + 1}',
						_contents.length,
						_deleteBlock,
						_addNewBlockAfter,
						_deleteLine,
						_addNewLineInBlockAfter,
						_copyBlockAfter,
						_copyLineInBlockAfter,
						_splitBlockBefore,
						_mergeBlockWithNext,
						_splitRow,
						_mergeRow,
						_convertPlainTextToRow,
					);
					_contents.add(
						_buildDragAndDropList(
							block: block,
							lines: lines.map((line) => DragAndDropItem(child: line)).toList(),
						),
					);
					blockText = '';
				} else {
					blockText += line + '\n';
				}
			} else if (inSongNote) {
				if (line.startsWith(songNoteEndSymbol())) {
					inSongNote = false;
				} else {
					songNote += line + '\n';
				}
			} else {
				if (line.startsWith(songNoteStartSymbol())) {
					inSongNote = true;
				} else if (line.startsWith(blockStart())) {
					inBlock = true;
				}
			}
		}
	}

	Future<void> writeInTextController() async {
		String text = '';

		text += _metadata.to_string();
		if (songNote.isNotEmpty) {
			text += songNoteStartSymbol() + '\n';
			text += songNote;
			if (!text.endsWith('\n'))
				text += '\n';
			text += songNoteEndSymbol() + '\n\n';
		}

		for (final list in _contents) {
			final block_.Block block = list.header! as block_.Block;
			final lines = list.children.map((item) => item.child as line_.Line).toList();
			text += block.to_string(lines);
		}

		widget.controller.text = text;
	}

	void _updateScroll() => widget.onScrollUpdate(_scrollController.offset);

	void _deleteBlock(int index) => setState(() {
		_contents.removeAt(index);
		_updateBlocksIndexesAfter(index);
	});
	void _deleteLine(int index, int parentIndex) => setState(() {
		_contents[parentIndex].children.removeAt(index);
		_updateLinesIndexesAfter(index, parentIndex);
	});

	void _addNewBlockAfter(int index) => setState(() {
		final int newIndex = index + 1;
		final block = block_.Block(
			key: UniqueKey(),
			index: newIndex,
			onDelete: _deleteBlock,
			onAddNewBlock: _addNewBlockAfter,
			onCopy: _copyBlockAfter,
			onMergeBlock: _mergeBlockWithNext,
		);
		_contents.insert(newIndex,
			_buildDragAndDropList(block: block),
		);

		_updateBlocksIndexesAfter(newIndex + 1);
	});

	void _addNewLineInBlockAfter(int parentIndex, int index) async {
		final LineType? lineType = await showModalBottomSheet<LineType?>(
			isScrollControlled: true,
			context: context,
			builder: (context) => SelectLineType(),
		);
		if (lineType == null)
			return;

		final newIndex = index + 1;
		final line = switch (lineType) {
			LineType.textBlock => line_.TextBlock(
				key: UniqueKey(),
				index: newIndex,
				parentIndex: parentIndex,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
				onCopy: _copyLineInBlockAfter,
				onSplitRow: _splitRow,
				onMerge: _mergeRow,
			),
			LineType.chordsLine => line_.ChordsLine(
				chords: '',
				key: UniqueKey(),
				index: newIndex,
				parentIndex: parentIndex,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onCopy: _copyLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
			),
			LineType.noteLine => line_.NoteLine(
				text: '',
				key: UniqueKey(),
				index: newIndex,
				parentIndex: parentIndex,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onCopy: _copyLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
			),
			LineType.plainText => line_.PlainText(
				text: '',
				key: UniqueKey(),
				index: newIndex,
				parentIndex: parentIndex,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onCopy: _copyLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
				onConvertToRow: _convertPlainTextToRow,
			),
			LineType.tab => line_.Tab(
				tab: '',
				key: UniqueKey(),
				index: newIndex,
				parentIndex: parentIndex,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onCopy: _copyLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
			),
			LineType.emptyLine => line_.EmptyLine(
				key: UniqueKey(),
				index: newIndex,
				parentIndex: parentIndex,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onCopy: _copyLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
			),
		};

		setState(() {
			_contents[parentIndex].children.insert(newIndex,
				DragAndDropItem(child: line),
			);

			_updateLinesIndexesAfter(newIndex, parentIndex);
		});
	}
	void _copyLineInBlockAfter(int parentIndex, int  index, line_.Line line) {
		final newIndex = index + 1;
		setState(() {
			_contents[parentIndex].children.insert(newIndex,
				DragAndDropItem(
					child: line.copyWith(
						key: UniqueKey(),
						index: newIndex,
					)
				),
			);

			_updateLinesIndexesAfter(newIndex, parentIndex);
		});
	}
	void _copyBlockAfter(int index) {
		final item = _contents[index];
		final block = item.header! as block_.Block;
		final lines = item.children.map((item) => item.child as line_.Line).toList();

		final newIndex = index + 1;
		final newBlock = block.copyWith(
			key: UniqueKey(),
			index: newIndex,
		);
		final newLines = lines.map((line) {
			return DragAndDropItem(
				child: line.copyWith(
					key: UniqueKey(),
					parentIndex: newIndex,
				),
			);
		}).toList();

		final newItem = _buildDragAndDropList(
			block: newBlock,
			lines: newLines,
		);
		
		setState(() {
			_contents.insert(newIndex, newItem);
			_updateBlocksIndexesAfter(newIndex);
		});
	}

	void _splitBlockBefore(int blockIndex, int lineIndex) {
		final item = _contents.removeAt(blockIndex);

		final block = item.header! as block_.Block;
		final List<DragAndDropItem> lines = item.children;

		final oldBlockLines = lines.sublist(0, lineIndex);
		final oldItem = _buildDragAndDropList(
			block: block,
			lines: oldBlockLines,
		);

		final newIndex = blockIndex + 1;
		final newBlockLines = lines.sublist(lineIndex);
		final newBlock = block_.Block(
			key: UniqueKey(),
			index: newIndex,
			onDelete: _deleteBlock,
			onAddNewBlock: _addNewBlockAfter,
			onCopy: _addNewBlockAfter,
			onMergeBlock: _mergeBlockWithNext,
		);

		final newItem = _buildDragAndDropList(
			block: newBlock,
			lines: newBlockLines,
		);


		setState(() {
			_contents.insert(blockIndex, oldItem);
			_contents.insert(newIndex, newItem);

			_updateBlocksIndexesAfter(blockIndex);
			_updateAllLinesIndexesInBlock(blockIndex + 1);
		});
	}

	void _mergeBlockWithNext(int index) {
		if (index == _contents.length - 1) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(AppLocalizations.of(context)!.editorTheLastBlockMsg),
					duration: Duration(seconds: 1),
				),
			);


			return;
		}


		final nextItem = _contents.removeAt(index + 1);
		final item = _contents.removeAt(index);

		final block = item.header! as block_.Block;
		final lines = item.children;
		final nextLines = nextItem.children;

		final newBlock = block.copyWith(key: UniqueKey());
		final newLines = [...lines, ...nextLines];

		final newItem = _buildDragAndDropList(
			block: newBlock,
			lines: newLines,
		);


		setState(() {
			_contents.insert(index, newItem);
			_updateBlocksIndexesAfter(index);
			_updateLinesIndexesAfter(lines.length, index);
		});
	}

	void _splitRow(int blockIndex, int lineIndex, int inlineIndex) {
		final item = _contents[blockIndex];
		final row = item.children[lineIndex].child as line_.TextBlock;


		String chords = row.chords ?? '';
		String rhythm = row.rhythm ?? '';
		String text = row.text ?? '';

		int maxLen = chords.length;
		if (rhythm.length > maxLen)
			maxLen = rhythm.length;
		if (text.length > maxLen)
			maxLen = text.length;

		if (chords.length < maxLen)
			chords += ' ' * (maxLen - chords.length);
		if (rhythm.length < maxLen)
			rhythm += ' ' * (maxLen - rhythm.length);
		if (text.length < maxLen)
			text += ' ' * (maxLen - text.length);


		final oldChords = chords.substring(0, inlineIndex);
		final newChords = chords.substring(inlineIndex);

		final oldRhythm = rhythm.substring(0, inlineIndex);
		final newRhythm = rhythm.substring(inlineIndex);

		final oldText = text.substring(0, inlineIndex);
		final newText = text.substring(inlineIndex);


		final oldRow = row.copyWith(
			key: UniqueKey(),
			index: lineIndex,
			chords: oldChords,
			rhythm: oldRhythm,
			text: oldText,
		);

		final newIndex = lineIndex + 1;
		final newRow = row.copyWith(
			key: UniqueKey(),
			index: newIndex,
			chords: newChords,
			rhythm: newRhythm,
			text: newText,
			requestFocus: true,
		);


		setState(() {
			item.children.removeAt(lineIndex);

			item.children.insert(lineIndex, DragAndDropItem(child: oldRow));
			item.children.insert(newIndex, DragAndDropItem(child: newRow));


			_updateLinesIndexesAfter(lineIndex, blockIndex);
		});
	}
	void _mergeRow(int blockIndex, int lineIndex) {
		final item = _contents[blockIndex];
		if (item.children.length == lineIndex + 1) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(AppLocalizations.of(context)!.editorTheLastRowInTheBlockMsg),
					duration: Duration(seconds: 1),
				),
			);


			return;
		}

		if (item.children[lineIndex + 1].child is! line_.TextBlock) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(AppLocalizations.of(context)!.editorNextLineIsNotARowMsg),
					duration: Duration(seconds: 1),
				),
			);


			return;
		}


		final row = item.children[lineIndex].child as line_.TextBlock;
		final nextRow = item.children[lineIndex + 1].child as line_.TextBlock;

		final newRow = row.copyWith(
			key: UniqueKey(),

			chords: (row.chords ?? '') + (nextRow.chords ?? ''),
			rhythm: (row.rhythm ?? '') + (nextRow.rhythm ?? ''),
			text: (row.text ?? '') + (nextRow.text ?? ''),
		);


		setState(() {
			item.children.removeAt(lineIndex + 1);
			item.children[lineIndex] = DragAndDropItem(child: newRow);

			_updateLinesIndexesAfter(lineIndex, blockIndex);
		});
	}

	void _convertPlainTextToRow(int blockIndex, int lineIndex) {
		final item = _contents[blockIndex];
		final plainText = item.children[lineIndex].child as line_.PlainText;

		final List<String> lines = plainText.text.split('\n');
		final rows = [];
		for (int i = 0; i < lines.length; i++) {
			final line = lines[i];
			final row = line_.TextBlock(
				text: line,
				key: UniqueKey(),
				parentIndex: blockIndex,
				index: lineIndex + i,
				onDelete: _deleteLine,
				onAddNewLine: _addNewLineInBlockAfter,
				onSplitBlock: _splitBlockBefore,
				onCopy: _copyLineInBlockAfter,
				onSplitRow: _splitRow,
				onMerge: _mergeRow,
			);
			rows.add(DragAndDropItem(child: row));
		}

		setState(() {
			item.children.removeAt(lineIndex);
			int newIndex = lineIndex;
			for (final row in rows) {
				item.children.insert(newIndex, row);
				newIndex++;
			}

			_updateLinesIndexesAfter(newIndex, blockIndex);
		});
	}


	void _updateBlocksIndexesAfter(int index) {
		for (int i = index; i < _contents.length; i++) {
			final block = _contents[i].header! as block_.Block;
			final lines = _contents[i].children.map((item) => item.child as line_.Line).toList();

			block.index = i;
			for (final line in lines) {
				line.parentIndex = i;
			}
		}
	}
	void _updateLinesIndexesAfter(int index, int parentIndex) {
		for (int i = index; i < _contents[parentIndex].children.length; i++) {
			final line = _contents[parentIndex].children[i].child as line_.Line;
			line.index = i;
		}
	}

	void _updateAllBlocksIndexes() {
		for (int i = 0; i < _contents.length; i++) {
			final block = _contents[i].header! as block_.Block;
			block.index = i;

			_updateAllLinesIndexesInBlock(i);
		}
	}
	void _updateAllLinesIndexesInBlock(int index) {
		for (int i = 0; i < _contents[index].children.length; i++) {
			final line = _contents[index].children[i].child as line_.Line;
			line.index = i;
			line.parentIndex = index;
		}
	}


	void _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
		setState(() {
			var movedItem = _contents[oldListIndex].children.removeAt(oldItemIndex);
			_contents[newListIndex].children.insert(newItemIndex, movedItem);
			_updateAllLinesIndexesInBlock(newListIndex);
		});
	}

	void _onListReorder(int oldListIndex, int newListIndex) {
		setState(() {
			var movedList = _contents.removeAt(oldListIndex);
			_contents.insert(newListIndex, movedList);
			_updateAllBlocksIndexes();
		});
	}


	@override
	Widget build(BuildContext context) {
		_settings = context.watch<SettingsProvider>();

		return Focus(
			focusNode: widget.focusNode,
			child: (_contents.isEmpty)
				? _buildDragAndDropLists()
				: CustomScrollView(
					controller: _scrollController,
					slivers: [_buildDragAndDropLists()],
				),
		);
	}
	Widget _buildDragAndDropLists() => DragAndDropLists(
		children: _contents,
		contentsWhenEmpty: TextButton.icon(
			icon: Icon(Icons.add),
			label: Text(AppLocalizations.of(context)!.editorAddNewBlock),
			onPressed: () => _addNewBlockAfter(-1),
		),

		onItemReorder: _onItemReorder,
		onListReorder: _onListReorder,

		listDecoration: BoxDecoration(
			color: Theme.of(context).colorScheme.surfaceContainer,
			borderRadius: .circular(10),
		),
		listPadding: .all(10),
		itemDivider: const SizedBox(height: 10),

		sliverList: true,
		scrollController: _scrollController,
	);

	void showMetadataEditor() {
		showModalBottomSheet(
			backgroundColor: Theme.of(context).colorScheme.surface,
			isScrollControlled: true,
			clipBehavior: .antiAlias,

			context: context,
			builder: (context) => DraggableScrollableSheet(
				expand: false,
				snap: true,
				initialChildSize: 0.9,
				maxChildSize: 0.9,
				builder: (context, controller) => Column(
					children: [
						Expanded(
							child: ListView(
								controller: controller,
								children: [
									_metadata,
									_buildSongNoteField(),
								],
							),
						),

						SizedBox(height: MediaQuery.of(context).viewInsets.bottom), // для клавиатуры
						SizedBox(height: MediaQuery.of(context).padding.bottom), // safe area
					],
				),
			),
		);
	}

	Widget _buildSongNoteField() => Container(
		margin: const .all(10),
		padding: const .all(10),
		decoration: BoxDecoration(
			color: Theme.of(context).colorScheme.surfaceContainer,
			borderRadius: .circular(8),
		),
		child: Column(
			children: [
				Align(
					alignment: .centerRight,
					child: Text(AppLocalizations.of(context)!.editorSongNote),
				),
				
				Padding(
				padding: const .all(10),
					child: IntrinsicHeight(
						child: ManyLineTextField(
							controller: _songNoteController,
							style: _settings.notesStyle(context),
							onChanged: (value) => songNote = value,
						),
					),
				),
			],
		),
	);

	DragAndDropList _buildDragAndDropList({
		required block_.Block block,
		List<DragAndDropItem>? lines,
	}) => DragAndDropList(
		header: block,
		children: lines ?? [],

		leftSide: const SizedBox(width: 20),
		rightSide: const SizedBox(width: 20),

		contentsWhenEmpty: TextButton.icon(
			icon: Icon(Icons.add),
			label: Text(''), //AppLocalizations.of(context)!.editorAddNewLine),
			onPressed: () => _addNewLineInBlockAfter(block.index, -1),
		),
	);
}

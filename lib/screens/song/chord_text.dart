import 'package:flutter/material.dart';


class ChordText extends StatelessWidget {
	final String text;
	final TextStyle style;
	final Color background;

	const ChordText(
		this.text, {
		super.key,
		required this.style,
		required this.background,
	});

	@override
	Widget build(BuildContext context) {
		final List<TextSpan> spans = [];
		final buffer = StringBuffer();
		bool? isSpace;

		void flush() {
			if (buffer.isEmpty)
				return;

			final chunk = buffer.toString();
			buffer.clear();
			spans.add(TextSpan(text: chunk, style: (isSpace == true)
				? style
				: style.copyWith(backgroundColor: background),
			));
		}

		for (final rune in text.runes) {
			final is_space = (rune == 0x20); // 0x20 == ' '
			if (isSpace == null) {
				isSpace = is_space;
			} else if (isSpace != is_space) {
				flush();
				isSpace = is_space;
			}
			buffer.writeCharCode(rune);
		}
		flush();


		return Text.rich(TextSpan(children: spans));
	}
}

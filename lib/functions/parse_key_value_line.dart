String? parseKeyValueLine(String line) {
	final i = line.indexOf(':');
	if (i == -1)
		return null;

	final result = line.substring(i + 1).trim();
	if (result.isEmpty)
		return null;
	else
		return result;
}

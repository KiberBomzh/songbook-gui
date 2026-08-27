import 'package:songbook/main.dart';


String getPathName(String path) {
	return path.substring(path.lastIndexOf(pathDivider) + 1);
}

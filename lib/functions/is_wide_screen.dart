import 'package:flutter/material.dart';


bool isWideScreen(BuildContext context) {
	return (MediaQuery.of(context).size.width > 600);
}

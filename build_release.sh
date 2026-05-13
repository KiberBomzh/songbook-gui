#!/usr/bin/env bash


if [ -z "$APPIMAGE_TOOL_PATH" ]; then
	echo "APPIMAGE_TOOL_PATH is empty! Set a path to appimagetool!"
	exit 1
fi

flutter clean
scripts/build_apk.sh
scripts/build_appimage.sh

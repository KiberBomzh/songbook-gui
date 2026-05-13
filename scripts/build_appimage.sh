#!/usr/bin/env bash


if [ -z "$APPIMAGE_TOOL_PATH" ]; then
	echo "APPIMAGE_TOOL_PATH is empty! Set a path to appimagetool!"
	exit 1
fi


flutter build linux
cp -r linux/AppDir build/
cp assets/icon.png build/AppDir/
cp -r build/linux/x64/release/bundle/* build/AppDir/
$APPIMAGE_TOOL_PATH -n build/AppDir

rm -rf build/AppDir


mkdir -p release/linux
mv songbook-x86_64.AppImage release/linux

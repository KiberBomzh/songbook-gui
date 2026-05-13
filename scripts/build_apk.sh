#!/usr/bin/env bash


flutter build apk
flutter build apk --split-per-abi
mkdir -p release/android
cp \
	build/app/outputs/flutter-apk/app-release.apk \
	build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
	build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
	build/app/outputs/flutter-apk/app-x86_64-release.apk \
	build/app/outputs/flutter-apk/app-release.apk.sha1 \
	build/app/outputs/flutter-apk/app-arm64-v8a-release.apk.sha1 \
	build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk.sha1 \
	build/app/outputs/flutter-apk/app-x86_64-release.apk.sha1 \
	release/android/

@echo off
title windows release in zip


set "SOURCE=build\windows\x64\runner\Release\"
set "DEST=..\..\..\..\..\release\windows"
set "ZIP_NAME=songbook-x86_64-windows.zip"


call flutter clean
call flutter build windows

pushd "%SOURCE%"
if not exist "%DEST%" mkdir "%DEST%"

powershell -NoProfile -Command "Compress-Archive -Path * -DestinationPath '%DEST%\%ZIP_NAME%' -Force"
popd

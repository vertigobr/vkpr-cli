#!/usr/bin/env bash

BIN_FOLDER=bin
BINARY_NAME_UNIX=run.sh
ENTRY_POINT_UNIX=main.sh
LIB_RESOURCES="../../../lib"

#bash-build:
	mkdir -p $BIN_FOLDER/src
	#shellcheck disable=SC2086
	cp -r $LIB_RESOURCES $BIN_FOLDER/src
	cp -r src/* $BIN_FOLDER
	mv $BIN_FOLDER/$ENTRY_POINT_UNIX $BIN_FOLDER/$BINARY_NAME_UNIX
	chmod +x $BIN_FOLDER/$BINARY_NAME_UNIX

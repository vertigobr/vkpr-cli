#!/bin/sh

BIN_FOLDER=bin
BINARY_NAME_UNIX=run.sh
ENTRY_POINT_UNIX=main.sh


#bash-build:
	#copy script from vkpr/utils/ instead of ~/.vkpr/src/
	mkdir -p $BIN_FOLDER/utils
	# BIN_GITLAB_OPERATION=../../../utils/gitlab-operations.sh
	#copying script from vkpr/utils/
	# cp $BIN_GITLAB_OPERATION $BIN_FOLDER/utils

	cp -r src/* $BIN_FOLDER
	mv $BIN_FOLDER/$ENTRY_POINT_UNIX $BIN_FOLDER/$BINARY_NAME_UNIX
	chmod +x $BIN_FOLDER/$BINARY_NAME_UNIX

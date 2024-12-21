#!/bin/bash

if [ "$1" == "brave" ]; then
	build-ipak --distro-file ../build/debian.tgz brave.ipakfile
else if [ "$1" == "libreoffice" ]; then
	build-ipak --distro-file ../build/alpine.tgz libreoffice.ipakfile
else if [ "$1" == "firefox" ]; then
	build-ipak --distro-file ../build/alpine.tgz firefox.ipakfile
else if [ "$1" == "gedit" ]; then
	build-ipak --distro-file ../build/alpine.tgz gedit.ipakfile
else if [ "$1" == "vscode" ]; then
	build-ipak --distro-file ../build/debian.tgz vscode.ipakfile
else
	for i in *.ipakfile; do
		build-ipak $i
	done
fi
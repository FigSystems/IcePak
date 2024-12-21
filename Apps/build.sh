#!/bin/bash

if [ "$1" == "brave" ]; then
	build-ipak --distro-file ../build/debian.tgz brave.ipakfile
	exit $?
fi
if [ "$1" == "libreoffice" ]; then
	build-ipak --distro-file ../build/alpine.tgz libreoffice.ipakfile
	exit $?
fi
if [ "$1" == "firefox" ]; then
	build-ipak --distro-file ../build/alpine.tgz firefox.ipakfile
	exit $?
fi
if [ "$1" == "gedit" ]; then
	build-ipak --distro-file ../build/alpine.tgz gedit.ipakfile
	exit $?
fi
if [ "$1" == "vscode" ]; then
	build-ipak --distro-file ../build/debian.tgz vscode.ipakfile
	exit $?
fi

for i in *.ipakfile; do
	build-ipak $i
done

exit 0
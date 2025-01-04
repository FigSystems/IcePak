#!/bin/bash

SQUASHFS_OFFSET="__SQUASHFS_OFFSET__" # Patched at IcePak creation time

if [ "$SQUASHFS_OFFSET" == "__SQUASHFS_OFFSET__" ]; then
	echo "SQUASHFS_OFFSET not set"
	echo "This is normally patched by the icepak creater script"
	echo "You can do it manually, by replacing __SQUASHFS_OFFSET__ with the value:"
	echo "(number of bytes in this file) - (length of string '__SQUASHFS_OFFSET__' - length of string \$(length of the string with the number of bytes in this file))"
	echo
	echo "We do recommend using the icepak creater script though"
	exit 1
fi

function error() {
	if which zenity > /dev/null; then
		zenity --error --text "$1"
	else
		echo Error: "$1"
	fi
}

function exit_error() {
	error "$2"
	exit $1
}

if which squashfs-mount > /dev/null; then
	echo "squashfs-mount found!"
else
	# FIXME: Offer to install it
	exit_error 1 "squashfs-mount not found!"
fi

mkdir -p /tmp/self
SQUASHFS_MOUNT_OFFSET="${SQUASHFS_OFFSET}" squashfs-mount "$1":/tmp/self -- bash <<EOF
/tmp/self/runtime.sh "$@"
EOF
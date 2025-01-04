#!/bin/bash

SQUASHFS_OFFSET=""

SQUASHFS_OFFSET=$(grep -n -x "__RUNTIME_END__" $0 -m 1 | cut -d: -f1)
SQUASHFS_OFFSET=$(head -n $SQUASHFS_OFFSET $0 | wc -c)
SQUASHFS_OFFSET=$((SQUASHFS_OFFSET + 1))

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
__RUNTIME_END__
#!/bin/bash

SQUASHFS_OFFSET=""

SQUASHFS_OFFSET=$(grep -n -x --text "__RUNTIME_END__" $0 -m 1 | cut -d: -f1)
SQUASHFS_OFFSET=$(head -n $SQUASHFS_OFFSET $0 | wc -c)
# SQUASHFS_OFFSET=$((SQUASHFS_OFFSET + 1))

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

if which dwarfs > /dev/null; then
	echo "dwarfs found!"
else
	# FIXME: Offer to install it
	exit_error 1 "dwarfs not found!"
fi

unshare -Urm -- bash -c " \
mkdir -p /tmp/self ; \
dwarfs -o offset=\"$SQUASHFS_OFFSET\" $0 /tmp/self ; \
/tmp/self/AppRun "$@" ; \
umount /tmp/self || ((sleep 1; umount /tmp/self) || (sleep 4; umount /tmp/self || echo \"Failed to unmount dwarfs!\"))"
exit 0
__RUNTIME_END__

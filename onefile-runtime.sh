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

if false; then
	echo "dwarfs found!"
else
	if which zenity > /dev/null; then
		# We have zenity!
		zenity --question --text "dwarfs not found!\nInstall? (Doesn't require root) If you aren't sure, click 'Yes'."
		if [ "$?" == "0" ]; then
			BROWSER_URL=$(curl -s https://api.github.com/repos/mhx/dwarfs/releases/latest | grep -E -o "\"https://github.com/mhx/dwarfs/releases/download/v.*\..*\..*/dwarfs-universal-.*\..*\..*-Linux-$(uname -m)-clang\"" | tr -d "\"")
			(echo "Downloading dwarfs..."; wget -O dwarfs-universal $BROWSER_URL -q || zenity --error --text 'Failed to download dwarfs. Please check your internet connection and try again.' && (echo ; echo "# Done!"; echo 100)) | zenity --progress --title="Downloading dwarfs" --auto-close --pulsate
			chmod +x dwarfs-universal
			mkdir -p ~/.local/bin
			mv dwarfs-universal ~/.local/bin/dwarfs-universal
			ln -sfT ~/.local/bin/dwarfs-universal ~/.local/bin/dwarfs
			ln -sfT ~/.local/bin/dwarfs-universal ~/.local/bin/mkdwarfs
			ln -sfT ~/.local/bin/dwarfs-universal ~/.local/bin/dwarfsck
			zenity --info --text "dwarfs installed! Click 'OK' to continue."
		else
			exit 1
		fi

	else
		echo "dwarfs not found!"
		exit 1
	fi

fi

unshare -Urm -- bash -c " \
mkdir -p /tmp/self ; \
dwarfs -o offset=\"$SQUASHFS_OFFSET\" $0 /tmp/self ; \
/tmp/self/AppRun "$@" ; \
umount /tmp/self || ((sleep 1; umount /tmp/self) || (sleep 4; umount /tmp/self || echo \"Failed to unmount dwarfs!\"))"
exit 0
__RUNTIME_END__

#!/bin/bash

# To be run from inside the IPak's directory.
# $PWD
# |- rootfs
# |- icon
# \- app.desktop

cmd="/AppRun"
POSITIONAL_ARGS=()
ALL_ARGS=()
user_cwd=""
extract_icon=""
cmd="/AppRun"
build_mode="false"

out="$(dirname $0)"
echo "out: $out"

while [[ $# -gt 0 ]]; do
  case $1 in
	--ipak-help)
		echo "Usage: $0 [arguments to contained command...]"
		echo "--ipak-help         show this help text"
		echo "--ipak-shell        run an interactive shell in the bundle"
		shift
		exit 0
		;;
	--ipak-shell)
		echo "Running interactive shell..."
		cmd="/bin/sh"
		shift
		;;
	--ipak-build-mode)
		build_mode="true"
		shift
		;;
	--ipak-cwd)
		if [ -z "$2" ]; then
			echo "Usage: $0 --ipak-cwd directory"
			exit 1
		fi
		user_cwd="$2"
		shift
		shift
		;;
    -*|--*)
	  ALL_ARGS+=("$1")
	  shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
	  ALL_ARGS+=("$1")
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

cmd="$cmd ${ALL_ARGS[@]}"

if [ "$1" == "shell" ]; then
	cmd="${ALL_ARGS[@]:1}"
fi
if [ "$1" == "set-entrypoint" ]; then
	if [ -z "$2" ]; then
		echo "Usage: $0 set-entrypoint path/to/executable"
		exit 1
	fi
	cmd="echo '#!/bin/sh' > /AppRun && echo '${ALL_ARGS[@]:1}' > /AppRun && chmod +x /AppRun"
fi
if [ "$1" == "cp" ]; then
	if [ -z "$2" ]; then
		echo "Usage: $0 cp source dest"
		exit 1
	fi
	cmd="cp -r '$(realpath $2)' '$3'"
fi

bwrap_chdir=$user_cwd

if [ "${bwrap_chdir:0:5}" != "/home" ] && [ "${bwrap_chdir:0:6}" != "/Users" ]; then
	bwrap_chdir="/"
fi

echo "Running command: $cmd"
echo "Changing directory to: $bwrap_chdir"
mkdir -p "$out/rootfs/$HOME"

####################################

if [ "$1" != "commit" ]; then
if [ "$build_mode" == "false" ]; then
# Inspired by pelf :D
# $out/rootfs/usr/bin/
bwrap --new-session \
 --bind $out/rootfs / \
 --bind /tmp /tmp \
 --proc /proc \
 --dev-bind /dev /dev \
 --bind /run /run \
 --bind-try /media /media \
 --bind-try /mnt /mnt \
 --bind-try $out/rootfs/$HOME $HOME \
 --bind-try /$HOME/Downloads $HOME/Downloads \
 --bind-try $HOME/Desktop $HOME/Desktop \
 --bind-try $HOME/Documents $HOME/Documents \
 --bind-try $HOME/Pictures $HOME/Pictures \
 --bind-try $HOME/Music $HOME/Music \
 --bind-try $HOME/Videos $HOME/Videos \
 --bind-try $HOME/Templates $HOME/Templates \
 --bind-try $HOME/Public $HOME/Public \
 --bind-try /sys /sys \
 --ro-bind-try /etc/resolv.conf /etc/resolv.conf \
 --ro-bind-try /etc/hosts /etc/hosts \
 --ro-bind-try /etc/nsswitch.conf /etc/nsswitch.conf \
 --ro-bind-try /etc/machine-id /etc/machine-id \
 --ro-bind-try /etc/asound.conf /etc/asound.conf \
 --ro-bind-try /etc/hostname /etc/hostname \
 --ro-bind-try /usr/share/fontconfig /usr/share/fontconfig \
 --ro-bind-try /usr/share/fonts /usr/share/fonts \
 --ro-bind-try /usr/share/themes /usr/share/themes \
 --ro-bind-try /lib/firmware /lib/firmware \
 --setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR" \
 --setenv HOME "$HOME" \
 --setenv XDG_CACHE_HOME "$XDG_CACHE_HOME" \
 --setenv XDG_CONFIG_HOME "$XDG_CONFIG_HOME" \
 --setenv XDG_DATA_HOME "$XDG_DATA_HOME" \
 --setenv XDG_BIN_HOME "$XDG_BIN_HOME" \
 --setenv XDG_MUSIC_DIR "$XDG_MUSIC_DIR" \
 --setenv XDG_PICTURES_DIR "$XDG_PICTURES_DIR" \
 --setenv XDG_VIDEOS_DIR "$XDG_VIDEOS_DIR" \
 --setenv XDG_DESKTOP_DIR "$XDG_DESKTOP_DIR" \
 --setenv XDG_DOCUMENTS_DIR "$XDG_DOCUMENTS_DIR" \
 --setenv XDG_DOWNLOAD_DIR "$XDG_DOWNLOAD_DIR" \
 --setenv XDG_TEMPLATES_DIR "$XDG_TEMPLATES_DIR" \
 --setenv XDG_PUBLICSHARE_DIR "$XDG_PUBLICSHARE_DIR" \
 --setenv XDG_DATA_DIRS "$XDG_DATA_DIRS" \
 --setenv PATH "/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/games:$HOME/.local/bin" \
 --setenv TERM "$TERM" \
 --setenv LANG "$LANG" \
 --setenv LANGUAGE "$LANGUAGE" \
 --setenv FAKEROOTDONTTRYCHOWN "1" \
 --unshare-all \
 --share-net \
 --chdir $bwrap_chdir \
 /bin/sh -c "$cmd"

else
# Build mode
# $out/rootfs/usr/bin/
bwrap --new-session \
 --bind $out/rootfs / \
 --proc /proc \
 --dev-bind /dev /dev \
 --ro-bind-try /home /home \
 --ro-bind-try /Users /Users \
 --ro-bind-try /etc/resolv.conf /etc/resolv.conf \
 --ro-bind-try /etc/hosts /etc/hosts \
 --ro-bind-try /etc/nsswitch.conf /etc/nsswitch.conf \
 --ro-bind-try /etc/machine-id /etc/machine-id \
 --ro-bind-try /etc/asound.conf /etc/asound.conf \
 --ro-bind-try /etc/hostname /etc/hostname \
 --setenv FAKEROOTDONTTRYCHOWN "1" \
 --setenv PATH "/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/games:$HOME/.local/bin" \
 --setenv TERM "$TERM" \
 --unshare-all \
 --share-net \
 /bin/sh -c "$cmd"
fi
fi
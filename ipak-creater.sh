#!/bin/bash

# BASEDIR=`dirname "${0}"`
# cd "$BASEDIR"

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
	-h | --help)
		echo "Usage: $0 directory output_file"
		echo "-h, --help      show this help text"
		shift
		exit 0
		;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

[ -n "$1" ] || (echo "Usage: $0 directory output_file")
[ -n "$2" ] || (echo "Usage: $0 directory output_file")

[ -n "$1" ] || exit 1
[ -n "$2" ] || exit 1

payload_in=$1
script=$2
tmp=__extract__$RANDOM
payload="__payload__$RANDOM.tar"
additions_tmp=$(mktemp -d)

echo "Compresssing payload..."
$(tar -cvf $payload -C $payload_in . || exit 1)



# Additions
mkdir -p $additions_tmp/rootfs/usr/bin
echo "Downloading bwrap..."
wget -O $additions_tmp/rootfs/usr/bin/bwrap https://github.com/ruanformigoni/bubblewrap-musl-static/releases/latest/download/bwrap-x86_64
chmod +x $additions_tmp/rootfs/usr/bin/bwrap

echo "Adding payload additions..."
tar -uvf $payload -C $additions_tmp . || exit 1



cat <<EOF > "$tmp"
#!/bin/bash
# IPak<->IPak<->IPak<->IPak

# identifier string is above.
set -e

cmd="/AppRun"
POSITIONAL_ARGS=()
ALL_ARGS=()
extract_icon=""
cmd="/AppRun"
bind_temp="true"
share_fonts="true"
build_mode="false"
output_is_tar="__OUTPUT_IS_TAR__"

while [[ \$# -gt 0 ]]; do
  case \$1 in
	--ipak-help)
		echo "Usage: \$0 [arguments to contained command...]"
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
	--ipak-no-bind-tmp)
		bind_temp="false"
		shift
		;;
	--ipak-no-share-fonts)
		share_fonts="false"
		shift
		;;
	--ipak-build-mode)
		build_mode="true"
		shift
		;;
    -*|--*)
    #   echo "Unknown option \$1"
    #   exit 1
	  ALL_ARGS+=("\$1")
	  shift
      ;;
    *)
      POSITIONAL_ARGS+=("\$1") # save positional arg
	  ALL_ARGS+=("\$1")
      shift # past argument
      ;;
  esac
done

set -- "\${POSITIONAL_ARGS[@]}" # restore positional parameters

cmd="\$cmd \${ALL_ARGS[@]}"

user_cwd="\$(pwd)"
out=\$(mktemp -d)

PAYLOAD_LINE=\`awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' \$0\`
PAYLOAD_BYTE=\$(head -n \$((PAYLOAD_LINE - 1)) \$0 | wc -c)

if [ -n "\$output_is_tar" ]; then
	tail -n+\$PAYLOAD_LINE \$0 | tar -x -C \$out
else
	squashfuse \$0 \$out -o offset=\$((PAYLOAD_BYTE))
fi

# Resolve any relative paths here before they get destroyed!!!!
selfpath=\$(realpath \$0)


# function use_host_tmp() {
# 	if [ \${bind_temp} == "true" ]; then
# 		return --bind /tmp /tmp
# 	fi
# 	return --tmpfs /tmp
# }

# function use_host_fonts() {
# 	if [ \${share_fonts} == "true" ]; then
# 		return "--ro-bind-try /usr/share/fontconfig /usr/share/fontconfig \
# 				--ro-bind-try /usr/share/fonts /usr/share/fonts"
# 	fi
# 	return
# }

function cleanup() {
	echo "Cleaning up..."
	cd /
	if [ ! -f "\$out/.mutable" ]; then
		# (overlayfs)
		if mountpoint -q -- "\$out"; then
			fusermount -u \$out || fusermount -uz \$out
		fi
	fi
	rm -rf "\$out"
}
trap cleanup ERR TERM INT KILL EXIT HUP

if [ "\$1" == "commit" ]; then
	rm -rf "\$out/.mutable"
fi
if [ "\$1" == "shell" ]; then
	cmd="\${ALL_ARGS[@]:1}"
fi
if [ "\$1" == "set-entrypoint" ]; then
	if [ -z "\$2" ]; then
		echo "Usage: \$0 set-entrypoint path/to/executable"
		exit 1
	fi
	cmd="echo '#!/bin/sh' > /AppRun && echo '\${ALL_ARGS[@]:1}' > /AppRun && chmod +x /AppRun"
fi
if [ "\$1" == "cp" ]; then
	if [ -z "\$2" ]; then
		echo "Usage: \$0 cp source dest"
		exit 1
	fi
	cmd="cp -r '\$(realpath \$2)' '\$3'"
fi

# Process optional args before sandbox
bwrap_chdir=\$user_cwd

if [ "\${bwrap_chdir:0:5}" != "/home" ] && [ "\${bwrap_chdir:0:6}" != "/Users" ]; then
	bwrap_chdir="/"
fi

echo "Running command: \$cmd"
echo "Changing directory to: \$bwrap_chdir"

cd \$out
####################################

if [ "\$1" != "commit" ]; then
if [ "\$build_mode" == "false" ]; then
# Inspired by pelf :D
\$out/rootfs/usr/bin/bwrap --new-session \
 --overlay-src \$out/rootfs \
 --tmp-overlay / \
 --uid \$(id -u) \
 --gid \$(id -g) \
 --bind /tmp /tmp \
 --proc /proc \
 --dev-bind /dev /dev \
 --bind /run /run \
 --bind-try /media /media \
 --bind-try /mnt /mnt \
 --bind-try /home /home \
 --bind-try /Users /Users \
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
 --setenv XDG_RUNTIME_DIR "\$XDG_RUNTIME_DIR" \
 --setenv HOME "\$HOME" \
 --setenv XDG_CACHE_HOME "\$XDG_CACHE_HOME" \
 --setenv XDG_CONFIG_HOME "\$XDG_CONFIG_HOME" \
 --setenv XDG_DATA_HOME "\$XDG_DATA_HOME" \
 --setenv XDG_BIN_HOME "\$XDG_BIN_HOME" \
 --setenv XDG_MUSIC_DIR "\$XDG_MUSIC_DIR" \
 --setenv XDG_PICTURES_DIR "\$XDG_PICTURES_DIR" \
 --setenv XDG_VIDEOS_DIR "\$XDG_VIDEOS_DIR" \
 --setenv XDG_DESKTOP_DIR "\$XDG_DESKTOP_DIR" \
 --setenv XDG_DOCUMENTS_DIR "\$XDG_DOCUMENTS_DIR" \
 --setenv XDG_DOWNLOAD_DIR "\$XDG_DOWNLOAD_DIR" \
 --setenv XDG_TEMPLATES_DIR "\$XDG_TEMPLATES_DIR" \
 --setenv XDG_PUBLICSHARE_DIR "\$XDG_PUBLICSHARE_DIR" \
 --setenv XDG_DATA_DIRS "\$XDG_DATA_DIRS" \
 --setenv PATH "/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/games:$HOME/.local/bin" \
 --setenv TERM "\$TERM" \
 --setenv LANG "\$LANG" \
 --setenv LANGUAGE "\$LANGUAGE" \
 --setenv FAKEROOTDONTTRYCHOWN "1" \
 --unshare-all \
 --share-net \
 --chdir \$bwrap_chdir \
 /bin/sh -c "\$cmd"

else
# Build mode
\$out/rootfs/usr/bin/bwrap --new-session \
 --bind \$out/rootfs / \
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
 --setenv TERM "\$TERM" \
 --unshare-all \
 --share-net \
 /bin/sh -c "\$cmd"
fi
fi
####################################

if [ -f "\$out/.mutable" ] || [ "\$1" == "commit" ]; then
	tmp_self_out=\$(mktemp)
	head -n \$((\$PAYLOAD_LINE - 1)) \$selfpath > \$tmp_self_out # Create the self extracting script
	if [ "\$1" == "commit" ]; then
		tmp_squashfs_out=\$(mktemp)
		sed -i -e "s/__OUTPUT_IS_TAR__//g" \$tmp_self_out
		mksquashfs \$out \$tmp_squashfs_out -noappend
		cat \$tmp_squashfs_out >> \$tmp_self_out
		rm \$tmp_squashfs_out
	else
		tar -cf - -C \$out . >> \$tmp_self_out # Create the tarball
	fi
	chmod +x \$tmp_self_out
	mv -f \$tmp_self_out \$selfpath
fi

# cd /
# rm -rf \$out/

# cd \$user_cwd

exit 0
__PAYLOAD_BELOW__
EOF

echo "Packaging final script..."
cat "$tmp" "$payload" > "$script"

echo "Cleaning up..."
rm "$tmp"
chmod +x "$script"

rm -f "$payload"

echo "Done."

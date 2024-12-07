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

payload_in=$1
script=$2
tmp=__extract__$RANDOM
payload="__payload__$RANDOM.tar"

echo "Compresssing payload..."
$(tar -cvf $payload -C $payload_in . || exit 1)

cat <<EOF > "$tmp"
#!/bin/bash

cmd="/AppRun"
POSITIONAL_ARGS=()
extract_icon=""
persistent=""
base="/tmp/root"
custom_base="false"

while [[ \$# -gt 0 ]]; do
  case \$1 in
	--appbundle-help)
		echo "Usage: \$0 [arguments to contained command...]"
		echo "--appbundle-help      show this help text"
		echo "--appbundle-shell     run an interactive shell in the bundle"
		echo "--persistent outfile  recreate bundle after execution"
		echo "--base dir            base directory for overlay"
		shift
		exit 0
		;;
	--appbundle-shell)
		cmd="/bin/bash"
		shift
		;;
	--persistent)
		persistent="\$2"
		shift
		shift
		;;
	--base)
		base="\$2"
		custom_base="true"
		shift
		shift
		;;
    -*|--*)
      echo "Unknown option \$1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("\$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "\${POSITIONAL_ARGS[@]}" # restore positional parameters

user_cwd="\$(pwd)"
out=\$(mktemp -d)

PAYLOAD_LINE=\`awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' \$0\`
tail -n+\$PAYLOAD_LINE \$0 | tar -x -C \$out

# Resolve any relative paths here before they get destroyed!!!!
if [ -n "\$persistent" ]; then
	persistent=\$(realpath \$persistent)
fi

base=\$(realpath \$base)

cd \$out
ls

# Process optional args before sandbox
bwrap_chdir=\$user_cwd

if [ "\$custom_base" = "true" ]; then
	# User provided base image
	if [ ! -d "\$base" ]; then
		echo "Base directory does not exist: \$base"
		exit 1
	fi

	bwrap_chdir="/"
fi

####################################

mkdir -p work overlay
bwrap \
 --overlay-src \$base			\
 --overlay rootfs work /		\
 --chdir "\$bwrap_chdir"		\
 --unshare-all					\
 --hostname "bubblewrapped"		\
 --share-net					\
 \$cmd \${@:1}

sleep 0.5

echo "Cleaning up..."
bwrap --bind \$base / \
 --bind work /work \
 sh -c "rm -rf work"

####################################
cd \$user_cwd

# Repackage self if persistent flag is set

if [ -n "\$persistent" ]; then
	head -n \$((\$PAYLOAD_LINE - 1)) \$0 > \$persistent # Create the self extracting script
	tar --exclude="./work" --strip-components 1 -cvf - -C \$out . >> \$persistent # Create the tarball
	chmod +x \$persistent
fi

rm -rf \$out
exit 0
__PAYLOAD_BELOW__\n"
EOF

echo "Packaging final script..."
cat "$tmp" "$payload" > "$script"

echo "Cleaning up..."
rm "$tmp"
chmod +x "$script"

rm -f "$payload"

echo "Done."

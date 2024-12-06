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

while [[ \$# -gt 0 ]]; do
  case \$1 in
	--appbundle-help)
		echo "Usage: \$0 [arguments to contained command...]"
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

cd \$out

# Process optional args before sandbox
ls

####################################

mkdir -p work overlay
bwrap \
 --overlay-src /tmp/root	\
 --overlay rootfs work /	\
 --chdir "\$user_cwd"		\
 --unshare-all \$cmd \${@:1}

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

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

echo "Compresssing payload..."
$(tar -cvf $payload -C $payload_in . || exit 1)

cat <<EOF > "$tmp"
#!/bin/bash
# IPak<->IPak<->IPak<->IPak

# identifier string is above.

cmd="/AppRun"
POSITIONAL_ARGS=()
extract_icon=""
persistent=""
base="/tmp/root"
custom_base="false"

while [[ \$# -gt 0 ]]; do
  case \$1 in
	--ipak-help)
		echo "Usage: \$0 [arguments to contained command...]"
		echo "--ipak-help         show this help text"
		echo "--ipak-shell        run an interactive shell in the bundle"
		echo "--base dir          base directory for overlay"
		shift
		exit 0
		;;
	--ipak-shell)
		cmd="/bin/bash"
		shift
		;;
	--ipak-base)
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

base=\$(realpath \$base)

cd \$out

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

bargs=()
# bargs+=( "--overlay-src" )
# bargs+=( "\$base" )

bargs+=( "--overlay-src" )
bargs+=( "\$out/rootfs" )

bargs+=( "--tmp-overlay" )
bargs+=( "/" )

bargs+=( "--chdir" )
bargs+=( "\$bwrap_chdir" )

bargs+=( "--unshare-all" )

bargs+=( "--hostname" )
bargs+=( "bubblewrapped" )

bargs+=( "--share-net" )

bargs+=( "--dev" )
bargs+=( "/dev" )

bargs+=( "\$cmd" )
bargs+=( "\${@:1}" )

bwrap "\${bargs[@]}"

####################################
cd \$user_cwd

rm -rf \$out/

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

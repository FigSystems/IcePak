#!/bin/bash

# Usage: abc.sh <payload> <script>
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
tar -cvf $payload $payload_in || exit 1

cat <<EOF > "$tmp"
#!/bin/bash

cmd="/AppRun"
POSITIONAL_ARGS=()

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

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

user_cwd="\$(pwd)"
out=\$(mktemp -d)

PAYLOAD_LINE=\`awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' \$0\`
tail -n+\$PAYLOAD_LINE \$0 | tar -x -C \$out

cd \$out/*
####################################

mkdir -p work overlay
bwrap \
 --overlay-src /tmp/root	\
 --overlay rootfs work /	\
 --chdir "\$user_cwd"		\
 --unshare-all \$cmd \${@:1}

####################################
cd \$user_cwd
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

#!/bin/bash

# Usage: abc.sh <payload> <script>
# BASEDIR=`dirname "${0}"`
# cd "$BASEDIR"

payload_in=$1
script=$2
tmp=__extract__$RANDOM
payload="__payload__$RANDOM.tar"

[ "$payload_in" != "" ] || read -e -p "Enter the path of the directory: " payload_in
[ "$script" != "" ] || read -e -p "Enter the name/path of the script: " script

echo "Compresssing payload..."
tar -cvf $payload $payload_in || exit 1

cat <<EOF > "$tmp"
#!/bin/bash

cmd="/AppRun"
case \$1 in
  "--appbundle-help")
	echo "AppBundle Help"
	echo ""
    echo "Usage: \$0 <arguments>"
    echo "    --appbundle-help : Show this help and exit"
	echo "    arguments : The (optional) arguments to the command"
	shift # Not scrictly needed but good practice
	exit 0
    ;;
  "--appbundle-shell")
	cmd="/bin/bash"
	shift
	;;
esac

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

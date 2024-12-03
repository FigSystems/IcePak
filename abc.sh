#!/bin/bash -x

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
chown $(id -u):$(id -g) $payload

cat <<EOF > "$tmp"
#!/bin/bash
user_cwd=\$(pwd)
out=\$(mktemp -d)

PAYLOAD_LINE=\`awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' \$0\`
tail -n+\$PAYLOAD_LINE \$0 | pv -p -s \$((\$(wc -c < \$0) - \$PAYLOAD_LINE)) | tar -xz -C \$out

cd \$out
####################################

ls



####################################
cd \$user_cwd
rm -rf \$out
exit 0
__PAYLOAD_BELOW__\n"
EOF

cat "$tmp" "$payload" > "$script" && rm "$tmp"
chmod +x "$script"

rm -f "$payload"
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
chown $(id -u):$(id -g) $payload

cat <<EOF > "$tmp"
#!/bin/bash
user_cwd=\$(pwd)
out=\$(mktemp -d)

PAYLOAD_LINE=\`awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' \$0\`
tail -n+\$PAYLOAD_LINE \$0 | tar -x -C \$out

cd \$out/*
####################################

ls

# Start namespace
unshare -Urm <<EOD
# Needed for pivot_root
# mount --bind rootfs rootfs
mount -t overlay overlay -o lowerdir=/,upperdir=rootfs,workdir=work overlay
cd overlay
mkdir old_root

# Pivot root (similar to chroot, but more secure)
pivot_root . old_root
# Hopefully we don't crash here... :/
cd /

# Run AppRun
./AppRun

umount old_root || (echo "Failed to unmount old_root, Can't proceed as this is insecure!"; exit 2)
EOD


####################################
cd \$user_cwd
rm -rf \$out
exit 0
__PAYLOAD_BELOW__\n"
EOF

echo "Packaging final script..."
pv "$tmp" "$payload" > "$script"

echo "Cleaning up..."
rm "$tmp"
chmod +x "$script"

rm -f "$payload"

echo "Done."
#!/bin/bash

POSITIONAL_ARGS=()

cmd=""

while [[ $# -gt 0 ]]; do
  case $1 in
	-h | --help)
		echo "Usage: $0 pkgname command output_file"
		echo "-h, --help      show this help text"
		shift
		exit 0
		;;
	--cmd)
		cmd="$2"
		shift
		shift
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

if [ -z "$1" ]; then
	echo "Usage: $0 pkgname output_file"
	exit 1
fi
if [ -z "$2" ]; then
	echo "Usage: $0 pkgname output_file"
	exit 1
fi
if [ -z "$3" ]; then
	echo "Usage: $0 pkgname output_file"
	exit 1
fi


echo "Please authenticate at the sudo prompt."

# Check if the __ipak_cache__/dbase directory exists
if [ ! -d "__ipak_cache__/dbase" ]; then
	mkdir -p "__ipak_cache__/dbase"
	sudo debootstrap --variant=minbase stable __ipak_cache__/dbase http://deb.debian.org/debian
fi

pkg_out=$(mktemp -d)
mkdir -p "${pkg_out}/rootfs"
sudo cp -r __ipak_cache__/dbase/* ${pkg_out}/rootfs/
ls "${pkg_out}/rootfs"
# workdir=$(mktemp -d)
# merged=$(mktemp -d)
# sudo mount -t overlay overlay \
#  -o lowerdir="__ipak_cache__/dbase",upperdir="${pkg_out}/rootfs",workdir="$workdir" \
#  "$merged"

sudo arch-chroot "${pkg_out}/rootfs" /bin/bash <<EOF
apt update -y
apt install -y $1
$cmd
EOF

# sudo umount "$merged"
# if [ $? -ne 0 ]; then
# 	sleep 4
# 	sudo umount "$merged"
# fi
# sudo rm -Rf "$merged"
# sudo rm -Rf "$workdir"


cat <<EOF > "$pkg_out/rootfs/AppRun"
#!/bin/bash
$2 \$@
exit \$?
EOF
chmod +x "$pkg_out/rootfs/AppRun"

sudo rm -Rf "$pkg_out/rootfs/dev"
mkdir "$pkg_out/rootfs/dev"

sudo chown -R "$USER":"$USER" "$pkg_out"
./ipak-creater.sh "$pkg_out" "$3"


rm -Rf "$pkg_out"

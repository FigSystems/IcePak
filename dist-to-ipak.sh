#!/bin/bash
shopt -s extglob

POSITIONAL_ARGS=()

cmd=""
dist=""
output_file=""

while [[ $# -gt 0 ]]; do
  case $1 in
	-h | --help)
		echo "Usage: $0 --dist <distro> --out output_file"
		echo "-h, --help      show this help text"
		echo "--dist          distribution to use for the rootfs"
		echo "                Run --help-dists for a list of distro/distroless bases"
		shift
		exit 0
		;;
	--help-dists)
		echo "Available distros:"
		echo "    alpine"
		echo "    debian"
		exit 0
		;;
	--dist)
		dist="$2"
		shift
		shift
		;;
	-o|--out)
		output_file="$2"
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

ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/alpine-minirootfs-3.21.0-x86_64.tar.gz"


if [ -z "$dist" ]; then
	echo "You need to specify a distro. using --dist <distro>."
	echo "What? You think we're just going to pick one for you?"
	echo "Think again! Hahaha!"
	echo ";)"
	exit 1
fi
if [ -z "$output_file" ]; then
	echo "You need to specify an output file. using --out <output_file>."
	exit 1
fi

base=""
if [ "$dist" == "debian" ]; then
	# Check if the __ipak_cache__/dbase directory exists
	if [ ! -d "__ipak_cache__/dbase" ]; then
		mkdir -p "__ipak_cache__/dbase"
		echo "Please authenticate at the sudo prompt to create debian base"
		sudo debootstrap --variant=minbase stable __ipak_cache__/dbase http://deb.debian.org/debian
		sudo chown -R "$USER":"$USER" "__ipak_cache__/dbase"
	fi
	base="__ipak_cache__/dbase"
elif [ "$dist" == "alpine" ]; then
	# Check if the __ipak_cache__/abase directory exists
	if [ ! -d "__ipak_cache__/abase" ]; then
		mkdir -p "__ipak_cache__/abase"
		echo "Downloading alpine base..."
		cd ./__ipak_cache__/abase
		wget -O- $ALPINE_URL | tar xz
		cd ../..
	fi
	base="__ipak_cache__/abase"
else
	echo "Unknown distro: $dist"
	exit 1
fi

pkg_out=$(mktemp -d)
mkdir -p "${pkg_out}/rootfs"
cp -r $base/!(dev) ${pkg_out}/rootfs/
ls "${pkg_out}/rootfs"

mkdir -p $pkg_out/rootfs/etc
sudo touch $pkg_out/rootfs/etc/resolv.conf

touch "$pkg_out/.mutable"

mkdir "$pkg_out/rootfs/dev"

# sudo chown -R "$USER":"$USER" "$pkg_out"
./ipak-creater.sh "$pkg_out" "$output_file"


rm -Rf "$pkg_out"

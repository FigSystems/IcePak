#!/bin/bash

sudo debootstrap focal base_img https://archive.ubuntu.com/ubuntu
sudo arch-chroot base_img /bin/bash <<EOF
# Any packages that can be assumed to be on any system (except libc)
apt install -y linux-headers-5.4.0-26-generic linux-image-5.6.0-1007-oem locales
apt install -y coreutils bash util-linux
apt install -y network-manager
EOF

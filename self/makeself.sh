#!/bin/bash

rm -Rf self
mkdir self
mkdir self/rootfs
cp ../ipak-creater.sh self/rootfs/
cp ../dist-to-ipak.sh self/rootfs/
cp ../build.sh self/rootfs/

ln -sf build.sh self/rootfs/AppRun

# To be expanded upon

../ipak-creater.sh self self.app
rm -Rf self